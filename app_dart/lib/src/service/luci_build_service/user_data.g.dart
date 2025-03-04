// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitUserData _$PresubmitUserDataFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PresubmitUserData',
      json,
      ($checkedConvert) {
        final val = PresubmitUserData(
          checkRunId: $checkedConvert('check_run_id', (v) => v as int),
          builderName: $checkedConvert('builder_name', (v) => v as String),
          commitSha: $checkedConvert('commit_sha', (v) => v as String),
          commitBranch: $checkedConvert('commit_branch', (v) => v as String),
          repoOwner: $checkedConvert('repo_owner', (v) => v as String),
          repoName: $checkedConvert('repo_name', (v) => v as String),
          userAgent: $checkedConvert('user_agent', (v) => v as String),
          firestoreTaskDocumentName:
              $checkedConvert('firestore_task_document_name', (v) => FirestoreTaskDocumentName._parse(v as String?)),
        );
        return val;
      },
      fieldKeyMap: const {
        'checkRunId': 'check_run_id',
        'builderName': 'builder_name',
        'commitSha': 'commit_sha',
        'commitBranch': 'commit_branch',
        'repoOwner': 'repo_owner',
        'repoName': 'repo_name',
        'userAgent': 'user_agent',
        'firestoreTaskDocumentName': 'firestore_task_document_name'
      },
    );

Map<String, dynamic> _$PresubmitUserDataToJson(PresubmitUserData instance) {
  final val = <String, dynamic>{
    'check_run_id': instance.checkRunId,
    'builder_name': instance.builderName,
    'commit_sha': instance.commitSha,
    'commit_branch': instance.commitBranch,
    'repo_owner': instance.repoOwner,
    'repo_name': instance.repoName,
    'user_agent': instance.userAgent,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('firestore_task_document_name', FirestoreTaskDocumentName._toJson(instance.firestoreTaskDocumentName));
  return val;
}
