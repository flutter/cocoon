// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'pull_request_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullRequestReviewEvent _$PullRequestReviewEventFromJson(
  Map<String, dynamic> json,
) => PullRequestReviewEvent(
  action: json['action'] as String?,
  review: json['review'] == null
      ? null
      : PullRequestReview.fromJson(json['review'] as Map<String, dynamic>),
  pullRequest: json['pull_request'] == null
      ? null
      : PullRequest.fromJson(json['pull_request'] as Map<String, dynamic>),
  repository: json['repository'] == null
      ? null
      : Repository.fromJson(json['repository'] as Map<String, dynamic>),
  sender: json['sender'] == null
      ? null
      : User.fromJson(json['sender'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PullRequestReviewEventToJson(
  PullRequestReviewEvent instance,
) => <String, dynamic>{
  'action': instance.action,
  'review': instance.review,
  'pull_request': instance.pullRequest,
  'repository': instance.repository,
  'sender': instance.sender,
};
