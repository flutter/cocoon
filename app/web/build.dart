// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'dart:async';
// import 'dart:html';

import 'package:angular/angular.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/browser_client.dart' as browser_http;

// import 'package:cocoon/cli.dart';
import 'package:cocoon/components/status_table.dart';
// import 'package:cocoon/logging.dart';
import 'package:cocoon/components/status_table.template.dart' as ng;

void main() async {
  // logger = new HtmlLogger();
  // http.Client httpClient = new browser_http.BrowserClient();

  // if (httpClient == null)
  //   return;

  // Start the angular app
  ComponentRef<StatusTable> _ = runApp(ng.StatusTableNgFactory);

  // Start CLI
  // Cli.install(ref.injector);
}

// class HtmlLogger implements Logger {
//   @override
//   void info(String message) => window.console.log(message);

//   @override
//   void warning(String message) => window.console.warn(message);

//   @override
//   void error(String message) => window.console.error(message);
// }
