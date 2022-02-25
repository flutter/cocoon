// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook {
  const GithubWebhook();

  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');

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
      // TODO(kristinbi): Check if PR can be submitted. https://github.com/flutter/flutter/issues/98707
    }

    return Response.ok(
      rawBody,
    );
  }
}
