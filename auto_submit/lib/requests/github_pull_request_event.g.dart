// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_pull_request_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GithubPullRequestEvent _$GithubPullRequestEventFromJson(Map<String, dynamic> json) => GithubPullRequestEvent(
      pullRequest:
          json['pull_request'] == null ? null : PullRequest.fromJson(json['pull_request'] as Map<String, dynamic>),
      action: json['action'] as String?,
      sender: json['sender'] == null ? null : User.fromJson(json['sender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GithubPullRequestEventToJson(GithubPullRequestEvent instance) => <String, dynamic>{
      'pull_request': instance.pullRequest,
      'action': instance.action,
      'sender': instance.sender,
    };
