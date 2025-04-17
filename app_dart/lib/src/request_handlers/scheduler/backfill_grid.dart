// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../../model/ci_yaml/target.dart';
import '../../service/luci_build_service/opaque_commit.dart';
import '../../service/luci_build_service/pending_task.dart';

/// An indexed grid-like mutable view of the last recent N commits and M tasks.
final class BackfillGrid {
  /// Creates an indexed data structure from the provided `(commit, [tasks])`.
  factory BackfillGrid.from(
    Iterable<(OpaqueCommit, List<OpaqueTask>)> grid, {
    required Iterable<Target> targets,
    bool omitTasksMissingFromTargets = true,
  }) {
    final targetsByName = {for (final t in targets) t.name: t};
    final commitsByName = <String, OpaqueCommit>{};
    final tasksByName = <String, List<OpaqueTask>>{};
    for (final (commit, tasks) in grid) {
      commitsByName[commit.sha] = commit;
      for (final task in tasks) {
        if (!targetsByName.containsKey(task.name)) {
          continue;
        }
        tasksByName.update(
          task.name,
          (list) => list..add(task),
          ifAbsent: () => [task],
        );
      }
    }
    return BackfillGrid._(commitsByName, targetsByName, tasksByName);
  }

  BackfillGrid._(
    this._commitsBySha, //
    this._targetsByName,
    this._tasksByName,
  );

  final Map<String, OpaqueCommit> _commitsBySha;
  final Map<String, List<OpaqueTask>> _tasksByName;
  final Map<String, Target> _targetsByName;

  /// Returns a [BackfillTask] with the provided LUCI scheduling [priority].
  @useResult
  BackfillTask createBackfillTask(OpaqueTask task, {required int priority}) {
    return BackfillTask._from(
      task,
      target: _targetsByName[task.name]!,
      commit: _commitsBySha[task.commitSha]!,
      priority: priority,
    );
  }

  /// Removes tasks (a column) from the grid that return `true` for [predicate].
  void removeTaskColumnWhere(bool Function(List<OpaqueTask>) predicate) {
    return _tasksByName.removeWhere((_, tasks) {
      return predicate(UnmodifiableListView(tasks));
    });
  }

  /// Each task, ordered by row (commit by commit).
  Iterable<List<OpaqueTask>> get rows sync* {
    for (final column in _tasksByName.values) {
      if (column.isNotEmpty) {
        yield column;
      }
    }
  }

  /// Returns the [Target] for [task].
  Target getTargetFor(OpaqueTask task) => _targetsByName[task.name]!;
}

/// A proposed task to be scheduled as part of the backfill process.
@immutable
final class BackfillTask {
  const BackfillTask._from(
    this.task, {
    required this.target,
    required this.commit,
    required this.priority,
  });

  /// The task itself.
  final OpaqueTask task;

  /// Which [Target] (originating from `.ci.yaml`) defined this task.
  final Target target;

  /// The commit this task is associated with.
  final OpaqueCommit commit;

  /// The LUCI scheduling priority of backfilling this task.
  final int priority;

  @override
  String toString() {
    return 'BackfillTask ${const JsonEncoder.withIndent('  ').convert({
      task: '$task', //
      target: '$target',
      commit: '$commit',
      priority: priority,
    })}';
  }

  /// Converts to a [PendingTask].
  PendingTask toPendingTask() {
    return PendingTask(target: target, taskName: task.name, priority: priority);
  }
}
