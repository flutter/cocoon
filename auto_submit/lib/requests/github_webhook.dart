// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/service/config.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/github_service.dart';
import '../service/log.dart';
import '../server/request_handler.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends RequestHandler {
  GithubWebhook({
    required Config config,
  }) : super(config: config);

  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    log.info('Header: $reqHeader');

    // Listen to the pull request with 'autosubmit' label.
    bool hasAutosubmit = false;
    final String rawBody = await request.readAsString();
    final body = json.decode(rawBody) as Map<String, dynamic>;

    if (!body.containsKey('pull_request') || !body['pull_request'].containsKey('labels')) {
      return Response.ok(jsonEncode(<String, String>{}));
    }

    final PullRequest pullRequest = PullRequest.fromJson(body['pull_request']);
    hasAutosubmit = pullRequest.labels!.any((label) => label.name == 'autosubmit');

    if (hasAutosubmit) {
      final GithubService gitHub = await config.createGithubService();
      final RepositorySlug slug = RepositorySlug.full(body['repository']['full_name']);
      final int number = body['number'];

      // TODO(kristinbi): move all the following information into another method later to make it clear.
      // Use github Rest API to get this pull request's reviews.
      final List<PullRequestReview> reviews = await gitHub.getReviews(slug, prNumber: number);
      log.info('Get the reviews $reviews');

      // This is used to remove the bot label as it requires manual intervention.
      final bool isConflicting = pullRequest.mergeable == false;
      // This is used to skip landing until we are sure the pullRequest is mergeable.
      final bool unknownMergeableState = pullRequest.mergeableState == 'UNKNOWN';
      log.info('Get the isConflicting $isConflicting, unknownMergeableState $unknownMergeableState.');

      List<CheckRun>? checkRuns;
      List<CheckSuite>? checkSuitesList;
      if (pullRequest.head != null && pullRequest.head!.sha != null) {
        checkRuns = await gitHub.getCheckRuns(slug, ref: pullRequest.head!.sha!);
        checkSuitesList = await gitHub.getCheckSuites(slug, ref: pullRequest.head!.sha!);
      }
      checkRuns ??= <CheckRun>[];
      checkSuitesList ??= <CheckSuite>[];
      CheckSuite? checkSuite = checkSuitesList.isEmpty ? null : checkSuitesList[0];
      log.info('Get the checkSuite $checkSuite.');

      final String? author = pullRequest.user!.login;
      final String? authorAssociation = body['pull_request']['author_association'] as String?;
      log.info('Get the autho $author, authorAssociation $authorAssociation.');

      final String sha = pullRequest.head!.sha as String;
      final List<RepositoryStatus> statuses = await gitHub.getStatuses(slug, sha);
      log.info('Get the statuses $statuses.');

      // List of labels associated with the pull request.
      final List<String> labelNames = ((PullRequest.fromJson(body['pull_request']).labels as List<IssueLabel>))
          .map<String>((IssueLabel labelMap) => labelMap.name)
          .toList();
      log.info('Get the labels $labelNames.');

      // TODO(kristinbi): Check if pullRequest can be submitted. https://github.com/flutter/flutter/issues/98707

    }

    return Response.ok(rawBody);
  }
}
