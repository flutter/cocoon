// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_guard.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitGuardResponse _$PresubmitGuardResponseFromJson(
  Map<String, dynamic> json,
) => PresubmitGuardResponse(
  prNum: (json['pr_num'] as num).toInt(),
  checkRunId: (json['check_run_id'] as num).toInt(),
  author: json['author'] as String,
  stages: (json['stages'] as List<dynamic>)
      .map((e) => PresubmitGuardStage.fromJson(e as Map<String, dynamic>))
      .toList(),
  guardStatus: $enumDecode(_$GuardStatusEnumMap, json['guard_status']),
);

Map<String, dynamic> _$PresubmitGuardResponseToJson(
  PresubmitGuardResponse instance,
) => <String, dynamic>{
  'pr_num': instance.prNum,
  'check_run_id': instance.checkRunId,
  'author': instance.author,
  'stages': instance.stages,
  'guard_status': instance.guardStatus,
};

const _$GuardStatusEnumMap = {
  GuardStatus.waitingForBackfill: 'New',
  GuardStatus.inProgress: 'In Progress',
  GuardStatus.failed: 'Failed',
  GuardStatus.succeeded: 'Succeeded',
};

PresubmitGuardStage _$PresubmitGuardStageFromJson(Map<String, dynamic> json) =>
    PresubmitGuardStage(
      name: json['name'] as String,
      createdAt: (json['created_at'] as num).toInt(),
      builds: (json['builds'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, $enumDecode(_$TaskStatusEnumMap, e)),
      ),
    );

Map<String, dynamic> _$PresubmitGuardStageToJson(
  PresubmitGuardStage instance,
) => <String, dynamic>{
  'name': instance.name,
  'created_at': instance.createdAt,
  'builds': instance.builds,
};

const _$TaskStatusEnumMap = {
  TaskStatus.cancelled: 'Cancelled',
  TaskStatus.waitingForBackfill: 'New',
  TaskStatus.inProgress: 'In Progress',
  TaskStatus.infraFailure: 'Infra Failure',
  TaskStatus.failed: 'Failed',
  TaskStatus.succeeded: 'Succeeded',
  TaskStatus.skipped: 'Skipped',
};
