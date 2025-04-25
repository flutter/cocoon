// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitUserData _$PresubmitUserDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PresubmitUserData',
      json,
      ($checkedConvert) {
        final val = PresubmitUserData(
          repoOwner: $checkedConvert('repo_owner', (v) => v as String),
          repoName: $checkedConvert('repo_name', (v) => v as String),
          commitBranch: $checkedConvert('commit_branch', (v) => v as String),
          commitSha: $checkedConvert('commit_sha', (v) => v as String),
          checkRunId: $checkedConvert(
            'check_run_id',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'repoOwner': 'repo_owner',
        'repoName': 'repo_name',
        'commitBranch': 'commit_branch',
        'commitSha': 'commit_sha',
        'checkRunId': 'check_run_id',
      },
    );

Map<String, dynamic> _$PresubmitUserDataToJson(PresubmitUserData instance) =>
    <String, dynamic>{
      'repo_owner': instance.repoOwner,
      'repo_name': instance.repoName,
      'commit_branch': instance.commitBranch,
      'commit_sha': instance.commitSha,
      'check_run_id': instance.checkRunId,
    };

PostsubmitUserData _$PostsubmitUserDataFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PostsubmitUserData',
      json,
      ($checkedConvert) {
        final val = PostsubmitUserData(
          checkRunId: $checkedConvert(
            'check_run_id',
            (v) => (v as num?)?.toInt(),
          ),
          taskId: $checkedConvert('task_id', (v) => TaskId.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'checkRunId': 'check_run_id', 'taskId': 'task_id'},
    );

Map<String, dynamic> _$PostsubmitUserDataToJson(PostsubmitUserData instance) =>
    <String, dynamic>{
      if (instance.checkRunId case final value?) 'check_run_id': value,
      'task_id': PostsubmitUserData._documentToString(instance.taskId),
    };
