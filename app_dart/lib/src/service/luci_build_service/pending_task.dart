// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:cocoon_service/src/service/luci_build_service.dart';
library;

import 'package:meta/meta.dart';

import '../../../ci_yaml.dart';

/// Represents a task that has yet to be scheduled in [LuciBuildService].
///
/// This is a glorified tuple that has a concrete type and documentation.
@immutable
final class PendingTask {
  const PendingTask({
    required this.target,
    required this.taskName,
    required this.priority,
    required this.currentAttempt,
  });

  /// Target that is represented by [task].
  final Target target;

  /// Task that, when executed, faithfully cares out the request in [target].
  final String taskName;

  /// Priority of the task.
  final int priority;

  /// Which attempt this task is.
  final int currentAttempt;

  @override
  bool operator ==(Object other) {
    return other is PendingTask &&
        target == other.target &&
        taskName == other.taskName &&
        priority == other.priority &&
        currentAttempt == other.currentAttempt;
  }

  @override
  int get hashCode => Object.hash(target, taskName, priority, currentAttempt);

  @override
  String toString() {
    return 'PendingTask <$taskName($currentAttempt) | $target | $priority>';
  }
}
