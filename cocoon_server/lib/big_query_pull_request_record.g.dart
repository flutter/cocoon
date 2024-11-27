// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'big_query_pull_request_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullRequestRecord _$PullRequestRecordFromJson(Map<String, dynamic> json) => PullRequestRecord(
      prCreatedTimestamp:
          json['pr_created_timestamp'] == null ? null : DateTime.parse(json['pr_created_timestamp'] as String),
      prLandedTimestamp:
          json['pr_landed_timestamp'] == null ? null : DateTime.parse(json['pr_landed_timestamp'] as String),
      organization: json['organization'] as String?,
      repository: json['repository'] as String?,
      author: json['author'] as String?,
      prNumber: json['pr_number'] as int?,
      prCommit: json['pr_commit'] as String?,
      prRequestType: json['pr_request_type'] as String?,
    );

Map<String, dynamic> _$PullRequestRecordToJson(PullRequestRecord instance) => <String, dynamic>{
      'pr_created_timestamp': instance.prCreatedTimestamp?.toIso8601String(),
      'pr_landed_timestamp': instance.prLandedTimestamp?.toIso8601String(),
      'organization': instance.organization,
      'repository': instance.repository,
      'author': instance.author,
      'pr_number': instance.prNumber,
      'pr_commit': instance.prCommit,
      'pr_request_type': instance.prRequestType,
    };
