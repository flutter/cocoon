// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

/// Displays information from a [Task].
///
/// If [Task.status] is "In Progress", it will show as a "New" task
/// with a [CircularProgressIndicator] in the box.
/// Shows a black box for unknown statuses.
class TaskBox extends StatelessWidget {
  const TaskBox({Key key, @required this.task}) : super(key: key);

  /// [Task] to show information from.
  final Task task;

  /// Status messages that map to TaskStatus enums.
  /// TODO(chillers): Remove these and use TaskStatus enum when available. https://github.com/flutter/cocoon/issues/441
  static const String statusFailed = 'Failed';
  static const String statusNew = 'New';
  static const String statusSkipped = 'Skipped';
  static const String statusSucceeded = 'Succeeded';
  static const String statusUnderperformed = 'Underperformed';
  static const String statusInProgress = 'In Progress';

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  static const statusColor = <String, Color>{
    statusFailed: Colors.red,
    statusNew: Colors.blue,
    statusInProgress: Colors.blue,
    statusSkipped: Colors.transparent,
    statusSucceeded: Colors.green,
    statusUnderperformed: Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      color: statusColor.containsKey(task.status)
          ? statusColor[task.status]
          : Colors.black,
      child: (task.status == statusInProgress)
          ? const Padding(
              padding: const EdgeInsets.all(15.0),
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                backgroundColor: Colors.white70,
              ),
            )
          : null,
      width: 20,
      height: 20,
    );
  }
}
