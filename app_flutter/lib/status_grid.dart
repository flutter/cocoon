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
  const StatusGridContainer({Key key, @required this.gridImplementation})
      : super(key: key);

  final String gridImplementation;

  @visibleForTesting
  static const String errorCocoonBackend = 'Cocoon Backend is having issues';

  @override
  Widget build(BuildContext context) {
    return Consumer<FlutterBuildState>(
      builder: (_, FlutterBuildState buildState, Widget child) {
        final List<CommitStatus> statuses = buildState.statuses.data;

        if (buildState.hasError) {
          print('FlutterBuildState has an error');
          print('isTreeBuilding: ${buildState.isTreeBuilding.error}');
          print('statuses: ${buildState.statuses.error}');

          // TODO(chillers): Display the error
        }

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

        if (gridImplementation == 'ListView<ListView>') {
          return Experiment(
            statuses: statuses,
            taskMatrix: matrix,
          );
        }

        return StatusGrid(
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
    @required this.statuses,
    @required this.taskMatrix,
  }) : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  /// Computed matrix of [Task] to make it easy to retrieve and sort tasks.
  final task_matrix.TaskMatrix taskMatrix;

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
          width: columnCount * 50.0,
          // TODO(chillers): Refactor this to a separate TaskView widget. https://github.com/flutter/flutter/issues/43376
          child: GridView.builder(
            addRepaintBoundaries: false,
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
              /// of [List<List<Task>>]. This allows the row of [TaskIcon] to align
              /// with the column of [Task] that it maps to.
              ///
              /// Mapping [gridIndex] to [index] allows us to ignore the overhead the
              /// row of [TaskIcon] introduces.
              final int index = gridIndex - columnCount;
              if (index < 0) {
                return TaskIcon(task: taskMatrix.sampleTask(gridIndex - 1));
              }

              final int row = index ~/ columnCount;
              if (index % columnCount == 0) {
                return CommitBox(commit: statuses[row].commit);
              }

              final int column = (index % columnCount) - 1;
              final Task task = taskMatrix.task(row, column);
              if (task == null) {
                /// [Task] was skipped so don't show anything.
                return const SizedBox();
              }

              return TaskBox(task: task);
            },
          ),
        ),
      ),
    );
  }
}

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class Experiment extends StatefulWidget {
  const Experiment({
    Key key,
    @required this.statuses,
    @required this.taskMatrix,
  }) : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  /// Computed matrix of [Task] to make it easy to retrieve and sort tasks.
  final task_matrix.TaskMatrix taskMatrix;

  static SyncScrollController _horizontalController;

  @override
  _ExperimentState createState() => _ExperimentState();
}

class _ExperimentState extends State<Experiment> {
  List<ScrollController> controllers;
  SyncScrollController _syncScroller;
  @override
  void initState() {
    controllers = List<ScrollController>.generate(
        widget.taskMatrix.rows, (_) => ScrollController());
    _syncScroller = SyncScrollController(controllers);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int rowIndex = 0; rowIndex < widget.taskMatrix.rows; rowIndex++) {
      final List<TaskBox> tasks = <TaskBox>[];
      for (int colIndex = 0; colIndex < widget.taskMatrix.columns; colIndex++) {
        tasks.add(TaskBox(
          task: widget.taskMatrix.task(rowIndex, colIndex),
        ));
      }

      rows.add(
        Container(
          height: 60,
          child: NotificationListener<ScrollNotification>(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: controllers[rowIndex],
              itemBuilder: (BuildContext context, int colIndex) {
                return TaskBox(
                    task: widget.taskMatrix.task(rowIndex, colIndex));
              },
              shrinkWrap: false,
              addRepaintBoundaries: false,
            ),
            onNotification: (ScrollNotification scrollInfo) {
              _syncScroller.processNotification(
                  scrollInfo, controllers[rowIndex]);
              return true;
            },
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int row) {
          return rows[row];
        },
        itemCount: widget.taskMatrix.rows,
        shrinkWrap: false,
        addRepaintBoundaries: false,
      ),
    );
  }
}

// https://stackoverflow.com/questions/54859779/scroll-multiple-scrollable-widgets-in-sync
class SyncScrollController {
  List<ScrollController> _registeredScrollControllers =
      new List<ScrollController>();

  ScrollController _scrollingController;
  bool _scrollingActive = false;

  SyncScrollController(List<ScrollController> controllers) {
    controllers.forEach((controller) => registerScrollController(controller));
  }

  void registerScrollController(ScrollController controller) {
    _registeredScrollControllers.add(controller);
  }

  void processNotification(
      ScrollNotification notification, ScrollController sender) {
    if (notification is ScrollStartNotification && !_scrollingActive) {
      _scrollingController = sender;
      _scrollingActive = true;
      return;
    }

    if (identical(sender, _scrollingController) && _scrollingActive) {
      if (notification is ScrollEndNotification) {
        _scrollingController = null;
        _scrollingActive = false;
        return;
      }

      if (notification is ScrollUpdateNotification) {
        _registeredScrollControllers.forEach((controller) => {
              if (!identical(_scrollingController, controller))
                controller..jumpTo(_scrollingController.offset)
            });
        return;
      }
    }
  }
}
