// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'checks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckRunEvent _$CheckRunEventFromJson(Map<String, dynamic> json) =>
    CheckRunEvent(
      action: json['action'] as String?,
      checkRun:
          json['check_run'] == null
              ? null
              : CheckRun.fromJson(json['check_run'] as Map<String, dynamic>),
      sender:
          json['sender'] == null
              ? null
              : User.fromJson(json['sender'] as Map<String, dynamic>),
      repository:
          json['repository'] == null
              ? null
              : Repository.fromJson(json['repository'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CheckRunEventToJson(CheckRunEvent instance) =>
    <String, dynamic>{
      'check_run': instance.checkRun,
      'action': instance.action,
      'sender': instance.sender,
      'repository': instance.repository,
    };

CheckRun _$CheckRunFromJson(Map<String, dynamic> json) => CheckRun(
  conclusion: json['conclusion'] as String?,
  headSha: json['head_sha'] as String?,
  id: (json['id'] as num?)?.toInt(),
  pullRequests:
      (json['pull_requests'] as List<dynamic>?)
          ?.map((e) => PullRequest.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  name: json['name'] as String?,
  checkSuite:
      json['check_suite'] == null
          ? null
          : CheckSuite.fromJson(json['check_suite'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CheckRunToJson(CheckRun instance) => <String, dynamic>{
  'id': instance.id,
  'head_sha': instance.headSha,
  'conclusion': instance.conclusion,
  'name': instance.name,
  'check_suite': instance.checkSuite,
  'pull_requests': instance.pullRequests,
};

MergeGroupEvent _$MergeGroupEventFromJson(Map<String, dynamic> json) =>
    MergeGroupEvent(
      action: json['action'] as String,
      mergeGroup: MergeGroup.fromJson(
        json['merge_group'] as Map<String, dynamic>,
      ),
      reason: json['reason'] as String?,
      repository:
          json['repository'] == null
              ? null
              : Repository.fromJson(json['repository'] as Map<String, dynamic>),
      sender:
          json['sender'] == null
              ? null
              : User.fromJson(json['sender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MergeGroupEventToJson(MergeGroupEvent instance) =>
    <String, dynamic>{
      'action': instance.action,
      'reason': instance.reason,
      'merge_group': instance.mergeGroup,
      'repository': instance.repository,
      'sender': instance.sender,
    };

MergeGroup _$MergeGroupFromJson(Map<String, dynamic> json) => MergeGroup(
  headSha: json['head_sha'] as String,
  headRef: json['head_ref'] as String,
  baseSha: json['base_sha'] as String,
  baseRef: json['base_ref'] as String,
  headCommit: HeadCommit.fromJson(json['head_commit'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MergeGroupToJson(MergeGroup instance) =>
    <String, dynamic>{
      'head_sha': instance.headSha,
      'head_ref': instance.headRef,
      'base_sha': instance.baseSha,
      'base_ref': instance.baseRef,
      'head_commit': instance.headCommit,
    };

HeadCommit _$HeadCommitFromJson(Map<String, dynamic> json) => HeadCommit(
  id: json['id'] as String,
  treeId: json['tree_id'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$HeadCommitToJson(HeadCommit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tree_id': instance.treeId,
      'message': instance.message,
    };
