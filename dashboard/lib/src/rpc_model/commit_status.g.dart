// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitStatus _$CommitStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CommitStatus',
      json,
      ($checkedConvert) {
        final val = CommitStatus(
          commit: $checkedConvert('commit',
              (v) => CommitStatus._commitFromJson(v as Map<String, Object?>)),
          tasks: $checkedConvert(
              'tasks', (v) => CommitStatus._tasksFromJson(v as List)),
          branch: $checkedConvert('branch', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$CommitStatusToJson(CommitStatus instance) =>
    <String, dynamic>{
      'commit': CommitStatus._commitToJson(instance.commit),
      'tasks': CommitStatus._tasksToJson(instance.tasks),
      'branch': instance.branch,
    };
