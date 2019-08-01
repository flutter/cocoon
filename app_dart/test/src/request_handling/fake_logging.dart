// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:appengine/appengine.dart';

class FakeLogRecord {
  const FakeLogRecord(this.level, this.message, this.timestamp);

  final LogLevel level;
  final String message;
  final DateTime timestamp;
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
}
