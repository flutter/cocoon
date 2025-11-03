// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'consolidated_check_run_flow_flags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConsolidatedCheckRunFlow _$ConsolidatedCheckRunFlowFromJson(
  Map<String, dynamic> json,
) => ConsolidatedCheckRunFlow(
  useForAll: json['useForAll'] as bool?,
  useForUsers: (json['useForUsers'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ConsolidatedCheckRunFlowToJson(
  ConsolidatedCheckRunFlow instance,
) => <String, dynamic>{
  'useForAll': instance.useForAll,
  'useForUsers': instance.useForUsers,
};
