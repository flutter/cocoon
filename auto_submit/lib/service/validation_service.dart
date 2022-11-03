// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/exception/bigquery_exception.dart';
import 'package:auto_submit/model/big_query_pull_request_record.dart';
import 'package:auto_submit/model/big_query_revert_request_record.dart';
import 'package:auto_submit/model/pull_request_change_type.dart';
import 'dart:async';

import 'package:auto_submit/service/bigquery.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/service/revert_review_template.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/unknown_mergeable.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;
import 'package:retry/retry.dart';

import '../exception/retryable_exception.dart';
import '../model/auto_submit_query_result.dart';
import '../request_handling/pubsub.dart';
import '../validations/approval.dart';
import '../validations/change_requested.dart';
import '../validations/conflicting.dart';
import '../validations/empty_checks.dart';
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

    validations.addAll({
      /// Validates the PR has been approved following the codereview guidelines.
      Approval(config: config),

      /// Validates all the tests ran and where successful.
      CiSuccessful(config: config),

      /// Validates there are no pending change requests.
      ChangeRequested(config: config),

      /// Validates that the list of checks is not empty.
      EmptyChecks(config: config),

      /// Validates the PR state is in a well known state.
      UnknownMergeable(config: config),

      /// Validates the PR is conflict free.
      Conflicting(config: config),
    });
  }

  Revert? revertValidation;
  ApproverService? approverService;
  final Config config;
  final Set<Validation> validations = <Validation>{};
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
    final GithubService gitHubService = await config.createGithubService(slug);
    final github.PullRequest currentPullRequest = await gitHubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<github.IssueLabel>)
        .map<String>((github.IssueLabel labelMap) => labelMap.name)
        .toList();

    if (currentPullRequest.state == 'open' && labelNames.contains(Config.kRevertLabel)) {
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

    /// Runs all the validation defined in the service.
    for (Validation validation in validations) {
      final ValidationResult validationResult = await validation.validate(result, messagePullRequest);
      results.add(validationResult);
    }
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.message.isEmpty ? 'Validations Fail.' : result.message;

        final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commmentMessage';

        await removeLabelAndComment(
          githubService: gitHubService,
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
      githubService: gitHubService,
      config: config,
      queryResult: result,
      messagePullRequest: messagePullRequest,
    );

    if (!processed.result) {
      final String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, ${processed.message}.';

      await removeLabelAndComment(
        githubService: gitHubService,
        repositorySlug: slug,
        prNumber: prNumber,
        prLabel: Config.kAutosubmitLabel,
        message: message,
      );

      log.info(message);
    } else {
      log.info('Pull Request ${slug.fullName}#$prNumber was merged successfully!');
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
    final ValidationResult revertValidationResult = await revertValidation!.validate(result, messagePullRequest);

    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;
    final GithubService gitHubService = await config.createGithubService(slug);

    if (revertValidationResult.result) {
      // Approve the pull request automatically as it has been validated.
      await approverService!.revertApproval(result, messagePullRequest);

      final ProcessMergeResult processed = await processMerge(
        githubService: gitHubService,
        config: config,
        queryResult: result,
        messagePullRequest: messagePullRequest,
      );

      if (processed.result) {
        log.info('Revert request ${slug.fullName}#$prNumber was merged successfully.');
        try {
          final RevertReviewTemplate revertReviewTemplate = RevertReviewTemplate(
            repositorySlug: slug.fullName,
            revertPrNumber: prNumber,
            revertPrAuthor: result.repository!.pullRequest!.author!.login!,
            originalPrLink: revertValidation!.extractLinkFromText(messagePullRequest.body)!,
          );

          final github.Issue issue = await gitHubService.createIssue(
            // Created issues are created and tracked within flutter/flutter.
            slug: github.RepositorySlug(Config.flutter, Config.flutter),
            title: revertReviewTemplate.title!,
            body: revertReviewTemplate.body!,
            labels: <String>['P1'],
            assignee: result.repository!.pullRequest!.author!.login!,
          );
          log.info('Issue #${issue.id} was created to track the review for pr# $prNumber in ${slug.fullName}');

          log.info('Attempting to insert a revert pull request record into the database for pr# $prNumber');
          await insertPullRequestRecord(
            config: config,
            pullRequest: messagePullRequest,
            pullRequestType: PullRequestChangeType.revert,
          );

          log.info('Attempting to insert a revert tracking request record into the database for pr# $prNumber');
          await insertRevertRequestRecord(
            config: config,
            revertPullRequest: messagePullRequest,
            reviewIssue: issue,
          );
        } on github.GitHubError catch (exception) {
          // We have merged but failed to create follow up issue.
          final String errorMessage = '''
An exception has occurred while attempting to create the follow up review issue for pr# $prNumber.
Please create a follow up issue to track a review for this pull request.
Exception: ${exception.message}
''';
          log.warning(errorMessage);
          await gitHubService.createComment(slug, prNumber, errorMessage);
        }
      } else {
        final String message = 'revert label is removed for ${slug.fullName}, pr#: $prNumber, ${processed.message}.';

        await removeLabelAndComment(
          githubService: gitHubService,
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
        githubService: gitHubService,
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
    required GithubService githubService,
    required Config config,
    required QueryResult queryResult,
    required github.PullRequest messagePullRequest,
  }) async {
    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int number = messagePullRequest.number!;

    try {
      github.PullRequestMerge? result;

      await retryOptions.retry(
        () async {
          result = await _processMergeInternal(
            githubService: githubService,
            slug: slug,
            number: number,
            // TODO(ricardoamador): make this configurable per repository, https://github.com/flutter/flutter/issues/114557
            mergeMethod: github.MergeMethod.squash,
          );
        },
        retryIf: (Exception e) => e is RetryableException,
      );

      if (result != null && !result!.merged!) {
        final String message = 'Failed to merge pr#: $number with ${result!.message}';
        log.severe(message);
        return ProcessMergeResult(false, message);
      }
    } catch (e) {
      // Catch graphql client init exceptions.
      final String message = 'Failed to merge pr#: $number with ${e.toString()}';
      log.severe(message);
      return ProcessMergeResult(false, message);
    }

    return ProcessMergeResult.noMessage(true);
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
      log.info('Record inserted for pull request pr# ${pullRequest.number} successfully.');
    } on BigQueryException catch (exception) {
      log.severe('Unable to insert pull request record due to: ${exception.toString()}');
    }
  }

  Future<void> insertRevertRequestRecord({
    required Config config,
    required github.PullRequest revertPullRequest,
    required github.Issue reviewIssue,
  }) async {
    final github.RepositorySlug slug = revertPullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);
    // Get the updated revert issue.
    final github.PullRequest currentPullRequest = await gitHubService.getPullRequest(slug, revertPullRequest.number!);
    // Get the original pull request issue.
    final String originalPullRequestLink = revertValidation!.extractLinkFromText(revertPullRequest.body)!;
    final int originalPullRequestNumber = int.parse(originalPullRequestLink.split('#').elementAt(1));
    // return int.parse(linkSplit.elementAt(1));
    final github.PullRequest originalPullRequest = await gitHubService.getPullRequest(slug, originalPullRequestNumber);

    final RevertRequestRecord revertRequestRecord = RevertRequestRecord(
      organization: currentPullRequest.base!.repo!.slug().owner,
      repository: currentPullRequest.base!.repo!.slug().name,
      author: currentPullRequest.user!.login,
      prNumber: revertPullRequest.number,
      prCommit: currentPullRequest.head!.sha,
      prCreatedTimestamp: currentPullRequest.createdAt,
      prLandedTimestamp: currentPullRequest.closedAt,
      originalPrAuthor: originalPullRequest.user!.login,
      originalPrNumber: originalPullRequest.number,
      originalPrCommit: originalPullRequest.head!.sha,
      originalPrCreatedTimestamp: originalPullRequest.createdAt,
      originalPrLandedTimestamp: originalPullRequest.closedAt,
      reviewIssueAssignee: reviewIssue.assignee!.login,
      reviewIssueNumber: reviewIssue.number,
      reviewIssueCreatedTimestamp: reviewIssue.createdAt,
    );

    try {
      final BigqueryService bigqueryService = await config.createBigQueryService();
      await bigqueryService.insertRevertRequestRecord(
        projectId: Config.flutterGcpProjectId,
        revertRequestRecord: revertRequestRecord,
      );
      log.info('Record inserted for revert tracking request for pr# ${revertPullRequest.number} successfully.');
    } on BigQueryException catch (exception) {
      log.severe(exception.toString());
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
  required GithubService githubService,
  required github.RepositorySlug slug,
  required int number,
  required github.MergeMethod mergeMethod,
  String? commitMessage,
  String? requestSha,
}) async {
  final github.PullRequestMerge pullRequestMerge = await githubService.mergePullRequest(
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
