// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushMessageEnvelope _$PushMessageEnvelopeFromJson(Map<String, dynamic> json) {
  return PushMessageEnvelope(
    message: json['message'] == null
        ? null
        : PushMessage.fromJson(json['message'] as Map<String, dynamic>),
    subscription: json['subscription'] as String,
  );
}

Map<String, dynamic> _$PushMessageEnvelopeToJson(PushMessageEnvelope instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('subscription', instance.subscription);
  return val;
}

PushMessage _$PushMessageFromJson(Map<String, dynamic> json) {
  return PushMessage(
    attributes: (json['attributes'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    data: const Base64Converter().fromJson(json['data'] as String),
    messageId: json['messageId'] as String,
  );
}

Map<String, dynamic> _$PushMessageToJson(PushMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('attributes', instance.attributes);
  writeNotNull('data', const Base64Converter().toJson(instance.data));
  writeNotNull('messageId', instance.messageId);
  return val;
}

BuildPushMessage _$BuildPushMessageFromJson(Map<String, dynamic> json) {
  return BuildPushMessage(
    build: json['build'] == null
        ? null
        : Build.fromJson(json['build'] as Map<String, dynamic>),
    hostname: json['hostname'] as String,
    userData: json['user_data'] as String,
  );
}

Map<String, dynamic> _$BuildPushMessageToJson(BuildPushMessage instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('build', instance.build);
  writeNotNull('hostname', instance.hostname);
  writeNotNull('user_data', instance.userData);
  return val;
}

Build _$BuildFromJson(Map<String, dynamic> json) {
  return Build(
    bucket: json['bucket'] as String,
    canary: json['canary'] as bool,
    canaryPreference: _$enumDecodeNullable(
        _$CanaryPreferenceEnumMap, json['canary_preference']),
    cancelationReason: _$enumDecodeNullable(
        _$CancelationReasonEnumMap, json['cancelation_reason']),
    completedTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['completed_ts'] as String),
    createdBy: json['created_by'] as String,
    createdTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['created_ts'] as String),
    failureReason:
        _$enumDecodeNullable(_$FailureReasonEnumMap, json['failure_reason']),
    experimental: json['experimental'] as bool,
    id: const Int64Converter().fromJson(json['id'] as String),
    buildParameters:
        const NestedJsonConverter().fromJson(json['parameters_json'] as String),
    project: json['project'] as String,
    result: _$enumDecodeNullable(_$ResultEnumMap, json['result']),
    resultDetails: const NestedJsonConverter()
        .fromJson(json['result_details_json'] as String),
    serviceAccount: json['service_account'] as String,
    startedTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['started_ts'] as String),
    status: _$enumDecodeNullable(_$StatusEnumMap, json['status']),
    statusChangedTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['status_changed_ts'] as String),
    tags: (json['tags'] as List)?.map((e) => e as String)?.toList(),
    updatedTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['updated_ts'] as String),
    utcNowTimestamp: const MillisecondsSinceEpochConverter()
        .fromJson(json['utcnow_ts'] as String),
    url: json['url'] as String,
  );
}

Map<String, dynamic> _$BuildToJson(Build instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('bucket', instance.bucket);
  writeNotNull('canary', instance.canary);
  writeNotNull('canary_preference',
      _$CanaryPreferenceEnumMap[instance.canaryPreference]);
  writeNotNull('cancelation_reason',
      _$CancelationReasonEnumMap[instance.cancelationReason]);
  writeNotNull(
      'completed_ts',
      const MillisecondsSinceEpochConverter()
          .toJson(instance.completedTimestamp));
  writeNotNull('created_by', instance.createdBy);
  writeNotNull(
      'created_ts',
      const MillisecondsSinceEpochConverter()
          .toJson(instance.createdTimestamp));
  writeNotNull('experimental', instance.experimental);
  writeNotNull(
      'failure_reason', _$FailureReasonEnumMap[instance.failureReason]);
  writeNotNull('id', const Int64Converter().toJson(instance.id));
  writeNotNull('parameters_json',
      const NestedJsonConverter().toJson(instance.buildParameters));
  writeNotNull('project', instance.project);
  writeNotNull('result', _$ResultEnumMap[instance.result]);
  writeNotNull('result_details_json',
      const NestedJsonConverter().toJson(instance.resultDetails));
  writeNotNull('service_account', instance.serviceAccount);
  writeNotNull(
      'started_ts',
      const MillisecondsSinceEpochConverter()
          .toJson(instance.startedTimestamp));
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull(
      'status_changed_ts',
      const MillisecondsSinceEpochConverter()
          .toJson(instance.statusChangedTimestamp));
  writeNotNull('tags', instance.tags);
  writeNotNull(
      'updated_ts',
      const MillisecondsSinceEpochConverter()
          .toJson(instance.updatedTimestamp));
  writeNotNull('url', instance.url);
  writeNotNull('utcnow_ts',
      const MillisecondsSinceEpochConverter().toJson(instance.utcNowTimestamp));
  return val;
}

T _$enumDecode<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }
  return enumValues.entries
      .singleWhere((e) => e.value == source,
          orElse: () => throw ArgumentError(
              '`$source` is not one of the supported values: '
              '${enumValues.values.join(', ')}'))
      .key;
}

T _$enumDecodeNullable<T>(Map<T, dynamic> enumValues, dynamic source) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source);
}

const _$CanaryPreferenceEnumMap = <CanaryPreference, dynamic>{
  CanaryPreference.auto: 'AUTO',
  CanaryPreference.canary: 'CANARY',
  CanaryPreference.prod: 'PROD'
};

const _$CancelationReasonEnumMap = <CancelationReason, dynamic>{
  CancelationReason.canceledExplicitly: 'CANCELED_EXPLICITLY',
  CancelationReason.timeout: 'TIMEOUT'
};

const _$FailureReasonEnumMap = <FailureReason, dynamic>{
  FailureReason.buildbucketFailure: 'BUILDBUCKET_FAILURE',
  FailureReason.buildFailure: 'BUILD_FAILURE',
  FailureReason.infraFailure: 'INFRA_FAILURE',
  FailureReason.invalidBuildDefinition: 'INVALID_BUILD_DEFINITION'
};

const _$ResultEnumMap = <Result, dynamic>{
  Result.canceled: 'CANCELED',
  Result.failure: 'FAILURE',
  Result.success: 'SUCCESS'
};

const _$StatusEnumMap = <Status, dynamic>{
  Status.completed: 'COMPLETED',
  Status.scheduled: 'SCHEDULED',
  Status.started: 'STARTED'
};
