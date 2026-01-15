// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:github/github.dart';

import '../firestore/ci_staging.dart';

extension ChecksExtension on TaskStatus {
  /// Converts a [TaskStatus] to a [TaskConclusion].
  TaskConclusion toTaskConclusion() {
    return switch (this) {
      TaskStatus.succeeded => TaskConclusion.success,
      TaskStatus.failed || TaskStatus.infraFailure => TaskConclusion.failure,
      TaskStatus.inProgress => TaskConclusion.scheduled,
      _ => TaskConclusion.unknown,
    };
  }

  /// Converts a [TaskStatus] to a GitHub check conclusion string.
  String toConclusion() {
    return switch (this) {
      TaskStatus.succeeded => 'success',
      TaskStatus.failed || TaskStatus.infraFailure => 'failure',
      TaskStatus.cancelled => 'cancelled',
      TaskStatus.skipped => 'skipped',
      _ => '',
    };
  }

  /// Converts a [TaskStatus] to a GitHub check conclusion string.
  CheckRunConclusion toCheckRunConclusion() {
    return switch (this) {
      TaskStatus.succeeded => CheckRunConclusion.success,
      TaskStatus.failed ||
      TaskStatus.infraFailure => CheckRunConclusion.failure,
      TaskStatus.cancelled => CheckRunConclusion.cancelled,
      TaskStatus.skipped => CheckRunConclusion.skipped,
      _ => CheckRunConclusion.empty,
    };
  }

  /// Converts a GitHub check conclusion string to a [TaskStatus].
  static TaskStatus fromConclusion(String? conclusion) {
    return switch (conclusion) {
      'success' => TaskStatus.succeeded,
      'failure' => TaskStatus.failed,
      'neutral' => TaskStatus.succeeded,
      'cancelled' => TaskStatus.cancelled,
      'timed_out' => TaskStatus.failed,
      'action_required' => TaskStatus.failed,
      'skipped' => TaskStatus.skipped,
      _ => TaskStatus.failed,
    };
  }

  static TaskStatus fromCheckRunConclusion(CheckRunConclusion? conclusion) {
    return switch (conclusion) {
      CheckRunConclusion.success => TaskStatus.succeeded,
      CheckRunConclusion.failure => TaskStatus.failed,
      CheckRunConclusion.neutral => TaskStatus.succeeded,
      CheckRunConclusion.cancelled => TaskStatus.cancelled,
      CheckRunConclusion.timedOut => TaskStatus.failed,
      CheckRunConclusion.actionRequired => TaskStatus.failed,
      CheckRunConclusion.skipped => TaskStatus.skipped,
      _ => TaskStatus.failed,
    };
  }
}
