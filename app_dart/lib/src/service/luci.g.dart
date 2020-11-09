// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'luci.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LuciBuilder _$LuciBuilderFromJson(Map<String, dynamic> json) {
  $checkKeys(json,
      requiredKeys: const ['name', 'repo'],
      disallowNullValues: const ['name', 'repo']);
  return LuciBuilder(
    name: json['name'] as String,
    repo: json['repo'] as String,
    flaky: json['flaky'] as bool,
    enabled: json['enabled'] as bool,
    runIf: (json['run_if'] as List)?.map((e) => e as String)?.toList(),
    taskName: json['task_name'] as String,
  );
}

Map<String, dynamic> _$LuciBuilderToJson(LuciBuilder instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  writeNotNull('repo', instance.repo);
  val['flaky'] = instance.flaky;
  val['enabled'] = instance.enabled;
  val['run_if'] = instance.runIf;
  val['task_name'] = instance.taskName;
  return val;
}
