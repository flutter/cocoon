// Copyright (c) 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

typedef ShowSnackBarCallback = ScaffoldFeatureController<SnackBar, SnackBarClosedReason> Function(SnackBar snackBar);

class TaskBox {
  const TaskBox._();

  /// How big to make each square in the grid.
  static const double cellSize = 36;

  /// Status messages that map to [TaskStatus] enums.
  // TODO(chillers): Remove these and use TaskStatus enum when available. https://github.com/flutter/cocoon/issues/441
  static const String statusFailed = 'Failed';
  static const String statusNew = 'New';
  static const String statusSkipped = 'Skipped';
  static const String statusSucceeded = 'Succeeded';
  static const String statusInProgress = 'In Progress';

  // Synthetic status messages created by [effectiveTaskStatus].
  static const String statusSucceededButFlaky = 'Succeeded Flaky';
  static const String statusUnderperformed = 'Underperformed';
  static const String statusUnderperformedInProgress = 'Underperfomed In Progress';

  static String effectiveTaskStatus(Task task) {
    final bool attempted = task.attempts > 1;
    if (attempted) {
      switch (task.status) {
        case TaskBox.statusSucceeded:
          return TaskBox.statusSucceededButFlaky;
          break;
        case TaskBox.statusNew:
          return TaskBox.statusUnderperformed;
          break;
        case TaskBox.statusInProgress:
          return TaskBox.statusUnderperformedInProgress;
          break;
      }
    }
    return task.status;
  }

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  static const Map<String, Color> statusColor = <String, Color>{
    statusFailed: Colors.red,
    statusNew: Colors.blue,
    statusSkipped: Colors.transparent,
    statusSucceeded: Colors.green,
    statusInProgress: Colors.blue,
    statusSucceededButFlaky: Colors.yellow,
    statusUnderperformed: Colors.orange,
    statusUnderperformedInProgress: Colors.orange,
  };
}
