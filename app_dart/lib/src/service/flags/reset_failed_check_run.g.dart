// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'reset_failed_check_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResetFailedCheckRun _$ResetFailedCheckRunFromJson(Map<String, dynamic> json) =>
    ResetFailedCheckRun(
      useForAll: json['useForAll'] as bool?,
      useForUsers: (json['useForUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ResetFailedCheckRunToJson(
  ResetFailedCheckRun instance,
) => <String, dynamic>{
  'useForAll': instance.useForAll,
  'useForUsers': instance.useForUsers,
};
