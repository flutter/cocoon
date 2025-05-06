// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

/// Represents differerent states of a task, or an execution of a build target.
///
/// TODO(matanlurey): Finish migrating (https://github.com/flutter/flutter/issues/167284):
/// - [x] All usages of `Task.status` should be of type `TaskStatus`
/// - [ ] Stop implementing `String` and handle conversion elsewhere
/// - [ ] Replace extension type with an `enum`
extension type const TaskStatus._(String _schemaValue) implements String {
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

  /// The task was cancelled.
  static const cancelled = TaskStatus._('Cancelled');

  /// The task is waiting to be queued.
  static const waitingForBackfill = TaskStatus._('New');

  /// The task is either queued or running.
  static const inProgress = TaskStatus._('In Progress');

  /// The task has failed due to an infrastructure failure.
  static const infraFailure = TaskStatus._('Infra Failure');

  /// The task has failed.
  static const failed = TaskStatus._('Failed');

  /// The task ran successfully.
  static const succeeded = TaskStatus._('Succeeded');

  /// The task was skipped instead of being executed.
  static const skipped = TaskStatus._('Skipped');

  /// Each valid possible task status.
  ///
  /// This list is unmodifiable.
  static const values = [
    cancelled,
    waitingForBackfill,
    inProgress,
    infraFailure,
    failed,
    succeeded,
    skipped,
  ];

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
}
