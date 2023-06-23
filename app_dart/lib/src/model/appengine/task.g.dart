// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
      'ChecklistKey': const StringKeyConverter().toJson(instance.commitKey),
      'CreateTimestamp': instance.createTimestamp,
      'StartTimestamp': instance.startTimestamp,
      'EndTimestamp': instance.endTimestamp,
      'Name': instance.name,
      'Attempts': instance.attempts,
      'Flaky': instance.isFlaky,
      'TestFlaky': instance.isTestFlaky,
      'TimeoutInMinutes': instance.timeoutInMinutes,
      'Reason': instance.reason,
      'BuildNumber': instance.buildNumber,
      'BuildNumberList': instance.buildNumberList,
      'BuilderName': instance.builderName,
      'luciBucket': instance.luciBucket,
      'RequiredCapabilities': instance.requiredCapabilities,
      'ReservedForAgentID': instance.reservedForAgentId,
      'StageName': instance.stageName,
      'Status': instance.status,
    };

Map<String, dynamic> _$SerializableTaskToJson(SerializableTask instance) => <String, dynamic>{
      'Task': instance.task,
      'Key': const IntKeyConverter().toJson(instance.key),
    };
