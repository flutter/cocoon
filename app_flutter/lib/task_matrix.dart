// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

/// Matrix to handle data operations on [List<CommitStatus>], such as retrieving
/// a [Task] and ordering [List<CommitStatus>].
///
/// An internal column map is maintained to allow easy reordering of [List<Column>].
/// Additional operations after construction only modify this column map.
///
/// The columns of the matrix can be sorted by passing a custom comparator function.
/// [Column] stores a list of [Task] and [Column.key] is the stage name and task name
/// of the tasks in it. This comparator function will generate values for all of the
/// columns, and compare them in O(nlogn) time where n is the number of columns.
/// Note that the runtime of this sort is mostly the runtime of the comparator function
/// performed O(nlogn) times.
///
/// On addition of a new [CommitStatus], or modification of an existing [CommitStatus],
/// this needs to be rebuilt.
///
/// Construction flattens the list of [CommitStatus] from many [Stage] objects,
/// where each [Stage] object maps to many [Task] objects, to a 2D matrix.
/// Simplifies logic further by moving related [Task] into a [Column], so the
/// matrix is composed of just a list of columns.
class TaskMatrix {
  TaskMatrix({@required this.statuses}) {
    _columnKeyIndex = createColumnKeyIndex();

    // There is no fancy mapping at the start, so each index just points to itself.
    _columnMap = List<int>.generate(_columnKeyIndex.length, (int i) => i);

    _matrix = createTaskMatrix(statuses);
  }

  final List<CommitStatus> statuses;

  List<Column> _matrix;

  /// A map for taking in the corresponding column in [StatusGrid] and
  /// where it maps to in this matrix.
  List<int> _columnMap;

  /// A key, value table to find what grid column a [Task] is in.
  ///
  /// This is necessary to ensure every possible task has a column in the grid.
  Map<String, int> _columnKeyIndex;

  int get columns => _matrix.length;
  int get rows => statuses.length;

  /// Return [Task] for a cell in [StatusGrid].
  Task task(int gridRow, int gridCol) {
    final int mapCol = _columnMap[gridCol];
    return _matrix[mapCol].tasks[gridRow];
  }

  /// Return a sample task from a column.
  ///
  /// This is used for the [TaskIcon] widget row.
  Task sampleTask(int gridCol) {
    final int mapCol = _columnMap[gridCol];
    return _matrix[mapCol].sampleTask;
  }

  /// Sort the columns of this matrix based on [compare].
  ///
  /// This sort function does not change any of the underlying matrix.
  /// Instead, it remaps the column map to point to the correct order.
  ///
  /// This cannot sort the rows of the matrix.
  void sort(int compare(Column a, Column b)) {
    _columnMap.sort((int indexA, int indexB) {
      return compare(_matrix[indexA], _matrix[indexB]);
    });
  }

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

  /// Create a matrix of [Task] by grouping related tasks into a [Column].
  ///
  /// If no [Task] can be placed in a cell of the matrix, it will be left null.
  @visibleForTesting
  List<Column> createTaskMatrix(List<CommitStatus> statuses,
      {Map<String, int> columnKeyIndex}) {
    columnKeyIndex ??= _columnKeyIndex;

    final List<Column> matrix = List<Column>.generate(
        columnKeyIndex.keys.length,
        (int i) => Column(statuses.length, columnKeyIndex.keys.elementAt(i)));

    for (int row = 0; row < statuses.length; row++) {
      final CommitStatus status = statuses[row];

      /// Organize [Task] in [CommitStatus] to the [Column] they map to.
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

/// Helper class to group [Task] that have the same [taskColumnKey] as those tasks are the same
/// except for what [Commit] they were run on.
class Column {
  Column(int size, this.key) : tasks = List<Task>(size);

  /// The [taskColumnKey] that all [Task] in [List<Task>] have.
  final String key;

  /// The rows of [Task].
  ///
  /// There is guranteed to be one non-null entry.
  List<Task> tasks;

  /// The most recent [Task] that is not null.
  ///
  /// Useful for show information about a [Column] that is true in
  /// the tasks of [List<Task>]. For example, when showing the
  /// [TaskIcon] row in [StatusGrid].
  Task sampleTask;
}
