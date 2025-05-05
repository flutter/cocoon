// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Represents components of a backend task without specifying the backend.
@immutable
final class TaskRef {
  const TaskRef({
    required this.name,
    required this.currentAttempt,
    required this.status,
    required this.commitSha,
  });

  /// Name of the task.
  final String name;

  /// Which attempt number;
  final int currentAttempt;

  /// Status of the task.
  final String status;

  /// Commit the task belongs to.
  final String commitSha;

  @override
  bool operator ==(Object other) {
    if (other is! TaskRef) {
      return false;
    }
    return name == other.name &&
        currentAttempt == other.currentAttempt &&
        status == other.status &&
        commitSha == other.commitSha;
  }

  @override
  int get hashCode {
    return Object.hash(name, currentAttempt, status, commitSha);
  }

  @override
  String toString() {
    return 'Task <$name (SHA=$commitSha): $status ($currentAttempt)>';
  }
}
