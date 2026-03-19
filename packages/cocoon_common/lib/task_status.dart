// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

/// Represents differerent states of a task, or an execution of a build target.
import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
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

  /// The task ran but the status is ignored.
  neutral('Neutral'),

  /// The task was skipped instead of being executed.
  skipped('Skipped');

  const TaskStatus(this.value);

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
  final String value;

  /// Whether the status represents a completed task reaching a terminal state.
  bool get isComplete => isSuccess || isFailure;

  /// Whether the status represents a failure state.
  bool get isFailure => switch (this) {
    cancelled || infraFailure || failed => true,
    _ => false,
  };

  /// Whether the status represents a success state.
  bool get isSuccess => switch (this) {
    succeeded || skipped || neutral => true,
    _ => false,
  };

  /// Whether the status represents a skipped state.
  bool get isSkipped => this == skipped;

  /// Whether the status represents a running state.
  bool get isRunning => this == inProgress;

  /// Returns true if the build is waiting for backfill or in progress.
  bool get isBuildInProgress => switch (this) {
    waitingForBackfill || inProgress => true,
    _ => false,
  };

  /// Returns the JSON representation of `this`.
  Object? toJson() => value;

  @override
  String toString() => value;
}
