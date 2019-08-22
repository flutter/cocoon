// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSeries _$TimeSeriesFromJson(Map<String, dynamic> json) {
  return TimeSeries(
    archived: json['Archived'] as bool,
    baseline: (json['Baseline'] as num)?.toDouble(),
    goal: (json['Goal'] as num)?.toDouble(),
    timeSeriesId: json['ID'] as String,
    label: json['Label'] as String,
    taskName: json['TaskName'] as String,
    unit: json['Unit'] as String,
  );
}

Map<String, dynamic> _$TimeSeriesToJson(TimeSeries instance) =>
    <String, dynamic>{
      'Archived': instance.archived,
      'Baseline': instance.baseline,
      'Goal': instance.goal,
      'ID': instance.timeSeriesId,
      'Label': instance.label,
      'TaskName': instance.taskName,
      'Unit': instance.unit,
    };

Map<String, dynamic> _$TimeSeriesWrapperToJson(TimeSeriesWrapper instance) =>
    <String, dynamic>{
      'Timeseries': instance.series,
      'Key': const KeyConverter().toJson(instance.key),
    };
