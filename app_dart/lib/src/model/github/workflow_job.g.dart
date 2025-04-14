// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'workflow_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkflowJobEvent _$WorkflowJobEventFromJson(Map<String, dynamic> json) =>
    WorkflowJobEvent(
      workflowJob:
          json['workflow_job'] == null
              ? null
              : WorkflowJob.fromJson(
                json['workflow_job'] as Map<String, dynamic>,
              ),
      action: json['action'] as String?,
      sender:
          json['sender'] == null
              ? null
              : User.fromJson(json['sender'] as Map<String, dynamic>),
      repository:
          json['repository'] == null
              ? null
              : Repository.fromJson(json['repository'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WorkflowJobEventToJson(WorkflowJobEvent instance) =>
    <String, dynamic>{
      'workflow_job': instance.workflowJob,
      'action': instance.action,
      'sender': instance.sender,
      'repository': instance.repository,
    };

WorkflowJob _$WorkflowJobFromJson(Map<String, dynamic> json) => WorkflowJob(
  id: (json['id'] as num?)?.toInt(),
  runId: (json['run_id'] as num?)?.toInt(),
  workflowName: json['workflow_name'] as String?,
  headBranch: json['head_branch'] as String?,
  runUrl: json['run_url'] as String?,
  runAttempt: (json['run_attempt'] as num?)?.toInt(),
  nodeId: json['node_id'] as String?,
  headSha: json['head_sha'] as String?,
  url: json['url'] as String?,
  status: json['status'] as String?,
  conclusion: json['conclusion'] as String?,
  name: json['name'] as String?,
  checkRunUrl: json['check_run_url'] as String?,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => Steps.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$WorkflowJobToJson(WorkflowJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'run_id': instance.runId,
      'workflow_name': instance.workflowName,
      'head_branch': instance.headBranch,
      'run_url': instance.runUrl,
      'run_attempt': instance.runAttempt,
      'node_id': instance.nodeId,
      'head_sha': instance.headSha,
      'url': instance.url,
      'status': instance.status,
      'conclusion': instance.conclusion,
      'name': instance.name,
      'check_run_url': instance.checkRunUrl,
      'steps': instance.steps,
    };

Steps _$StepsFromJson(Map<String, dynamic> json) => Steps(
  name: json['name'] as String?,
  status: json['status'] as String?,
  conclusion: json['conclusion'] as String?,
  number: (json['number'] as num?)?.toInt(),
);

Map<String, dynamic> _$StepsToJson(Steps instance) => <String, dynamic>{
  'name': instance.name,
  'status': instance.status,
  'conclusion': instance.conclusion,
  'number': instance.number,
};
