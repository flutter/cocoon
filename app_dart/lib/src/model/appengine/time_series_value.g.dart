// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'time_series_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TimeSeriesValue _$TimeSeriesValueFromJson(Map<String, dynamic> json) {
  return TimeSeriesValue(
    dataMissing: json['DataMissing'] as bool ?? false,
    value: (json['Value'] as num)?.toDouble(),
    createTimestamp: json['CreateTimestamp'] as int,
    taskKey: const KeyConverter().fromJson(json['TaskKey'] as String),
    revision: json['Revision'] as String,
  );
}

Map<String, dynamic> _$TimeSeriesValueToJson(TimeSeriesValue instance) => <String, dynamic>{
      'DataMissing': instance.dataMissing,
      'Value': instance.value,
      'CreateTimestamp': instance.createTimestamp,
      'TaskKey': const KeyConverter().toJson(instance.taskKey),
      'Revision': instance.revision,
    };
