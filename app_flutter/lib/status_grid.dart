// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;
import 'package:flutter/material.dart';

import 'commit_box.dart';
import 'task_box.dart';

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({Key key, @required this.statuses})
      : assert(statuses != null),
        super(key: key);

  final List<CommitStatus> statuses;

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return Text('loading');
    }

    int columnCount = _getColumnCount(statuses.first);
    List<int> stageIndices = _getTaskIndexTable(statuses.first);

    // The grid is wrapped with SingleChildScrollView to enable scrolling both
    // horizontally and vertically
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: columnCount * 50.0,
          child: GridView.builder(
            itemCount: columnCount * statuses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount),
            itemBuilder: (BuildContext context, int index) {
              int commitStatusIndex = index ~/ columnCount;
              if (index % columnCount == 0) {
                return CommitBox(commit: statuses[commitStatusIndex].commit);
              }

              return TaskBox(
                  task: _getTaskFromStatuses(index, columnCount, stageIndices));
            },
          ),
        ),
      ),
    );
  }

  /// Returns the number of columns the grid should show based on [CommitStatus].
  ///
  /// [CommitStatus] is composed of [List<Stage>] that contains the tasks run for that stage.
  /// Each [Stage] runs a different amount of tasks.
  ///
  /// Additionally, [Commit] from [CommitStatus] must have a cell reserved on the grid.
  int _getColumnCount(CommitStatus status) {
    int columnCount = 1;

    for (Stage stage in status.stages) {
      columnCount += stage.tasks.length;
    }

    return columnCount;
  }

  /// Returns
  List<int> _getTaskIndexTable(CommitStatus status) {
    List<int> indices = <int>[];

    for (int i = 0; i < status.stages.length; i++) {
      Stage stage = status.stages[i];
      if (i == 0) {
        indices.add(stage.tasks.length);
      } else {
        indices.add(indices[i - 1] + stage.tasks.length);
      }
    }

    return indices;
  }

  /// Returns [Task] associated with an overall index in [List<CommitStatus>]
  Task _getTaskFromStatuses(
      int index, int columnCount, List<int> stageIndices) {
    int commitStatusIndex = index ~/ columnCount;
    CommitStatus status = statuses[commitStatusIndex];

    // set index to be relative to this status (and remove the commit index)
    int indexOffset = columnCount * commitStatusIndex;
    index = index - indexOffset - 1;

    int stageIndex = 0;
    int taskIndex = 0;
    for (int i in stageIndices) {
      if (index < i) {
        break;
      }

      taskIndex = index - i;
      stageIndex++;
    }

    return status.stages[stageIndex].tasks[taskIndex];
  }
}
