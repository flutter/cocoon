// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_guards_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitGuardsResponse _$PresubmitGuardsResponseFromJson(
  Map<String, dynamic> json,
) => PresubmitGuardsResponse(
  guards: (json['guards'] as List<dynamic>)
      .map((e) => PresubmitGuardItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PresubmitGuardsResponseToJson(
  PresubmitGuardsResponse instance,
) => <String, dynamic>{'guards': instance.guards};

PresubmitGuardItem _$PresubmitGuardItemFromJson(Map<String, dynamic> json) =>
    PresubmitGuardItem(
      commitSha: json['commit_sha'] as String,
      creationTime: (json['creation_time'] as num).toInt(),
      guardStatus: $enumDecode(_$GuardStatusEnumMap, json['guard_status']),
    );

Map<String, dynamic> _$PresubmitGuardItemToJson(PresubmitGuardItem instance) =>
    <String, dynamic>{
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
