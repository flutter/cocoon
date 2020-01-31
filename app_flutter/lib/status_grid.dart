// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Task;

import 'commit_box.dart';
import 'state/flutter_build.dart';
import 'task_box.dart';
import 'task_icon.dart';
import 'task_matrix.dart' as task_matrix;

/// Container that manages the layout and data handling for [StatusGrid].
///
/// If there's no data for [StatusGrid], it shows [CircularProgressIndicator].
class StatusGridContainer extends StatelessWidget {
  const StatusGridContainer({Key key}) : super(key: key);

  @visibleForTesting
  static const String errorFetchCommitStatus =
      'An error occurred fetching commit statuses';
  @visibleForTesting
  static const String errorFetchTreeStatus =
      'An error occurred fetching tree build status';
  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);

  @override
  Widget build(BuildContext context) {
    return Consumer<FlutterBuildState>(
      builder: (_, FlutterBuildState buildState, Widget child) {
        final List<CommitStatus> statuses = buildState.statuses;

        // Assume if there is no data that it is loading.
        if (statuses.isEmpty) {
          return const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final task_matrix.TaskMatrix matrix =
            task_matrix.TaskMatrix(statuses: statuses);
        matrix.sort(compareRecentlyFailed);

        return StatusGrid(
          buildState: buildState,
          statuses: statuses,
          taskMatrix: matrix,
        );
      },
    );
  }

  /// Order columns by showing those that have failed recently first.
  int compareRecentlyFailed(task_matrix.Column a, task_matrix.Column b) {
    return _lastFailed(a).compareTo(_lastFailed(b));
  }

  /// Return how many [Task] since the last failure for [Column].
  ///
  /// If no failure has ever occurred, return the highest possible value for
  /// the matrix. This max would be the number of rows in the matrix.
  int _lastFailed(task_matrix.Column a) {
    for (int row = 0; row < a.tasks.length; row++) {
      if (a.tasks[row]?.status == TaskBox.statusFailed) {
        return row;
      }
    }

    return a.tasks.length;
  }
}

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid({
    Key key,
    @required this.buildState,
    @required this.statuses,
    @required this.taskMatrix,
    this.insertCellKeys = false,
  }) : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  /// Computed matrix of [Task] to make it easy to retrieve and sort tasks.
  final task_matrix.TaskMatrix taskMatrix;

  /// Reference to the build state to perform actions on [TaskMatrix], like rerunning tasks.
  final FlutterBuildState buildState;

  /// Used for testing to lookup the widget corresponding to a position in [StatusGrid].
  @visibleForTesting
  final bool insertCellKeys;

  static const double cellSize = 50;

  @override
  Widget build(BuildContext context) {
    /// The grid needs to know its dimensions. Column is based off how many tasks are
    /// in a row (+ 1 to account for [CommitBox]).
    final int columnCount = taskMatrix.columns + 1;
    return Expanded(
      // The grid is wrapped with SingleChildScrollView to enable scrolling both
      // horizontally and vertically
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: columnCount * cellSize,
          // TODO(chillers): Refactor this to a separate TaskView widget. https://github.com/flutter/flutter/issues/43376
          child: GridView.builder(
            addRepaintBoundaries: false,

            /// The grid has as many rows as there are statuses. Additionally,
            /// one row for task descriptions, and one at the bottom to show
            /// a loader for more data.
            itemCount: columnCount * (statuses.length + 2),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
            ),
            itemBuilder: (BuildContext context, int gridIndex) {
              if (gridIndex == 0) {
                /// The top left corner of the grid is nothing since
                /// the left column is for [CommitBox] and the top
                /// row is for [TaskIcon].
                return const SizedBox();
              }

              /// Loader row at the bottom of the grid.
              if (_isLastRow(
                gridIndex: gridIndex,
                columnCount: columnCount,
              )) {
                final int loaderIndex = gridIndex % columnCount;
                const String loadingText = 'LOADING ';

                /// Only trigger [fetchMoreCommitStatuses] API call once for
                /// this loading row.
                if (loaderIndex == 0) {
                  buildState.fetchMoreCommitStatuses();
                }

                /// This loader row will spell out [loadingText].
                return Container(
                  key: insertCellKeys ? Key('loader-$loaderIndex') : null,
                  color: Colors.blueGrey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10.0, 14.0, 10.0, 14.0),
                    child: Text(
                      loadingText[loaderIndex % loadingText.length],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                );
              }

              /// This [GridView] is composed of a row of [TaskIcon] and a subgrid
              /// of [List<List<Task>>]. This allows the row of [TaskIcon] to align
              /// with the column of [Task] that it maps to.
              ///
              /// Mapping [gridIndex] to [index] allows us to ignore the overhead the
              /// row of [TaskIcon] introduces.
              final int index = gridIndex - columnCount;
              if (index < 0) {
                return TaskIcon(
                  key: insertCellKeys
                      ? Key('taskicon-${index % columnCount}')
                      : null,
                  task: taskMatrix.sampleTask(gridIndex - 1),
                );
              }

              final int row = index ~/ columnCount;
              if (index % columnCount == 0) {
                return CommitBox(commit: statuses[row].commit);
              }

              final int column = (index % columnCount) - 1;
              final Task task = taskMatrix.task(row, column);
              if (task == null) {
                /// [Task] was skipped so don't show anything.
                return SizedBox(
                  key: insertCellKeys ? Key('cell-$row-$column') : null,
                  width: StatusGrid.cellSize,
                );
              }

              return TaskBox(
                key: insertCellKeys ? Key('cell-$row-$column') : null,
                task: task,
                buildState: buildState,
                commit: statuses[row].commit,
              );
            },
          ),
        ),
      ),
    );
  }

  /// Check whether the current [gridIndex] resides in the last row.
  ///
  /// Used for checking if logic needs to be performed for the loader row.
  bool _isLastRow({
    @required int gridIndex,
    @required int columnCount,
  }) {
    assert(gridIndex != null && gridIndex >= 0);
    assert(columnCount != null && columnCount >= 0);

    return gridIndex >= (columnCount * (statuses.length + 1));
  }
}
