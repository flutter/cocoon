// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

final Logger logger = Logger('GithubWebhook');

class GithubWebhook {
  githubWebhook() {}

  Future<Response> webhookHandler(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');

    final String rawBody = await request.readAsString();
    return Response.ok(
      rawBody,
    );
  }
}
