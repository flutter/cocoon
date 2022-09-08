// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'big_query_revert_request_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevertRequestRecord _$RevertRequestRecordFromJson(Map<String, dynamic> json) => RevertRequestRecord(
      organization: json['organization'] as String?,
      repository: json['repository'] as String?,
      revertingPrAuthor: json['reverting_pr_author'] as String?,
      revertingPrNumber: json['reverting_pr_number'] as int?,
      revertingPrCommit: json['reverting_pr_commit'] as String?,
      revertingPrUrl: json['reverting_pr_url'] as String?,
      revertingPrCreatedTimestamp: json['reverting_pr_created_timestamp'] as int?,
      revertingPrLandedTimestamp: json['reverting_pr_landed_timestamp'] as int?,
      originalPrAuthor: json['original_pr_author'] as String?,
      originalPrNumber: json['original_pr_number'] as int?,
      originalPrCommit: json['original_pr_commit'] as String?,
      originalPrUrl: json['original_pr_url'] as String?,
      originalPrCreatedTimestamp: json['original_pr_created_timestamp'] as int?,
      originalPrLandedTimestamp: json['original_pr_landed_timestamp'] as int?,
    );

Map<String, dynamic> _$RevertRequestRecordToJson(RevertRequestRecord instance) => <String, dynamic>{
      'organization': instance.organization,
      'repository': instance.repository,
      'reverting_pr_author': instance.revertingPrAuthor,
      'reverting_pr_number': instance.revertingPrNumber,
      'reverting_pr_commit': instance.revertingPrCommit,
      'reverting_pr_url': instance.revertingPrUrl,
      'reverting_pr_created_timestamp': instance.revertingPrCreatedTimestamp,
      'reverting_pr_landed_timestamp': instance.revertingPrLandedTimestamp,
      'original_pr_author': instance.originalPrAuthor,
      'original_pr_number': instance.originalPrNumber,
      'original_pr_commit': instance.originalPrCommit,
      'original_pr_url': instance.originalPrUrl,
      'original_pr_created_timestamp': instance.originalPrCreatedTimestamp,
      'original_pr_landed_timestamp': instance.originalPrLandedTimestamp,
    };
