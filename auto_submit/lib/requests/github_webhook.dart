// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:auto_submit/service/log.dart';

/// Handler for processing GitHub webhooks.
///
/// On events where an 'autosubmit' label was added to a pull request,
/// check if the pull request is mergable and publish to pubsub.
class GithubWebhook {
  const GithubWebhook();

  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');

    //Listen to the pull request with 'autosubmit' label.
    bool hasAutosubmit = false;
    final String rawBody = await request.readAsString();
    final body = json.decode(rawBody) as Map<String, dynamic>;
    List<Map<String, dynamic>> labels = <Map<String, dynamic>>[];
    if (body.containsKey('pull_request') && body['pull_request'].containsKey('labels')) {
      labels = List<Map<String, dynamic>>.from(body['pull_request']['labels']);
    }

    for (int i = 0; i < labels.length; i++) {
      if (labels[i]['name'] == 'autosubmit') {
        hasAutosubmit = true;
      }
    }

    if (hasAutosubmit) {
      //Creat a github client and use rest API to get this single pr
      //to check shouldMerge later.
    }

    return Response.ok(
      rawBody,
    );
  }
}
