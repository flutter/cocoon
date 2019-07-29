// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';

import 'package:appengine/appengine.dart';
import 'package:appengine/appengine.dart' as gae show context;
import 'package:gcloud/db.dart';

Future<void> main() async {
  await withAppEngineServices(() async {
    final Config config = Config(dbService);
    final AuthenticationProvider authProvider = AuthenticationProvider(config, () => gae.context);

    final Map<String, RequestHandler<dynamic>> handlers = <String, RequestHandler<dynamic>>{
      '/api/append-log': AppendLog(config, authProvider),
      '/api/github-webhook-pullrequest': GithubWebhook(config),
      '/api/reserve-task': ReserveTask(config, authProvider),
      '/api/update-task-status': UpdateTaskStatus(config, authProvider),
      '/api/debug/get-task-by-id': DebugGetTaskById(config, authProvider),
      '/api/debug/reset-pending-tasks': DebugResetPendingTasks(config, authProvider),
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
