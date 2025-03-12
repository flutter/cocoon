// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:cocoon_service/src/service/scheduler.dart';
library;

import 'package:meta/meta.dart';

/// Possible results for [Scheduler.processCheckRun].
@immutable
sealed class ProcessCheckRunResult {
  const factory ProcessCheckRunResult.success() = SuccessResult._;
  const factory ProcessCheckRunResult.userError(String message) =
      RecoverableErrorResult._;
  const factory ProcessCheckRunResult.internalError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) = InternalErrorResult._;
}

/// Successful.
final class SuccessResult implements ProcessCheckRunResult {
  const SuccessResult._();

  @override
  bool operator ==(Object other) => other is SuccessResult;

  @override
  int get hashCode => (SuccessResult).hashCode;

  @override
  String toString() {
    return 'ProcessCheckResult.success()';
  }
}

/// User-recoverable error.
final class RecoverableErrorResult implements ProcessCheckRunResult {
  const RecoverableErrorResult._(this.message);

  /// What should be displayed to the user.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is RecoverableErrorResult && message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(RecoverableErrorResult, message);
  }

  @override
  String toString() {
    return 'ProcessCheckResult.userError($message)';
  }
}

/// Internal error.
final class InternalErrorResult implements ProcessCheckRunResult {
  const InternalErrorResult._(this.message, {this.error, this.stackTrace});

  /// What should be displayed to the user.
  final String message;

  /// Originating error, if any.
  final Object? error;

  /// Originating stack trace, if any.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) {
    return other is InternalErrorResult &&
        message == other.message &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    return Object.hash(InternalErrorResult, message, error, stackTrace);
  }

  @override
  String toString() {
    return 'ProcessCheckRunResult.internalError($message, error: $error, stackTrace: $stackTrace)';
  }
}
