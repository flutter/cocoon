// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:async';

import 'package:auto_submit/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:auto_submit/requests/github_webhook.dart';

Future main() async {
  GithubWebhook githubWebhook = GithubWebhook();

  final router = Router()..post('/webhook', githubWebhook.post);
  await serveHandler(router);
}
