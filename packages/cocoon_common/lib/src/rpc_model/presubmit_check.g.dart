// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_check.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitCheck _$PresubmitCheckFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PresubmitCheck',
      json,
      ($checkedConvert) {
        final val = PresubmitCheck(
          attemptNumber: $checkedConvert(
            'attempt_number',
            (v) => (v as num).toInt(),
          ),
          taskName: $checkedConvert('task_name', (v) => v as String),
          creationTime: $checkedConvert(
            'creation_time',
            (v) => (v as num).toInt(),
          ),
          startTime: $checkedConvert('start_time', (v) => (v as num?)?.toInt()),
          endTime: $checkedConvert('end_time', (v) => (v as num?)?.toInt()),
          status: $checkedConvert('status', (v) => v as String),
          summary: $checkedConvert('summary', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'attemptNumber': 'attempt_number',
        'taskName': 'task_name',
        'creationTime': 'creation_time',
        'startTime': 'start_time',
        'endTime': 'end_time',
      },
    );

Map<String, dynamic> _$PresubmitCheckToJson(PresubmitCheck instance) =>
    <String, dynamic>{
      'attempt_number': instance.attemptNumber,
      'task_name': instance.taskName,
      'creation_time': instance.creationTime,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'status': instance.status,
      'summary': instance.summary,
    };
