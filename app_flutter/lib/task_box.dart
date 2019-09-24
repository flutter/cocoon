// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Task;

/// Displays information from a [Task].
///
/// Shows a black box for unknown messages.
class TaskBox extends StatelessWidget {
  const TaskBox({Key key, @required this.task}) : super(key: key);

  /// [Task] to show information from.
  final Task task;

  /// A lookup table to define the background color for this ResultBox.
  ///
  /// The result messages are based on the messages the backend sends.
  static const resultColor = <String, Color>{
    'Failed': Colors.red,
    'In Progress': Colors.purple, // v1 used the 'New' color while spinning
    'New': Colors.blue,
    'Skipped': Colors.transparent,
    'Succeeded': Colors.green,
    'Underperformed': Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      color: resultColor.containsKey(task.status)
          ? resultColor[task.status]
          : Colors.black,
      width: 20,
      height: 20,
    );
  }
}
