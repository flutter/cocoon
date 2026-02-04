// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'presubmit_guard.g.dart';

@immutable
@JsonSerializable()
final class PresubmitGuardResponse {
  const PresubmitGuardResponse({
    required this.prNum,
    required this.checkRunId,
    required this.author,
    required this.stages,
    required this.guardStatus,
  });

  factory PresubmitGuardResponse.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardResponseFromJson(json);

  @JsonKey(name: 'pr_num')
  final int prNum;

  @JsonKey(name: 'check_run_id')
  final int checkRunId;

  final String author;

  final List<PresubmitGuardStage> stages;

  @JsonKey(name: 'guard_status')
  final GuardStatus guardStatus;

  Map<String, Object?> toJson() => _$PresubmitGuardResponseToJson(this);
}

@immutable
@JsonSerializable()
final class PresubmitGuardStage {
  const PresubmitGuardStage({
    required this.name,
    required this.createdAt,
    required this.builds,
  });

  factory PresubmitGuardStage.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardStageFromJson(json);

  final String name;

  @JsonKey(name: 'created_at')
  final int createdAt;

  final Map<String, TaskStatus> builds;

  Map<String, Object?> toJson() => _$PresubmitGuardStageToJson(this);
}
