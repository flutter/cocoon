// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'big_query_pull_request_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullRequestRecord _$PullRequestRecordFromJson(Map<String, dynamic> json) => PullRequestRecord(
      prCreatedTimestamp: json['pr_created_timestamp'] as int?,
      prLandedTimestamp: json['pr_landed_timestamp'] as int?,
      organization: json['organization'] as String?,
      repository: json['repository'] as String?,
      author: json['author'] as String?,
      prNumber: json['pr_number'] as int?,
      prCommit: json['pr_commit'] as String?,
      prRequestType: json['pr_request_type'] as String?,
    );

Map<String, dynamic> _$PullRequestRecordToJson(PullRequestRecord instance) => <String, dynamic>{
      'pr_created_timestamp': instance.prCreatedTimestamp,
      'pr_landed_timestamp': instance.prLandedTimestamp,
      'organization': instance.organization,
      'repository': instance.repository,
      'author': instance.author,
      'pr_number': instance.prNumber,
      'pr_commit': instance.prCommit,
      'pr_request_type': instance.prRequestType,
    };
