// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presubmit_job_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresubmitJobResponse _$PresubmitJobResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'PresubmitJobResponse',
  json,
  ($checkedConvert) {
    final val = PresubmitJobResponse(
      attemptNumber: $checkedConvert(
        'attempt_number',
        (v) => (v as num).toInt(),
      ),
      jobName: $checkedConvert('job_name', (v) => v as String),
      creationTime: $checkedConvert('creation_time', (v) => (v as num).toInt()),
      startTime: $checkedConvert('start_time', (v) => (v as num?)?.toInt()),
      endTime: $checkedConvert('end_time', (v) => (v as num?)?.toInt()),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TaskStatusEnumMap, v),
      ),
      summary: $checkedConvert('summary', (v) => v as String?),
      buildNumber: $checkedConvert('build_number', (v) => (v as num?)?.toInt()),
      buildId: $checkedConvert('build_id', (v) => (v as num?)?.toInt()),
      logAnalysis: $checkedConvert('log_analysis', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'attemptNumber': 'attempt_number',
    'jobName': 'job_name',
    'creationTime': 'creation_time',
    'startTime': 'start_time',
    'endTime': 'end_time',
    'buildNumber': 'build_number',
    'buildId': 'build_id',
    'logAnalysis': 'log_analysis',
  },
);

Map<String, dynamic> _$PresubmitJobResponseToJson(
  PresubmitJobResponse instance,
) => <String, dynamic>{
  'attempt_number': instance.attemptNumber,
  'job_name': instance.jobName,
  'creation_time': instance.creationTime,
  'start_time': ?instance.startTime,
  'end_time': ?instance.endTime,
  'status': instance.status,
  'summary': ?instance.summary,
  'build_number': ?instance.buildNumber,
  'build_id': ?instance.buildId,
  'log_analysis': ?instance.logAnalysis,
};

const _$TaskStatusEnumMap = {
  TaskStatus.cancelled: 'Cancelled',
  TaskStatus.waitingForBackfill: 'New',
  TaskStatus.inProgress: 'In Progress',
  TaskStatus.infraFailure: 'Infra Failure',
  TaskStatus.failed: 'Failed',
  TaskStatus.succeeded: 'Succeeded',
  TaskStatus.neutral: 'Neutral',
  TaskStatus.skipped: 'Skipped',
};
