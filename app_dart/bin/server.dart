import 'dart:io';

import 'package:cocoon_service/cocoon.dart';

import 'package:appengine/appengine.dart';
import 'package:gcloud/db.dart';

const Map<String, HttpRequestHandler> _handlers = <String, HttpRequestHandler>{
  '/api/github-webhook-pullrequest': githubWebhookPullRequest,
};

Config config;

Future<void> requestHandler(HttpRequest request) async {
  final HttpRequestHandler handler = _handlers[request.uri.path];
  if (handler != null) {
    return handler(config, request);
  } else {
    await request.response
      ..statusCode = HttpStatus.notFound
      ..close();
    return null;
  }
}

Future<void> main() async {
  print('Serving requests');
  withAppEngineServices(() {
    config = Config(dbService);
    return runAppEngine(requestHandler);
  });
}
