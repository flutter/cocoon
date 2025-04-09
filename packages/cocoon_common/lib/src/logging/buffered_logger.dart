// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'log_sink.dart';
import 'severity.dart';

/// An implementation of [LogSink] that records [messages] in memory.
final class BufferedLogger with LogSink {
  /// Creates a new emtpy buffered logger.
  factory BufferedLogger() = BufferedLogger.forTesting;

  @visibleForTesting
  BufferedLogger.forTesting({DateTime Function() now = DateTime.now})
    : _now = now;

  final DateTime Function() _now;

  /// Messages that were recorded as a result of [log], in order of invocation.
  ///
  /// To clear the buffer, use [clear].
  late final Iterable<LogRecord> messages = UnmodifiableListView(_messages);
  final _messages = <LogRecord>[];

  /// Clear the buffer.
  void clear() {
    _messages.clear();
  }

  @override
  void log(
    String message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  }) {
    _messages.add(
      StringLogRecord._(
        message,
        severity: severity,
        error: error,
        trace: trace,
        recordedAt: _now(),
      ),
    );
  }

  @override
  void logJson(
    Object? message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  }) {
    _messages.add(
      JsonLogRecord._(
        message,
        severity: severity,
        error: error,
        trace: trace,
        recordedAt: _now(),
      ),
    );
  }

  @override
  String toString() {
    return 'BufferedLogger ${const JsonEncoder.withIndent('  ').convert(_messages)}';
  }
}

/// A struct that contains the parameters when invoking [BufferedLogger.log].
///
/// If [BufferedLogger.logJson] was invoked, [JsonLogRecord] is the subtype.
@immutable
sealed class LogRecord {
  LogRecord({
    required this.severity,
    required this.error,
    required this.trace,
    required this.recordedAt,
  });

  /// The message, either a [String] or a JSON-encodable object.
  ///
  /// To distinguish, pattern match to [StringLogRecord] or [JsonLogRecord].
  Object? get message;

  /// The severity of the message.
  final Severity severity;

  /// The error provided with the log, or `null` if omitted.
  final Object? error;

  /// The stack trace provided with the log, or `null` if omitted.
  final StackTrace? trace;

  /// The time and date when the log was recorded.
  final DateTime recordedAt;

  @override
  @nonVirtual
  bool operator ==(Object other) {
    return other is LogRecord &&
        message == other.message &&
        severity == other.severity &&
        error == other.error &&
        trace == other.trace &&
        recordedAt == other.recordedAt;
  }

  @override
  @nonVirtual
  int get hashCode {
    return Object.hash(message, severity, error, trace, recordedAt);
  }

  @override
  @nonVirtual
  String toString() {
    return 'LogRecord ${const JsonEncoder.withIndent('  ').convert(toJson())}';
  }

  /// Returns a JSON object representation of the log record.
  @nonVirtual
  Map<String, Object?> toJson() {
    return {
      'message': message,
      'severity': severity.name,
      'recordedAt': recordedAt.toIso8601String(),
      if (error case final error?) 'error': '$error',
      if (trace case final trace?)
        'trace': [...Trace.from(trace).frames.map((f) => '$f')],
    };
  }
}

/// A [LogRecord] that was invoked as a result of [BufferedLogger.log].
final class StringLogRecord extends LogRecord {
  StringLogRecord._(
    this.message, {
    required super.severity,
    required super.error,
    required super.trace,
    required super.recordedAt,
  });

  @override
  final String message;
}

///
final class JsonLogRecord extends LogRecord {
  JsonLogRecord._(
    this.message, {
    required super.severity,
    required super.error,
    required super.trace,
    required super.recordedAt,
  });

  @override
  final Object? message;
}
