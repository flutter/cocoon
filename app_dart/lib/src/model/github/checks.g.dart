// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'checks.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckSuiteEvent _$CheckSuiteEventFromJson(Map<String, dynamic> json) {
  return CheckSuiteEvent(
    action: json['action'] as String,
    checkSuite: json['check_suite'] == null ? null : CheckSuite.fromJson(json['check_suite'] as Map<String, dynamic>),
    sender: json['sender'] == null ? null : User.fromJson(json['sender'] as Map<String, dynamic>),
    repository: json['repository'] == null ? null : Repository.fromJson(json['repository'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CheckSuiteEventToJson(CheckSuiteEvent instance) => <String, dynamic>{
      'check_suite': instance.checkSuite,
      'action': instance.action,
      'sender': instance.sender,
      'repository': instance.repository,
    };

CheckSuite _$CheckSuiteFromJson(Map<String, dynamic> json) {
  return CheckSuite(
    conclusion: json['conclusion'] as String,
    headSha: json['head_sha'] as String,
    id: json['id'] as int,
    pullRequests: (json['pull_requests'] as List)
            ?.map((e) => e == null ? null : PullRequest.fromJson(e as Map<String, dynamic>))
            ?.toList() ??
        [],
    headBranch: json['head_branch'] as String,
  );
}

Map<String, dynamic> _$CheckSuiteToJson(CheckSuite instance) => <String, dynamic>{
      'id': instance.id,
      'head_sha': instance.headSha,
      'conclusion': instance.conclusion,
      'head_branch': instance.headBranch,
      'pull_requests': instance.pullRequests,
    };

CheckRunEvent _$CheckRunEventFromJson(Map<String, dynamic> json) {
  return CheckRunEvent(
    action: json['action'] as String,
    checkRun: json['check_run'] == null ? null : CheckRun.fromJson(json['check_run'] as Map<String, dynamic>),
    sender: json['sender'] == null ? null : User.fromJson(json['sender'] as Map<String, dynamic>),
    repository: json['repository'] == null ? null : Repository.fromJson(json['repository'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CheckRunEventToJson(CheckRunEvent instance) => <String, dynamic>{
      'check_run': instance.checkRun,
      'action': instance.action,
      'sender': instance.sender,
      'repository': instance.repository,
    };

CheckRun _$CheckRunFromJson(Map<String, dynamic> json) {
  return CheckRun(
    conclusion: json['conclusion'] as String,
    headSha: json['head_sha'] as String,
    id: json['id'] as int,
    pullRequests: (json['pull_requests'] as List)
            ?.map((e) => e == null ? null : PullRequest.fromJson(e as Map<String, dynamic>))
            ?.toList() ??
        [],
    name: json['name'] as String,
    checkSuite: json['check_suite'] == null ? null : CheckSuite.fromJson(json['check_suite'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$CheckRunToJson(CheckRun instance) => <String, dynamic>{
      'id': instance.id,
      'head_sha': instance.headSha,
      'conclusion': instance.conclusion,
      'name': instance.name,
      'check_suite': instance.checkSuite,
      'pull_requests': instance.pullRequests,
    };
