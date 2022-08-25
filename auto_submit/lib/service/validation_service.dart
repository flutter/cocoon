// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/revert.dart';
import 'package:auto_submit/validations/unknown_mergeable.dart';
import 'package:github/github.dart' as gh;
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
  final Config config;
  final Set<Validation> validations = <Validation>{};

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(gh.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
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
        log.info('Shout not process ${messagePullRequest.toJson()}, and ack the message.');
        await pubsub.acknowledge('auto-submit-queue-sub', ackId);
        break;
    }
  }

  /// Fetch the most up to date info for the current pull request from github.
  Future<QueryResult> getNewestPullRequestInfo(Config config, gh.PullRequest pullRequest) async {
    final gh.RepositorySlug slug = pullRequest.base!.repo!.slug();
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
  Future<ProcessMethod> processPullRequestMethod(gh.PullRequest pullRequest) async {
    final gh.RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);
    final gh.PullRequest currentPullRequest = await gitHubService.getPullRequest(slug, pullRequest.number!);
    final List<String> labelNames = (currentPullRequest.labels as List<gh.IssueLabel>)
        .map<String>((gh.IssueLabel labelMap) => labelMap.name)
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
      required gh.PullRequest messagePullRequest, 
      required String ackId, 
      required PubSub pubsub}) async {
    List<ValidationResult> results = <ValidationResult>[];

    /// Runs all the validation defined in the service.
    for (Validation validation in validations) {
      ValidationResult validationResult = await validation.validate(result, messagePullRequest);
      results.add(validationResult);
    }
    gh.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final GithubService gitHubService = await config.createGithubService(slug);

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commentMessage = result.message.isEmpty ? 'Validations Failed.' : result.message;
        log.info('auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');
        await removeLabelAndComment(
          githubService: gitHubService, 
          repositorySlug: slug, 
          prNumber: prNumber, 
          prLabel: Config.kAutosubmitLabel, 
          message: commentMessage);
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
    await processMergeSafely(
        config: config, 
        gitHubService: gitHubService, 
        messagePullRequest: messagePullRequest, 
        queryResult: result, 
        pubSub: pubsub, 
        ackId: ackId, 
        repositorySlug: slug, 
        prNumber: prNumber, 
        prLabel: Config.kAutosubmitLabel);
  }

  /// The logic for processing a revert request and opening the follow up
  /// review issue in github.
  Future<void> processRevertRequest({
    required Config config,
    required QueryResult result,
    required gh.PullRequest messagePullRequest,
    required String ackId,
    required PubSub pubsub,
  }) async {
    ValidationResult revertValidationResult = await revertValidation!.validate(result, messagePullRequest);

    gh.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final int prNumber = messagePullRequest.number!;
    final GithubService githubService = await config.createGithubService(slug);

    if (revertValidationResult.result) {
      try {
        bool processed = await processMerge(config, result, messagePullRequest);
        if (processed) {
          gh.Issue issue = await githubService.createIssue(
            slug,
            'Follow up review for revert pull request $prNumber',
            'Revert request by author ${result.repository!.pullRequest!.author}',
          );
          log.info('Issue #${issue.id} was created to track the review for $prNumber in ${slug.fullName}');
        } else {
          String message = 'Unable to merge pull request $prNumber.';
          log.warning(message);
          await removeLabelAndComment(
            githubService: githubService, 
            repositorySlug: slug, 
            prNumber: prNumber, 
            prLabel: Config.kRevertLabel, 
            message: message);
        }
      } catch (exception) {
        String message = '''
An exception occurred during merge of pull request $prNumber, removing the revert label.
Exception: ${exception.toString()}
''';
        log.severe(message);
        await removeLabelAndComment(
          githubService: githubService, 
          repositorySlug: slug, 
          prNumber: prNumber, 
          prLabel: Config.kRevertLabel, 
          message: message);
      }

      // We will acknowledge in any case so do it here.
      log.info('Ack the processed message : $ackId.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
    } else {
      // Since we do not temporarily ignore anything with a revert request we
      // know we will report the error and remove the label.
      final String commentMessage =
          revertValidationResult.message.isEmpty ? 'Validation Failed.' : revertValidationResult.message;
      log.info('revert label is removed for ${slug.fullName}, pr: $prNumber, due to $commentMessage');
      await removeLabelAndComment(
        githubService: githubService, 
        repositorySlug: slug,
        prNumber: prNumber, 
        prLabel: Config.kRevertLabel, 
        message: commentMessage);
      log.info('The pr ${slug.fullName}/$prNumber with message: $ackId should be acknowledged.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
    }
  }

  /// Safe merge that wraps the merging process so that we can fail gracefully and
  /// process the pull request correctly.
  Future<bool> processMergeSafely({
      required Config config,
      required GithubService gitHubService,
      required gh.PullRequest messagePullRequest,
      required QueryResult queryResult,
      required PubSub pubSub,
      required String ackId,
      required gh.RepositorySlug repositorySlug,
      required int prNumber,
      required String prLabel}) async {
    try {
      bool processed = await processMerge(config, queryResult, messagePullRequest);

      if (!processed) {
        String message = 'Unable to merge pull request $prNumber.';
        log.warning(message);
        await removeLabelAndComment(
          githubService: gitHubService, 
          repositorySlug: repositorySlug, 
          prNumber: prNumber, 
          prLabel: prLabel, 
          message: message);
      }

      log.info('Ack the processed message : $ackId.');
      await pubSub.acknowledge('auto-submit-queue-sub', ackId);
      return processed;
    } catch (exception) {
      String message = '''
An exception occurred during merge of pull request $prNumber, removing the autosubmit label.
Exception: ${exception.toString()}
''';
      log.severe(message);
      await removeLabelAndComment(
        githubService: gitHubService, 
        repositorySlug: repositorySlug, 
        prNumber: prNumber, 
        prLabel: prLabel, 
        message: message);
      log.info('Ack the processed message : $ackId.');
      await pubSub.acknowledge('auto-submit-queue-sub', ackId);
      return false;
    }
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<bool> processMerge(Config config, QueryResult queryResult, gh.PullRequest messagePullRequest) async {
    String id = queryResult.repository!.pullRequest!.id!;
    gh.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final PullRequest pullRequest = queryResult.repository!.pullRequest!;
    Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final String? sha = commit.oid;
    int number = messagePullRequest.number!;
    final graphql.GraphQLClient client = await config.createGitHubGraphQLClient(slug);

    try {
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

  /// Remove the requested label and add a comment to the target pull request issue.
  Future<void> removeLabelAndComment({
      required GithubService githubService, 
      required gh.RepositorySlug repositorySlug, 
      required int prNumber,
      required String prLabel, 
      required String message}) async {
    await githubService.removeLabel(repositorySlug, prNumber, prLabel);
    await githubService.createComment(repositorySlug, prNumber, message);
  }
}
