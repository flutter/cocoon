// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

import 'commit_box.dart';
import 'state/flutter_build.dart';
import 'task_box.dart';
import 'task_icon.dart';

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

        return StatusGrid(
          statuses: statuses,
          taskMatrix: createTaskMatrix(statuses),
        );
      },
    );
  }

  /// A unique index for grouping [Task] from separate [CommitStatus].
  ///
  /// [task.stageName] and [task.name] are not unique. However, they
  /// are unique when combined together.
  static String taskColumnKey(Task task) {
    return '${task.stageName}:${task.name}';
  }

  /// A map of all [taskColumnKey] to a unique index from [List<CommitStatus>].
  ///
  /// Scans through all [Task] in [List<CommitStatus>] to find all unique [taskColumnKey].
  /// This ensures a column is allocated in [createTaskMatrix].
  ///
  /// When a new [taskColumnKey] is found, it is inserted and the index is incremeted.
  @visibleForTesting
  static Map<String, int> createTaskColumnKeyIndex(
      List<CommitStatus> statuses) {
    final Map<String, int> taskColumnKeyIndex = <String, int>{};
    int currentIndex = 0;

    /// O(Tasks * CommitStatuses). In production, this is usually O(85 * 100) ~ 8500 operations.
    for (CommitStatus status in statuses) {
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          final String key = taskColumnKey(task);
          if (taskColumnKeyIndex.containsKey(key)) {
            continue;
          }

          taskColumnKeyIndex[key] = currentIndex++;
        }
      }
    }

    return taskColumnKeyIndex;
  }

  /// Create a matrix of [Task] for easier sorting of [List<CommitStatus>].
  @visibleForTesting
  static List<List<Task>> createTaskMatrix(List<CommitStatus> statuses) {
    final Map<String, int> taskColumnKeyIndex =
        createTaskColumnKeyIndex(statuses);

    /// Rows are commits, columns are [Task] with same [taskColumnKey].
    final List<List<Task>> taskMatrix = List<List<Task>>.generate(
        statuses.length, (_) => List<Task>(taskColumnKeyIndex.keys.length));

    for (int statusIndex = 0; statusIndex < statuses.length; statusIndex++) {
      final CommitStatus status = statuses[statusIndex];
      final List<Task> statusTasks = taskMatrix[statusIndex];

      /// Organize [Task] in [CommitStatus] to the column they map to.
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          statusTasks[taskColumnKeyIndex[taskColumnKey(task)]] = task;
        }
      }
    }

    return taskMatrix;
  }
}

/// Display results from flutter/flutter repository's continuous integration.
///
/// Results are displayed in a matrix format. Rows are commits and columns
/// are the results from tasks.
class StatusGrid extends StatelessWidget {
  const StatusGrid(
      {Key key, @required this.statuses, @required this.taskMatrix})
      : super(key: key);

  /// The build status data to display in the grid.
  final List<CommitStatus> statuses;

  /// Computed 2D array of [Task] to make it easy to retrieve and sort tasks.
  final List<List<Task>> taskMatrix;

  @override
  Widget build(BuildContext context) {
    // The grid needs to know its dimensions, column is based off the stages and
    // how many tasks they each run.
    final int columnCount = taskMatrix[0].length;

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
              /// of [List<List<Task>>]. This allows the row of [TaskIcon] to align
              /// with the column of [Task] that it maps to.
              ///
              /// Mapping [gridIndex] to [index] allows us to ignore the overhead the
              /// row of [TaskIcon] introduces.
              final int index = gridIndex - columnCount;
              if (index < 0) {
                return TaskIcon(task: taskMatrix[0][gridIndex - 1]);
              }

              final int statusIndex = index ~/ columnCount;
              if (index % columnCount == 0) {
                return CommitBox(commit: statuses[statusIndex].commit);
              }

              final int taskIndex = index % columnCount;
              return TaskBox(
                task: taskMatrix[statusIndex][taskIndex],
              );
            },
          ),
        ),
      ),
    );
  }
}
