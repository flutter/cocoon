// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:cocoon_service/src/service/scheduler.dart';
library;

import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

/// Possible results for [Scheduler.processCheckRun].
///
/// It is important to use a precise result type, where possible, as a 500-error
/// ([ProcessCheckRunResult.retrySoon]) indicates that a request _could_ be
/// succeeded at a later point in time, and it is often retried.
@immutable
sealed class ProcessCheckRunResult {
  /// The check run was successful.
  const factory ProcessCheckRunResult.success() = SuccessResult._;

  /// The check run failed in a way that an end-user needs to do something.
  const factory ProcessCheckRunResult.userError(String message) =
      UserErrorResult._;

  /// The check run failed to find a required entity.
  ///
  /// It is assumed repeated attempts to check for the same entity will fail.
  const factory ProcessCheckRunResult.missingEntity(String message) =
      MissingEntityErrorResult._;

  /// The check run failed, but could succeed in the near future.
  const factory ProcessCheckRunResult.retrySoon(String message) =
      RetrySoonErrorResult._;

  /// The check run crashed.
  const factory ProcessCheckRunResult.unexpectedError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) = UnexpectedErrorResult._;

  /// Writes an HTTP response of this type.
  void writeResponse(HttpResponse response);
}

/// Successful.
final class SuccessResult implements ProcessCheckRunResult {
  const SuccessResult._();

  @override
  bool operator ==(Object other) => other is SuccessResult;

  @override
  int get hashCode => (SuccessResult).hashCode;

  @override
  void writeResponse(HttpResponse response) {
    // Intentionally left blank to default to OK.
  }

  @override
  String toString() {
    return 'ProcessCheckResult.success()';
  }
}

/// User-recoverable error.
final class UserErrorResult implements ProcessCheckRunResult {
  const UserErrorResult._(this.message);

  /// What should be displayed to the user.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is UserErrorResult && message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(UserErrorResult, message);
  }

  @override
  void writeResponse(HttpResponse response) {
    response.statusCode = HttpStatus.badRequest;
    response.reasonPhrase = message;
  }

  @override
  String toString() {
    return 'ProcessCheckResult.userError($message)';
  }
}

/// An expected entity was missing, and a retry should not be performed.
final class MissingEntityErrorResult implements ProcessCheckRunResult {
  const MissingEntityErrorResult._(this.message);

  /// What should be displayed to the user.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is MissingEntityErrorResult && message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(MissingEntityErrorResult, message);
  }

  @override
  void writeResponse(HttpResponse response) {
    response.statusCode = HttpStatus.notFound;
    response.reasonPhrase = message;
  }

  @override
  String toString() {
    return 'ProcessCheckResult.missingEntity($message)';
  }
}

/// An internal error that is expected.
final class RetrySoonErrorResult implements ProcessCheckRunResult {
  const RetrySoonErrorResult._(this.message);

  /// What should be displayed to the user.
  final String message;

  @override
  bool operator ==(Object other) {
    return other is UnexpectedErrorResult && message == other.message;
  }

  @override
  int get hashCode {
    return Object.hash(UnexpectedErrorResult, message);
  }

  @override
  void writeResponse(HttpResponse response) {
    log.info(message);
    response.statusCode = HttpStatus.serviceUnavailable;
    response.reasonPhrase = message;
  }

  @override
  String toString() {
    return 'ProcessCheckRunResult.retrySoon($message)';
  }
}

/// Internal error that is unexpected.
final class UnexpectedErrorResult implements ProcessCheckRunResult {
  const UnexpectedErrorResult._(this.message, {this.error, this.stackTrace});

  /// What should be displayed to the user.
  final String message;

  /// Originating error, if any.
  final Object? error;

  /// Originating stack trace, if any.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) {
    return other is UnexpectedErrorResult &&
        message == other.message &&
        error == other.error &&
        stackTrace == other.stackTrace;
  }

  @override
  int get hashCode {
    return Object.hash(UnexpectedErrorResult, message, error, stackTrace);
  }

  @override
  void writeResponse(HttpResponse response) {
    log.error(message, error, stackTrace);
    response.statusCode = HttpStatus.internalServerError;
    response.reasonPhrase = message;
  }

  @override
  String toString() {
    return 'ProcessCheckRunResult.unexpectedError($message, error: $error, stackTrace: $stackTrace)';
  }
}
