// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../guard_status.dart';
import '../../task_status.dart';

part 'presubmit_guard.g.dart';

/// Response model for a Presubmit Guard.
///
/// Contains the aggregated status and stages of presubmit checks for a specific commit.
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

  /// The pull request number.
  @JsonKey(name: 'pr_num')
  final int prNum;

  /// The check run ID associated with the presubmit guard.
  @JsonKey(name: 'check_run_id')
  final int checkRunId;

  /// The login name of the author of the commit or pull request.
  final String author;

  /// The list of stages and their corresponding builds for this presubmit guard.
  final List<PresubmitGuardStage> stages;

  /// The overall status of the presubmit guard across all stages.
  @JsonKey(name: 'guard_status')
  final GuardStatus guardStatus;

  /// Creates a [PresubmitGuardResponse] from a JSON map.
  factory PresubmitGuardResponse.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardResponseFromJson(json);

  /// Converts this [PresubmitGuardResponse] to a JSON map.
  Map<String, Object?> toJson() => _$PresubmitGuardResponseToJson(this);
}

/// Represents a single stage in a presubmit guard.
///
/// A stage groups related builds (tasks) together, for example, 'fusion' or 'engine'.
@immutable
@JsonSerializable()
final class PresubmitGuardStage {
  const PresubmitGuardStage({
    required this.name,
    required this.createdAt,
    required this.builds,
  });

  /// The name of the stage (e.g., 'fusion', 'engine').
  final String name;

  /// The creation timestamp of this stage in milliseconds since the epoch.
  @JsonKey(name: 'created_at')
  final int createdAt;

  /// Map of build names to their current statuses.
  final Map<String, TaskStatus> builds;

  /// Creates a [PresubmitGuardStage] from a JSON map.
  factory PresubmitGuardStage.fromJson(Map<String, Object?> json) =>
      _$PresubmitGuardStageFromJson(json);

  /// Converts this [PresubmitGuardStage] to a JSON map.
  Map<String, Object?> toJson() => _$PresubmitGuardStageToJson(this);
}
