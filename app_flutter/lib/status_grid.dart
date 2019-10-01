// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart'
    show Commit, CommitStatus, Stage, Task;

import 'commit_box.dart';
import 'state/flutter_build.dart';
import 'task_box.dart';
import 'task_icon.dart';

/// Container that manages the layout and data handling for [StatusGrid].
///
/// If there's no data for [StatusGrid], it shows [CircularProgressIndicator].
class StatusGridContainer extends StatelessWidget {
  const StatusGridContainer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FlutterBuildState>(
      builder: (_, FlutterBuildState buildState, Widget child) {
        CocoonResponse<List<CommitStatus>> statuses = buildState.statuses;

        // Assume if there is no data that it is loading.
        if (statuses.data.isEmpty) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return StatusGrid(
          statuses: statuses.data,
        );
      },
    );
  }
}

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({Key key, @required this.statuses}) : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  @override
  Widget build(BuildContext context) {
    // The grid needs to know its dimensions, column is based off the stages and
    // how many tasks they each run.
    final int columnCount = _getColumnCount(statuses.first);

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
              if (gridIndex == 0) {
                /// The top left corner of the grid is nothing since
                /// the left column is for [CommitBox] and the top
                /// row is for [TaskIcon].
                return const SizedBox();
              }

              /// This [GridView] is composed of a row of [TaskIcon] and a subgrid
              /// of [List<CommitStatus>]. This allows the row of [TaskIcon] to align
              /// with the column of [Task] that it maps to.
              ///
              /// Mapping [gridIndex] to [index] allows us to ignore the overhead the
              /// row of [TaskIcon] introduces.
              final int index = gridIndex - columnCount;
              if (index < 0) {
                return TaskIcon(
                    task:
                        _mapGridIndexToTaskBruteForce(gridIndex, columnCount));
              }

              if (index % columnCount == 0) {
                final int statusIndex = index ~/ columnCount;
                return CommitBox(commit: statuses[statusIndex].commit);
              }

              return TaskBox(
                task: _mapGridIndexToTaskBruteForce(index, columnCount),
              );
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

  /// Maps a [gridIndex] to a specific [Task] in [List<CommitStatus>]
  ///
  /// Runs in O(# of [Stage]).
  // TODO(chillers): Optimize to O(1). https://github.com/flutter/cocoon/issues/461
  Task _mapGridIndexToTaskBruteForce(int gridIndex, int columnCount) {
    final int commitStatusIndex = gridIndex ~/ columnCount;
    final CommitStatus status = statuses[commitStatusIndex];

    int taskIndex = (gridIndex % columnCount) - 1;

    int currentStageIndex = 0;
    while (taskIndex >= 0 && currentStageIndex < status.stages.length) {
      final Stage currentStage = status.stages[currentStageIndex];
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
