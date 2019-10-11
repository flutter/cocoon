// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:gcloud/db.dart';
import 'package:mime/mime.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    final Config config = Config(dbService);
    final AuthenticationProvider authProvider = AuthenticationProvider(config);
    final BuildBucketClient buildBucketClient = BuildBucketClient(
      accessTokenProvider: AccessTokenProvider(config),
    );

    final Map<String, RequestHandler<dynamic>> handlers =
        <String, RequestHandler<dynamic>>{
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
      '/api/update-agent-health': UpdateAgentHealth(config, authProvider),
      '/api/update-benchmark-targets': UpdateBenchmarkTargets(config, authProvider),
      '/api/update-task-status': UpdateTaskStatus(config, authProvider),
      '/api/update-timeseries': UpdateTimeSeries(config, authProvider),
      '/api/vacuum-clean': VacuumClean(config, authProvider),

      '/api/debug/get-task-by-id': DebugGetTaskById(config, authProvider),
      '/api/debug/reset-pending-tasks': DebugResetPendingTasks(config, authProvider),
      
      '/api/public/build-status': GetBuildStatus(config),
      '/api/public/get-benchmarks': GetBenchmarks(config),
      '/api/public/get-status': GetStatus(config),
      '/api/public/get-timeseries-history': GetTimeSeriesHistory(config),
    };

    final ProxyRequestHandler legacyBackendProxyHandler = ProxyRequestHandler(
      config: config,
      scheme: await config.forwardScheme,
      host: await config.forwardHost,
      port: await config.forwardPort,
    );

    /// Send HTTP 404 Response to Client
    Future<void> sendNotFound(HttpResponse response) async {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }

    /// Send HTTP 500 Response to Client
    Future<void> sendInternalError(HttpResponse response) async {
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    }

    /// Send static assets for the Flutter application to the client.
    /// 
    /// If the asset cannot be found, send a 404 Not Found response.
    /// If there is an error sending the asset, send a 500 Internal Server Error
    /// response.
    Future<void> sendFlutterApplicationAssets(HttpRequest request) async {
      String filePath = request.uri.toFilePath();
      // TODO(chillers): Remove when Flutter application goes into production.
      filePath = filePath.replaceFirst('/v2', '');

      final String resultPath = filePath == '/' ? '/index.html' : filePath;
      const String basePath = '../app_flutter/build/web';
      final File file = File('$basePath$resultPath');

      if (file.existsSync()) {
        try {
          final String mimeType = lookupMimeType(resultPath);
          request.response.headers.contentType = ContentType.parse(mimeType);
          await request.response.addStream(file.openRead());
          await request.response.close();
        } catch (exception) {
          print('Error: $exception');
          await sendInternalError(request.response);
        }
      } else {
        await sendNotFound(request.response);
      }
    }

    /// Check if the requested URI is for the Flutter Application
    /// 
    /// Currently the Flutter application will run at
    /// https://flutter-dashboard.appspot.com/v2/
    bool isRequestForFlutterApplicationBeta(HttpRequest request) {
      return request.uri.path.contains('/v2');
    }

    return await runAppEngine((HttpRequest request) async {
      if (isRequestForFlutterApplicationBeta(request)) {
        await sendFlutterApplicationAssets(request);
      }

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