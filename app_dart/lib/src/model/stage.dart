// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'commit.dart';
import 'task.dart';

/// A group of related [Task]s run against a particular [Commit].
///
/// Stages are grouped by the infrastructure family that runs them, such as
/// Cirrus, LUCI, DeviceLab on Linux, DeviceLab on Windows, etc.
@immutable
class Stage implements Comparable<Stage> {
  const Stage._(this.name, this.commit, this.tasks, this.taskStatus)
      : assert(name != null),
        assert(commit != null),
        assert(tasks != null),
        assert(tasks.length > 0),
        assert(taskStatus != null);

  /// The fixed ordering of the stages (by name).
  ///
  /// Unknown stages will be placed at the end of any ordering.
  static const List<String> _order = <String>[
    "cirrus",
    "chromebot",
    "devicelab",
    "devicelab_win",
    "devicelab_ios",
  ];

  /// List of stage names that constitute those stages that aren't managed by
  /// the Flutter device lab.
  static const List<String> _external = <String>[
    "cirrus",
    "chromebot",
  ];

  /// Arbitrarily large index to represent the "end of the ordering".
  static const int _endOfList = 1000000;

  /// The name of the stage (e.g. 'cirrus', 'devicelab', 'devicelab_win').
  ///
  /// This is guaranteed to be non-null.
  final String name;

  /// The commit that owns this stage.
  ///
  /// All [tasks] will be run against this commit.
  final Commit commit;

  /// The list of tasks in this stage.
  ///
  /// These tasks will be run against [commit]. This list is guaranteed to be
  /// non-empty.
  final List<Task> tasks;

  /// The aggregate status, accounting for all [tasks] in this stage.
  ///
  /// The status is defined as follows:
  ///
  ///  * If all tasks in this stage succeeded, then 'Succeeded', else...
  ///  * If at least one task in this stage failed, then 'Failed', else...
  ///  * If at least one task is in progress and others are new, then
  ///    'In Progress', else...
  ///  * If all tasks have the same status, then that status, else...
  ///  * 'Failed'
  final String taskStatus;

  /// Whether this stage is managed by the Flutter device lab.
  ///
  /// Stages such as 'cirrus' and 'chromebot' are not managed by the Flutter
  /// device lab.
  bool get isManagedByDeviceLab => !_external.contains(name);

  @override
  int compareTo(Stage other) => _orderIndex(this).compareTo(_orderIndex(other));

  static int _orderIndex(Stage stage) {
    int index = _order.indexOf(stage.name);
    if (index == -1) {
      // Put unknown stages last.
      index = _endOfList;
    }
    return index;
  }

  @override
  String toString() {
    StringBuffer buf = StringBuffer();
    buf
      ..write('$runtimeType(')
      ..write('name: $name')
      ..write(', commit: ${commit.sha}')
      ..write(', tasks: ${tasks.length}')
      ..write(', taskStatus: $taskStatus')
      ..write(')');
    return buf.toString();
  }
}

/// A mutable class used to build instances of [Stage].
class StageBuilder {
  /// The name of the stage.
  ///
  /// See also:
  ///  * [Stage.name]
  String name;

  /// The commit that owns the stage.
  ///
  /// See also:
  ///  * [Stage.commit]
  Commit commit;

  /// The tasks within the stage, run against [commit].
  ///
  /// See also:
  ///  * [Stage.commit]
  List<Task> tasks = <Task>[];

  /// Builds a [Stage] from the information in this builder.
  ///
  /// Throws a [StateError] if [name] is null, [commit] is null, or [tasks] is
  /// empty.
  Stage build() {
    if (name == null) {
      throw StateError('name must not be null');
    }
    if (commit == null) {
      throw StateError('commit must not be null');
    }
    if (tasks.isEmpty) {
      throw StateError('There are tasks in this stage ($name)');
    }
    return Stage._(name, commit, List<Task>.unmodifiable(tasks), _taskStatus);
  }

  String get _taskStatus {
    assert(tasks.isNotEmpty);
    bool isSucceeded(Task task) => task.status == 'Succeeded';
    bool isFailed(Task task) => task.status == 'Failed';
    bool isInProgress(Task task) => task.status == 'In Progress';
    bool isNew(Task task) => task.status == 'New';
    bool isNewOrInProgress(Task task) => isNew(task) || isInProgress(task);

    if (tasks.every(isSucceeded)) {
      return 'Succeeded';
    }

    if (tasks.any(isFailed)) {
      return 'Failed';
    }

    if (tasks.any(isInProgress) && tasks.every(isNewOrInProgress)) {
      return 'In Progress';
    }

    String commonStatus = tasks
        .map<String>((Task task) => task.status)
        .reduce((String a, String b) => a == b ? a : null);
    return commonStatus ?? 'Failed';
  }
}
