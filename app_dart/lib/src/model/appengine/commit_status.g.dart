// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'commit_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitStatus _$CommitStatusFromJson(Map<String, dynamic> json) {
  return CommitStatus(
    commit: json['commit'] == null
        ? null
        : Commit.fromJson(json['commit'] as Map<String, dynamic>),
    stages: (json['stages'] as List)
        ?.map(
            (e) => e == null ? null : Stage.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$CommitStatusToJson(CommitStatus instance) =>
    <String, dynamic>{
      'commit': instance.commit,
      'stages': instance.stages,
    };
