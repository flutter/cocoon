// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:auto_submit/helpers.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    final Router router = Router()..post('/webhook', GithubWebhook().run);
    await serveHandler(router);
  });
}
