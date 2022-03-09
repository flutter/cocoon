// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:github/github.dart';
import 'package:shelf/shelf.dart';

import '../service/config.dart';
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
      log.info(body);
      // TODO(kristinbi): Publish the pr with 'autosbumit' label to pubsub.

    }

    return Response.ok(rawBody);
  }
}
