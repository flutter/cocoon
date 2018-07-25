// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetStatusResult _$GetStatusResultFromJson(Map<String, dynamic> json) {
  return new GetStatusResult(
      statuses: (json['Statuses'] as List)
          ?.map((e) => e == null
              ? null
              : new BuildStatus.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      agentStatuses: (json['AgentStatuses'] as List)
          ?.map((e) => e == null
              ? null
              : new AgentStatus.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

abstract class _$GetStatusResultSerializerMixin {
  List<BuildStatus> get statuses;
  List<AgentStatus> get agentStatuses;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Statuses': statuses, 'AgentStatuses': agentStatuses};
}

BuildStatus _$BuildStatusFromJson(Map<String, dynamic> json) {
  return new BuildStatus(
      stages: (json['Stages'] as List)
          ?.map((e) =>
              e == null ? null : new Stage.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      checklist: json['Checklist'] == null
          ? null
          : new ChecklistEntity.fromJson(
              json['Checklist'] as Map<String, dynamic>));
}

abstract class _$BuildStatusSerializerMixin {
  List<Stage> get stages;
  ChecklistEntity get checklist;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Stages': stages, 'Checklist': checklist};
}

AgentStatus _$AgentStatusFromJson(Map<String, dynamic> json) {
  return new AgentStatus(
      agentId: json['AgentID'] as String,
      isHealthy: json['IsHealthy'] as bool ?? true,
      healthCheckTimestamp: json['HealthCheckTimestamp'] == null
          ? null
          : fromMilliseconds(json['HealthCheckTimestamp'] as int),
      healthDetails: json['HealthDetails'] as String);
}

abstract class _$AgentStatusSerializerMixin {
  String get agentId;
  bool get isHealthy;
  DateTime get healthCheckTimestamp;
  String get healthDetails;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'AgentID': agentId,
        'IsHealthy': isHealthy,
        'HealthCheckTimestamp': healthCheckTimestamp?.toIso8601String(),
        'HealthDetails': healthDetails
      };
}

CommitInfo _$CommitInfoFromJson(Map<String, dynamic> json) {
  return new CommitInfo(
      sha: json['Sha'] as String,
      author: json['Author'] == null
          ? null
          : new AuthorInfo.fromJson(json['Author'] as Map<String, dynamic>));
}

abstract class _$CommitInfoSerializerMixin {
  String get sha;
  AuthorInfo get author;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Sha': sha, 'Author': author};
}

AuthorInfo _$AuthorInfoFromJson(Map<String, dynamic> json) {
  return new AuthorInfo(
      login: json['Login'] as String, avatarUrl: json['avatar_url'] as String);
}

abstract class _$AuthorInfoSerializerMixin {
  String get login;
  String get avatarUrl;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Login': login, 'avatar_url': avatarUrl};
}

ChecklistEntity _$ChecklistEntityFromJson(Map<String, dynamic> json) {
  return new ChecklistEntity(
      key: json['Key'] as String,
      checklist: json['Checklist'] == null
          ? null
          : new Checklist.fromJson(json['Checklist'] as Map<String, dynamic>));
}

abstract class _$ChecklistEntitySerializerMixin {
  String get key;
  Checklist get checklist;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Key': key, 'Checklist': checklist};
}

Checklist _$ChecklistFromJson(Map<String, dynamic> json) {
  return new Checklist(
      flutterRepositoryPath: json['FlutterRepositoryPath'] as String,
      commit: json['Commit'] == null
          ? null
          : new CommitInfo.fromJson(json['Commit'] as Map<String, dynamic>),
      createTimestamp: json['CreateTimestamp'] == null
          ? null
          : fromMilliseconds(json['CreateTimestamp'] as int));
}

abstract class _$ChecklistSerializerMixin {
  String get flutterRepositoryPath;
  CommitInfo get commit;
  DateTime get createTimestamp;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'FlutterRepositoryPath': flutterRepositoryPath,
        'Commit': commit,
        'CreateTimestamp': createTimestamp?.toIso8601String()
      };
}

Stage _$StageFromJson(Map<String, dynamic> json) {
  return new Stage(
      name: json['Name'] as String,
      tasks: (json['Tasks'] as List)
          ?.map((e) => e == null
              ? null
              : new TaskEntity.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

abstract class _$StageSerializerMixin {
  String get name;
  List<TaskEntity> get tasks;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Name': name, 'Tasks': tasks};
}

TaskEntity _$TaskEntityFromJson(Map<String, dynamic> json) {
  return new TaskEntity(
      key: json['Key'] as String,
      task: json['Task'] == null
          ? null
          : new Task.fromJson(json['Task'] as Map<String, dynamic>));
}

abstract class _$TaskEntitySerializerMixin {
  String get key;
  Task get task;
  Map<String, dynamic> toJson() => <String, dynamic>{'Key': key, 'Task': task};
}

Task _$TaskFromJson(Map<String, dynamic> json) {
  return new Task(
      checklistKey: json['ChecklistKey'] as String,
      stageName: json['StageName'] as String,
      name: json['Name'] as String,
      status: json['Status'] as String,
      startTimestamp: json['StartTimestamp'] == null
          ? null
          : fromMilliseconds(json['StartTimestamp'] as int),
      endTimestamp: json['EndTimestamp'] == null
          ? null
          : fromMilliseconds(json['EndTimestamp'] as int),
      attempts: json['Attempts'] as int,
      isFlaky: json['Flaky'] as bool);
}

abstract class _$TaskSerializerMixin {
  String get checklistKey;
  String get stageName;
  String get name;
  String get status;
  DateTime get startTimestamp;
  DateTime get endTimestamp;
  int get attempts;
  bool get isFlaky;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ChecklistKey': checklistKey,
        'StageName': stageName,
        'Name': name,
        'Status': status,
        'StartTimestamp': startTimestamp?.toIso8601String(),
        'EndTimestamp': endTimestamp?.toIso8601String(),
        'Attempts': attempts,
        'Flaky': isFlaky
      };
}

GetBenchmarksResult _$GetBenchmarksResultFromJson(Map<String, dynamic> json) {
  return new GetBenchmarksResult(
      benchmarks: (json['Benchmarks'] as List)
          ?.map((e) => e == null
              ? null
              : new BenchmarkData.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

abstract class _$GetBenchmarksResultSerializerMixin {
  List<BenchmarkData> get benchmarks;
  Map<String, dynamic> toJson() => <String, dynamic>{'Benchmarks': benchmarks};
}

BenchmarkData _$BenchmarkDataFromJson(Map<String, dynamic> json) {
  return new BenchmarkData(
      timeseries: json['Timeseries'] == null
          ? null
          : new TimeseriesEntity.fromJson(
              json['Timeseries'] as Map<String, dynamic>),
      values: (json['Values'] as List)
          ?.map((e) => e == null
              ? null
              : new TimeseriesValue.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

abstract class _$BenchmarkDataSerializerMixin {
  TimeseriesEntity get timeseries;
  List<TimeseriesValue> get values;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Timeseries': timeseries, 'Values': values};
}

GetTimeseriesHistoryResult _$GetTimeseriesHistoryResultFromJson(
    Map<String, dynamic> json) {
  return new GetTimeseriesHistoryResult(
      benchmarkData: json['BenchmarkData'] == null
          ? null
          : new BenchmarkData.fromJson(
              json['BenchmarkData'] as Map<String, dynamic>),
      lastPosition: json['LastPosition'] as String);
}

abstract class _$GetTimeseriesHistoryResultSerializerMixin {
  BenchmarkData get benchmarkData;
  String get lastPosition;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'BenchmarkData': benchmarkData,
        'LastPosition': lastPosition
      };
}

TimeseriesEntity _$TimeseriesEntityFromJson(Map<String, dynamic> json) {
  return new TimeseriesEntity(
      key: json['Key'] as String,
      timeseries: json['Timeseries'] == null
          ? null
          : new Timeseries.fromJson(
              json['Timeseries'] as Map<String, dynamic>));
}

abstract class _$TimeseriesEntitySerializerMixin {
  String get key;
  Timeseries get timeseries;
  Map<String, dynamic> toJson() =>
      <String, dynamic>{'Key': key, 'Timeseries': timeseries};
}

Timeseries _$TimeseriesFromJson(Map<String, dynamic> json) {
  return new Timeseries(
      id: json['ID'] as String,
      taskName: json['TaskName'] as String,
      label: json['Label'] as String,
      unit: json['Unit'] as String,
      goal: (json['Goal'] as num)?.toDouble(),
      baseline: (json['Baseline'] as num)?.toDouble(),
      isArchived: json['Archived'] as bool);
}

abstract class _$TimeseriesSerializerMixin {
  String get id;
  String get taskName;
  String get label;
  String get unit;
  double get goal;
  double get baseline;
  bool get isArchived;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ID': id,
        'TaskName': taskName,
        'Label': label,
        'Unit': unit,
        'Goal': goal,
        'Baseline': baseline,
        'Archived': isArchived
      };
}

TimeseriesValue _$TimeseriesValueFromJson(Map<String, dynamic> json) {
  return new TimeseriesValue(
      createTimestamp: json['CreateTimestamp'] as int,
      revision: json['Revision'] as String,
      value: (json['Value'] as num)?.toDouble(),
      isDataMissing: json['DataMissing'] as bool ?? false);
}

abstract class _$TimeseriesValueSerializerMixin {
  int get createTimestamp;
  String get revision;
  double get value;
  bool get isDataMissing;
  Map<String, dynamic> toJson() => <String, dynamic>{
        'CreateTimestamp': createTimestamp,
        'Revision': revision,
        'Value': value,
        'DataMissing': isDataMissing
      };
}
