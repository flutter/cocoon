// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import 'base.dart';
import 'commit.dart';
import 'task.dart';

part 'commit_status.g.dart';

@JsonSerializable(checked: true)
@immutable
final class CommitStatus extends Model {
  CommitStatus({required this.commit, required Iterable<Task> tasks})
    : tasks = List.unmodifiable(tasks);

  factory CommitStatus.fromJson(Map<String, Object?> json) {
    return _$CommitStatusFromJson(json);
  }

  @JsonKey(name: 'Commit')
  final Commit commit;

  @JsonKey(name: 'Tasks')
  final List<Task> tasks;

  @override
  Map<String, Object?> toJson() {
    return _$CommitStatusToJson(this);
  }
}
