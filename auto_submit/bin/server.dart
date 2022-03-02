// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:auto_submit/helpers.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:auto_submit/service/config.dart';
import 'package:shelf_router/shelf_router.dart';

Future main() async {
  Config config = Config();
  GithubWebhook githubWebhook = GithubWebhook(config);

  final router = Router()..post('/webhook', githubWebhook.post);
  await serveHandler(router);
}
