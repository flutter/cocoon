// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merge_group_hooks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MergeGroupHooks _$MergeGroupHooksFromJson(Map<String, dynamic> json) =>
    MergeGroupHooks(
      hooks: (json['hooks'] as List<dynamic>)
          .map((e) => MergeGroupHook.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MergeGroupHooksToJson(MergeGroupHooks instance) =>
    <String, dynamic>{'hooks': instance.hooks};

MergeGroupHook _$MergeGroupHookFromJson(Map<String, dynamic> json) =>
    MergeGroupHook(
      id: json['id'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      action: json['action'] as String,
      headRef: json['head_ref'] as String?,
      headCommitId: json['head_commit_id'] as String?,
      headCommitMessage: json['head_commit_message'] as String?,
    );

Map<String, dynamic> _$MergeGroupHookToJson(MergeGroupHook instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp,
      'action': instance.action,
      'head_ref': ?instance.headRef,
      'head_commit_id': ?instance.headCommitId,
      'head_commit_message': ?instance.headCommitMessage,
    };
