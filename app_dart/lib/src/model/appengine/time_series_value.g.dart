// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_series_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TimeSeriesValueToJson(TimeSeriesValue instance) =>
    <String, dynamic>{
      'DataMissing': instance.dataMissing,
      'Value': instance.value,
      'CreateTimestamp': instance.createTimestamp,
      'TaskKey': const KeyConverter().toJson(instance.taskKey),
      'Revision': instance.revision,
    };

TimeSeriesValue _$TimeSeriesValueFromJson(Map<String, dynamic> json) {
  return TimeSeriesValue(
    createTimestamp: json['CreateTimestamp'],
    revision: json['Revision'],
    value: (json['Value'])?.toDouble(),
    dataMissing: json['DataMissing'] ?? false,
  );
}