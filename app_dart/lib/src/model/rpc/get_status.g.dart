// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'get_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GetStatusResponse _$GetStatusResponseFromJson(Map<String, dynamic> json) {
  return GetStatusResponse(
    agents: (json['agents'] as List)
        ?.map(
            (e) => e == null ? null : Agent.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    statuses: (json['statuses'] as List)
        ?.map((e) =>
            e == null ? null : CommitStatus.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$GetStatusResponseToJson(GetStatusResponse instance) =>
    <String, dynamic>{
      'agents': instance.agents,
      'statuses': instance.statuses,
    };
