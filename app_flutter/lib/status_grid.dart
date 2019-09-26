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

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  @override
  Widget build(BuildContext context) {
    // Assume if there is no data that it is loading.
    if (statuses.isEmpty) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // The grid needs to know its dimensions, column is based off the stages and
    // how many tasks they each run.
    int columnCount = _getColumnCount(statuses.first);

    /// This is a list of total number of tasks at the end of each stage.
    ///
    /// This allows us to lookup a task based on the number of stages instead of
    /// bruteforcing and looping through all stages and their tasks.
    ///
    /// We calculate this once as it is used when retrieving each [Task].
    List<int> taskIndexBoundaries = _getTaskIndexBoundaries(statuses.first);

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
            itemBuilder: (BuildContext context, int gridIndex) {
              int statusIndex = gridIndex ~/ columnCount;

              if (gridIndex % columnCount == 0) {
                return CommitBox(commit: statuses[statusIndex].commit);
              }

              return TaskBox(
                  task: _mapGridIndexToTask(
                      gridIndex, columnCount, taskIndexBoundaries));
            },
          ),
        ),
      ),
    );
  }

  /// Returns the number of columns the grid should show based on [CommitStatus].
  ///
  /// [CommitStatus] is composed of [List<Stage>] that contains the tasks run
  /// for that stage. Each [Stage] runs a different amount of tasks.
  ///
  /// Additionally, [Commit] from [CommitStatus] must have a cell reserved on
  /// the grid which is another index offset that is accounted.
  int _getColumnCount(CommitStatus status) {
    int columnCount = 1; // start at 1 to reserve room for CommitBox column

    for (Stage stage in status.stages) {
      columnCount += stage.tasks.length;
    }

    return columnCount;
  }

  /// Returns a list of the total number of tasks at the end of each stage.
  ///
  /// This is useful for quickly looking up what [Stage] a [Task] is in given
  /// just an index.
  ///
  /// Additionally, storing the total number of tasks at the end of a [Stage]
  /// allows for quickly getting the relative index for a task in that [Stage].
  ///
  /// The last boundary is 1 above the total number of tasks, thus this
  /// list is inclusive of all tasks (assuming the first [CommitStatus] is
  /// representative of the data).
  List<int> _getTaskIndexBoundaries(CommitStatus status) {
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
  Task _mapGridIndexToTask(
      int gridIndex, int columnCount, List<int> taskIndexBoundaries) {
    int commitStatusIndex = gridIndex ~/ columnCount;
    CommitStatus status = statuses[commitStatusIndex];

    // set index to be relative to this status (and remove the commit index)
    int indexOffset = columnCount * commitStatusIndex;
    int index = gridIndex - indexOffset - 1;

    int stageIndex = 0;
    int taskIndex = 0;
    for (int taskIndexBoundary in taskIndexBoundaries) {
      if (index < taskIndexBoundary) {
        break;
      }

      taskIndex = index - taskIndexBoundary;
      stageIndex++;
    }

    return status.stages[stageIndex].tasks[taskIndex];
  }
}
