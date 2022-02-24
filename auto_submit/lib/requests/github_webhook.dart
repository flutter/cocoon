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

    if (body.containsKey('pull_request') && body['pull_request'].containsKey('labels')) {
      hasAutosubmit = body['pull_request']['labels'].any((label) => IssueLabel.fromJson(label).name == 'autosubmit');
    }
    print(hasAutosubmit);

    if (hasAutosubmit) {
      // TODO(kristinbi): Check if PR can be submitted. https://github.com/flutter/flutter/issues/98707
    }

    return Response.ok(
      rawBody,
    );
  }
}

// class Label {
//   final int id;
//   final String? nodeId;
//   final String? url;
//   final String name;
//   final String? color;
//   final String? defaultStatus;

//   const Label(this.id, this.nodeId, this.url, this.name, this.color,
//       this.defaultStatus);

//   Label.fromJson(Map<String, dynamic> json)
//       : id = json['id'],
//         nodeId = json['nodeId'],
//         url = json['url'],
//         name = json['name'],
//         color = json['color'],
//         defaultStatus = json['defalt'];
// }
