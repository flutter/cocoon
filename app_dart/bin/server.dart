// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';

Future<void> main() async {
  await withAppEngineServices(() {
    final Config config = Config(dbService);
    final Map<String, RequestHandler> handlers = <String, RequestHandler>{
      '/api/github-webhook-pullrequest': GithubWebhook(config),
      '/api/reserve-task': ReserveTask(config),
    };

    return runAppEngine((HttpRequest request) async {
      final RequestHandler handler = handlers[request.uri.path];
      if (handler != null) {
        await handler.service(request);
      } else {
        await request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    }, onAcceptingConnections: (InternetAddress address, int port) {
      String host = address.isLoopback ? 'localhost' : address.host;
      print('Serving requests at $host:$port');
    });
  });
}
