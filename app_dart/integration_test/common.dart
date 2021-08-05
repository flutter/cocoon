// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:test/test.dart';

class TestLogging implements Logging {
  @override
  void critical(String string, {DateTime timestamp}) {
    print('critical: $string');
  }

  @override
  void error(String string, {DateTime timestamp}) {
    print('error: $string');
  }

  @override
  void warning(String string, {DateTime timestamp}) {
    print('warning: $string');
  }

  @override
  void info(String string, {DateTime timestamp}) {}

  @override
  void debug(String string, {DateTime timestamp}) {}

  @override
  void reportError(
    LogLevel level,
    Object error,
    StackTrace stackTrace, {
    DateTime timestamp,
  }) {
    print('error: $error');
  }

  @override
  void log(
    LogLevel level,
    String message, {
    DateTime timestamp,
  }) {}

  @override
  Future<void> flush() async {}

  static TestLogging _instance;
  static TestLogging get instance {
    _instance ??= TestLogging();
    return _instance;
  }
}

/// Validates the local tree has no outstanding changes.
void expectNoDiff(String path) {
  final ProcessResult gitResult = Process.runSync('git', <String>['diff', '--exit-code', path]);
  if (gitResult.exitCode != 0) {
    final ProcessResult gitDiffOutput = Process.runSync('git', <String>['diff', path]);
    fail('The working tree has a diff. Ensure changes are checked in:\n${gitDiffOutput.stdout}');
  }
}
