// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_guard_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitGuardSummary _$PresubmitGuardSummaryFromJson(
  Map<String, dynamic> json,
) => PresubmitGuardSummary(
  commitSha: json['commit_sha'] as String,
  creationTime: (json['creation_time'] as num).toInt(),
  guardStatus: $enumDecode(_$GuardStatusEnumMap, json['guard_status']),
);

Map<String, dynamic> _$PresubmitGuardSummaryToJson(
  PresubmitGuardSummary instance,
) => <String, dynamic>{
  'commit_sha': instance.commitSha,
  'creation_time': instance.creationTime,
  'guard_status': instance.guardStatus,
};

const _$GuardStatusEnumMap = {
  GuardStatus.waitingForBackfill: 'New',
  GuardStatus.inProgress: 'In Progress',
  GuardStatus.failed: 'Failed',
  GuardStatus.succeeded: 'Succeeded',
};
