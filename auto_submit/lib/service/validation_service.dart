// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/big_query_pull_request_record.dart';
import 'package:cocoon_server/bigquery.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';

import '../exception/retryable_exception.dart';
import '../model/auto_submit_query_result.dart';
import '../model/pull_request_data_types.dart';
import '../requests/graphql_queries.dart';
import 'config.dart';
import 'graphql_service.dart';

/// Class containing common methods to each of the pull request type validation
/// services.
class ValidationService {
  ValidationService(this.config, {RetryOptions? retryOptions})
    : retryOptions = retryOptions ?? Config.mergeRetryOptions;

  final Config config;
  final RetryOptions retryOptions;

  /// Fetch the most up to date info for the current pull request from github.
  Future<QueryResult> getNewestPullRequestInfo(
    Config config,
    github.PullRequest pullRequest,
  ) async {
    final slug = pullRequest.base!.repo!.slug();
    final prNumber = pullRequest.number;

    final graphQlService = await GraphQlService.forRepo(config, slug);

    final findPullRequestsWithReviewsQuery = FindPullRequestsWithReviewsQuery(
      repositoryOwner: slug.owner,
      repositoryName: slug.name,
      pullRequestNumber: prNumber!,
    );

    final data = await graphQlService.queryGraphQL(
      documentNode: findPullRequestsWithReviewsQuery.documentNode,
      variables: findPullRequestsWithReviewsQuery.variables,
    );

    return QueryResult.fromJson(data);
  }

  Future<github.PullRequest> getFullPullRequest(
    github.RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    final githubService = await config.createGithubService(slug);
    return githubService.getPullRequest(slug, pullRequestNumber);
  }

  /// Merges the commit if the PullRequest passes all the validations.
  Future<MergeResult> submitPullRequest({
    required Config config,
    required github.PullRequest pullRequest,
  }) async {
    final slug = pullRequest.base!.repo!.slug();
    final number = pullRequest.number!;

    // Pass an explicit commit message from the PR title otherwise the GitHub API will use the first commit message.
    const revertPattern = 'Revert "Revert';
    var messagePrefix = '';

    if (pullRequest.title!.contains(revertPattern)) {
      // Cleanup auto-generated revert messages.
      messagePrefix = '''
${pullRequest.title!.replaceFirst('Revert "Revert', 'Reland')}

''';
    }

    final prBody = _sanitizePrBody(pullRequest.body ?? '');
    final commitMessage = '$messagePrefix$prBody';

    if (pullRequest.isMergeQueueEnabled) {
      return _enqueuePullRequest(slug, pullRequest);
    } else {
      return _mergePullRequest(number, commitMessage, slug);
    }
  }

  Future<MergeResult> _enqueuePullRequest(
    github.RepositorySlug slug,
    github.PullRequest restPullRequest,
  ) async {
    final graphQlService = await GraphQlService.forRepo(config, slug);
    final isEmergencyPullRequest =
        restPullRequest.labels
            ?.where((label) => label.name == Config.kEmergencyLabel)
            .isNotEmpty ??
        false;

    try {
      await retryOptions.retry(() async {
        await graphQlService.enqueuePullRequest(
          slug,
          restPullRequest.number!,
          isEmergencyPullRequest,
        );
      }, retryIf: (Exception e) => e is RetryableException);
    } catch (e) {
      final message =
          'Failed to enqueue ${slug.fullName}/${restPullRequest.number} with $e';
      log.severe(message);
      return (result: false, message: message, method: SubmitMethod.enqueue);
    }

    return (
      result: true,
      message: restPullRequest.title!,
      method: SubmitMethod.enqueue,
    );
  }

  Future<MergeResult> _mergePullRequest(
    int number,
    String commitMessage,
    github.RepositorySlug slug,
  ) async {
    try {
      github.PullRequestMerge? result;

      await retryOptions.retry(() async {
        result = await _processMergeInternal(
          config: config,
          commitMessage: commitMessage,
          slug: slug,
          number: number,
          mergeMethod: github.MergeMethod.squash,
        );
      }, retryIf: (Exception e) => e is RetryableException);

      final merged = result?.merged ?? false;
      if (result != null && !merged) {
        final message =
            'Failed to merge ${slug.fullName}/$number with ${result?.message}';
        log.severe(message);
        return (result: false, message: message, method: SubmitMethod.merge);
      }
    } catch (e) {
      // Catch graphql client init exceptions.
      final message = 'Failed to merge ${slug.fullName}/$number with $e';
      log.severe(message);
      return (result: false, message: message, method: SubmitMethod.merge);
    }

    return (result: true, message: commitMessage, method: SubmitMethod.merge);
  }

  /// Insert a merged pull request record into the database.
  Future<void> insertPullRequestRecord({
    required Config config,
    required github.PullRequest pullRequest,
    required PullRequestChangeType pullRequestType,
  }) async {
    final slug = pullRequest.base!.repo!.slug();
    final gitHubService = await config.createGithubService(slug);
    // We need the updated time fields for the merged request from github.
    final currentPullRequest = await gitHubService.getPullRequest(
      slug,
      pullRequest.number!,
    );

    // add a record for the pull request into our metrics tracking
    final pullRequestRecord = PullRequestRecord(
      organization: currentPullRequest.base!.repo!.slug().owner,
      repository: currentPullRequest.base!.repo!.slug().name,
      author: currentPullRequest.user!.login,
      prNumber: pullRequest.number!,
      prCommit: currentPullRequest.head!.sha,
      prRequestType: pullRequestType.name,
      prCreatedTimestamp: currentPullRequest.createdAt!,
      prLandedTimestamp: currentPullRequest.closedAt!,
    );

    try {
      final bigqueryService = await config.createBigQueryService();
      await bigqueryService.insertPullRequestRecord(
        projectId: Config.flutterGcpProjectId,
        pullRequestRecord: pullRequestRecord,
      );
    } on BigQueryException catch (exception) {
      log.severe(
        'Failed to insert pull request record into BigQuery for pull request ${slug.fullName}/${pullRequest.number} due to: $exception',
      );
    }
  }
}

/// Method used to submit the PR for merging.
enum SubmitMethod {
  /// The PR is enqueued into the merge queue, and the merge queue is responsible
  /// for merging the PR.
  enqueue('enqueued'),

  /// The PR is immediately merged into the target branch.
  ///
  /// This is the old method for merging PRs, used by repos where merge queues
  /// are not (yet?) enabled.
  merge('merged');

  const SubmitMethod(this.pastTenseLabel);

  /// The verb in past tense used to describe what happened to a PR when this
  /// submit method was used, e.g. "merged".
  final String pastTenseLabel;
}

/// Small wrapper class to allow us to capture and create a comment in the PR with
/// the issue that caused the merge failure.
typedef MergeResult = ({bool result, String message, SubmitMethod method});

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
  log.info('Attempting to merge ${slug.fullName}/$number.');
  final gitHubService = await config.createGithubService(slug);
  final pullRequestMerge = await gitHubService.mergePullRequest(
    slug,
    number,
    commitMessage: commitMessage,
    mergeMethod: mergeMethod,
    requestSha: requestSha,
  );

  if (pullRequestMerge.merged != true) {
    throw RetryableException(
      'Pull request ${slug.fullName}/$number could not be merged: ${pullRequestMerge.message}',
    );
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
  var lastLineWasEmpty = false;
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

/// Repos that use MQ-based workflow.
///
/// This variable is read-write to allow tests to choose which repos they want
/// to test in which mode.
List<String> mqEnabledRepos = const <String>['flutter/flutter'];

/// Convenience extension so one can just do `pullRequest.isMergeQueueEnabled`.
extension PullRequestExtension on github.PullRequest {
  /// Whether this pull requests must be merged via a merge queue.
  bool get isMergeQueueEnabled {
    final baseRef = base!.ref;
    if (baseRef != 'main' && baseRef != 'master') {
      // MQ is only enabled for main and master branches.
      return false;
    }

    final slug = base!.repo!.slug();
    return mqEnabledRepos.contains(slug.fullName);
  }

  /// Extracts label names from the `IssueLabel` list [labels].
  List<String> get labelNames {
    final labels = this.labels;
    if (labels == null) {
      return const <String>[];
    }

    return labels.map<String>((label) => label.name).toList();
  }
}
