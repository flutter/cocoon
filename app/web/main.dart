// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html';
import 'package:angular2/platform/browser.dart';
import 'package:cocoon/components/status_table.dart';
import 'package:cocoon/logging.dart';

void main() {
  logger = new HtmlLogger();
  bootstrap(StatusTable);
}

class HtmlLogger implements Logger {
  @override
  void info(String message) => window.console.log(message);

  @override
  void warning(String message) => window.console.warn(message);

  @override
  void error(String message) => window.console.error(message);
}
