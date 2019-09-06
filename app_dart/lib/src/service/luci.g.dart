// ignore_for_file: specify_type_annotations
// GENERATED CODE - DO NOT MODIFY BY HAND

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
    taskName: json['taskName'] as String,
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
  val['taskName'] = instance.taskName;
  return val;
}
