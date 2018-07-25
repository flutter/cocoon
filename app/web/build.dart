// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';

import 'package:angular/angular.dart';
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser_http;

import 'package:cocoon/cli.dart';
import 'package:cocoon/logging.dart';
import 'package:cocoon/build/status_table.template.dart' as ng;
import 'package:cocoon/build/status_table.dart';

void main() {
  final ComponentRef<StatusTableComponent> componentRef = runApp(
    ng.StatusTableComponentNgFactory,
    createInjector: ([Injector injector]) {
      final client = new browser_http.BrowserClient();
      return new Injector.map({
        Logger: new HtmlLogger(),
        http.Client: new browser_http.BrowserClient(),
        CreateAgentCommand: new CreateAgentCommand(client),
        AuthorizeAgentCommand: new AuthorizeAgentCommand(client),
        RefreshGithubCommitsCommand: new RefreshGithubCommitsCommand(client),
        ReserveTaskCommand: new ReserveTaskCommand(client),
        RawHttpCommand: new RawHttpCommand(client),
      }, injector);
  });
  Cli.install(componentRef.injector);
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}
