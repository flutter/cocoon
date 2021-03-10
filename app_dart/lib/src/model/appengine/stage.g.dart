// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'stage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Stage _$StageFromJson(Map<String, dynamic> json) {
  return Stage(
    name: json['Name'] as String,
    tasks: (json['Tasks'] as List)
        ?.map(
            (e) => e == null ? null : Task.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    taskStatus: json['Status'] as String,
  );
}

Map<String, dynamic> _$StageToJson(Stage instance) => <String, dynamic>{
      'Name': instance.name,
      'Tasks': instance.tasks,
      'Status': instance.taskStatus,
    };
