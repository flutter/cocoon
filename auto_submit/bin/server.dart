// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:appengine/appengine.dart';
import 'package:auto_submit/helpers.dart';
import 'package:auto_submit/request_handling/authentication.dart';
import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:auto_submit/requests/check_revert_request.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:auto_submit/requests/readiness_check.dart';
import 'package:auto_submit/service/config.dart';
import 'package:cocoon_server/access_client_provider.dart';
import 'package:cocoon_server/secret_manager.dart';
import 'package:neat_cache/neat_cache.dart';
import 'package:shelf_router/shelf_router.dart';

/// Number of entries allowed in [Cache].
const int kCacheSize = 1024;

Future<void> main() async {
  await withAppEngineServices(() async {
    useLoggingPackageAdaptor();

    final cache = Cache.inMemoryCacheProvider(kCacheSize);
    final config = Config(
      cacheProvider: cache,
      secretManager: await SecretManager.create(
        AccessClientProvider(),
        projectId: Config.flutterGcpProjectId,
      ),
    );
    const authProvider = CronAuthProvider();

    final router =
        Router()
          ..post('/webhook', GithubWebhook(config: config).post)
          ..get(
            '/check-pull-request',
            CheckPullRequest(
              config: config,
              cronAuthProvider: authProvider,
            ).run,
          )
          ..get(
            '/check-revert-requests',
            CheckRevertRequest(
              config: config,
              cronAuthProvider: authProvider,
            ).run,
          )
          ..get('/readiness_check', ReadinessCheck(config: config).run);
    await serveHandler(router.call);
  });
}
