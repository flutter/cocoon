// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

@JsonSerializable(nullable: true)
class GetStatusResult {
  const GetStatusResult({this.statuses, this.agentStatuses});

  factory GetStatusResult.fromJson(Map<String, dynamic> json) =>
      _$GetStatusResultFromJson(json);

  @JsonKey(name: 'Statuses')
  final List<BuildStatus> statuses;

  @JsonKey(name: 'AgentStatuses')
  final List<AgentStatus> agentStatuses;
}

@JsonSerializable(nullable: true)
class BuildStatus {
  const BuildStatus({this.stages, this.checklist});

  factory BuildStatus.fromJson(Map<String, dynamic> json) =>
      _$BuildStatusFromJson(json);

  @JsonKey(name: 'Stages')
  final List<Stage> stages;

  @JsonKey(name: 'Checklist')
  final ChecklistEntity checklist;
}

@JsonSerializable(nullable: true)
class AgentStatus {
  const AgentStatus({
    this.agentId,
    this.isHealthy,
    this.healthCheckTimestamp,
    this.healthDetails,
  });

  factory AgentStatus.fromJson(Map<String, dynamic> json) =>
      _$AgentStatusFromJson(json);

  @JsonKey(name: 'AgentID')
  final String agentId;

  @JsonKey(name: 'IsHealthy', defaultValue: true)
  final bool isHealthy;

  @JsonKey(name: 'HealthCheckTimestamp', fromJson: fromMilliseconds)
  final DateTime healthCheckTimestamp;

  @JsonKey(name: 'HealthDetails')
  final String healthDetails;
}

@JsonSerializable(nullable: true)
class CommitInfo {
  CommitInfo({this.sha, this.author});

  factory CommitInfo.fromJson(Map<String, dynamic> json) =>
      _$CommitInfoFromJson(json);

  @JsonKey(name: 'Sha')
  final String sha;

  @JsonKey(name: 'Author')
  final AuthorInfo author;
}

@JsonSerializable(nullable: true)
class AuthorInfo extends _$AuthorInfoSerializerMixin {
  AuthorInfo({this.login, this.avatarUrl});

  factory AuthorInfo.fromJson(Map<String, dynamic> json) =>
      _$AuthorInfoFromJson(json);

  @JsonKey(name: 'Login')
  @override
  final String login;

  @JsonKey(name: 'avatar_url')
  @override
  final String avatarUrl;
}

@JsonSerializable(nullable: true)
class ChecklistEntity {
  const ChecklistEntity({this.key, this.checklist});

  factory ChecklistEntity.fromJson(Map<String, dynamic> json) =>
      _$ChecklistEntityFromJson(json);

  @JsonKey(name: 'Key')
  final String key;

  @JsonKey(name: 'Checklist')
  final Checklist checklist;
}

@JsonSerializable(nullable: true)
class Checklist {
  const Checklist({
    this.flutterRepositoryPath,
    this.commit,
    this.createTimestamp,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) =>
      _$ChecklistFromJson(json);

  @JsonKey(name: 'FlutterRepositoryPath')
  final String flutterRepositoryPath;

  @JsonKey(name: 'Commit')
  final CommitInfo commit;

  @JsonKey(name: 'CreateTimestamp', fromJson: fromMilliseconds)
  final DateTime createTimestamp;
}

@JsonSerializable(nullable: true)
class Stage {
  const Stage({this.name, this.tasks});

  factory Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);

  @JsonKey(name: 'Name')
  final String name;

  @JsonKey(name: 'Tasks')
  final List<TaskEntity> tasks;
}

@JsonSerializable(nullable: true)
class TaskEntity {
  const TaskEntity({this.key, this.task});

  factory TaskEntity.fromJson(Map<String, dynamic> json) =>
      _$TaskEntityFromJson(json);

  @JsonKey(name: 'Key')
  final String key;

  @JsonKey(name: 'Task')
  final Task task;
}

@JsonSerializable(nullable: true)
class Task {
  Task({
    this.checklistKey,
    this.stageName,
    this.name,
    this.status,
    this.startTimestamp,
    this.endTimestamp,
    this.attempts,
    this.isFlaky,
    this.host,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  @JsonKey(name: 'ChecklistKey')
  final String checklistKey;

  @JsonKey(name: 'StageName')
  final String stageName;

  @JsonKey(name: 'Name')
  final String name;

  @JsonKey(name: 'Status')
  final String status;

  @JsonKey(name: 'StartTimestamp', fromJson: fromMilliseconds)
  final DateTime startTimestamp;

  @JsonKey(name: 'EndTimestamp', fromJson: fromMilliseconds)
  final DateTime endTimestamp;

  @JsonKey(name: 'Attempts')
  final int attempts;

  @JsonKey(name: 'Flaky')
  final bool isFlaky;

  @JsonKey(name: 'ReservedForAgentID')
  final String host;
}

@JsonSerializable(nullable: true)
class GetBenchmarksResult {
  const GetBenchmarksResult({this.benchmarks});

  factory GetBenchmarksResult.fromJson(Map<String, dynamic> json) =>
      _$GetBenchmarksResultFromJson(json);

  @JsonKey(name: 'Benchmarks')
  final List<BenchmarkData> benchmarks;
}

@JsonSerializable(nullable: true)
class BenchmarkData {
  const BenchmarkData({this.timeseries, this.values});

  factory BenchmarkData.fromJson(Map<String, dynamic> json) =>
      _$BenchmarkDataFromJson(json);

  @JsonKey(name: 'Timeseries')
  final TimeseriesEntity timeseries;

  @JsonKey(name: 'Values')
  final List<TimeseriesValue> values;
}

@JsonSerializable(nullable: true)
class GetTimeseriesHistoryResult {
  const GetTimeseriesHistoryResult({
    this.benchmarkData,
    this.lastPosition,
  });

  factory GetTimeseriesHistoryResult.fromJson(Map<String, dynamic> json) =>
      _$GetTimeseriesHistoryResultFromJson(json);

  @JsonKey(name: 'BenchmarkData')
  final BenchmarkData benchmarkData;

  @JsonKey(name: 'LastPosition', fromJson: fromCursor)
  final String lastPosition;
}

@JsonSerializable(nullable: true)
class TimeseriesEntity {
  const TimeseriesEntity({
    this.key,
    this.timeseries,
  });

  factory TimeseriesEntity.fromJson(Map<String, dynamic> json) =>
      _$TimeseriesEntityFromJson(json);

  @JsonKey(name: 'Key')
  final String key;

  @JsonKey(name: 'Timeseries')
  final Timeseries timeseries;
}

@JsonSerializable(nullable: true)
class Timeseries {
  const Timeseries({
    this.id,
    this.taskName,
    this.label,
    this.unit,
    this.goal,
    this.baseline,
    this.isArchived,
  });

  factory Timeseries.fromJson(Map<String, dynamic> json) =>
      _$TimeseriesFromJson(json);

  @JsonKey(name: 'ID')
  final String id;

  @JsonKey(name: 'TaskName')
  final String taskName;

  @JsonKey(name: 'Label')
  final String label;

  @JsonKey(name: 'Unit')
  final String unit;

  @JsonKey(name: 'Goal')
  final double goal;

  @JsonKey(name: 'Baseline')
  final double baseline;

  @JsonKey(name: 'Archived')
  final bool isArchived;
}

@JsonSerializable(nullable: true)
class TimeseriesValue {
  const TimeseriesValue({
    this.createTimestamp,
    this.revision,
    this.value,
    this.isDataMissing,
  });

  factory TimeseriesValue.fromJson(Map<String, dynamic> json) =>
      _$TimeseriesValueFromJson(json);

  @JsonKey(name: 'CreateTimestamp')
  final int createTimestamp;

  @JsonKey(name: 'Revision')
  final String revision;

  @JsonKey(name: 'Value')
  final double value;

  @JsonKey(name: 'DataMissing', defaultValue: false)
  final bool isDataMissing;
}

/// Creates a [DateTime] object from milliseconds.
///
/// Used in a [JsonKey] annotation to deserialize a [DateTime] from an [int].
DateTime fromMilliseconds(int millisecondsSinceEpoch) {
  return new DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

/// Creates a string which represents a Cursor object
String fromCursor(Object value) {
  return value?.toString() ?? '';
}