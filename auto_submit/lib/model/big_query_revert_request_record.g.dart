// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'big_query_revert_request_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RevertRequestRecord _$RevertRequestRecordFromJson(Map<String, dynamic> json) => RevertRequestRecord(
      organization: json['organization'] as String?,
      repository: json['repository'] as String?,
      author: json['author'] as String?,
      prNumber: json['pr_number'] as int?,
      prCommit: json['pr_commit'] as String?,
      prCreatedTimestamp:
          json['pr_created_timestamp'] == null ? null : DateTime.parse(json['pr_created_timestamp'] as String),
      prLandedTimestamp:
          json['pr_landed_timestamp'] == null ? null : DateTime.parse(json['pr_landed_timestamp'] as String),
      originalPrAuthor: json['original_pr_author'] as String?,
      originalPrNumber: json['original_pr_number'] as int?,
      originalPrCommit: json['original_pr_commit'] as String?,
      originalPrCreatedTimestamp: json['original_pr_created_timestamp'] == null
          ? null
          : DateTime.parse(json['original_pr_created_timestamp'] as String),
      originalPrLandedTimestamp: json['original_pr_landed_timestamp'] == null
          ? null
          : DateTime.parse(json['original_pr_landed_timestamp'] as String),
      reviewIssueAssignee: json['review_issue_assignee'] as String?,
      reviewIssueNumber: json['review_issue_number'] as int?,
      reviewIssueCreatedTimestamp: json['review_issue_created_timestamp'] == null
          ? null
          : DateTime.parse(json['review_issue_created_timestamp'] as String),
      reviewIssueLandedTimestamp: json['review_issue_landed_timestamp'] == null
          ? null
          : DateTime.parse(json['review_issue_landed_timestamp'] as String),
      reviewIssueClosedBy: json['review_issue_closed_by'] as String?,
    );

Map<String, dynamic> _$RevertRequestRecordToJson(RevertRequestRecord instance) => <String, dynamic>{
      'pr_created_timestamp': instance.prCreatedTimestamp?.toIso8601String(),
      'pr_landed_timestamp': instance.prLandedTimestamp?.toIso8601String(),
      'organization': instance.organization,
      'repository': instance.repository,
      'author': instance.author,
      'pr_number': instance.prNumber,
      'pr_commit': instance.prCommit,
      'original_pr_author': instance.originalPrAuthor,
      'original_pr_number': instance.originalPrNumber,
      'original_pr_commit': instance.originalPrCommit,
      'original_pr_created_timestamp': instance.originalPrCreatedTimestamp?.toIso8601String(),
      'original_pr_landed_timestamp': instance.originalPrLandedTimestamp?.toIso8601String(),
      'review_issue_assignee': instance.reviewIssueAssignee,
      'review_issue_number': instance.reviewIssueNumber,
      'review_issue_created_timestamp': instance.reviewIssueCreatedTimestamp?.toIso8601String(),
      'review_issue_landed_timestamp': instance.reviewIssueLandedTimestamp?.toIso8601String(),
      'review_issue_closed_by': instance.reviewIssueClosedBy,
    };
