// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'package:angular2/core.dart';
import 'package:angular2/platform/browser.dart';
import 'package:cocoon/components/status_table.dart';
import 'package:cocoon/logging.dart';
import 'package:http/browser_client.dart' as browser_http;
import 'package:http/http.dart' as http;
import 'package:http/src/base_client.dart' as base_http;

@AngularEntrypoint()
main() async {
  logger = new HtmlLogger();
  http.Client httpClient = await _getAuthenticatedClientOrRedirectToSignIn();

  // Start the angular app
  bootstrap(StatusTable, [
    provide(http.Client, useValue: httpClient)
  ]);
}

Future<http.Client> _getAuthenticatedClientOrRedirectToSignIn() {
  const _oauthClientId = '308150028417-vlj9mqlm3gk1d03fb0efif1fu5nagdtt.apps.googleusercontent.com';

  Uri location = Uri.parse(window.location.href);
  String accessToken;
  if (location.fragment.contains('access_token=')) {
    int tokenStart = location.fragment.indexOf('access_token=');
    int tokenEnd = location.fragment.indexOf('&', tokenStart + 1);
    accessToken = Uri.decodeComponent(location.fragment.substring(
      tokenStart + 'access_token='.length,
      tokenEnd != -1 ? tokenEnd : null
    ));
  }

  Completer<http.Client> completer = new Completer<http.Client>();
  if (accessToken != null) {
    completer.complete(new AuthenticatedClient(accessToken));
  } else {
    String host = location.host;
    String scheme = host == 'localhost' || host == '127.0.0.1'
      ? 'http'
      : 'https';
    String port = location.port == 80 ? '' : ':${location.port}';
    String redirectUri = '$scheme://$host$port';
    String signInUrl = 'https://accounts.google.com/o/oauth2/v2/auth?'
       'scope=email&'
       'redirect_uri=${redirectUri}&'
       'response_type=token&'
       'client_id=${_oauthClientId}';
    window.open(signInUrl, '_self');
  }
  return completer.future;
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}

class AuthenticatedClient extends base_http.BaseClient {
  AuthenticatedClient(this._accessToken);

  final String _accessToken;
  final browser_http.BrowserClient _delegate = new browser_http.BrowserClient();

  Future<http.StreamedResponse> send(http.Request request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _delegate.send(request);
  }
}
