// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'ChecklistKey': const KeyConverter().toJson(instance.commitKey),
      'CreateTimestamp': instance.createTimestamp,
      'StartTimestamp': instance.startTimestamp,
      'EndTimestamp': instance.endTimestamp,
      'Name': instance.name,
      'Attempts': instance.attempts,
      'Flaky': instance.isFlaky,
      'TimeoutInMinutes': instance.timeoutInMinutes,
      'Reason': instance.reason,
      'RequiredCapabilities': instance.requiredCapabilities,
      'ReservedForAgentID': instance.reservedForAgentId,
      'StageName': instance.stageName,
      'Status': instance.status,
    };

Map<String, dynamic> _$TaskWrapperToJson(TaskWrapper instance) =>
    <String, dynamic>{
      'Task': instance.task,
      'Key': const KeyConverter().toJson(instance.key),
    };
