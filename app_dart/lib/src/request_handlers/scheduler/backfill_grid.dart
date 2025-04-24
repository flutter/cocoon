// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'backfill_strategy.dart';
library;

import 'dart:collection';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../../model/ci_yaml/target.dart';
import '../../service/luci_build_service/commit_task_ref.dart';
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
    Iterable<(CommitRef, List<TaskRef>)> grid, {
    required Iterable<Target> tipOfTreeTargets,
  }) {
    final totTargetsByName = {for (final t in tipOfTreeTargets) t.name: t};
    final commitsByName = <String, CommitRef>{};
    final tasksByName = <String, List<TaskRef>>{};
    for (final (commit, tasks) in grid) {
      commitsByName[commit.sha] = commit;
      for (final task in tasks) {
        // Must exist at ToT (in this Map) and must be BatchPolicy.
        if (totTargetsByName[task.name]?.schedulerPolicy is! BatchPolicy) {
          // Even if it existed, let's remove it at this point because it is no
          // longer relevant to the BackfillGrid, and if there are future API
          // changes to the class it shouldn't show up.
          totTargetsByName.remove(task.name);
          continue;
        }
        (tasksByName[task.name] ??= []).add(task);
      }
    }

    // Final filtering step: remove empty targets/tasks.
    tasksByName.removeWhere((_, tasks) => tasks.isEmpty);
    totTargetsByName.removeWhere((name, _) => !tasksByName.containsKey(name));

    return BackfillGrid._(commitsByName, totTargetsByName, tasksByName);
  }

  BackfillGrid._(
    this._commitsBySha, //
    this._targetsByName,
    this._tasksByName,
  );

  final Map<String, CommitRef> _commitsBySha;
  final Map<String, List<TaskRef>> _tasksByName;
  final Map<String, Target> _targetsByName;

  /// Returns a [BackfillTask] with the provided LUCI scheduling [priority].
  ///
  /// If [task] does not originate from [eligibleTasks] the behavior is undefined.
  @useResult
  BackfillTask createBackfillTask(TaskRef task, {required int priority}) {
    final target = _targetsByName[task.name];
    if (target == null) {
      throw ArgumentError.value(
        task,
        'task',
        'No target for task "${task.name}',
      );
    }
    final commit = _commitsBySha[task.commitSha];
    if (commit == null) {
      throw ArgumentError.value(
        task,
        'task',
        'No commit for task "${task.name}',
      );
    }
    return BackfillTask._from(
      task,
      target: target,
      commit: commit,
      priority: priority,
    );
  }

  /// Removes a task column from the grid for which [predicate] returns `true`.
  void removeColumnWhere(bool Function(List<TaskRef>) predicate) {
    return _tasksByName.removeWhere((_, tasks) {
      return predicate(UnmodifiableListView(tasks));
    });
  }

  /// Each task, ordered by column (task by task).
  ///
  /// Returned [TaskRef]s are eligible to be used in [createBackfillTask].
  Iterable<(Target, List<TaskRef>)> get eligibleTasks sync* {
    for (final MapEntry(key: name, value: column) in _tasksByName.entries) {
      if (column.isEmpty) {
        throw StateError('A target ("$name") should never have 0 tasks');
      }
      final target = _targetsByName[name];
      if (target == null) {
        throw StateError('A target ("$name") should have existed in the grid');
      }
      if (target.backfill) {
        yield (target, column);
      }
    }
  }

  /// Each task, ordered by column (task by task).
  ///
  /// Returned tasks are not to be backfilled, and should be marked skipped.
  Iterable<SkippableTask> get skippableTasks sync* {
    for (final MapEntry(key: name, value: column) in _tasksByName.entries) {
      if (column.isEmpty) {
        throw StateError('A target ("$name") should never have 0 tasks');
      }
      final target = _targetsByName[name];
      if (target == null) {
        throw StateError('A target ("$name") should have existed in the grid');
      }
      if (!target.backfill) {
        for (final task in column) {
          final commit = _commitsBySha[task.commitSha];
          if (commit == null) {
            throw StateError(
              'A commit ("${task.commitSha}") should have existed in the grid',
            );
          }
          yield SkippableTask._from(task, target: target, commit: commit);
        }
      }
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
  final TaskRef task;

  /// Which [Target] (originating from `.ci.yaml`) defined this task.
  final Target target;

  /// The commit this task is associated with.
  final CommitRef commit;

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

/// A proposed task to be skipped as part of the backfill process.
@immutable
final class SkippableTask {
  const SkippableTask._from(
    this.task, {
    required this.target,
    required this.commit,
  });

  /// The task itself.
  final TaskRef task;

  /// Which [Target] (originating from `.ci.yaml`) defined this task.
  final Target target;

  /// The commit this task is associated with.
  final CommitRef commit;

  @override
  String toString() {
    return 'SkippableTask ${const JsonEncoder.withIndent('  ').convert({
      'task': '$task', //
      'target': '$target',
      'commit': '$commit',
    })}';
  }
}
