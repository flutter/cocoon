// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
import '../service/github_service.dart';
import '../service/log.dart';
import '../server/request_handler.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook extends RequestHandler {
  GithubWebhook(
    this.config,
  );
  final Config config;

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

    PullRequest pullRequest = PullRequest.fromJson(body['pull_request']);
    hasAutosubmit = pullRequest.labels!.any((label) => label.name == 'autosubmit');

    if (hasAutosubmit) {
      final String githubToken = Platform.environment['AUTOSUBMIT_TOKEN']!;
      final GithubService gitHub = config.createGithubServiceWithToken(githubToken);

      final RepositorySlug slug = RepositorySlug.full(body['repository']['full_name']);
      final int number = body['number'];

      // TODO(Kristin): use slug and prnumber to call github Rest API to get this single pull request.
    }
    return Response.ok(rawBody);
  }
}
