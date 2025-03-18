// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'commit.dart';
import 'task.dart';

part 'stage.g.dart';

/// A group of related [Task]s run against a particular [Commit].
///
/// Stages are grouped by the infrastructure family that runs them, such as
/// LUCI, DeviceLab on Linux, DeviceLab on Windows, etc.
@immutable
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
class Stage implements Comparable<Stage> {
  const Stage(this.name, this.commit, this.tasks, this.taskStatus);

  const Stage._(this.name, this.commit, this.tasks, this.taskStatus);

  /// The fixed ordering of the stages (by name).
  ///
  /// Unknown stages will be placed at the end of any ordering.
  static const List<String?> _order = <String?>[
    'chromebot',
    'devicelab',
    'devicelab_win',
    'devicelab_ios',
  ];

  /// Arbitrarily large index to represent the "end of the ordering".
  static const int _endOfList = 1000000;

  /// The name of the stage (e.g. 'devicelab', 'devicelab_win').
  ///
  /// This is guaranteed to be non-null.
  @JsonKey(name: 'Name')
  final String? name;

  /// The commit that owns this stage.
  ///
  /// All [tasks] will be run against this commit.
  final Commit? commit;

  /// The list of tasks in this stage.
  ///
  /// These tasks will be run against [commit]. This list is guaranteed to be
  /// non-empty.
  final List<Task> tasks;

  /// Representation of [tasks] used for JSON serialization.
  @JsonKey(name: 'Tasks')
  List<SerializableTask> get serializableTasks {
    return tasks.map<SerializableTask>(SerializableTask.new).toList();
  }

  /// The aggregate status, accounting for all [tasks] in this stage.
  ///
  /// The status is defined as follows:
  ///
  ///  * If all tasks in this stage succeeded, then [Task.statusSucceeded]
  ///  * If at least one task in this stage failed, then [Task.statusFailed]
  ///  * If all tasks have the same status, then that status
  ///  * Else [Task.statusInProgress]
  @JsonKey(name: 'Status')
  final String taskStatus;

  /// Whether this stage is managed by the Flutter device lab.
  ///
  /// Stages such as 'chromebot' are not managed by the Flutter
  /// device lab.
  bool get isManagedByDeviceLab => name!.startsWith('devicelab');

  @override
  int compareTo(Stage other) => _orderIndex(this).compareTo(_orderIndex(other));

  static int _orderIndex(Stage stage) {
    var index = _order.indexOf(stage.name);
    if (index == -1) {
      // Put unknown stages last.
      index = _endOfList;
    }
    return index;
  }

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$StageToJson(this);

  @override
  String toString() {
    final buf =
        StringBuffer()
          ..write('$runtimeType(')
          ..write('name: $name')
          ..write(', commit: ${commit?.sha}')
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
  String? name;

  /// The commit that owns the stage.
  ///
  /// See also:
  ///  * [Stage.commit]
  Commit? commit;

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
      throw StateError('Cannot build a stage with no name');
    }
    if (commit == null) {
      throw StateError('Cannot build a stage with no commit ($name)');
    }
    if (tasks.isEmpty) {
      throw StateError('Cannot build a stage with no tasks ($name)');
    }
    return Stage._(name, commit, List<Task>.unmodifiable(tasks), _taskStatus);
  }

  String get _taskStatus {
    assert(tasks.isNotEmpty);
    bool isSucceeded(Task task) => task.status == Task.statusSucceeded;
    bool isFailed(Task task) => task.status == Task.statusFailed;

    if (tasks.every(isSucceeded)) {
      return Task.statusSucceeded;
    }

    if (tasks.any(isFailed)) {
      return Task.statusFailed;
    }

    final commonStatus = tasks
        .map<String?>((Task task) => task.status)
        .reduce((String? a, String? b) => a == b ? a : null);
    return commonStatus ?? Task.statusInProgress;
  }
}
