// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/unknown_mergeable.dart';
import 'package:github/github.dart' as github;
import 'package:graphql/client.dart' as graphql;

import '../model/auto_submit_query_result.dart';
import '../request_handling/pubsub.dart';
import '../validations/approval.dart';
import '../validations/change_requested.dart';
import '../validations/conflicting.dart';
import '../validations/empty_checks.dart';
import '../validations/validation.dart';

/// Provides an extensible and standardized way to validate different aspects of
/// a commit to ensure it is ready to land, it has been reviewed, and it has been
/// tested. The expectation is that the list of validation will grow overtime.
class ValidationService {
  ValidationService(this.config) {
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

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    ProcessMethod processMethod = await processPullRequestMethod(messagePullRequest);

    switch (processMethod) {
      case ProcessMethod.processAutosubmit:
        await processPullRequest(
            config: config,
            result: await getNewestPullRequestInfo(config, messagePullRequest),
            messagePullRequest: messagePullRequest,
            ackId: ackId,
            pubsub: pubsub);
        break;
      case ProcessMethod.processRevert:
        await processRevertRequest(
            config: config,
            result: await getNewestPullRequestInfo(config, messagePullRequest),
            messagePullRequest: messagePullRequest,
            ackId: ackId,
            pubsub: pubsub);
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
    GraphQlService graphQlService = GraphQlService();
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
    List<ValidationResult> results = <ValidationResult>[];

    /// Runs all the validation defined in the service.
    for (Validation validation in validations) {
      ValidationResult validationResult = await validation.validate(result, messagePullRequest);
      results.add(validationResult);
    }
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.message.isEmpty ? 'Validations Fail.' : result.message;

        String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commmentMessage';

        log.info(message);
        await removeLabelAndComment(
            githubService: gitHubService,
            repositorySlug: slug,
            prNumber: prNumber,
            prLabel: Config.kAutosubmitLabel,
            message: message);

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
    bool processed = await processMerge(config: config, queryResult: result, messagePullRequest: messagePullRequest);

    if (!processed) {
      String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, merge did not succeed.';
      log.info(message);
      await removeLabelAndComment(
          githubService: gitHubService,
          repositorySlug: slug,
          prNumber: prNumber,
          prLabel: Config.kAutosubmitLabel,
          message: message);
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
    ValidationResult revertValidationResult = await revertValidation!.validate(result, messagePullRequest);

    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;
    final GithubService gitHubService = await config.createGithubService(slug);

    if (revertValidationResult.result) {
      // Approve the pull request automatically as it has been validated.
      await approverService!.revertApproval(result, messagePullRequest);

      bool processed = await processMerge(
          config: config,
          queryResult: result,
          messagePullRequest: messagePullRequest,);

      if (processed) {
        try {
          github.Issue issue = await gitHubService.createIssue(
            repositorySlug: github.RepositorySlug('flutter', 'flutter'),
            title: 'Follow up review for revert pull request $prNumber',
            body: 'Revert request by author ${result.repository!.pullRequest!.author}',
            labels: <String>['P1'],
          );
          log.info('Issue #${issue.id} was created to track the review for $prNumber in ${slug.fullName}');
        } on github.GitHubError catch (exception) {
          // We have merged but failed to create follow up issue.
          String errorMessage = '''
An exception has occurred while attempting to create the follow up review issue for $prNumber.
Please create a follow up issue to track a review for this pull request.
Exception: ${exception.message}
''';
          log.warning(errorMessage);
          await gitHubService.createComment(slug, prNumber, errorMessage);
        }
      } else {
        String message = 'auto label is removed for ${slug.fullName}, pr: $prNumber, merge did not succeed.';
        log.info(message);
        await removeLabelAndComment(
            githubService: gitHubService,
            repositorySlug: slug,
            prNumber: prNumber,
            prLabel: Config.kRevertLabel,
            message: message,);
      }
    } else {
      // since we do not temporarily ignore anything with a revert request we
      // know we will report the error and remove the label.
      final String commentMessage =
          revertValidationResult.message.isEmpty ? 'Validations Fail.' : revertValidationResult.message;
      log.info('revert label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');

      await removeLabelAndComment(
          githubService: gitHubService,
          repositorySlug: slug,
          prNumber: prNumber,
          prLabel: Config.kRevertLabel,
          message: commentMessage,);

      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
    }

    log.info('Ack the processed message : $ackId.');
    await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<bool> processMerge({
    required Config config,
    required QueryResult queryResult,
    required github.PullRequest messagePullRequest,
  }) async {
    String id = queryResult.repository!.pullRequest!.id!;
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final PullRequest pullRequest = queryResult.repository!.pullRequest!;
    Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final String? sha = commit.oid;
    int number = messagePullRequest.number!;

    try {
      // The createGitHubGraphQLClient can throw Exception on github permissions
      // errors.
      final graphql.GraphQLClient client = await config.createGitHubGraphQLClient(slug);

      final graphql.QueryResult result = await client.mutate(graphql.MutationOptions(
        document: mergePullRequestMutation,
        variables: <String, dynamic>{
          'id': id,
          'oid': sha,
          'title': '${queryResult.repository!.pullRequest!.title} (#$number)',
        },
      ));
      if (result.hasException) {
        log.severe('Failed to merge pr#: $number with ${result.exception.toString()}');
        return false;
      }
    } catch (e) {
      log.severe('_processMerge error in $slug: $e');
      return false;
    }
    return true;
  }

  /// Remove a pull request label and add a comment to the pull request.
  Future<void> removeLabelAndComment(
      {required GithubService githubService,
      required github.RepositorySlug repositorySlug,
      required int prNumber,
      required String prLabel,
      required String message}) async {
    await githubService.removeLabel(repositorySlug, prNumber, prLabel);
    await githubService.createComment(repositorySlug, prNumber, message);
  }
}
