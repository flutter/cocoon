// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:appengine/appengine.dart';
import 'package:logging/logging.dart';

final Application application = Application()
  ..addGet('api/public/pulls', (HttpRequest request) async {
    request.response.statusCode = HttpStatus.ok;
    try {
      await pushToGitHub();
    } on Exception {
      request.response.statusCode = 500; // or 400...who knows
    }
    return request.response;
  });

void main() {
  useLoggingPackageAdaptor();
  runAppEngine(application.handle,
      onError: (Object error, StackTrace stackTrace) {});
}

///
typedef RequestHandler = Future<HttpResponse> Function(HttpRequest);

class Application {
  final Map<String, RequestHandler> _handlers = <String, RequestHandler>{};

  void addGet(String path, RequestHandler handler) {
    _handlers['GET::$path'] = handler;
  }

  void addPost(String path, RequestHandler handler) {
    _handlers['POST::$path'] = handler;
  }

  Future<HttpResponse> handle(HttpRequest request) async {
    final String key = '${request.method}::${request.requestedUri}';
    final RequestHandler handler = _handlers[key];
    if (handler == null) {
      request.response.statusCode = HttpStatus.notFound;
      return request.response;
    }
    return handler(request);
  }
}

enum BuildStatus {
  Succeeded,
  Failed,
  Pending,
}

final Codec<Object, List<int>> codec = json.fuse(utf8);

/// Labels the given `commit` SHA on GitHub with the build status information.
///
/// `commit` is the SHA that this build status is for.
/// `status` The latest build status. Must be either [BuildStatus.Succeeded] or [BuildStatus.Failed].
/// `buildName` is the name that describes the build (e.g. "Engine Windows").
/// `buildContext` is Set as the "context" field on the GitHub SHA.
/// `link` is the URL link that will be added to the PR that the contributor can use to find more details.
/// `gitHubRepoApiURL` is the URL of the JSON endpoint for the GitHub repository that is being notified.
Future<void> pushToGitHub({
  String commit,
  BuildStatus status,
  String buildName,
  String buildContext,
  String link,
  String gitHubRepoApiURL,
}) async {
  final Uri url = Uri.parse('$gitHubRepoApiURL/statuses/$commit');
  final Map<String, String> data = <String, String>{};
  if (status == BuildStatus.Succeeded) {
    data['state'] = 'success';
  } else {
    data['state'] = 'failure';
    data['target_url'] = 'https://flutter-dashboard.appspot.com/build.html';
    data['description'] =
        '$buildName is currently broken. Please do not merge this PR unless it contains a fix to the broken build.';
  }
  data['context'] = buildContext;
  // Inject a server using a similar technique to the flutter_tool
  HttpClient client;
  final HttpClientRequest request = await client.postUrl(url);
  request.headers
    ..add(HttpHeaders.userAgentHeader, 'FlutterCocoon')
    ..add(HttpHeaders.acceptHeader, 'application/json; version=2')
    ..add(HttpHeaders.contentTypeHeader, 'application/json')
    ..add(HttpHeaders.authorizationHeader, 'GET TOKEN');
  request.write(json.encode(data));
  final HttpClientResponse response = await request.close();
  if (response.statusCode != HttpStatus.created) {
    final String body = await response.transform(utf8.decoder).join('');
    Logger.root.warning('Failed to post build status: ${body}');
  }
}
