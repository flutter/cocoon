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
