// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'presubmit_guard_conclusion.dart';
library;

/// Explains what happened when attempting to mark the conclusion of a check run
/// using [PresubmitGuard.markConclusion].
enum PresubmitGuardConclusionResult {
  /// Check run update recorded successfully in the respective CI stage.
  ///
  /// It is OK to evaluate returned results for stage completeness.
  ok,

  /// The check run is not in the specified CI stage.
  ///
  /// Perhaps it's from a different CI stage.
  missing,

  /// An unexpected error happened, and the results of the conclusion are
  /// undefined.
  ///
  /// Examples of situations that can lead to this result:
  ///
  /// * The Firestore document is missing.
  /// * The contents of the Firestore document are inconsistent.
  /// * An unexpected error happend while trying to read from/write to Firestore.
  ///
  /// When this happens, it's best to stop the current transaction, report the
  /// error to the logs, and have someone investigate the issue.
  internalError,
}

/// Represents the current state of jobs in a CI stage.
class PresubmitGuardState {
  final int remaining;
  final int failed;

  const PresubmitGuardState({
    required this.remaining,
    required this.failed,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresubmitGuardState &&
          other.remaining == remaining &&
          other.failed == failed);

  @override
  int get hashCode => Object.hash(remaining, failed);

  @override
  String toString() => 'PresubmitGuardState("$remaining", "$failed")';
}

/// Results from attempting to mark a staging task as completed.
///
/// See: [PresubmitGuard.markConclusion]
class PresubmitGuardConclusion {
  final PresubmitGuardConclusionResult result;
  final PresubmitGuardState previousState;
  final PresubmitGuardState currentState;
  final String? checkRunGuard;
  final String summary;
  final String details;

  const PresubmitGuardConclusion({
    required this.result,
    required this.previousState,
    required this.currentState,
    required this.checkRunGuard,
    required this.summary,
    required this.details,
  });

  bool get isOk => result == PresubmitGuardConclusionResult.ok;

  bool get isPending => isOk && currentState.remaining > 0;

  bool get isFailed => isOk && currentState.failed > 0;

  bool get isComplete => isOk && !isPending && !isFailed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PresubmitGuardConclusion &&
          other.result == result &&
          other.previousState == previousState &&
          other.currentState == currentState &&
          other.checkRunGuard == checkRunGuard &&
          other.summary == summary &&
          other.details == details);

  @override
  int get hashCode => Object.hashAll([
    result,
    previousState,
    currentState,
    checkRunGuard,
    summary,
    details,
  ]);

  @override
  String toString() =>
      'BuildConclusion("$result", "$previousState", "$currentState", "$summary", "$details", "$checkRunGuard")';
}
