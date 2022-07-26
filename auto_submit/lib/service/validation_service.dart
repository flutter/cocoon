// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/github_service.dart';
import 'package:auto_submit/service/graphql_service.dart';
import 'package:auto_submit/service/log.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/unknown_mergeable.dart';
import 'package:graphql/client.dart' as graphql;

import '../model/auto_submit_query_result.dart';
import '../request_handling/pubsub.dart';
import '../validations/approval.dart';
import '../validations/change_requested.dart';
import '../validations/conflicting.dart';
import '../validations/empty_checks.dart';
import '../validations/validation.dart';
import 'package:github/github.dart' as github;

/// Provides an extensible and standardized way to validate different aspects of
/// a commit to ensure it is ready to land, it has been reviewed, and it has been
/// tested. The expectation is that the list of validation will grow overtime.
class ValidationService {
  ValidationService(this.config) {
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

  final Config config;
  final Set<Validation> validations = <Validation>{};

  /// Checks if a pullRequest is still open before trying to process it.
  Future<bool> shouldProcess(github.PullRequest pullRequest) async {
    github.RepositorySlug slug = pullRequest.base!.repo!.slug();
    github.GitHub gitHub = await config.createGithubClient(pullRequest.base!.repo!.slug());
    github.PullRequest currentPullRequest = await gitHub.pullRequests.get(slug, pullRequest.number!);
    // Accepted states open, closed, or all.
    return currentPullRequest.state == 'open';
  }

  /// Processes a pub/sub message associated with PullRequest event.
  Future<void> processMessage(github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    if (!await shouldProcess(messagePullRequest)) {
      log.info('Shout not process ${messagePullRequest.toJson()}, and ack the message.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      return;
    }

    final github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final graphql.GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);
    final int? prNumber = messagePullRequest.number;
    GraphQlService graphQlService = GraphQlService();
    final Map<String, dynamic> data = await graphQlService.queryGraphQL(
      slug,
      prNumber!,
      graphQLClient,
    );
    QueryResult queryResult = QueryResult.fromJson(data);
    await processPullRequest(config, queryResult, messagePullRequest, ackId, pubsub);
  }

  /// Processes a PullRequest.
  ///
  /// If it is a ToT revert, the PR will be landed without validations.
  /// If it is not a ToT revert, the PR will be landed if all validations pass.
  Future<void> processPullRequest(
      Config config, QueryResult result, github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
    final PullRequest pullRequest = result.repository!.pullRequest!;
    Commit commit = pullRequest.commits!.nodes!.single.commit!;
    final String? sha = commit.oid;
    final GithubService gitHubService = await config.createGithubService(slug);
    final bool isTotRevert = await checkIsTotRevert(sha!, slug, gitHubService);
    bool shouldMergePR = false;
    if (!isTotRevert) {
      shouldMergePR = await checkShoudMergePR(config, result, messagePullRequest, ackId, pubsub, slug, gitHubService);
      if (!shouldMergePR) {
        return;
      }
    }
    // If we got to this point it means we are ready to submit the PR.
    bool processed = await processMerge(config, result, messagePullRequest, sha);
    if (processed) {
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('Acked the processed message : $ackId.');
    }
  }

  /// Check if the `commitSha` is a clean revert of TOT commit.
  ///
  /// A clean revert of TOT commit only reverts all changes made by TOT, thus should be
  /// equivalent to the second TOT commit. When comparing the current commit with second
  /// TOT commit, empty `files` in `GitHubComparison` validates a clean revert of TOT commit.
  ///
  /// Note: [compareCommits] expects base commit first, and then head commit.
  Future<bool> checkIsTotRevert(String headSha, github.RepositorySlug slug, GithubService githubService) async {
    final github.RepositoryCommit secondTotCommit = await githubService.getCommit(slug, 'HEAD~');
    log.info('Current commit is: $headSha');
    log.info('Second TOT commit is: ${secondTotCommit.sha}');
    final github.GitHubComparison githubComparison =
        await githubService.compareTwoCommits(slug, secondTotCommit.sha!, headSha);
    final bool filesIsEmpty = githubComparison.files!.isEmpty;
    if (filesIsEmpty) {
      log.info('This is a TOT revert. Merge ignoring tests statuses.');
    }
    return filesIsEmpty;
  }

  /// Check if a PullRequest is mergeable.
  ///
  /// The check conducts several validations to decide whether to land the commit
  /// or remove the autosubmit label.
  Future<bool> checkShoudMergePR(Config config, QueryResult result, github.PullRequest messagePullRequest, String ackId,
      PubSub pubsub, github.RepositorySlug slug, GithubService gitHubService) async {
    List<ValidationResult> results = <ValidationResult>[];

    /// Runs all the validation defined in the service.
    for (Validation validation in validations) {
      ValidationResult validationResult = await validation.validate(result, messagePullRequest);
      results.add(validationResult);
    }

    /// If there is at least one action that requires to remove label do so and add comments for all the failures.
    bool shouldReturn = false;
    final int prNumber = messagePullRequest.number!;
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        final String commmentMessage = result.message.isEmpty ? 'Validations Fail.' : result.message;
        await gitHubService.createComment(slug, prNumber, commmentMessage);
        await gitHubService.removeLabel(slug, prNumber, config.autosubmitLabel);
        log.info('auto label is removed for ${slug.fullName}, pr: $prNumber, due to $commmentMessage');
        shouldReturn = true;
      }
    }
    if (shouldReturn) {
      log.info('The pr ${slug.fullName}/$prNumber with message: $ackId should be acknoledged.');
      await pubsub.acknowledge('auto-submit-queue-sub', ackId);
      log.info('The pr ${slug.fullName}/$prNumber is not feasible for merge and message: $ackId is acknowledged.');
      return false;
    }
    // If PR has some failures to ignore temporarily do nothing and continue.
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.IGNORE_TEMPORARILY) {
        return false;
      }
    }
    return true;
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<bool> processMerge(
      Config config, QueryResult queryResult, github.PullRequest messagePullRequest, String sha) async {
    String id = queryResult.repository!.pullRequest!.id!;
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();

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
}
