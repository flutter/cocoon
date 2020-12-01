// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
