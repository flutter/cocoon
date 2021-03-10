// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

import '../appengine/commit.dart';

part 'schedule_prod.g.dart';

/// RPC to scheduler microservice to trigger tasks against [commits].
@JsonSerializable()
class ScheduleProdTasks {
  /// Creates a new [Task].
  const ScheduleProdTasks({
    this.commits,
  });

  factory ScheduleProdTasks.fromJson(Map<String, dynamic> json) => _$ScheduleProdTasksFromJson(json);

  final Set<Commit> commits;

  Map<String, dynamic> toJson() => _$ScheduleProdTasksToJson(this);
}
