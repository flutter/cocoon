// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'benchmark_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BenchmarkData _$BenchmarkDataFromJson(Map<String, dynamic> json) {
  return BenchmarkData(
    timeSeriesEntity: json['TimeSeries'] == null
        ? null
        : TimeseriesEntity.fromJson(json['TimeSeries']),
    values: (json['Values'])
        ?.map((Map<String, dynamic> e) => e == null
            ? null
            : TimeSeriesValue.fromJson(e))
        ?.toList(),
  );
}

Map<String, dynamic> _$BenchmarkDataToJson(BenchmarkData instance) =>
    <String, dynamic>{
      'Timeseries': instance.timeSeriesEntity,
      'Values': instance.values,
    };
