// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:process/process.dart';

/// Virtual current working directory, which affect functions, such as [exec].
String cwd = Directory.current.path;

ProcessManager processManager = LocalProcessManager();

final Logger logger = PrintLogger(out: stdout, level: LogLevel.info);

class LogLevel {
  const LogLevel._(this._level, this.name);

  final int _level;
  final String name;

  static const LogLevel debug = const LogLevel._(0, 'DEBUG');
  static const LogLevel info = const LogLevel._(1, 'INFO');
  static const LogLevel warning = const LogLevel._(2, 'WARN');
  static const LogLevel error = const LogLevel._(3, 'ERROR');
}

abstract class Logger {
  void debug(Object message);
  void info(Object message);
  void warning(Object message);
  void error(Object message);
}

class PrintLogger implements Logger {
  PrintLogger({
    IOSink out,
    this.level = LogLevel.info,
  }) : out = out ?? stdout;

  final IOSink out;
  final LogLevel level;

  @override
  void debug(Object message) => _log(LogLevel.debug, message);

  @override
  void info(Object message) => _log(LogLevel.info, message);

  @override
  void warning(Object message) => _log(LogLevel.warning, message);

  @override
  void error(Object message) => _log(LogLevel.error, message);

  void _log(LogLevel level, Object message) {
    if (level._level >= this.level._level) out.writeln(toLogString('$message', level: level));
  }
}

String toLogString(String message, {LogLevel level}) {
  final StringBuffer buffer = StringBuffer();
  buffer.write(DateTime.now().toIso8601String());
  buffer.write(': ');
  if (level != null) {
    buffer.write(level.name);
    buffer.write(' ');
  }
  buffer.write(message);
  return buffer.toString();
}

void fail(String message) {
  throw BuildFailedError(message);
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}
