// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:async';

import 'package:auto_submit/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AutosubmitServer {
  AutosubmitServer();

  Future<Response> webhookHandler(Request request) async {
    print('this is the webhookHandler 1!');
    final String? reqHeader = jsonEncode(request.headers);
    print('Header: $reqHeader');
    final String? event = request.headers['X-GitHub-Event'];
    print('Event: $event');
    return Response.ok(
      jsonEncode(<String, String>{}),
      headers: request.headers,
    );
  }

  Future runServer() async {
    final router = Router()
      ..get('/webhook', webhookHandler)
      ..post('/webhook', webhookHandler);
    await serveHandler(router);
  }
}
