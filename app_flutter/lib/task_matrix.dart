// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus, Stage, Task;

class TaskMatrix {
  TaskMatrix({@required this.statuses}) {
    _columnKeyIndex = _createColumnKeyIndex();
    _columnMap = <int, int>{};
    for (int i = 0; i < _columnKeyIndex.length; i++) {
      _columnMap[i] = i;
    }

    _matrix = _createTaskMatrix(statuses);
  }

  final List<CommitStatus> statuses;

  List<Column> _matrix;

  /// A map for taking in the corresponding column in [StatusGrid] and
  /// where it maps to in [_taskMatrix].
  Map<int, int> _columnMap;

  /// A key, value table to find what column a [Task] is in.
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
  String _taskColumnKey(Task task) {
    return '${task.stageName}:${task.name}';
  }

  /// A map of all [taskColumnKey] to a unique index from [List<CommitStatus>].
  ///
  /// Scans through all [Task] in [List<CommitStatus>] to find all unique [taskColumnKey].
  /// This ensures a column is allocated in [_createTaskMatrix].
  ///
  /// When a new [taskColumnKey] is found, it is inserted and the index is incremeted.
  Map<String, int> _createColumnKeyIndex({List<CommitStatus> statuses}) {
    statuses ??= this.statuses;

    final Map<String, int> taskColumnKeyIndex = <String, int>{};
    int currentIndex = 0;

    /// O(Tasks * CommitStatuses).
    /// In production, this is usually O(85 * 100) ~ 8500 operations.
    for (CommitStatus status in statuses) {
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          final String key = _taskColumnKey(task);
          if (taskColumnKeyIndex.containsKey(key)) {
            continue;
          }

          taskColumnKeyIndex[key] = currentIndex++;
        }
      }
    }

    return taskColumnKeyIndex;
  }

  /// Sort [columnKeyIndex] based on a list of weights.
  ///
  /// For duplicate weights, order is assumed to not matter.
  @visibleForTesting
  Map<String, int> sortColumnKeyIndex(
      Map<String, int> columnKeyIndex, List<int> weights) {
    final Map<String, int> sortedColumnKeyIndex = <String, int>{};

    // 1. Create a map that maps the current index to its given weight
    final Map<int, int> weightIndex = <int, int>{};
    for (int i = 0; i < weights.length; i++) {
      weightIndex[i] = weights[i];
    }

    // 2. Sort (1) by value (weight) in ascending order.
    final List<int> sortedWeightKeys = weightIndex.keys.toList()
      ..sort((int k1, int k2) => weightIndex[k1].compareTo(weightIndex[k2]));

    // Store in a LinkedHashMap to preserve the order
    final LinkedHashMap<int, int> sortedWeights = LinkedHashMap<int, int>();
    for (int index = 0; index < sortedWeightKeys.length; index++) {
      final int weight = sortedWeightKeys[index];
      sortedWeights[weight] = weightIndex[weight];
    }

    // 3. Reassign the task index map based on the order from (2)
    final Map<int, String> reversedColumnKeyIndex = columnKeyIndex
        .map((String key, int value) => MapEntry<int, String>(value, key));
    int newIndex = 0;
    sortedWeights.forEach((int key, int value) {
      final String taskKey = reversedColumnKeyIndex[key];
      sortedColumnKeyIndex[taskKey] = newIndex++;
    });

    return sortedColumnKeyIndex;
  }

  /// Create a matrix of [Task] for easier sorting of [List<CommitStatus>].
  ///
  /// If no [Task] can be placed in a cell of the matrix, it will be left null.
  List<Column> _createTaskMatrix(List<CommitStatus> statuses,
      {Map<String, int> columnKeyIndex}) {
    columnKeyIndex ??= _columnKeyIndex;

    /// Rows are commits, columns are [Task] with same [taskColumnKey].
    final List<Column> matrix = List<Column>.filled(
        columnKeyIndex.keys.length, Column(statuses.length));

    for (int row = 0; row < statuses.length; row++) {
      final CommitStatus status = statuses[row];

      /// Organize [Task] in [CommitStatus] to the column they map to.
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          final int columnIndex = columnKeyIndex[_taskColumnKey(task)];
          final Column column = matrix[columnIndex];
          column.tasks[row] = task;
          column.sampleTask = task;
        }
      }
    }

    return matrix;
  }
}

class Column {
  Column(int size) : tasks = List<Task>.filled(size, null);

  List<Task> tasks;

  /// Task for the task icon
  Task sampleTask;
}
