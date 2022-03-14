// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
import '../service/github_service.dart';
import '../service/log.dart';
import '../server/request_handler.dart';

/// Handler for processing pull requests with 'autosubmit' label.
///
/// For pull requests where an 'autosubmit' label was added in pubsub,
/// check if the pull request is mergable.
class CheckPullRequest extends RequestHandler {
  CheckPullRequest({
    required Config config,
  }) : super(config: config);

  Future<Response> get(Request request) async {
    //TODO(Kristin): Change the way to get this PR later according to the real situation, https://github.com/flutter/flutter/issues/99720
    final String rawBody = await request.readAsString();
    final body = json.decode(rawBody) as Map<String, dynamic>;
    final PullRequest pullRequest = PullRequest.fromJson(body['pull_request']);
    final RepositorySlug slug = pullRequest.base!.repo!.slug();

    final GithubService gitHub = await config.createGithubService();
    final _AutoMergeQueryResult queryResult = await _parseQueryData(pullRequest, gitHub);
    if (await shouldMergePullRequest(queryResult, slug, gitHub)) {
      // TODO(Kristin): Keep pulling pubsub queue, https://github.com/flutter/flutter/issues/98704

    } else if (queryResult.shouldRemoveLabel) {
      log.info('Removing label for commit: ${queryResult.sha}');
      await _removeLabel();
      return Response.ok(jsonEncode(<String, String>{}));
    }

    return Response.ok(rawBody);
  }

  /// Check if the pull request should be merged.
  ///
  /// A pull request should be merged on either cases:
  /// 1) All tests have finished running and satified basic merge requests
  /// 2) Not all tests finish but this is a clean revert of the Tip of Tree (TOT) commit.
  Future<bool> shouldMergePullRequest(
      _AutoMergeQueryResult queryResult, RepositorySlug slug, GithubService github) async {
    if (queryResult.shouldMerge) {
      return true;
    }
    // If the PR is a revert of the tot commit, merge without waiting for checks passing.
    return await isTOTRevert(queryResult.sha, slug, github);
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

  Future<bool> _removeLabel() async {
    // TODO(Kristin): Implement the logic to remove the label. https://github.com/flutter/flutter/issues/99877
    return true;
  }

  Future<_AutoMergeQueryResult> _parseQueryData(PullRequest pr, GithubService gitHub) async {
    // This is used to remove the bot label as it requires manual intervention.
    final bool isConflicting = pr.mergeable == false;
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = pr.mergeableState == 'UNKNOWN';

    final RepositorySlug slug = pr.base!.repo!.slug();
    List<CheckRun> checkRuns = <CheckRun>[];

    //TODO(Kristin): Inject pages to obtain all the check runs. https://github.com/flutter/flutter/issues/99804.
    if (pr.head != null && pr.head!.sha != null) {
      checkRuns.addAll(await gitHub.getCheckRuns(slug, pr.head!.sha!));
    }

    final List<PullRequestReview> reviews = await gitHub.getReviews(slug, pr.number!);

    final Set<String?> changeRequestAuthors = <String?>{};
    final Set<_FailureDetail> failures = <_FailureDetail>{};
    final String sha = pr.head!.sha as String;
    final List<RepositoryStatus> statuses = await gitHub.getStatuses(slug, sha);
    final String? author = pr.user!.login;
    final String? authorAssociation = pr.authorAssociation;

    // List of labels associated with the pull request.
    final List<String> labelNames =
        (pr.labels as List<IssueLabel>).map<String>((IssueLabel labelMap) => labelMap.name).toList();

    final bool hasApproval = config.rollerAccounts.contains(author) ||
        _checkApproval(
          author,
          authorAssociation,
          reviews,
          changeRequestAuthors,
        );
    final bool ciSuccessful = await _checkStatuses(
      slug,
      sha,
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
        number: pr.number!,
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
        failures.add(_FailureDetail('tree status $treeStatusName', 'https://flutter-dashboard.appspot.com/#/build'));
      }
    }

    final String overrideTreeStatusLabel = config.overrideTreeStatusLabel;
    log.info('Validating name: $name, status: $statuses');
    for (RepositoryStatus status in statuses) {
      final String? name = status.context;
      if (status.state != 'success') {
        if (notInAuthorsControl.contains(name) && labels.contains(overrideTreeStatusLabel)) {
          continue;
        }
        allSuccess = false;
        if (status.state == 'failure' && !notInAuthorsControl.contains(name)) {
          failures.add(_FailureDetail(name!, status.targetUrl as String));
        }
      }
    }

    log.info('Validating name: $name, checks: $checkRuns');
    //TODO(Kristin): Distinguish check runs from cirrus or flutter-dashboard. https://github.com/flutter/flutter/issues/99805.
    //TODO(Kristin): Upstream checkRun to include conclusion. https://github.com/flutter/flutter/issues/99850.
    //TODO(Kristin): Implement the logic to validate check run statuses. https://github.com/flutter/flutter/issues/99873.

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
    final String? authorlogin = review.user.login;

    if (state == 'APPROVED') {
      approvers.add(authorlogin);
      changeRequestAuthors.remove(authorlogin);
    } else if (state == 'CHANGES_REQUESTED') {
      changeRequestAuthors.add(authorlogin);
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
      !hasApprovedReview || changeRequestAuthors.isNotEmpty || failures.isNotEmpty || emptyChecks || isConflicting;

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
