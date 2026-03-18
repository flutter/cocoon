// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';

/// Compares two tasks by status first, then by name.
///
/// Status priority (highest to lowest):
/// 1. Failed
/// 2. Infra Failure
/// 3. In Progress
/// 4. New (waitingForBackfill)
/// 5. Cancelled
/// 6. Skipped
/// 7. Succeeded
int compareTasks(
  String nameA,
  TaskStatus statusA,
  String nameB,
  TaskStatus statusB,
) {
  final priorityA = _statusPriority(statusA);
  final priorityB = _statusPriority(statusB);

  if (priorityA != priorityB) {
    return priorityA.compareTo(priorityB);
  }

  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
}

int _statusPriority(TaskStatus status) {
  switch (status) {
    case TaskStatus.failed:
      return 1;
    case TaskStatus.infraFailure:
      return 2;
    case TaskStatus.inProgress:
      return 3;
    case TaskStatus.waitingForBackfill:
      return 4;
    case TaskStatus.cancelled:
      return 5;
    case TaskStatus.skipped:
      return 6;
    case TaskStatus.succeeded:
      return 7;
  }
}
