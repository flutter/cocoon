// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular2/core.dart';
import 'package:angular2/platform/browser.dart';
import 'package:http/browser_client.dart' as browser_http;
import 'package:http/http.dart' as http;

import 'package:cocoon/components/status_table.dart';
import 'package:cocoon/logging.dart';
import 'package:cocoon/cli.dart';

@AngularEntrypoint()
main() async {
  logger = new HtmlLogger();
  http.Client httpClient = await _getAuthenticatedClientOrRedirectToSignIn();

  // Start the angular app
  ComponentRef ref = await bootstrap(StatusTable, [
    provide(http.Client, useValue: httpClient),
  ]..addAll(Cli.commandTypes.map((Type type) => provide(type, useClass: type))));

  // Start CLI
  Cli.install(ref.injector);
}

Future<http.Client> _getAuthenticatedClientOrRedirectToSignIn() async {
  http.Client client = new browser_http.BrowserClient();
  Map<String, dynamic> status = JSON.decode((await client.get('/api/get-authentication-status')).body);

  if (status['Status'] == 'OK') {
    return client;
  } else {
    window.open(status['LoginURL'], '_self');
    return null;
  }
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}
