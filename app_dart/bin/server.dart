// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:gcloud/db.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    final Config config = Config(dbService);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenProvider: AccessTokenProvider(config),
    );

    final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
      '/api/append-log': AppendLog(config, authProvider),
      '/api/authorize-agent': null,
      '/api/create-agent': null,
      '/api/get-authentication-status': GetAuthenticationStatus(config, authProvider),
      '/api/get-log': GetLog(config, authProvider),
      '/api/github-webhook-pullrequest': GithubWebhook(config, buildBucketClient),
      '/api/luci-status-handler': LuciStatusHandler(config),
      '/api/push-build-status-to-github': PushBuildStatusToGithub(config, authProvider),
      '/api/push-engine-build-status-to-github': PushEngineStatusToGithub(config, authProvider),
      '/api/refresh-chromebot-status': RefreshChromebotStatus(config, authProvider),
      '/api/refresh-github-commits': RefreshGithubCommits(config, authProvider),
      '/api/refresh-cirrus-status': RefreshCirrusStatus(config, authProvider),
      '/api/reserve-task': ReserveTask(config, authProvider),
      '/api/reset-devicelab-task': ResetDevicelabTask(config, authProvider),
      '/api/update-agent-health': null,
      '/api/update-benchmark-targets': null,
      '/api/update-task-status': UpdateTaskStatus(config, authProvider),
      '/api/update-timeseries': null,
      '/api/vacuum-clean': VacuumClean(config, authProvider),

      '/api/debug/get-task-by-id': DebugGetTaskById(config, authProvider),
      '/api/debug/reset-pending-tasks': DebugResetPendingTasks(config, authProvider),

      '/api/public/build-status': GetBuildStatus(config),
      //'/api/public/get-benchmarks': GetBenchmarks(config),
      //'/api/public/get-status': GetStatus(config),
      '/api/public/get-timeseries-history': null,
    };

    final ProxyRequestHandler legacyBackendProxyHandler = ProxyRequestHandler(
      config: config,
      scheme: await config.forwardScheme,
      host: await config.forwardHost,
      port: await config.forwardPort,
    );

    return await runAppEngine((HttpRequest request) async {
      final RequestHandler<dynamic> handler = handlers[request.uri.path];
      if (handler != null) {
        await handler.service(request);
      } else {
        await legacyBackendProxyHandler.service(request);
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      final String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at $host:$port');
    });
  });
}
