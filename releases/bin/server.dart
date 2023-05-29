// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:releases/common/handler.dart';
import 'package:releases/common/router.dart';
import 'package:releases/requests/github_webhook.dart';
import 'package:releases/requests/readiness_check.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    final Router router = Router(<Handler>[
      const GithubWebhook(),
      const ReadinessCheck(),
    ]);
    await router.serveRequests();
  });
}
