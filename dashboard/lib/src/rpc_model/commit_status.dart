// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../model/commit.pb.dart';
import '../../model/task.pb.dart';
import 'base.dart';

part 'commit_status.g.dart';

@JsonSerializable(checked: true)
@immutable
final class CommitStatus extends Model {
  CommitStatus({required this.commit, required Iterable<Task> tasks})
    : tasks = List.unmodifiable(tasks);

  factory CommitStatus.fromJson(Map<String, Object?> json) {
    return _$CommitStatusFromJson(json);
  }

  @JsonKey(name: 'commit', toJson: _commitToJson, fromJson: _commitFromJson)
  final Commit commit;

  static Map<String, Object?> _commitToJson(Commit commit) {
    return commit.toProto3Json() as Map<String, Object?>;
  }

  static Commit _commitFromJson(Map<String, Object?> json) {
    return Commit()..mergeFromJsonMap(json);
  }

  @JsonKey(name: 'tasks', toJson: _tasksToJson, fromJson: _tasksFromJson)
  final List<Task> tasks;

  static List<Object?> _tasksToJson(List<Task> tasks) {
    return tasks.map((t) => t.toProto3Json()).toList();
  }

  static List<Task> _tasksFromJson(List<Object?> tasks) {
    return tasks
        .cast<Map<String, Object?>>()
        .map((t) => Task()..mergeFromJsonMap(t))
        .toList();
  }

  static final _listEq = const ListEquality<void>().equals;

  @override
  bool operator ==(Object other) {
    return other is CommitStatus &&
        commit == other.commit &&
        _listEq(tasks, other.tasks);
  }

  @override
  int get hashCode {
    return Object.hash(commit, Object.hashAll(tasks));
  }

  @override
  Map<String, Object?> toJson() {
    return _$CommitStatusToJson(this);
  }
}
