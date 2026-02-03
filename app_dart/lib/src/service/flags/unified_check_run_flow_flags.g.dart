// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter, use_null_aware_elements

part of 'unified_check_run_flow_flags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedCheckRunFlow _$UnifiedCheckRunFlowFromJson(Map<String, dynamic> json) =>
    UnifiedCheckRunFlow(
      useForAll: json['useForAll'] as bool?,
      useForUsers: (json['useForUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UnifiedCheckRunFlowToJson(
  UnifiedCheckRunFlow instance,
) => <String, dynamic>{
  'useForAll': instance.useForAll,
  'useForUsers': instance.useForUsers,
};
