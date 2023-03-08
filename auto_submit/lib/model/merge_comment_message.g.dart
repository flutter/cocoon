// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merge_comment_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MergeCommentMessage _$MergeCommentMessageFromJson(Map<String, dynamic> json) =>
    MergeCommentMessage(
      issue: json['issue'] == null
          ? null
          : Issue.fromJson(json['issue'] as Map<String, dynamic>),
      comment: json['comment'] == null
          ? null
          : IssueComment.fromJson(json['comment'] as Map<String, dynamic>),
      repository: json['repository'] == null
          ? null
          : Repository.fromJson(json['repository'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MergeCommentMessageToJson(
        MergeCommentMessage instance) =>
    <String, dynamic>{
      'issue': instance.issue,
      'comment': instance.comment,
      'repository': instance.repository,
    };
