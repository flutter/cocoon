// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:cocoon_service/src/service/luci_build_service.dart';
library;

import 'package:meta/meta.dart';

import '../../../ci_yaml.dart';
import '../../model/appengine/task.dart';

/// Represents a task that has yet to be scheduled in [LuciBuildService].
///
/// This is a glorified tuple that has a concrete type and documentation.
@immutable
final class PendingTask {
  const PendingTask({
    required this.target,
    required this.task,
    required this.priority,
  });

  /// Target that is represented by [task].
  final Target target;

  /// Task that, when executed, faithfully cares out the request in [target].
  final Task task;

  /// Priority of the task.
  final int priority;

  @override
  bool operator ==(Object other) {
    return other is PendingTask &&
        target == other.target &&
        task == other.task &&
        priority == other.priority;
  }

  @override
  int get hashCode => Object.hash(target, task, priority);

  @override
  String toString() {
    return 'PendingTask <${task.builderName} | $target | $priority>';
  }
}
