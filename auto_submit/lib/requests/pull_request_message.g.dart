// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pull_request_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PullRequestMessage _$PullRequestMessageFromJson(Map<String, dynamic> json) =>
    PullRequestMessage(
      pullRequest: json['pull_request'] == null
          ? null
          : PullRequest.fromJson(json['pull_request'] as Map<String, dynamic>),
      action: json['action'] as String?,
      sender: json['sender'] as String?,
    );

Map<String, dynamic> _$PullRequestMessageToJson(PullRequestMessage instance) =>
    <String, dynamic>{
      'pull_request': instance.pullRequest,
      'action': instance.action,
      'sender': instance.sender,
    };
