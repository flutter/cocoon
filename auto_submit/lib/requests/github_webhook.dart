// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:auto_submit/service/log.dart';

class GithubWebhook {
  const GithubWebhook();

  Future<Response> post(Request request) async {
    final Map<String, String> reqHeader = request.headers;
    logger.info('Header: $reqHeader');
    final String rawBody = await request.readAsString();

    return Response.ok(
      rawBody,
    );
  }
}
