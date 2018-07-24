// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:http/http.dart' as http;

import 'package:cocoon/components/benchmark_grid.dart';
import 'package:cocoon/http.dart';
import 'package:cocoon/logging.dart';

Future<Null> main() async {
  logger = new HtmlLogger();
  http.Client httpClient = await getAuthenticatedClientOrRedirectToSignIn('/benchmarks.html');

  if (httpClient == null)
    return null;

  // Start the angular app
  await runAppLegacyAsync(BenchmarkGrid,
    beforeComponentCreated: (_) async {},
    createInjectorFromProviders: [
    provide(http.Client, useValue: httpClient),
  ]);
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}
