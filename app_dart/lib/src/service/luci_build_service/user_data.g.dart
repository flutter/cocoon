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
          checkRunId: $checkedConvert(
            'check_run_id',
            (v) => (v as num).toInt(),
          ),
          repoOwner: $checkedConvert('repo_owner', (v) => v as String),
          repoName: $checkedConvert('repo_name', (v) => v as String),
          builderName: $checkedConvert('builder_name', (v) => v as String),
          commitSha: $checkedConvert('commit_sha', (v) => v as String),
          commitBranch: $checkedConvert('commit_branch', (v) => v as String),
          userAgent: $checkedConvert('user_agent', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'checkRunId': 'check_run_id',
        'repoOwner': 'repo_owner',
        'repoName': 'repo_name',
        'builderName': 'builder_name',
        'commitSha': 'commit_sha',
        'commitBranch': 'commit_branch',
        'userAgent': 'user_agent',
      },
    );

Map<String, dynamic> _$PresubmitUserDataToJson(PresubmitUserData instance) =>
    <String, dynamic>{
      'repo_owner': instance.repoOwner,
      'repo_name': instance.repoName,
      'check_run_id': instance.checkRunId,
      'builder_name': instance.builderName,
      'commit_sha': instance.commitSha,
      'commit_branch': instance.commitBranch,
      'user_agent': instance.userAgent,
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
          repoName: $checkedConvert('repo_name', (v) => v as String),
          repoOwner: $checkedConvert('repo_owner', (v) => v as String),
          taskKey: $checkedConvert('task_key', (v) => v as String),
          commitKey: $checkedConvert('commit_key', (v) => v as String),
          firestoreTaskDocumentName: $checkedConvert(
            'firestore_task_document_name',
            (v) => FirestoreTaskDocumentName._parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'checkRunId': 'check_run_id',
        'repoName': 'repo_name',
        'repoOwner': 'repo_owner',
        'taskKey': 'task_key',
        'commitKey': 'commit_key',
        'firestoreTaskDocumentName': 'firestore_task_document_name',
      },
    );

Map<String, dynamic> _$PostsubmitUserDataToJson(PostsubmitUserData instance) =>
    <String, dynamic>{
      'repo_owner': instance.repoOwner,
      'repo_name': instance.repoName,
      if (instance.checkRunId case final value?) 'check_run_id': value,
      'task_key': instance.taskKey,
      'commit_key': instance.commitKey,
      if (FirestoreTaskDocumentName._toJson(instance.firestoreTaskDocumentName)
          case final value?)
        'firestore_task_document_name': value,
    };
