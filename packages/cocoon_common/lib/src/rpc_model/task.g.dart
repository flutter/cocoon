// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Task',
  json,
  ($checkedConvert) {
    final val = Task(
      createTimestamp: $checkedConvert(
        'CreateTimestamp',
        (v) => (v as num).toInt(),
      ),
      startTimestamp: $checkedConvert(
        'StartTimestamp',
        (v) => (v as num).toInt(),
      ),
      endTimestamp: $checkedConvert('EndTimestamp', (v) => (v as num).toInt()),
      attempts: $checkedConvert('Attempts', (v) => (v as num).toInt()),
      isBringup: $checkedConvert('IsBringup', (v) => v as bool),
      isFlaky: $checkedConvert('IsFlaky', (v) => v as bool),
      status: $checkedConvert('Status', (v) => v as String),
      buildNumberList: $checkedConvert(
        'BuildNumberList',
        (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
      ),
      builderName: $checkedConvert('BuilderName', (v) => v as String),
      lastAttemptFailed: $checkedConvert('LastAttemptFailed', (v) => v as bool),
    );
    return val;
  },
  fieldKeyMap: const {
    'createTimestamp': 'CreateTimestamp',
    'startTimestamp': 'StartTimestamp',
    'endTimestamp': 'EndTimestamp',
    'attempts': 'Attempts',
    'isBringup': 'IsBringup',
    'isFlaky': 'IsFlaky',
    'status': 'Status',
    'buildNumberList': 'BuildNumberList',
    'builderName': 'BuilderName',
    'lastAttemptFailed': 'LastAttemptFailed',
  },
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'CreateTimestamp': instance.createTimestamp,
  'StartTimestamp': instance.startTimestamp,
  'EndTimestamp': instance.endTimestamp,
  'Attempts': instance.attempts,
  'IsBringup': instance.isBringup,
  'IsFlaky': instance.isFlaky,
  'Status': instance.status,
  'BuildNumberList': instance.buildNumberList,
  'BuilderName': instance.builderName,
  'LastAttemptFailed': instance.lastAttemptFailed,
};
