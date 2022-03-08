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

    final GithubService gitHub = await config.createGithubService();
    final _AutoMergeQueryResult queryResult =
        await _parseQueryData(pullRequest, gitHub);
    if (await shouldMergePullRequest(queryResult)) {
      // TODO(Kristin): Keep pulling pubsub queue, https://github.com/flutter/flutter/issues/98704

    } else {
      return Response.ok(jsonEncode(<String, String>{}));
    }

    return Response.ok(rawBody);
  }

  /// Check if the pull request should be merged.
  Future<bool> shouldMergePullRequest(_AutoMergeQueryResult queryResult) async {
    // TODO(Kristin): Implement shouldMergePullRequest, https://github.com/flutter/flutter/issues/98707

    return true;
  }

  Future<_AutoMergeQueryResult> _parseQueryData(
      PullRequest pr, GithubService gitHub) async {
    // This is used to remove the bot label as it requires manual intervention.
    final bool isConflicting = pr.mergeable == false;
    // This is used to skip landing until we are sure the PR is mergeable.
    final bool unknownMergeableState = pr.mergeableState == 'UNKNOWN';

    final RepositorySlug slug = pr.base!.repo!.slug();
    List<CheckRun> checkRuns = <CheckRun>[];
    List<CheckSuite> checkSuitesList = <CheckSuite>[];
    if (pr.head != null && pr.head!.sha != null) {
      checkRuns.addAll(await gitHub.getCheckRuns(slug, pr.head!.sha!));
      checkSuitesList.addAll(await gitHub.getCheckSuites(slug, pr.head!.sha!));
    }

    final CheckSuite? checkSuite =
        checkSuitesList.isEmpty ? null : checkSuitesList[0];
    log.info('Get the checkSuite $checkSuite.');

    final Iterable<PullRequestReview> reviews =
        await gitHub.getReviews(slug, pr.number!);

    final Set<String?> changeRequestAuthors = <String?>{};
    log.info('Get the reviews $reviews');

    final Set<_FailureDetail> failures = <_FailureDetail>{};
    final String sha = pr.head!.sha as String;
    final Iterable<RepositoryStatus> statuses =
        await gitHub.getStatuses(slug, sha);
    log.info('Get the statuses $statuses.');

    // TODO(Kristin): Get the author, authorAssociation, labels later.https://github.com/flutter/flutter/issues/99718.
    final bool hasApproval = false;
    final bool ciSuccessful = false;
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
      !hasApprovedReview ||
      changeRequestAuthors.isNotEmpty ||
      failures.isNotEmpty ||
      emptyChecks ||
      isConflicting;

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
