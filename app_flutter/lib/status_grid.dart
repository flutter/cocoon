// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;

import 'state/flutter_build.dart';
import 'commit_box.dart';
import 'task_box.dart';

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// The build status data to display in the grid.
    List<CommitStatus> statuses;

    return Consumer<FlutterBuildState>(
      builder: (context, buildState, child) {
        statuses = buildState.statuses;

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

        return Expanded(
          // The grid is wrapped with SingleChildScrollView to enable scrolling both
          // horizontally and vertically
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
                    task: _mapGridIndexToTaskBruteForce(
                        gridIndex, columnCount, statuses),
                  );
                },
              ),
            ),
          ),
        );
      },
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

  /// Maps a [gridIndex] to a specific [Task] in [List<CommitStatus>]
  Task _mapGridIndexToTaskBruteForce(
      int gridIndex, int columnCount, List<CommitStatus> statuses) {
    int commitStatusIndex = gridIndex ~/ columnCount;
    CommitStatus status = statuses[commitStatusIndex];

    int taskIndex = (gridIndex % columnCount) - 1;

    int currentStageIndex = 0;
    while (taskIndex >= 0 && currentStageIndex < status.stages.length) {
      Stage currentStage = status.stages[currentStageIndex];
      if (taskIndex >= currentStage.tasks.length) {
        taskIndex = taskIndex - currentStage.tasks.length;
        currentStageIndex++;
      } else {
        return currentStage.tasks[taskIndex];
      }
    }

    throw Exception('Could not find Task for gridIndex=$gridIndex');
  }
}
