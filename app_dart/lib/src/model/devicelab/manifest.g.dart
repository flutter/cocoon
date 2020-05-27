// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Manifest _$ManifestFromJson(Map json) {
  return Manifest(
    tasks: (json['tasks'] as Map)?.map(
      (k, e) => MapEntry(
          k as String, e == null ? null : ManifestTask.fromJson(e as Map)),
    ),
  );
}

Map<String, dynamic> _$ManifestToJson(Manifest instance) => <String, dynamic>{
      'tasks': instance.tasks,
    };

ManifestTask _$ManifestTaskFromJson(Map json) {
  $checkKeys(json,
      requiredKeys: const ['stage'], disallowNullValues: const ['stage']);
  return ManifestTask(
    description: json['description'] as String,
    stage: json['stage'] as String,
    requiredAgentCapabilities: (json['required_agent_capabilities'] as List)
            ?.map((e) => e as String)
            ?.toList() ??
        [],
    isFlaky: json['flaky'] as bool ?? false,
    timeoutInMinutes: json['timeout_in_minutes'] as int ?? 0,
  );
}

Map<String, dynamic> _$ManifestTaskToJson(ManifestTask instance) {
  final val = <String, dynamic>{
    'description': instance.description,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('stage', instance.stage);
  val['required_agent_capabilities'] = instance.requiredAgentCapabilities;
  val['flaky'] = instance.isFlaky;
  val['timeout_in_minutes'] = instance.timeoutInMinutes;
  return val;
}
