// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';

class FakeLogRecord {
  const FakeLogRecord(this.level, this.message, this.timestamp);

  final LogLevel level;
  final String message;
  final DateTime timestamp;

  @override
  String toString() {
    return '$timestamp: ($level) $message';
  }
}

class FakeLogging implements Logging {
  final List<FakeLogRecord> records = <FakeLogRecord>[];

  @override
  void debug(String message, {DateTime timestamp}) {
    log(LogLevel.DEBUG, message, timestamp: timestamp);
  }

  @override
  void info(String message, {DateTime timestamp}) {
    log(LogLevel.INFO, message, timestamp: timestamp);
  }

  @override
  void warning(String message, {DateTime timestamp}) {
    log(LogLevel.WARNING, message, timestamp: timestamp);
  }

  @override
  void error(String message, {DateTime timestamp}) {
    log(LogLevel.ERROR, message, timestamp: timestamp);
  }

  @override
  void critical(String message, {DateTime timestamp}) {
    log(LogLevel.CRITICAL, message, timestamp: timestamp);
  }

  @override
  void log(LogLevel level, String message, {DateTime timestamp}) {
    records.add(FakeLogRecord(level, message, timestamp));
  }

  @override
  Future<void> flush() async {}

  @override
  void reportError(
    LogLevel level,
    Object error,
    StackTrace stackTrace, {
    DateTime timestamp,
  }) {
    log(level, 'Error: $error\n$stackTrace', timestamp: timestamp);
  }
}

bool Function(FakeLogRecord) hasLevel(LogLevel level) {
  return (FakeLogRecord record) {
    return record.level == level;
  };
}
