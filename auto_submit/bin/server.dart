// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:async';

import 'package:auto_submit/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:auto_submit/requests/github_webhook.dart';

Future main() async {
  Future<Response> emptyHandler(Request request) async {
    return Response.ok(
      jsonEncode(<String, String>{}),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  GithubWebhook githubWebhook = GithubWebhook();

  final router = Router()
    ..get('/', emptyHandler)
    ..post('/webhook', githubWebhook.post);
  await serveHandler(router);
}
