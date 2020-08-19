// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'benchmark_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BenchmarkData _$BenchmarkDataFromJson(Map<String, dynamic> json) {
  return BenchmarkData(
    timeSeriesEntity: json['Timeseries'] == null
        ? null
        : TimeseriesEntity.fromJson(json['Timeseries'] as Map<String, dynamic>),
    values: (json['Values'] as List)
        ?.map((e) => e == null
            ? null
            : TimeSeriesValue.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$BenchmarkDataToJson(BenchmarkData instance) =>
    <String, dynamic>{
      'Timeseries': instance.timeSeriesEntity,
      'Values': instance.values,
    };
