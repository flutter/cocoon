// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:auto_submit/service/log.dart';

class GithubWebhook {
  const GithubWebhook();

  /// Handler for processing GitHub webhooks.
  ///
  /// On events where an 'autosubmit' label was added to a pull request,
  /// check if the pull request is mergable and publish to pubsub.
  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');
    final String rawBody = await request.readAsString();

    return Response.ok(
      rawBody,
    );
  }
}
