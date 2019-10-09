// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeseriesEntity _$TimeseriesEntityFromJson(Map<String, dynamic> json) {
  return TimeseriesEntity(
    timeSeries: json['TimeSeries'] == null
        ? null
        : TimeSeries.fromJson(json['TimeSeries'])
  );
}

Map<String, dynamic> _$TimeseriesEntityToJson(TimeseriesEntity instance) =>
    <String, dynamic>{
      'Timeseries': instance.timeSeries,
      'Key': instance.key,
    };
