// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_check_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitCheckResponse _$PresubmitCheckResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PresubmitCheckResponse',
  json,
  ($checkedConvert) {
    final val = PresubmitCheckResponse(
      attemptNumber: $checkedConvert(
        'attempt_number',
        (v) => (v as num).toInt(),
      ),
      buildName: $checkedConvert('build_name', (v) => v as String),
      creationTime: $checkedConvert('creation_time', (v) => (v as num).toInt()),
      startTime: $checkedConvert('start_time', (v) => (v as num?)?.toInt()),
      endTime: $checkedConvert('end_time', (v) => (v as num?)?.toInt()),
      status: $checkedConvert('status', (v) => v as String),
      summary: $checkedConvert('summary', (v) => v as String?),
      buildNumber: $checkedConvert('build_number', (v) => (v as num?)?.toInt()),
    );
    return val;
  },
  fieldKeyMap: const {
    'attemptNumber': 'attempt_number',
    'buildName': 'build_name',
    'creationTime': 'creation_time',
    'startTime': 'start_time',
    'endTime': 'end_time',
    'buildNumber': 'build_number',
  },
);

Map<String, dynamic> _$PresubmitCheckResponseToJson(
  PresubmitCheckResponse instance,
) => <String, dynamic>{
  'attempt_number': instance.attemptNumber,
  'build_name': instance.buildName,
  'creation_time': instance.creationTime,
  'start_time': ?instance.startTime,
  'end_time': ?instance.endTime,
  'status': instance.status,
  'summary': ?instance.summary,
  'build_number': ?instance.buildNumber,
};
