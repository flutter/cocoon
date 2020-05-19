// Copyright (c) 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

Logger logger = new PrintLogger();

abstract class Logger {
  void info(String message);
  void warning(String message);
  void error(String message);
}

class PrintLogger implements Logger {
  @override
  void info(String message) => print('[INFO] $message');

  @override
  void warning(String message) => print('[WARNING] $message');

  @override
  void error(String message) => print('[ERROR] $message');
}
