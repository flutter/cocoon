// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
import '../service/github_service.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook {
  const GithubWebhook(
    this.config,
  );

  final Config config;

  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');

    // Listen to the pull request with 'autosubmit' label.
    bool hasAutosubmit = false;
    final String rawBody = await request.readAsString();
    final body = json.decode(rawBody) as Map<String, dynamic>;

    if (!body.containsKey('pull_request') ||
        !body['pull_request'].containsKey('labels')) {
      return Response.ok(jsonEncode(<String, String>{}));
    }

    PullRequest pullRequest = PullRequest.fromJson(body['pull_request']);
    hasAutosubmit =
        pullRequest.labels!.any((label) => label.name == 'autosubmit');

    if (hasAutosubmit) {
      // TODO(kristin): hardcode the githubToken this time for test, will add it to env later.
      // final String githubToken = Platform.environment['AUTOSUBMIT_TOKEN']!;

      final String githubToken = 'f4d8bc081a5f3ad57f3df3a99ec0417b269cec90';
      final GithubService gitHub =
          config.createGithubServiceWithToken(githubToken);

      if (!(body.containsKey('repository') &&
          body['repository'].containsKey('full_name') &&
          body.containsKey('number'))) {
        return Response.ok(jsonEncode(<String, String>{}));
      }
      RepositorySlug slug =
          RepositorySlug.full(body['repository']['full_name']);
      int number = body['number'];

      // Use github Rest API to get this single pull request.
      final PullRequest pr =
          await gitHub.getPullRequest(slug, prNumber: number);
      logger.info('Get the pull request $pr');

      _AutoMergeQueryResult queryResult =
          await _parseQueryData(pr, gitHub, body);
      if (await shouldMergePullRequest(queryResult, slug, gitHub)) {
        // TODO(Kristin): publish the pr with 'autosubmit' labek to pubsub. https://github.com/flutter/flutter/issues/98704

      } else {
        return Response.ok(jsonEncode(<String, String>{}));
      }
    }

    return Response.ok(
      rawBody,
    );
  }

  /// Check if the pull request should be merged.
  ///
  /// A pull request should be merged on either cases:
  /// 1) All tests have finished running and satified basic merge requests
  /// 2) Not all tests finish but this is a clean revert of the Tip of Tree (TOT) commit.
  Future<bool> shouldMergePullRequest(_AutoMergeQueryResult queryResult,
      RepositorySlug slug, GithubService github) async {
    if (queryResult.shouldMerge) {
      return true;
    }
    // If the PR is a revert of the tot commit, merge without waiting for checks passing.
    return await isTOTRevert(queryResult.sha, slug, github);
  }

  /// Check if the `commitSha` is a clean revert of TOT commit.
  ///
  /// By comparing the current commit with second TOT commit, an empty `files` in
  /// `GitHubComparison` validates a clean revert of TOT commit.
  ///
  /// Note: [compareCommits] expects base commit first, and then head commit.
  Future<bool> isTOTRevert(
      String headSha, RepositorySlug slug, GithubService github) async {
    final RepositoryCommit secondTotCommit =
        await github.getRepoCommit(slug, 'HEAD~');
    logger.info('Current commit is: $headSha');
    logger.info('Second TOT commit is: ${secondTotCommit.sha}');
    final GitHubComparison githubComparison =
        await github.compareTwoCommits(slug, secondTotCommit.sha!, headSha);
    final bool filesIsEmpty = githubComparison.files!.isEmpty;
    if (filesIsEmpty) {
      logger.info('This is a TOT revert. Merge ignoring tests statuses.');
    }
    return filesIsEmpty;
  }

  Future<_AutoMergeQueryResult> _parseQueryData(
      PullRequest pr, GithubService gitHub, Map<String, dynamic> body) async {
    // TODO(Kristin): validate the way to parse data later if needed when get the real payload.

    // This is used to remove the bot label as it requires manual intervention.
    final bool isConflicting = pr.mergeable == false;
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = pr.mergeableState == 'UNKNOWN';
    RepositorySlug slug = RepositorySlug.full(body['repository']['full_name']);

    List<CheckRun>? checkRuns;
    List<CheckSuite>? checkSuitesList;
    if (pr.head != null && pr.head!.sha != null) {
      checkRuns = await gitHub.getCheckRuns(slug, ref: pr.head!.sha!);
      checkSuitesList = await gitHub.listCheckSuites(slug, ref: pr.head!.sha!);
    }
    checkRuns ??= <CheckRun>[];
    checkSuitesList ??= <CheckSuite>[];
    CheckSuite? checkSuite =
        checkSuitesList.isEmpty ? null : checkSuitesList[0];

    final String? author = pr.user!.login;
    final String? authorAssociation =
        body['pull_request']['author_association'] as String?;
    final List<PullRequestReview> reviews =
        await gitHub.getReviews(slug, prNumber: body['number']);
    final Set<String?> changeRequestAuthors = <String?>{};
    final bool hasApproval = config.rollerAccounts.contains(author) ||
        _checkApproval(
          author,
          authorAssociation,
          reviews,
          changeRequestAuthors,
        );

    final Set<_FailureDetail> failures = <_FailureDetail>{};
    final String sha = pr.head!.sha as String;
    final List<RepositoryStatus> statuses = await gitHub.getStatuses(slug, sha);

    // List of labels associated with the pull request.
    final List<String> labelNames = ((PullRequest.fromJson(body['pull_request'])
            .labels as List<IssueLabel>))
        .map<String>((IssueLabel labelMap) => labelMap.name)
        .toList();

    final bool ciSuccessful = await _checkStatuses(
      slug,
      sha,
      failures,
      statuses,
      checkRuns,
      checkSuite,
      slug.name,
      labelNames,
    );
    return _AutoMergeQueryResult(
        ciSuccessful: ciSuccessful,
        failures: failures,
        hasApprovedReview: hasApproval,
        changeRequestAuthors: changeRequestAuthors,
        number: body['number'],
        sha: sha,
        emptyChecks: checkRuns.isEmpty,
        isConflicting: isConflicting,
        unknownMergeableState: unknownMergeableState);
  }

  /// Returns whether all statuses are successful.
  ///
  /// Also fills [failures] with the names of any status/check that has failed.
  Future<bool> _checkStatuses(
    RepositorySlug slug,
    String sha,
    Set<_FailureDetail> failures,
    List<RepositoryStatus> statuses,
    List<CheckRun> checkRuns,
    CheckSuite? checkSuite,
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
      for (RepositoryStatus status in statuses) {
        if (status.context == treeStatusName) {
          treeStatusExists = true;
        }
      }

      if (!treeStatusExists) {
        failures.add(_FailureDetail('tree status $treeStatusName',
            'https://flutter-dashboard.appspot.com/#/build'));
      }
    }

    String overrideTreeStatusLabel = config.overrideTreeStatusLabel;
    logger.info('Validating name: $name, status: $statuses');
    for (RepositoryStatus status in statuses) {
      final String? name = status.context;
      if (status.state != 'success') {
        if (notInAuthorsControl.contains(name) &&
            labels.contains(overrideTreeStatusLabel)) {
          continue;
        }
        allSuccess = false;
        if (status.state == 'failure' && !notInAuthorsControl.contains(name)) {
          failures.add(_FailureDetail(name!, status.targetUrl as String));
        }
      }
    }

    logger.info('Validating name: $name, checks: $checkRuns');
    for (CheckRun checkRun in checkRuns) {
      final String? name = checkRun.name;
      if (checkSuite!.conclusion == CheckRunConclusion.success) {
        continue;
      } else if (checkRun.status == CheckRunStatus.completed) {
        failures.add(_FailureDetail(name!, checkRun.detailsUrl as String));
      }
      allSuccess = false;
    }

    // Validate cirrus
    const List<String> _failedStates = <String>['FAILED', 'ABORTED'];
    const List<String> _succeededStates = <String>['COMPLETED', 'SKIPPED'];
    final CirrusGraphQLClient cirrusGraphQlClient =
        await config.createCirrusGraphQLClient();
    final List<CirrusResult> cirrusResults =
        await cirrusGraphQlClient.queryCirrusGraphQL(sha, name);

    // The first build of cirrusGraphQL query always reflects the latest test statuses of the PR.
    final List<Map<String, dynamic>>? cirrusStatuses =
        cirrusResults.first.tasks;

    if (cirrusStatuses == null) {
      return allSuccess;
    }
    for (Map<String, dynamic> runStatus in cirrusStatuses) {
      final String? status = runStatus['status'] as String?;
      final String? name = runStatus['name'] as String?;
      final String? id = runStatus['id'] as String?;
      if (!_succeededStates.contains(status)) {
        allSuccess = false;
      }
      if (_failedStates.contains(status)) {
        failures.add(_FailureDetail(name!, 'https://cirrus-ci.com/task/$id'));
      }
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
/// not automatically dismiss the previous one (why, GitHub? Why?).
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
  List<PullRequestReview> reviews,
  Set<String?> changeRequestAuthors,
) {
  assert(changeRequestAuthors.isEmpty);
  const Set<String> allowedReviewers = <String>{'MEMBER', 'OWNER'};
  final Set<String?> approvers = <String?>{};
  if (allowedReviewers.contains(authorAssociation)) {
    approvers.add(author);
  }

  for (PullRequestReview review in reviews) {
    // Ignore reviews from non-members/owners.
    if (!allowedReviewers.contains(review.authorAssociation)) {
      continue;
    }
    // Reviews come back in order of creation.
    final String? state = review.state;
    final String? authorloggerin = review.user.login;

    if (state == 'APPROVED') {
      approvers.add(authorloggerin);
      changeRequestAuthors.remove(authorloggerin);
    } else if (state == 'CHANGES_REQUESTED') {
      changeRequestAuthors.add(authorloggerin);
    }
  }

  final bool approved = (approvers.length > 1) && changeRequestAuthors.isEmpty;
  logger.info(
      'PR approved $approved, approvers: $approvers, change request authors: $changeRequestAuthors');
  return (approvers.length > 1) && changeRequestAuthors.isEmpty;
}

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
  final int number;

  /// The git SHA to be merged.
  final String sha;

  /// Whether the commit has checks or not.
  final bool emptyChecks;

  /// Whether the PR has conflicts or not.
  final bool isConflicting;

  /// Whether has an unknown mergeable state or not.
  final bool unknownMergeableState;

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
      !hasApprovedReview ||
      changeRequestAuthors.isNotEmpty ||
      failures.isNotEmpty ||
      emptyChecks ||
      isConflicting;

  String get removalMessage {
    if (!shouldRemoveLabel) {
      return '';
    }
    final StringBuffer buffer = StringBuffer();
    buffer.writeln(
        'This pull request is not suitable for automatic merging in its '
        'current state.');
    buffer.writeln();
    if (!hasApprovedReview && changeRequestAuthors.isEmpty) {
      buffer.writeln(
          '- Please get at least one approved review if you are already '
          'a member or two member reviews if you are not a member before re-applying this '
          'label. __Reviewers__: If you left a comment approving, please use '
          'the "approve" review action instead.');
    }
    for (String? author in changeRequestAuthors) {
      buffer.writeln(
          '- This pull request has changes requested by @$author. Please '
          'resolve those before re-applying the label.');
    }
    for (_FailureDetail detail in failures) {
      buffer.writeln(
          '- The status or check suite ${detail.markdownLink} has failed. Please fix the '
          'issues identified (or deflake) before re-applying this label.');
    }
    if (emptyChecks) {
      buffer.writeln(
          '- This commit has no checks. Please check that ci.yaml validation has started'
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
