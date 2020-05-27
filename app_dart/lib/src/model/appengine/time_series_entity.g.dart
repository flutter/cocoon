// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'time_series_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeseriesEntity _$TimeseriesEntityFromJson(Map<String, dynamic> json) {
  return TimeseriesEntity(
    timeSeries: json['Timeseries'] == null
        ? null
        : TimeSeries.fromJson(json['Timeseries'] as Map<String, dynamic>),
    key: json['Key'] as String,
  );
}

Map<String, dynamic> _$TimeseriesEntityToJson(TimeseriesEntity instance) =>
    <String, dynamic>{
      'Timeseries': instance.timeSeries,
      'Key': instance.key,
    };
