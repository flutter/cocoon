// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'schedule_postsubmits_for_commit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Request _$RequestFromJson(Map<String, dynamic> json) => $checkedCreate(
      '_Request',
      json,
      ($checkedConvert) {
        final val = _Request(
          repo: $checkedConvert('repo', (v) => v as String),
          branch: $checkedConvert('branch', (v) => v as String),
          commit: $checkedConvert('commit', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$RequestToJson(_Request instance) => <String, dynamic>{
      'repo': instance.repo,
      'branch': instance.branch,
      'commit': instance.commit,
    };
