// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/pull_request_change_type.dart';
import 'dart:async';

import 'package:auto_submit/service/bigquery.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/validation_filter.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:retry/retry.dart';

import '../exception/retryable_exception.dart';
import '../model/auto_submit_query_result.dart';
import '../request_handling/pubsub.dart';
import '../validations/validation.dart';
import 'approver_service.dart';

/// Provides an extensible and standardized way to validate different aspects of
/// a commit to ensure it is ready to land, it has been reviewed, and it has been
/// tested. The expectation is that the list of validation will grow overtime.
class ValidationService {
  ValidationService(this.config, {RetryOptions? retryOptions})
      : retryOptions = retryOptions ?? Config.mergeRetryOptions {
    /// Validates a PR marked with the reverts label.
    revertValidation = Revert(config: config);
    approverService = ApproverService(config);
  }

  Revert? revertValidation;
  ApproverService? approverService;
  final Config config;
  final RetryOptions retryOptions;

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    final ProcessMethod processMethod = await processPullRequestMethod(messagePullRequest);

    switch (processMethod) {
      case ProcessMethod.processAutosubmit:
        await processPullRequest(
          config: config,
          result: await getNewestPullRequestInfo(config, messagePullRequest),
          messagePullRequest: messagePullRequest,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      case ProcessMethod.processRevert:
        await processRevertRequest(
          config: config,
          result: await getNewestPullRequestInfo(config, messagePullRequest),
          messagePullRequest: messagePullRequest,
          ackId: ackId,
          pubsub: pubsub,
        );
        break;
      case ProcessMethod.doNotProcess:
        log.info('Should not process ${messagePullRequest.toJson()}, and ack the message.');
        await pubsub.acknowledge('auto-submit-queue-sub', ackId);
        break;
    }
  }

  /// Fetch the most up to date info for the current pull request from github.
  Future<QueryResult> getNewestPullRequestInfo(Config config, github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final graphql.GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);
    final int? prNumber = pullRequest.number;
    final GraphQlService graphQlService = GraphQlService();
    final Map<String, dynamic> data = await graphQlService.queryGraphQL(
      slug,
      prNumber!,
      graphQLClient,
    );
    return QueryResult.fromJson(data);
  }

  /// Checks if a pullRequest is still open and with autosubmit label before trying to process it.
  Future<ProcessMethod> processPullRequestMethod(github.PullRequest pullRequest) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest currentPullRequest = await githubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    if (currentPullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
      if (!repositoryConfiguration.supportNoReviewReverts) {
        log.info(
          'Cannot allow revert request (${slug.fullName}/${pullRequest.number}) without review. Processing as regular pull request.',
        );
        return ProcessMethod.processAutosubmit;
      }
      return ProcessMethod.processRevert;
    } else if (currentPullRequest.state == 'open' && labelNames.contains(Config.kAutosubmitLabel)) {
      return ProcessMethod.processAutosubmit;
    } else {
      return ProcessMethod.doNotProcess;
    }
  }

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.
  Future<void> processPullRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    final List<ValidationResult> results = <ValidationResult>[];
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final RepositoryConfiguration repositoryConfiguration = await config.getRepositoryConfiguration(slug);

    // filter out validations here
    final ValidationFilter validationFilter = ValidationFilter(
      config,
      ProcessMethod.processAutosubmit,
      repositoryConfiguration,
    );
    final Set<Validation> validations = validationFilter.getValidations();

    /// Runs all the validation defined in the service.
    /// If the runCi flag is false then we need a way to not run the ciSuccessful validation.
    for (Validation validation in validations) {
      final ValidationResult validationResult = await validation.validate(
        result,
        messagePullRequest,
      );
      results.add(validationResult);
    }

    final GithubService githubService = await config.createGithubService(slug);

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.message.isEmpty ? 'Validations Fail.' : result.message;

        final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commmentMessage';

        await removeLabelAndComment(
          githubService: githubService,
          repositorySlug: slug,
          prNumber: prNumber,
          prLabel: Config.kAutosubmitLabel,
          message: message,
        );

        log.info(message);

        shouldReturn = true;
      }
    }

    if (shouldReturn) {
      log.info('The pr ${slug.fullName}/$prNumber with message: $ackId should be acknowledged.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
      return;
    }

    // If PR has some failures to ignore temporarily do nothing and continue.
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.IGNORE_TEMPORARILY) {
        return;
      }
    }

    // If we got to this point it means we are ready to submit the PR.
    final ProcessMergeResult processed = await processMerge(
      config: config,
      messagePullRequest: messagePullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, ${processed.message}.';

      await removeLabelAndComment(
        githubService: githubService,
        repositorySlug: slug,
        prNumber: prNumber,
        prLabel: Config.kAutosubmitLabel,
        message: message,
      );

      log.info(message);
    } else {
      log.info('Pull Request ${slug.fullName}/$prNumber was merged successfully!');
      log.info('Attempting to insert a pull request record into the database for $prNumber');

      await insertPullRequestRecord(
        config: config,
        pullRequest: messagePullRequest,
        pullRequestType: PullRequestChangeType.change,
      );
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }

  /// The logic for processing a revert request and opening the follow up
  /// review issue in github.
  Future<void> processRevertRequest({
    required Config config,
    required QueryResult result,
    required github.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    // get validations to be run here.
    final ValidationResult revertValidationResult = await revertValidation!.validate(
      result,
      messagePullRequest,
    );

    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;
    final GithubService githubService = await config.createGithubService(slug);

    if (revertValidationResult.result) {
      // Approve the pull request automatically as it has been validated.
      await approverService!.revertApproval(result, messagePullRequest);

      final ProcessMergeResult processed = await processMerge(
        config: config,
        messagePullRequest: messagePullRequest,
      );

      if (processed.result) {
        log.info('Revert request ${slug.fullName}/$prNumber was merged successfully.');
        log.info('Insert a revert pull request record into the database for pr ${slug.fullName}/$prNumber');
        await insertPullRequestRecord(
          config: config,
          pullRequest: messagePullRequest,
          pullRequestType: PullRequestChangeType.revert,
        );
      } else {
        final String message = 'revert label is removed for ${slug.fullName}/$prNumber, ${processed.message}.';
        await removeLabelAndComment(
          githubService: githubService,
          repositorySlug: slug,
          prNumber: prNumber,
          prLabel: Config.kRevertLabel,
          message: message,
        );

        log.info(message);
      }
    } else if (!revertValidationResult.result && revertValidationResult.action == Action.IGNORE_TEMPORARILY) {
      // if required check runs have not completed process again.
      log.info('Some of the required checks have not completed. Requeueing.');
      return;
    } else {
      // since we do not temporarily ignore anything with a revert request we
      // know we will report the error and remove the label.
      final String commentMessage =
          revertValidationResult.message.isEmpty ? 'Validations Fail.' : revertValidationResult.message;

      await removeLabelAndComment(
        githubService: githubService,
        repositorySlug: slug,
        prNumber: prNumber,
        prLabel: Config.kRevertLabel,
        message: commentMessage,
      );

      log.info('revert label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<ProcessMergeResult> processMerge({
    required Config config,
    required github.PullRequest messagePullRequest,
  }) async {
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int number = messagePullRequest.number!;

    // Determine if the pull request is mergeable before we attempt to merge it.
    final ProcessMergeResult mergeResult = await isMergeable(
      slug,
      number,
    );
    if (!mergeResult.result) {
      return mergeResult;
    }

    // Pass an explicit commit message from the PR title otherwise the GitHub API will use the first commit message.
    const String revertPattern = 'Revert "Revert';
    String messagePrefix = '';

    if (messagePullRequest.title!.contains(revertPattern)) {
      // Cleanup auto-generated revert messages.
      messagePrefix = '''
${messagePullRequest.title!.replaceFirst('Revert "Revert', 'Reland')}

''';
    }

    final String prBody = _sanitizePrBody(messagePullRequest.body ?? '');
    final String commitMessage = '$messagePrefix$prBody';

    try {
      github.PullRequestMerge? result;

      await retryOptions.retry(
        () async {
          result = await _processMergeInternal(
            config: config,
            commitMessage: commitMessage,
            slug: slug,
            number: number,
            // TODO(ricardoamador): make this configurable per repository, https://github.com/flutter/flutter/issues/114557
            mergeMethod: github.MergeMethod.squash,
          );
        },
        retryIf: (Exception e) => e is RetryableException,
      );

      final bool merged = result?.merged ?? false;
      if (result != null && !merged) {
        final String message = 'Failed to merge ${slug.fullName}/$number with ${result?.message}';
        log.severe(message);
        return ProcessMergeResult(false, message);
      }
    } catch (e) {
      // Catch graphql client init exceptions.
      final String message = 'Failed to merge ${slug.fullName}/$number with ${e.toString()}';
      log.severe(message);
      return ProcessMergeResult(false, message);
    }

    return ProcessMergeResult(true, commitMessage);
  }

  /// Determine if a pull request is mergeable at this time.
  Future<ProcessMergeResult> isMergeable(github.RepositorySlug slug, int pullRequestNumber) async {
    final GithubService githubService = await config.createGithubService(slug);
    final github.PullRequest pullRequest = await githubService.getPullRequest(slug, pullRequestNumber);

    bool result = true;
    String message = 'Pull request ${slug.fullName}/$pullRequestNumber is mergeable';
    if (pullRequest.mergeable == null) {
      message =
          'Mergeability of pull request ${slug.fullName}/$pullRequestNumber could not be determined at time of merge.';
      result = false;
    } else if (pullRequest.mergeable == false) {
      result = false;
      message = 'Pull request ${slug.fullName}/$pullRequestNumber is not in a mergeable state.';
    }
    log.info(message);
    return ProcessMergeResult(result, message);
  }

  /// Remove a pull request label and add a comment to the pull request.
  Future<void> removeLabelAndComment({
    required GithubService githubService,
    required github.RepositorySlug repositorySlug,
    required int prNumber,
    required String prLabel,
    required String message,
  }) async {
    await githubService.removeLabel(repositorySlug, prNumber, prLabel);
    await githubService.createComment(repositorySlug, prNumber, message);
  }

  /// Insert a merged pull request record into the database.
  Future<void> insertPullRequestRecord({
    required Config config,
    required github.PullRequest pullRequest,
    required PullRequestChangeType pullRequestType,
  }) async {
    final github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);
    // We need the updated time fields for the merged request from github.
    final github.PullRequest currentPullRequest = await gitHubService.getPullRequest(slug, pullRequest.number!);

    log.info('Updated pull request info: ${currentPullRequest.toString()}');

    // add a record for the pull request into our metrics tracking
    final PullRequestRecord pullRequestRecord = PullRequestRecord(
      organization: currentPullRequest.base!.repo!.slug().owner,
      repository: currentPullRequest.base!.repo!.slug().name,
      author: currentPullRequest.user!.login,
      prNumber: pullRequest.number!,
      prCommit: currentPullRequest.head!.sha,
      prRequestType: pullRequestType.name,
      prCreatedTimestamp: currentPullRequest.createdAt!,
      prLandedTimestamp: currentPullRequest.closedAt!,
    );

    log.info('Created pull request record: ${pullRequestRecord.toString()}');

    try {
      final BigqueryService bigqueryService = await config.createBigQueryService();
      await bigqueryService.insertPullRequestRecord(
        projectId: Config.flutterGcpProjectId,
        pullRequestRecord: pullRequestRecord,
      );
      log.info('Record inserted for pull request ${slug.fullName}/${pullRequest.number} successfully.');
    } on BigQueryException catch (exception) {
      log.severe('Unable to insert pull request record due to: ${exception.toString()}');
    }
  }
}

/// Small wrapper class to allow us to capture and create a comment in the PR with
/// the issue that caused the merge failure.
class ProcessMergeResult {
  ProcessMergeResult.noMessage(this.result);
  ProcessMergeResult(this.result, this.message);

  bool result = false;
  String? message;
}

/// Function signature that will be executed with retries.
typedef RetryHandler = Function();

/// Internal wrapper for the logic of merging a pull request into github.
Future<github.PullRequestMerge> _processMergeInternal({
  required Config config,
  required github.RepositorySlug slug,
  required int number,
  required github.MergeMethod mergeMethod,
  String? commitMessage,
  String? requestSha,
}) async {
  // This is retryable so to guard against token expiration we get a fresh
  // client each time.
  final GithubService gitHubService = await config.createGithubService(slug);
  final github.PullRequestMerge pullRequestMerge = await gitHubService.mergePullRequest(
    slug,
    number,
    commitMessage: commitMessage,
    mergeMethod: mergeMethod,
    requestSha: requestSha,
  );

  if (pullRequestMerge.merged != true) {
    throw RetryableException("Pull request could not be merged: ${pullRequestMerge.message}");
  }

  return pullRequestMerge;
}

final RegExp _kCheckboxPattern = RegExp(r'^\s*-[ ]?\[( |x|X)\]');
final RegExp _kCommentPattern = RegExp(r'<!--.*-->');
final RegExp _kMarkdownLinkRefDef = RegExp(r'^\[[\w\/ -]+\]:');
final RegExp _kPreLaunchHeader = RegExp(r'## Pre-launch Checklist');
final RegExp _kDiscordPattern = RegExp(r'#hackers-new');

String _sanitizePrBody(String rawPrBody) {
  final buffer = StringBuffer();
  bool lastLineWasEmpty = false;
  for (final line in rawPrBody.split('\n')) {
    if (_kCheckboxPattern.hasMatch(line) ||
        _kCommentPattern.hasMatch(line) ||
        _kMarkdownLinkRefDef.hasMatch(line) ||
        _kPreLaunchHeader.hasMatch(line) ||
        _kDiscordPattern.hasMatch(line)) {
      continue;
    }
    if (line.trim().isEmpty) {
      // we don't need to include multiple empty lines
      if (lastLineWasEmpty) {
        continue;
      }
      lastLineWasEmpty = true;
    } else {
      lastLineWasEmpty = false;
    }
    buffer.writeln(line);
  }
  return buffer.toString().trim();
}
