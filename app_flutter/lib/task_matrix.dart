// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

class TaskMatrix {
  TaskMatrix({@required this.statuses}) {
    _columnKeyIndex = createColumnKeyIndex();
    _columnMap = List<int>.generate(_columnKeyIndex.length, (int i) => i);

    _matrix = createTaskMatrix(statuses);
  }

  final List<CommitStatus> statuses;

  List<Column> _matrix;

  /// A map for taking in the corresponding column in [StatusGrid] and
  /// where it maps to in [_taskMatrix].
  List<int> _columnMap;

  /// A key, value table to find what column a [Task] is in.
  ///
  /// This is necessary to ensure every possible task has a column in the grid.
  Map<String, int> _columnKeyIndex;

  int get columns => _matrix.length;
  int get rows => statuses.length;

  /// Return [Task] in [_matrix] for a row and col in [StatusGrid].
  Task task(int gridRow, int gridCol) {
    final int mapCol = _columnMap[gridCol];
    return _matrix[mapCol].tasks[gridRow];
  }

  /// Return a sample task from a column.
  Task sampleTask(int gridCol) {
    final int mapCol = _columnMap[gridCol];
    return _matrix[mapCol].sampleTask;
  }

  void sort(int compare(Column a, Column b)) {}

  /// A unique index for grouping [Task] from separate [CommitStatus].
  ///
  /// [task.stageName] and [task.name] are not unique. However, they
  /// are unique when combined together.
  @visibleForTesting
  String taskColumnKey(Task task) {
    return '${task.stageName}:${task.name}';
  }

  /// A map of all [taskColumnKey] to a unique index from [List<CommitStatus>].
  ///
  /// Scans through all [Task] in [List<CommitStatus>] to find all unique [taskColumnKey].
  /// This ensures a column is allocated in [createTaskMatrix].
  ///
  /// When a new [taskColumnKey] is found, it is inserted and the index is incremeted.
  @visibleForTesting
  Map<String, int> createColumnKeyIndex({List<CommitStatus> statuses}) {
    statuses ??= this.statuses;

    final Map<String, int> taskColumnKeyIndex = <String, int>{};
    int currentIndex = 0;

    /// O(Tasks * CommitStatuses).
    /// In production, this is usually O(85 * 100) ~ 8500 operations.
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
  ///
  /// If no [Task] can be placed in a cell of the matrix, it will be left null.
  @visibleForTesting
  List<Column> createTaskMatrix(List<CommitStatus> statuses,
      {Map<String, int> columnKeyIndex}) {
    columnKeyIndex ??= _columnKeyIndex;

    /// Rows are commits, columns are [Task] with same [taskColumnKey].
    final List<Column> matrix = List<Column>.generate(
        columnKeyIndex.keys.length,
        (int i) => Column(statuses.length, columnKeyIndex.keys.elementAt(i)));

    for (int row = 0; row < statuses.length; row++) {
      final CommitStatus status = statuses[row];

      /// Organize [Task] in [CommitStatus] to the column they map to.
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          final String columnKey = taskColumnKey(task);
          final int columnIndex = columnKeyIndex[columnKey];
          final Column column = matrix[columnIndex];
          final List<Task> tasks = column.tasks;

          tasks[row] = task;
          column.sampleTask ??= task;
        }
      }
    }

    return matrix;
  }
}

class Column {
  Column(int size, this.key) : tasks = List<Task>(size);

  final String key;

  List<Task> tasks;

  /// Task for the task icon
  Task sampleTask;
}
