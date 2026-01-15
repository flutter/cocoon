// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

/// Represents differerent states of a task, or an execution of a build target.
enum TaskStatus {
  /// The task was cancelled.
  cancelled('Cancelled'),

  /// The task is waiting to be queued.
  waitingForBackfill('New'),

  /// The task is either queued or running.
  inProgress('In Progress'),

  /// The task has failed due to an infrastructure failure.
  infraFailure('Infra Failure'),

  /// The task has failed.
  failed('Failed'),

  /// The task ran successfully.
  succeeded('Succeeded'),

  /// The task was skipped instead of being executed.
  skipped('Skipped');

  const TaskStatus(this._schemaValue);
  final String _schemaValue;

  /// Returns the status represented by the provided [value].
  ///
  /// [value] must be a valid [TaskStatus.value].
  factory TaskStatus.from(String value) {
    return tryFrom(value) ?? (throw ArgumentError.value(value, 'value'));
  }

  /// Returns the task represented by the provided [value].
  ///
  /// Returns `null` if [value] is not a valid [TaskStatus.value].
  static TaskStatus? tryFrom(String value) {
    return values.firstWhereOrNull((v) => v.value == value);
  }

  /// The canonical string value representing `this`.
  ///
  /// This is the inverse of [TaskStatus.from] or [TaskStatus.tryFrom].
  String get value => _schemaValue;

  /// Whether the status represents a completed task reaching a terminal state.
  bool get isComplete => _complete.contains(this);
  static const _complete = {..._failed, succeeded, skipped};

  /// Whether the status represents a failure state.
  bool get isFailure => _failed.contains(this);
  static const _failed = {cancelled, infraFailure, failed};

  /// Whether the status represents a success state.
  bool get isSuccess => this == succeeded;

  /// Whether the status represents a skipped state.
  bool get isSkipped => this == skipped;

  /// Whether the status represents a running state.
  bool get isRunning => this == inProgress;

  /// Returns true if the build is waiting for backfill or in progress.
  bool get isBuildInProgress =>
      this == TaskStatus.waitingForBackfill || this == TaskStatus.inProgress;

  /// Returns true if the build succeeded or was skipped.
  bool get isBuildSuccessed =>
      this == TaskStatus.succeeded || this == TaskStatus.skipped;

  /// Returns true if the build failed, had an infra failure, or was cancelled.
  bool get isBuildFailed =>
      this == TaskStatus.failed ||
      this == TaskStatus.infraFailure ||
      this == TaskStatus.cancelled;

  /// Returns true if the build succeeded or some kind of failure occurred.
  bool get isBuildCompleted =>
      this == TaskStatus.succeeded ||
      this == TaskStatus.failed ||
      this == TaskStatus.infraFailure ||
      this == TaskStatus.cancelled;

  /// Returns the JSON representation of `this`.
  Object? toJson() => _schemaValue;

  @override
  String toString() => _schemaValue;
}
