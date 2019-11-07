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
class StatusGrid extends StatefulWidget {
  const StatusGrid({
    Key key,
    @required this.buildState,
    @required this.statuses,
    @required this.taskMatrix,
  }) : super(key: key);

  /// Reference to the build state to perform actions on [TaskMatrix], like rerunning tasks.
  final FlutterBuildState buildState;

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  /// Computed matrix of [Task] to make it easy to retrieve and sort tasks.
  final task_matrix.TaskMatrix taskMatrix;

  @override
  _StatusGridState createState() => _StatusGridState();
}

class _StatusGridState extends State<StatusGrid> {
  List<ScrollController> controllers;
  SyncScrollController _syncScroller;

  @override
  Widget build(BuildContext context) {
    controllers = List<ScrollController>.generate(
        widget.taskMatrix.rows + 1, (_) => ScrollController());
    _syncScroller = SyncScrollController(controllers);

    final List<ListView> rows = _buildRows();

    return Expanded(
      child: ListView(
        children: rows,
        shrinkWrap: false,
      ),
    );
  }

  List<ListView> _buildRows() {
    final List<Widget> rows = <Widget>[];

    rows.add(
      Container(
        height: 50,
        child: NotificationListener<ScrollNotification>(
          child: ListView(
            controller: controllers[0],
            children: _buildTaskIconRow(),
            scrollDirection: Axis.horizontal,
          ),
          onNotification: (ScrollNotification scrollInfo) {
            _syncScroller.processNotification(scrollInfo, controllers[0]);
            return;
          },
        ),
      ),
    );

    for (int rowIndex = 0; rowIndex < widget.taskMatrix.rows; rowIndex++) {
      final List<TaskBox> tasks = <TaskBox>[];
      for (int colIndex = 0; colIndex < widget.taskMatrix.columns; colIndex++) {
        tasks.add(TaskBox(
          buildState: widget.buildState,
          task: widget.taskMatrix.task(rowIndex, colIndex),
        ));
      }

      rows.add(
        Container(
          height: 50,
          child: NotificationListener<ScrollNotification>(
            child: ListView.builder(
              controller: controllers[rowIndex + 1],
              scrollDirection: Axis.horizontal,
              itemCount: widget.taskMatrix.columns + 1,
              itemBuilder: (BuildContext context, int colIndex) {
                if (colIndex == 0) {
                  return CommitBox(
                    commit: widget.statuses[rowIndex].commit,
                  );
                }
                return Container(
                  width: 50,
                  child: TaskBox(
                    buildState: widget.buildState,
                    task: widget.taskMatrix.task(rowIndex, colIndex - 1),
                  ),
                );
              },
              shrinkWrap: false,
            ),
            onNotification: (ScrollNotification scrollInfo) {
              _syncScroller.processNotification(
                  scrollInfo, controllers[rowIndex + 1]);
              return;
            },
          ),
        ),
      );
    }

    return rows;
  }

  List<Widget> _buildTaskIconRow() {
    final List<Widget> taskIcons = <Widget>[];
    taskIcons.add(Container(width: 50));
    for (int colIndex = 0; colIndex < widget.taskMatrix.columns; colIndex++) {
      taskIcons.add(
        Container(
          width: 50,
          child: TaskIcon(
            task: widget.taskMatrix.sampleTask(colIndex),
          ),
        ),
      );
    }

    return taskIcons;
  }
}

// https://stackoverflow.com/questions/54859779/scroll-multiple-scrollable-widgets-in-sync
class SyncScrollController {
  SyncScrollController(List<ScrollController> controllers) {
    controllers.forEach((controller) => registerScrollController(controller));
  }

  final List<ScrollController> _registeredScrollControllers =
      <ScrollController>[];

  ScrollController _scrollingController;
  bool _scrollingActive = false;

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
