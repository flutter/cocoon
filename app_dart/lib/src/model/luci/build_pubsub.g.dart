// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'build_pubsub.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Build _$BuildFromJson(Map<String, dynamic> json) => Build(
      id: json['id'] as int?,
      builder: json['builder'] == null
          ? null
          : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      builderInfo: json['builderInfo'] == null
          ? null
          : BuilderInfo.fromJson(json['builderInfo'] as Map<String, dynamic>),
      number: json['number'] as int?,
      createdBy: json['createdBy'] as String?,
      canceledBy: json['canceledBy'] as String?,
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      cancelTime: json['cancelTime'] == null
          ? null
          : DateTime.parse(json['cancelTime'] as String),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      summaryMarkdown: json['summaryMarkdown'] as String?,
      cancellationMarkdown: json['cancellationMarkdown'] as String?,
      critical: $enumDecodeNullable(_$TrinaryEnumMap, json['critical']),
      input: json['input'] == null
          ? null
          : Input.fromJson(json['input'] as Map<String, dynamic>),
      output: json['output'] == null
          ? null
          : Output.fromJson(json['output'] as Map<String, dynamic>),
      steps: (json['steps'] as List<dynamic>?)
          ?.map((e) => Step.fromJson(e as Map<String, dynamic>))
          .toList(),
      buildInfra: json['buildInfra'] == null
          ? null
          : BuildInfra.fromJson(json['buildInfra'] as Map<String, dynamic>),
      tags: const TagsConverter().fromJson(json['tags'] as List?),
      exe: json['exe'] == null
          ? null
          : Executable.fromJson(json['exe'] as Map<String, dynamic>),
      canary: json['canary'] as bool?,
      schedulingTimeout: json['schedulingTimeout'] == null
          ? null
          : Duration(microseconds: json['schedulingTimeout'] as int),
      executionTimeout: json['executionTimeout'] == null
          ? null
          : Duration(microseconds: json['executionTimeout'] as int),
      gracePeriod: json['gracePeriod'] == null
          ? null
          : Duration(microseconds: json['gracePeriod'] as int),
      waitForCapacity: json['waitForCapacity'] as bool?,
      canOutliveParent: json['canOutliveParent'] as bool?,
      ancestorIds: (json['ancestorIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      retriable: $enumDecodeNullable(_$TrinaryEnumMap, json['retriable']),
    );

Map<String, dynamic> _$BuildToJson(Build instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('builder', instance.builder);
  writeNotNull('builderInfo', instance.builderInfo);
  writeNotNull('number', instance.number);
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('canceledBy', instance.canceledBy);
  writeNotNull('createTime', instance.createTime?.toIso8601String());
  writeNotNull('startTime', instance.startTime?.toIso8601String());
  writeNotNull('endTime', instance.endTime?.toIso8601String());
  writeNotNull('updateTime', instance.updateTime?.toIso8601String());
  writeNotNull('cancelTime', instance.cancelTime?.toIso8601String());
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryMarkdown', instance.summaryMarkdown);
  writeNotNull('cancellationMarkdown', instance.cancellationMarkdown);
  writeNotNull('critical', _$TrinaryEnumMap[instance.critical]);
  writeNotNull('input', instance.input);
  writeNotNull('output', instance.output);
  writeNotNull('steps', instance.steps);
  writeNotNull('buildInfra', instance.buildInfra);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('exe', instance.exe);
  writeNotNull('canary', instance.canary);
  writeNotNull('schedulingTimeout', instance.schedulingTimeout?.inMicroseconds);
  writeNotNull('executionTimeout', instance.executionTimeout?.inMicroseconds);
  writeNotNull('gracePeriod', instance.gracePeriod?.inMicroseconds);
  writeNotNull('waitForCapacity', instance.waitForCapacity);
  writeNotNull('canOutliveParent', instance.canOutliveParent);
  writeNotNull('ancestorIds', instance.ancestorIds);
  writeNotNull('retriable', _$TrinaryEnumMap[instance.retriable]);
  return val;
}

const _$StatusEnumMap = {
  Status.unspecified: 'STATUS_UNSPECIFIED',
  Status.scheduled: 'SCHEDULED',
  Status.started: 'STARTED',
  Status.ended: 'ENDED_MASK',
  Status.success: 'SUCCESS',
  Status.failure: 'FAILURE',
  Status.infraFailure: 'INFRA_FAILURE',
  Status.canceled: 'CANCELED',
};

const _$TrinaryEnumMap = {
  Trinary.yes: 'YES',
  Trinary.no: 'NO',
  Trinary.unset: 'UNSET',
};

BuildV2PubSub _$BuildV2PubSubFromJson(Map<String, dynamic> json) =>
    BuildV2PubSub(
      build: json['build'] == null
          ? null
          : Build.fromJson(json['build'] as Map<String, dynamic>),
      compression:
          $enumDecodeNullable(_$CompressionEnumMap, json['compression']),
    );

Map<String, dynamic> _$BuildV2PubSubToJson(BuildV2PubSub instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('build', instance.build);
  writeNotNull('compression', _$CompressionEnumMap[instance.compression]);
  return val;
}

const _$CompressionEnumMap = {
  Compression.zlib: 'ZLIB',
  Compression.zstd: 'ZSTD',
};

PubSubCallBack _$PubSubCallBackFromJson(Map<String, dynamic> json) =>
    PubSubCallBack(
      buildV2PubSub: json['buildV2PubSub'] == null
          ? null
          : BuildV2PubSub.fromJson(
              json['buildV2PubSub'] as Map<String, dynamic>),
      userData: json['userData'] as String?,
    );

Map<String, dynamic> _$PubSubCallBackToJson(PubSubCallBack instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('buildV2PubSub', instance.buildV2PubSub);
  val['userData'] = instance.userData;
  return val;
}
