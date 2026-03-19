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
      .succeeded => .success,
      .neutral => .neutral,
      .failed || .infraFailure => .failure,
      .inProgress => .scheduled,
      _ => .unknown,
    };
  }

  /// Converts a [TaskStatus] to a GitHub check conclusion string.
  String toConclusion() {
    return switch (this) {
      .succeeded => 'success',
      .neutral => 'neutral',
      .failed || .infraFailure => 'failure',
      .cancelled => 'cancelled',
      .skipped => 'skipped',
      _ => '',
    };
  }

  /// Converts a [TaskStatus] to a GitHub check conclusion string.
  CheckRunConclusion toCheckRunConclusion() {
    return switch (this) {
      .succeeded => .success,
      .failed || .infraFailure => .failure,
      .cancelled => .cancelled,
      .skipped => .skipped,
      .neutral => .neutral,
      _ => .empty,
    };
  }

  /// Converts a GitHub check conclusion string to a [TaskStatus].
  static TaskStatus fromConclusion(String? conclusion) {
    return switch (conclusion) {
      'success' => .succeeded,
      'failure' => .failed,
      'neutral' => .neutral,
      'cancelled' => .cancelled,
      'timed_out' => .failed,
      'action_required' => .failed,
      'skipped' => .skipped,
      _ => .failed,
    };
  }

  static TaskStatus fromCheckRunConclusion(CheckRunConclusion? conclusion) {
    return switch (conclusion) {
      .success => .succeeded,
      .failure => .failed,
      .neutral => .neutral,
      .cancelled => .cancelled,
      .timedOut => .failed,
      .actionRequired => .failed,
      .skipped => .skipped,
      _ => .failed,
    };
  }
}
