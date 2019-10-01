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

  /// A lookup table to define the background color for this TaskBox.
  ///
  /// The status messages are based on the messages the backend sends.
  static const statusColor = <String, Color>{
    'Failed': Colors.red,
    'New': Colors.blue,
    'Skipped': Colors.transparent,
    'Succeeded': Colors.green,
    'Underperformed': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    if (task.status == 'In Progress') {
      return Container(
        margin: const EdgeInsets.all(1.0),
        color: statusColor['New'],
        child: const Padding(
          padding: EdgeInsets.all(25.0),
          child: const CircularProgressIndicator(
            strokeWidth: 3.0,
            backgroundColor: Colors.white70,
          ),
        ),
        width: 20,
        height: 20,
      );
    }

    return Container(
      margin: const EdgeInsets.all(1.0),
      color: statusColor.containsKey(task.status)
          ? statusColor[task.status]
          : Colors.black,
      width: 20,
      height: 20,
    );
  }
}
