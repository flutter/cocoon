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

  /// Processes a PullRequest running several validations to decide whether to
  /// land the commit or remove the autosubmit label.
  Future<void> processPullRequest(
      Config config, QueryResult result, github.PullRequest messagePullRequest, String ackId, PubSub pubsub) async {
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
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.REMOVE_LABEL) {
        await gitHubService.createComment(slug, messagePullRequest.number!, result.message);
        shouldReturn = true;
      }
    }
    if (shouldReturn) {
      pubsub.acknowledge('auto-submit-queue-sub', ackId);
      return;
    }
    // If PR has some failures to ignore temporarily do nothing and continue.
    for (ValidationResult result in results) {
      if (!result.result && result.action == Action.IGNORE_TEMPORARILY) {
        return;
      }
    }
    // If we got to this point it means we are ready to submit the PR.
    bool processed = await processMerge(config, result, messagePullRequest);
    if (processed) await pubsub.acknowledge('auto-submit-queue-sub', ackId);
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<bool> processMerge(Config config, QueryResult queryResult, github.PullRequest messagePullRequest) async {
    String id = queryResult.repository!.pullRequest!.id!;
    github.RepositorySlug slug = messagePullRequest.base!.repo!.slug();
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
}
