// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../internal.dart';
import 'severity.dart';

/// An interface that can record logging events, either to a buffer or backend.
///
/// Log sinks are required to extend or mix-in [LogSink], and implement [log].
/// More advanced implementations can conditionally override and implement
/// custom behavior for [flush] and [logJson], respectively.
abstract base mixin class LogSink {
  /// Flushes the log buffer to the output, if applicable.
  ///
  /// Implementations may override this method if flushing is used.
  Future<void> flush() => Future.value();

  /// Records a log [message].
  ///
  /// {@template cocoon_common.logging.log.details}
  /// If the [severity] is beneath the implemented logging threshold the call
  /// may be ignored.
  ///
  /// May optionally provide an [error] and/or [trace] for context.
  ///
  /// Implementations may choose whether this method is synchronous, or is
  /// implemented non-blocking, with a call to [flush] being required that the
  /// buffered message(s) were received, though a caller of this method should
  /// not need to distinguish a buffered log sink versus a non-buffered one.
  /// {@endtemplate}
  void log(
    String message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  });

  /// Records a structured log [message] that can be encoded safely to JSON.
  ///
  /// {@macro cocoon_common.logging.log.details}
  ///
  /// By default, this method calls [log] with [jsonEncode] in release mode
  /// (when assertions are disabled), and additionally adds indentation in
  /// debug mode (when assertions are enabled, i.e. for tests and local
  /// development). Implementations that support structured logging may override
  /// this method and use different behavior.
  void logJson(
    Object? message, {
    Severity severity = Severity.info,
    Object? error,
    StackTrace? trace,
  }) {
    final String text;
    if (assertionsEnabled) {
      text = const JsonEncoder.withIndent('  ').convert(message);
    } else {
      text = jsonEncode(message);
    }
    log(text, severity: severity, error: error, trace: trace);
  }

  /// A shortcut for calling [log] with [Severity.debug].
  @nonVirtual
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, severity: Severity.debug, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with [Severity.debug].
  @nonVirtual
  void debugJson(Object? message, {Object? error, StackTrace? stackTrace}) {
    logJson(message, severity: Severity.debug, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with [Severity.info].
  @nonVirtual
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, severity: Severity.info, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with (an explicit) [Severity.info].
  @nonVirtual
  void infoJson(Object? message, {Object? error, StackTrace? stackTrace}) {
    logJson(message, severity: Severity.info, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with [Severity.notice].
  @nonVirtual
  void notice(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, severity: Severity.notice, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with (an explicit) [Severity.info].
  @nonVirtual
  void noticeJson(Object? message, {Object? error, StackTrace? stackTrace}) {
    logJson(
      message,
      severity: Severity.notice,
      error: error,
      trace: stackTrace,
    );
  }

  /// A shortcut for calling [log] with [Severity.warning].
  @nonVirtual
  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, severity: Severity.warning, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with [Severity.warning].
  @nonVirtual
  void warnJson(Object? message, {Object? error, StackTrace? stackTrace}) {
    logJson(
      message,
      severity: Severity.warning,
      error: error,
      trace: stackTrace,
    );
  }

  /// A shortcut for calling [log] with [Severity.error].
  @nonVirtual
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(message, severity: Severity.warning, error: error, trace: stackTrace);
  }

  /// A shortcut for calling [log] with [Severity.error].
  @nonVirtual
  void errorJson(Object? message, {Object? error, StackTrace? stackTrace}) {
    logJson(
      message,
      severity: Severity.warning,
      error: error,
      trace: stackTrace,
    );
  }
}
