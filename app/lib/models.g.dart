// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetStatusResult _$GetStatusResultFromJson(Map<String, dynamic> json) {
  return GetStatusResult(
    statuses: (json['Statuses'] as List)
        ?.map((e) => e == null ? null : BuildStatus.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    agentStatuses: (json['AgentStatuses'] as List)
        ?.map((e) => e == null ? null : AgentStatus.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$GetStatusResultToJson(GetStatusResult instance) => <String, dynamic>{
      'Statuses': instance.statuses,
      'AgentStatuses': instance.agentStatuses,
    };

BuildStatus _$BuildStatusFromJson(Map<String, dynamic> json) {
  return BuildStatus(
    stages:
        (json['Stages'] as List)?.map((e) => e == null ? null : Stage.fromJson(e as Map<String, dynamic>))?.toList(),
    checklist: json['Checklist'] == null ? null : ChecklistEntity.fromJson(json['Checklist'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$BuildStatusToJson(BuildStatus instance) => <String, dynamic>{
      'Stages': instance.stages,
      'Checklist': instance.checklist,
    };

AgentStatus _$AgentStatusFromJson(Map<String, dynamic> json) {
  return AgentStatus(
    agentId: json['AgentID'] as String,
    isHealthy: json['IsHealthy'] as bool ?? true,
    healthCheckTimestamp: fromMilliseconds(json['HealthCheckTimestamp'] as int),
    healthDetails: json['HealthDetails'] as String,
  );
}

Map<String, dynamic> _$AgentStatusToJson(AgentStatus instance) => <String, dynamic>{
      'AgentID': instance.agentId,
      'IsHealthy': instance.isHealthy,
      'HealthCheckTimestamp': instance.healthCheckTimestamp?.toIso8601String(),
      'HealthDetails': instance.healthDetails,
    };

CommitInfo _$CommitInfoFromJson(Map<String, dynamic> json) {
  return CommitInfo(
    sha: json['Sha'] as String,
    author: json['Author'] == null ? null : AuthorInfo.fromJson(json['Author'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CommitInfoToJson(CommitInfo instance) => <String, dynamic>{
      'Sha': instance.sha,
      'Author': instance.author,
    };

AuthorInfo _$AuthorInfoFromJson(Map<String, dynamic> json) {
  return AuthorInfo(
    login: json['Login'] as String,
    avatarUrl: json['avatar_url'] as String,
  );
}

Map<String, dynamic> _$AuthorInfoToJson(AuthorInfo instance) => <String, dynamic>{
      'Login': instance.login,
      'avatar_url': instance.avatarUrl,
    };

ChecklistEntity _$ChecklistEntityFromJson(Map<String, dynamic> json) {
  return ChecklistEntity(
    key: json['Key'] as String,
    checklist: json['Checklist'] == null ? null : Checklist.fromJson(json['Checklist'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ChecklistEntityToJson(ChecklistEntity instance) => <String, dynamic>{
      'Key': instance.key,
      'Checklist': instance.checklist,
    };

Checklist _$ChecklistFromJson(Map<String, dynamic> json) {
  return Checklist(
    flutterRepositoryPath: json['FlutterRepositoryPath'] as String,
    commit: json['Commit'] == null ? null : CommitInfo.fromJson(json['Commit'] as Map<String, dynamic>),
    createTimestamp: fromMilliseconds(json['CreateTimestamp'] as int),
  );
}

Map<String, dynamic> _$ChecklistToJson(Checklist instance) => <String, dynamic>{
      'FlutterRepositoryPath': instance.flutterRepositoryPath,
      'Commit': instance.commit,
      'CreateTimestamp': instance.createTimestamp?.toIso8601String(),
    };

Stage _$StageFromJson(Map<String, dynamic> json) {
  return Stage(
    name: json['Name'] as String,
    tasks: (json['Tasks'] as List)
        ?.map((e) => e == null ? null : TaskEntity.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$StageToJson(Stage instance) => <String, dynamic>{
      'Name': instance.name,
      'Tasks': instance.tasks,
    };

TaskEntity _$TaskEntityFromJson(Map<String, dynamic> json) {
  return TaskEntity(
    key: json['Key'] as String,
    task: json['Task'] == null ? null : Task.fromJson(json['Task'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TaskEntityToJson(TaskEntity instance) => <String, dynamic>{
      'Key': instance.key,
      'Task': instance.task,
    };

Task _$TaskFromJson(Map<String, dynamic> json) {
  return Task(
    checklistKey: json['ChecklistKey'] as String,
    stageName: json['StageName'] as String,
    name: json['Name'] as String,
    status: json['Status'] as String,
    startTimestamp: fromMilliseconds(json['StartTimestamp'] as int),
    endTimestamp: fromMilliseconds(json['EndTimestamp'] as int),
    attempts: json['Attempts'] as int,
    isFlaky: json['Flaky'] as bool,
    host: json['ReservedForAgentID'] as String,
  );
}

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'ChecklistKey': instance.checklistKey,
      'StageName': instance.stageName,
      'Name': instance.name,
      'Status': instance.status,
      'StartTimestamp': instance.startTimestamp?.toIso8601String(),
      'EndTimestamp': instance.endTimestamp?.toIso8601String(),
      'Attempts': instance.attempts,
      'Flaky': instance.isFlaky,
      'ReservedForAgentID': instance.host,
    };

GetBenchmarksResult _$GetBenchmarksResultFromJson(Map<String, dynamic> json) {
  return GetBenchmarksResult(
    benchmarks: (json['Benchmarks'] as List)
        ?.map((e) => e == null ? null : BenchmarkData.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$GetBenchmarksResultToJson(GetBenchmarksResult instance) => <String, dynamic>{
      'Benchmarks': instance.benchmarks,
    };

BenchmarkData _$BenchmarkDataFromJson(Map<String, dynamic> json) {
  return BenchmarkData(
    timeseries:
        json['Timeseries'] == null ? null : TimeseriesEntity.fromJson(json['Timeseries'] as Map<String, dynamic>),
    values: (json['Values'] as List)
        ?.map((e) => e == null ? null : TimeseriesValue.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$BenchmarkDataToJson(BenchmarkData instance) => <String, dynamic>{
      'Timeseries': instance.timeseries,
      'Values': instance.values,
    };

GetTimeseriesHistoryResult _$GetTimeseriesHistoryResultFromJson(Map<String, dynamic> json) {
  return GetTimeseriesHistoryResult(
    benchmarkData:
        json['BenchmarkData'] == null ? null : BenchmarkData.fromJson(json['BenchmarkData'] as Map<String, dynamic>),
    lastPosition: fromCursor(json['LastPosition']),
  );
}

Map<String, dynamic> _$GetTimeseriesHistoryResultToJson(GetTimeseriesHistoryResult instance) => <String, dynamic>{
      'BenchmarkData': instance.benchmarkData,
      'LastPosition': instance.lastPosition,
    };

TimeseriesEntity _$TimeseriesEntityFromJson(Map<String, dynamic> json) {
  return TimeseriesEntity(
    key: json['Key'] as String,
    timeseries: json['Timeseries'] == null ? null : Timeseries.fromJson(json['Timeseries'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$TimeseriesEntityToJson(TimeseriesEntity instance) => <String, dynamic>{
      'Key': instance.key,
      'Timeseries': instance.timeseries,
    };

Timeseries _$TimeseriesFromJson(Map<String, dynamic> json) {
  return Timeseries(
    id: json['ID'] as String,
    taskName: json['TaskName'] as String,
    label: json['Label'] as String,
    unit: json['Unit'] as String,
    goal: (json['Goal'] as num)?.toDouble(),
    baseline: (json['Baseline'] as num)?.toDouble(),
    isArchived: json['Archived'] as bool,
  );
}

Map<String, dynamic> _$TimeseriesToJson(Timeseries instance) => <String, dynamic>{
      'ID': instance.id,
      'TaskName': instance.taskName,
      'Label': instance.label,
      'Unit': instance.unit,
      'Goal': instance.goal,
      'Baseline': instance.baseline,
      'Archived': instance.isArchived,
    };

BranchList _$BranchListFromJson(Map<String, dynamic> json) {
  return BranchList(
    branches: (json['Branches'] as List)?.map((e) => e as String)?.toList(),
  );
}

Map<String, dynamic> _$BranchListToJson(BranchList instance) => <String, dynamic>{
      'Branches': instance.branches,
    };

TimeseriesValue _$TimeseriesValueFromJson(Map<String, dynamic> json) {
  return TimeseriesValue(
    createTimestamp: json['CreateTimestamp'] as int,
    revision: json['Revision'] as String,
    value: (json['Value'] as num)?.toDouble(),
    isDataMissing: json['DataMissing'] as bool ?? false,
  );
}

Map<String, dynamic> _$TimeseriesValueToJson(TimeseriesValue instance) => <String, dynamic>{
      'CreateTimestamp': instance.createTimestamp,
      'Revision': instance.revision,
      'Value': instance.value,
      'DataMissing': instance.isDataMissing,
    };
