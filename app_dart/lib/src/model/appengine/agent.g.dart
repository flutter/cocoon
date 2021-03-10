// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) {
  return Agent(
    agentId: json['AgentID'] as String,
    healthCheckTimestamp: json['HealthCheckTimestamp'] as int,
    isHealthy: json['IsHealthy'] as bool,
    capabilities:
        (json['Capabilities'] as List)?.map((e) => e as String)?.toList(),
    healthDetails: json['HealthDetails'] as String,
  );
}

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
      'AgentID': instance.agentId,
      'HealthCheckTimestamp': instance.healthCheckTimestamp,
      'IsHealthy': instance.isHealthy,
      'Capabilities': instance.capabilities,
      'HealthDetails': instance.healthDetails,
    };
