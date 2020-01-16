// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:gcloud/db.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    final CacheService cache = CacheService();

    final Config config = Config(dbService, cache);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenProvider: AccessTokenProvider(config),
    );

    final Map<String, RequestHandler<dynamic>> handlers =
        <String, RequestHandler<dynamic>>{
      '/api/append-log': AppendLog(config, authProvider),
      '/api/authorize-agent': AuthorizeAgent(config, authProvider),
      '/api/check-waiting-pull-requests':
          CheckForWaitingPullRequests(config, authProvider),
      '/api/create-agent': CreateAgent(config, authProvider),
      '/api/get-authentication-status':
          GetAuthenticationStatus(config, authProvider),
      '/api/get-log': GetLog(config, authProvider),
      '/api/github-webhook-pullrequest':
          GithubWebhook(config, buildBucketClient),
      '/api/luci-status-handler': LuciStatusHandler(config),
      '/api/push-build-status-to-github':
          PushBuildStatusToGithub(config, authProvider),
      '/api/push-engine-build-status-to-github':
          PushEngineStatusToGithub(config, authProvider),
      '/api/refresh-chromebot-status':
          RefreshChromebotStatus(config, authProvider),
      '/api/refresh-github-commits': RefreshGithubCommits(config, authProvider),
      '/api/refresh-cirrus-status': RefreshCirrusStatus(config, authProvider),
      '/api/reserve-task': ReserveTask(config, authProvider),
      '/api/reset-devicelab-task': ResetDevicelabTask(config, authProvider),
      '/api/update-agent-health': UpdateAgentHealth(config, authProvider),
      '/api/update-agent-health-history':
          UpdateAgentHealthHistory(config, authProvider),
      '/api/update-benchmark-targets':
          UpdateBenchmarkTargets(config, authProvider),
      '/api/update-task-status': UpdateTaskStatus(config, authProvider),
      '/api/update-timeseries': UpdateTimeSeries(config, authProvider),
      '/api/vacuum-clean': VacuumClean(config, authProvider),
      '/api/debug/get-task-by-id': DebugGetTaskById(config, authProvider),
      '/api/debug/reset-pending-tasks':
          DebugResetPendingTasks(config, authProvider),
      '/api/public/build-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBuildStatus(config),
        ttl: const Duration(seconds: 15),
      ),
      '/api/public/get-benchmarks': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetBenchmarks(config),
        ttl: const Duration(minutes: 15),
      ),
      '/api/public/get-status': CacheRequestHandler<Body>(
        cache: cache,
        config: config,
        delegate: GetStatus(config),
      ),
      '/api/public/get-timeseries-history': GetTimeSeriesHistory(config),
    };

    return await runAppEngine((HttpRequest request) async {
      final RequestHandler<dynamic> handler = handlers[request.uri.path];
      if (handler != null) {
        await handler.service(request);
      } else {
        final String filePath = request.uri.toFilePath();

        const List<String> indexRedirects = <String>['/build.html'];
        if (indexRedirects.contains(filePath)) {
          request.response.statusCode = HttpStatus.permanentRedirect;
          // The separate HTML files are remnants from when Cocoon was written
          // with an Angular Dart frontend.
          final String flutterRouteName = filePath.replaceFirst('.html', '');
          return await request.response
              .redirect(Uri.parse('/#$flutterRouteName'));
        }

        await StaticFileHandler(filePath, config: config).service(request);
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      final String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at $host:$port');
    });
  });
}
