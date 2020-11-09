// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'override_github_build_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OverrideGitHubBuildStatusRequest _$OverrideGitHubBuildStatusRequestFromJson(
    Map<String, dynamic> json) {
  return OverrideGitHubBuildStatusRequest(
    repository: json['repository'] as String,
    closed: json['closed'] as bool,
    reason: json['reason'] as String,
  );
}

Map<String, dynamic> _$OverrideGitHubBuildStatusRequestToJson(
        OverrideGitHubBuildStatusRequest instance) =>
    <String, dynamic>{
      'repository': instance.repository,
      'closed': instance.closed,
      'reason': instance.reason,
    };

TreeOverrideStatusRow _$TreeOverrideStatusRowFromJson(
    Map<String, dynamic> json) {
  return TreeOverrideStatusRow(
    repository: json['repository'] as String,
    user: json['user'] as String,
    reason: json['reason'] as String,
    closed: json['closed'] as bool,
    timestamp: json['timestamp'] as int,
  );
}

Map<String, dynamic> _$TreeOverrideStatusRowToJson(
        TreeOverrideStatusRow instance) =>
    <String, dynamic>{
      'repository': instance.repository,
      'user': instance.user,
      'reason': instance.reason,
      'closed': instance.closed,
      'timestamp': instance.timestamp,
    };
