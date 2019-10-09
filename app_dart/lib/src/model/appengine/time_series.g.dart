// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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

Map<String, dynamic> _$SerializableTimeSeriesToJson(
        SerializableTimeSeries instance) =>
    <String, dynamic>{
      'Timeseries': instance.series,
      'Key': const KeyConverter().toJson(instance.key),
    };

TimeSeries _$TimeSeriesFromJson(Map<String, dynamic> json) {
  return TimeSeries(
    timeSeriesId: json['ID'],
    taskName: json['TaskName'],
    label: json['Label'],
    unit: json['Unit'],
    goal: (json['Goal'])?.toDouble(),
    baseline: (json['Baseline'])?.toDouble(),
    archived: json['Archived'],
  );
}