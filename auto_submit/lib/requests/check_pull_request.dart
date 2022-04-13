// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:shelf/shelf.dart';
import 'package:graphql/client.dart' hide Response, Request;

import 'check_pull_request_queries.dart';
import 'exceptions.dart';
import '../request_handling/authentication.dart';
import '../request_handling/pubsub.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import '../service/log.dart';
import '../server/authenticated_request_handler.dart';

/// Maximum number of pull requests to merge on each check on each repo.
/// This should be kept reasonably low to avoid flooding infra when the tree
/// goes green.
const int _kMergeCountPerRepo = 1;

/// Handler for processing pull requests with 'autosubmit' label.
///
/// For pull requests where an 'autosubmit' label was added in pubsub,
/// check if the pull request is mergable.
class CheckPullRequest extends AuthenticatedRequestHandler {
  CheckPullRequest({
    required Config config,
    required CronAuthProvider cronAuthProvider,
    this.pubsub = const PubSub(),
  }) : super(config: config, cronAuthProvider: cronAuthProvider);

  final PubSub pubsub;

  static const int kPullMesssageBatchSize = 100;

  @override
  Future<Response> get() async {
    final List<Response> responses = <Response>[];
    final pub.PullResponse pullResponse = await pubsub.pull('auto-submit-queue-sub', kPullMesssageBatchSize);
    final List<pub.ReceivedMessage>? receivedMessages = pullResponse.receivedMessages;
    if (receivedMessages == null) {
      log.info('There are no requests in the queue');
      return Response.ok('No requests in the queue.');
    }
    final List<Future<Response>> futures = <Future<Response>>[];
    //The repoPullRequestsMap stores the repo name and the set of PRs ready to merge to this repo
    final Map<String, Set<PullRequest>> repoPullRequestsMap = <String, Set<PullRequest>>{};
    for (pub.ReceivedMessage message in receivedMessages) {
      futures.add(_processMessage(message, repoPullRequestsMap));
    }
    responses.addAll(await Future.wait(futures));

    await checkPullRequests(repoPullRequestsMap);
    final StringBuffer responseMessages = StringBuffer();
    for (Response response in responses) {
      responseMessages.write(await response.readAsString());
    }
    return Response.ok(responseMessages.toString());
  }

  /// Check and merge the pull requests to each repo this cycle.
  ///
  /// The number of pull requests to be merged to each repo will not exceed
  /// the _kMergeCountPerRepo
  Future<List<Map<int, String>>> checkPullRequests(Map<String, Set<PullRequest>> repoPullRequestsMap) async {
    final List<Map<int, String>> responses = <Map<int, String>>[];
    for (String repoName in repoPullRequestsMap.keys) {
      // Merge first _kMergeCountPerRepo counts of pull requests to each repo
      for (int index = 0; index < repoPullRequestsMap[repoName]!.length; index++) {
        final PullRequest pullRequest = repoPullRequestsMap[repoName]!.elementAt(index);
        if (index < _kMergeCountPerRepo) {
          final bool mergeResult = await _processMerge(pullRequest);
          if (mergeResult) {
            responses.add(<int, String>{pullRequest.number!: 'merged'});
          } else {
            responses.add(<int, String>{pullRequest.number!: 'unmerged'});
          }
        } else {
          await pubsub.publish('auto-submit-queue', repoPullRequestsMap[repoName]!.elementAt(index));
          responses.add(<int, String>{pullRequest.number!: 'queued'});
        }
      }
    }
    return responses;
  }

  Future<bool> _processMerge(PullRequest pullRequest) async {
    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final int number = pullRequest.number!;
    final GithubService gitHub = await config.createGithubService(slug);
    PullRequestMerge mergeResult = await gitHub.merge(slug, number);
    final bool? merged = mergeResult.merged;
    if (merged == null) {
      log.warning('Can not merge the pull request $number. ${mergeResult.message}.');
      await pubsub.publish('auto-submit-queue', pullRequest);
    } else if (merged) {
      log.info('Merged the pull request $number in ${slug.fullName} repository.');
      return true;
    } else {
      log.warning('Failed to merge the pull request $number. ${mergeResult.message}.');
      await pubsub.publish('auto-submit-queue', pullRequest);
    }
    return false;
  }

  Future<Response> _processMessage(
      pub.ReceivedMessage receivedMessage, Map<String, Set<PullRequest>> repoPullRequestsMap) async {
    final String messageData = receivedMessage.message!.data!;
    final rawBody = json.decode(String.fromCharCodes(base64.decode(messageData))) as Map<String, dynamic>;
    final PullRequest pullRequest = PullRequest.fromJson(rawBody);
    log.info('Got the Pull Request ${pullRequest.number} from pubsub.');

    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final GithubService gitHub = await config.createGithubService(slug);
    final GraphQLClient graphQLClient = await config.createGitHubGraphQLClient(slug);

    final _AutoMergeQueryResult queryResult = await _parseQueryData(pullRequest, gitHub, graphQLClient);
    if (await shouldMergePullRequest(queryResult, slug, gitHub)) {
      final bool hasAutosubmitLabel = queryResult.labels.any((label) => label == config.autosubmitLabel);
      if (hasAutosubmitLabel) {
        if (!repoPullRequestsMap.containsKey(slug.fullName)) {
          repoPullRequestsMap[slug.fullName] = <PullRequest>{};
        }
        repoPullRequestsMap[slug.fullName]!.add(pullRequest);
        await pubsub.acknowledge('auto-submit-queue-sub', receivedMessage.ackId!);
        return Response.ok('Should merge the pull request ${queryResult.number} in ${slug.fullName} repository.');
      } else {
        await pubsub.acknowledge('auto-submit-queue-sub', receivedMessage.ackId!);
        return Response.ok('Does not merge the pull request ${queryResult.number} for no autosubmit label any more.');
      }
    } else if (queryResult.shouldRemoveLabel) {
      log.info('Removing label for commit: ${queryResult.sha}');
      await _removeLabel(queryResult, gitHub, slug, config.autosubmitLabel);
      log.info('Removed the label for commit: ${queryResult.sha}');
      await pubsub.acknowledge('auto-submit-queue-sub', receivedMessage.ackId!);
      log.info('Acknowledged the pubsub for commit: ${queryResult.sha}');
      return Response.ok('Remove the autosubmit label for commit: ${queryResult.sha}.');
    } else {
      log.info('The pull request ${queryResult.number} has unfinished tests,'
          'leave it at pubsub and check later.');
    }
    return Response.ok('Does not merge the pull request ${queryResult.number}.');
  }

  Future<Map<String, dynamic>> _queryGraphQL(
    RepositorySlug slug,
    int prNumber,
    GraphQLClient client,
  ) async {
    final QueryResult result = await client.query(
      QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': slug.owner,
          'sName': slug.name,
          'sPrNumber': prNumber,
        },
      ),
    );

    if (result.hasException) {
      log.severe(result.exception.toString());
      throw const BadRequestException('GraphQL query failed');
    }
    return result.data!;
  }

  /// Check if the pull request should be merged.
  ///
  /// A pull request should be merged on either cases:
  /// 1) All tests have finished running and satified basic merge requests
  /// 2) Not all tests finish but this is a clean revert of the Tip of Tree (TOT) commit.
  Future<bool> shouldMergePullRequest(
      _AutoMergeQueryResult queryResult, RepositorySlug slug, GithubService github) async {
    log.info('Before checking should merge logic');
    // Check the label again before merge the pull request.
    if (queryResult.shouldMerge) {
      return true;
    }
    // If the PR is a revert of the tot commit, merge without waiting for checks passing.
    return await isTOTRevert(queryResult.sha!, slug, github);
  }

  /// Check if the `commitSha` is a clean revert of TOT commit.
  ///
  /// A clean revert of TOT commit only reverts all changes made by TOT, thus should be
  /// equivalent to the second TOT commit. When comparing the current commit with second
  /// TOT commit, empty `files` in `GitHubComparison` validates a clean revert of TOT commit.
  ///
  /// Note: [compareCommits] expects base commit first, and then head commit.
  Future<bool> isTOTRevert(String headSha, RepositorySlug slug, GithubService github) async {
    final RepositoryCommit secondTotCommit = await github.getCommit(slug, 'HEAD~');
    log.info('Current commit is: $headSha');
    log.info('Second TOT commit is: ${secondTotCommit.sha}');
    final GitHubComparison githubComparison = await github.compareTwoCommits(slug, secondTotCommit.sha!, headSha);
    final bool filesIsEmpty = githubComparison.files!.isEmpty;
    if (filesIsEmpty) {
      log.info('This is a TOT revert. Merge ignoring tests statuses.');
    }
    return filesIsEmpty;
  }

  /// Removes the 'autosubmit' label if this PR should not be merged.
  ///
  /// Returns true if we successfully remove the label.
  Future<bool> _removeLabel(
      _AutoMergeQueryResult queryResult, GithubService gitHub, RepositorySlug slug, String label) async {
    final String commentBody = queryResult.removalMessage;
    await gitHub.createComment(slug, queryResult.number!, commentBody);
    final bool result = await gitHub.removeLabel(slug, queryResult.number!, config.autosubmitLabel);
    if (!result) {
      log.info('Failed to remove the autosubmit label.');
      return false;
    }
    return true;
  }

  /// Parses the Rest API query to a [_AutoMergeQueryResult].
  ///
  /// This method will not return null, but may return an empty list.
  Future<_AutoMergeQueryResult> _parseQueryData(
      PullRequest pr, GithubService gitHub, GraphQLClient graphQLClient) async {
    // This is used to remove the bot label as it requires manual intervention.
    final bool isConflicting = pr.mergeable == false;
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = pr.mergeableState == 'UNKNOWN';

    final RepositorySlug slug = pr.base!.repo!.slug();
    final int? prNumber = pr.number;
    final Map<String, dynamic> data = await _queryGraphQL(
      slug,
      prNumber!,
      graphQLClient,
    );
    final Map<String, dynamic>? repository = data['repository'] as Map<String, dynamic>?;
    if (repository == null || repository.isEmpty) {
      throw StateError('Query did not return a repository.');
    }
    final Map<String, dynamic> pullRequest = repository['pullRequest'] as Map<String, dynamic>;
    final String authorAssociation = pullRequest['authorAssociation'] as String;

    final Map<String, dynamic> commit = pullRequest['commits']['nodes'].single['commit'] as Map<String, dynamic>;
    List<Map<String, dynamic>> statuses = <Map<String, dynamic>>[];
    if (commit['status'] != null &&
        commit['status']['contexts'] != null &&
        (commit['status']['contexts'] as List<dynamic>).isNotEmpty) {
      statuses.addAll((commit['status']['contexts'] as List<dynamic>).cast<Map<String, dynamic>>());
    }

    final List<Map<String, dynamic>> reviews =
        (pullRequest['reviews']['nodes'] as List<dynamic>).cast<Map<String, dynamic>>();

    final Set<String?> changeRequestAuthors = <String?>{};
    final Set<_FailureDetail> failures = <_FailureDetail>{};
    final String? sha = pr.head!.sha;
    final String? author = pr.user!.login;

    // List of labels associated with the pull request.
    final List<String> labelNames =
        (pr.labels as List<IssueLabel>).map<String>((IssueLabel labelMap) => labelMap.name).toList();

    List<CheckRun> checkRuns = <CheckRun>[];
    if (pr.head != null && sha != null) {
      checkRuns.addAll(await gitHub.getCheckRuns(slug, sha));
    }

    final bool hasApproval = config.rollerAccounts.contains(author) ||
        _checkApproval(
          author,
          authorAssociation,
          reviews,
          changeRequestAuthors,
        );
    final bool ciSuccessful = await _checkStatuses(
      slug,
      failures,
      statuses,
      checkRuns,
      slug.name,
      labelNames,
    );
    return _AutoMergeQueryResult(
      ciSuccessful: ciSuccessful,
      failures: failures,
      hasApprovedReview: hasApproval,
      changeRequestAuthors: changeRequestAuthors,
      number: prNumber,
      sha: sha,
      emptyChecks: checkRuns.isEmpty,
      isConflicting: isConflicting,
      unknownMergeableState: unknownMergeableState,
      labels: labelNames,
    );
  }

  /// Returns whether all statuses are successful.
  ///
  /// Also fills [failures] with the names of any status/check that has failed.
  Future<bool> _checkStatuses(
    RepositorySlug slug,
    Set<_FailureDetail> failures,
    List<Map<String, dynamic>> statuses,
    List<CheckRun> checkRuns,
    String name,
    List<String> labels,
  ) async {
    assert(failures.isEmpty);
    bool allSuccess = true;

    // The status checks that are not related to changes in this PR.
    const Set<String> notInAuthorsControl = <String>{
      'luci-flutter', // flutter repo
      'luci-engine', // engine repo
      'submit-queue', // plugins repo
    };

    // Ensure repos with tree statuses have it set
    if (Config.reposWithTreeStatus.contains(slug)) {
      bool treeStatusExists = false;
      final String treeStatusName = 'luci-${slug.name}';

      // Scan list of statuses to see if the tree status exists (this list is expected to be <5 items)
      for (Map<String, dynamic> status in statuses) {
        if (status['context'] == treeStatusName) {
          treeStatusExists = true;
        }
      }

      if (!treeStatusExists) {
        failures.add(_FailureDetail('tree status $treeStatusName', 'https://flutter-dashboard.appspot.com/#/build'));
      }
    }

    final String overrideTreeStatusLabel = config.overrideTreeStatusLabel;
    log.info('Validating name: $name, status: $statuses');
    for (Map<String, dynamic> status in statuses) {
      final String? name = status['context'] as String?;
      if (status['state'] != 'SUCCESS') {
        if (notInAuthorsControl.contains(name) && labels.contains(overrideTreeStatusLabel)) {
          continue;
        }
        allSuccess = false;
        if (status['state'] == 'FAILURE' && !notInAuthorsControl.contains(name)) {
          failures.add(_FailureDetail(name!, status['targetUrl'] as String));
        }
      }
    }

    log.info('Validating name: $name, checks: $checkRuns');
    for (CheckRun checkRun in checkRuns) {
      final String? name = checkRun.name;
      if (checkRun.conclusion == CheckRunConclusion.success) {
        continue;
      } else if (checkRun.status == CheckRunStatus.completed) {
        failures.add(_FailureDetail(name!, checkRun.detailsUrl as String));
      }
      allSuccess = false;
    }
    return allSuccess;
  }
}

/// Parses the restApi response reviews.
///
/// If author is a MEMBER or OWNER then it only requires a single review from
/// another MEMBER or OWNER. If the author is not a MEMBER or OWNER then it
/// requires two reviews from MEMBERs or OWNERS.
///
/// If there are any CHANGES_REQUESTED reviews, checks if the same author has
/// subsequently APPROVED.  From testing, dismissing a review means it won't
/// show up in this list since it will have a status of DISMISSED and we only
/// ask for CHANGES_REQUESTED or APPROVED - however, adding a new review does
/// not automatically dismiss the previous one.
///
/// If the author has not subsequently approved or dismissed the review, the
/// name will be added to the changeRequestAuthors set.
///
/// Returns false if no approved reviews or any oustanding change request
/// reviews.
///
/// Returns true if at least one approved review and no outstanding change
/// request reviews.
bool _checkApproval(
  String? author,
  String? authorAssociation,
  List<Map<String, dynamic>> reviewNodes,
  Set<String?> changeRequestAuthors,
) {
  assert(changeRequestAuthors.isEmpty);
  const Set<String> allowedReviewers = <String>{'MEMBER', 'OWNER'};
  final Set<String?> approvers = <String?>{};
  if (allowedReviewers.contains(authorAssociation)) {
    approvers.add(author);
  }

  for (Map<String, dynamic> review in reviewNodes) {
    // Ignore reviews from non-members/owners.
    if (!allowedReviewers.contains(review['authorAssociation'])) {
      continue;
    }
    // Reviews come back in order of creation.
    final String? state = review['state'] as String?;
    final String? authorLogin = review['author']['login'] as String?;
    if (state == 'APPROVED') {
      approvers.add(authorLogin);
      changeRequestAuthors.remove(authorLogin);
    } else if (state == 'CHANGES_REQUESTED') {
      changeRequestAuthors.add(authorLogin);
    }
  }
  final bool approved = (approvers.length > 1) && changeRequestAuthors.isEmpty;
  log.info('PR approved $approved, approvers: $approvers, change request authors: $changeRequestAuthors');
  return (approvers.length > 1) && changeRequestAuthors.isEmpty;
}

// TODO(Kristin): Simplify the _AutoMergeQueryResult class. https://github.com/flutter/flutter/issues/99717.
class _AutoMergeQueryResult {
  const _AutoMergeQueryResult({
    required this.hasApprovedReview,
    required this.changeRequestAuthors,
    required this.ciSuccessful,
    required this.failures,
    required this.number,
    required this.sha,
    required this.emptyChecks,
    required this.isConflicting,
    required this.unknownMergeableState,
    required this.labels,
  });

  /// Whether the pull request has at least one approved review.
  final bool hasApprovedReview;

  /// A set of login names that have at least one outstanding change request.
  final Set<String?> changeRequestAuthors;

  /// Whether CI has run successfully on the pull request.
  final bool ciSuccessful;

  /// A set of status/check names that have failed.
  final Set<_FailureDetail> failures;

  /// The pull request number.
  final int? number;

  /// The git SHA to be merged.
  final String? sha;

  /// Whether the commit has checks or not.
  final bool emptyChecks;

  /// Whether the PR has conflicts or not.
  final bool isConflicting;

  /// Whether has an unknown mergeable state or not.
  final bool unknownMergeableState;

  /// List of labels associated with the PR.
  final List<String> labels;

  /// Whether it is sane to automatically merge this PR.
  bool get shouldMerge =>
      ciSuccessful &&
      failures.isEmpty &&
      hasApprovedReview &&
      changeRequestAuthors.isEmpty &&
      !emptyChecks &&
      !unknownMergeableState &&
      !isConflicting;

  /// Whether the auto-merge label should be removed from this PR.
  bool get shouldRemoveLabel =>
      !hasApprovedReview || changeRequestAuthors.isNotEmpty || failures.isNotEmpty || emptyChecks || isConflicting;

  /// The comment message we want to send when removing the label.
  String get removalMessage {
    if (!shouldRemoveLabel) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('This pull request is not suitable for automatic merging in its '
        'current state.');
    buffer.writeln();
    if (!hasApprovedReview && changeRequestAuthors.isEmpty) {
      buffer.writeln('- Please get at least one approved review if you are already '
          'a member or two member reviews if you are not a member before re-applying this '
          'label. __Reviewers__: If you left a comment approving, please use '
          'the "approve" review action instead.');
    }
    for (String? author in changeRequestAuthors) {
      buffer.writeln('- This pull request has changes requested by @$author. Please '
          'resolve those before re-applying the label.');
    }
    for (_FailureDetail detail in failures) {
      buffer.writeln('- The status or check suite ${detail.markdownLink} has failed. Please fix the '
          'issues identified (or deflake) before re-applying this label.');
    }
    if (emptyChecks) {
      buffer.writeln('- This commit has no checks. Please check that ci.yaml validation has started'
          ' and there are multiple checks. If not, try uploading an empty commit.');
    }
    if (isConflicting) {
      buffer.writeln('- This commit is not mergeable and has conflicts. Please'
          ' rebase your PR and fix all the conflicts.');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return '$runtimeType{PR#$number, '
        'sha: $sha, '
        'ciSuccessful: $ciSuccessful, '
        'hasApprovedReview: $hasApprovedReview, '
        'changeRequestAuthors: $changeRequestAuthors, '
        'emptyValidations: $emptyChecks, '
        'shouldMerge: $shouldMerge}';
  }
}

class _FailureDetail {
  const _FailureDetail(this.name, this.url);

  final String name;
  final String url;

  String get markdownLink => '[$name]($url)';

  @override
  int get hashCode => 17 * 31 + name.hashCode * 31 + url.hashCode;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is _FailureDetail && other.name == name && other.url == url;
  }
}
