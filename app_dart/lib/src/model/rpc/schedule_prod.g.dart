// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'schedule_prod.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleProdTasks _$ScheduleProdTasksFromJson(Map<String, dynamic> json) {
  return ScheduleProdTasks(
    commits: (json['commits'] as List)
        ?.map((e) =>
            e == null ? null : Commit.fromJson(e as Map<String, dynamic>))
        ?.toSet(),
  );
}

Map<String, dynamic> _$ScheduleProdTasksToJson(ScheduleProdTasks instance) =>
    <String, dynamic>{
      'commits': instance.commits?.toList(),
    };
