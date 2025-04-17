// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'backfill_strategy.dart';
library;

import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../../model/ci_yaml/target.dart';
import '../../service/luci_build_service/opaque_commit.dart';
import '../../service/luci_build_service/pending_task.dart';
import '../../service/scheduler/policy.dart';

/// An indexed grid-like mutable view of the last recent N commits and M tasks.
///
/// It is the primary input to [BackfillStrategy].
///
/// Some common tasks are performed for every grid, independent of a strategy:
/// - Tasks (& targets) are removed that do not exist at tip-of-tree[^1];
/// - Tasks (& targets) are removed that do not use backfilling ([BatchPolicy]);
///
/// [^1]: The latest commit in the default branch of the current repository.
final class BackfillGrid {
  /// Creates an indexed data structure from the provided `(commit, [tasks])`.
  ///
  /// Some automatic filtering is applied, removing targets/tasks where:
  /// - [tipOfTreeTargets] that does not use [BatchPolicy];
  /// - [tipOfTreeTargets] without a task;
  /// - task that does have a matching [tipOfTreeTargets].
  factory BackfillGrid.from(
    Iterable<(OpaqueCommit, List<OpaqueTask>)> grid, {
    required Iterable<Target> tipOfTreeTargets,
  }) {
    final targetsByName = {for (final t in tipOfTreeTargets) t.name: t};
    final commitsByName = <String, OpaqueCommit>{};
    final tasksByName = <String, List<OpaqueTask>>{};
    for (final (commit, tasks) in grid) {
      commitsByName[commit.sha] = commit;
      for (final task in tasks) {
        // Must exist at ToT (in this Map) and must be BatchPolicy.
        if (targetsByName[task.name]?.schedulerPolicy is! BatchPolicy) {
          // Even if it existed, let's remove it at this point because it is no
          // longer relevant to the BackfillGrid, and if there are future API
          // changes to the class it shouldn't show up.
          targetsByName.remove(task.name);
          continue;
        }
        (tasksByName[task.name] ??= []).add(task);
      }
    }

    // Final filtering step: remove empty targets/tasks.
    tasksByName.removeWhere((_, tasks) => tasks.isEmpty);
    targetsByName.removeWhere((name, _) => !tasksByName.containsKey(name));

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
  void removeColumnWhere(bool Function(List<OpaqueTask>) predicate) {
    return _tasksByName.removeWhere((_, tasks) {
      return predicate(UnmodifiableListView(tasks));
    });
  }

  /// Each task, ordered by column (task by task).
  Iterable<(Target, List<OpaqueTask>)> get targets sync* {
    for (final MapEntry(key: name, value: column) in _tasksByName.entries) {
      if (column.isEmpty) {
        throw StateError('A target ("$name") should never have 0 tasks');
      }
      final target = _targetsByName[name];
      if (target == null) {
        throw StateError('A target ("$name") should have existed in the grid');
      }
      yield (target, column);
    }
  }
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
      'task': '$task', //
      'target': '$target',
      'commit': '$commit',
      'priority': priority,
    })}';
  }

  /// Converts to a [PendingTask].
  PendingTask toPendingTask() {
    return PendingTask(target: target, taskName: task.name, priority: priority);
  }
}
