// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'buildbucket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchRequest _$BatchRequestFromJson(Map<String, dynamic> json) => BatchRequest(
      requests: (json['requests'] as List<dynamic>?)?.map((e) => Request.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$BatchRequestToJson(BatchRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('requests', instance.requests);
  return val;
}

Request _$RequestFromJson(Map<String, dynamic> json) => Request(
      getBuild: json['getBuild'] == null ? null : GetBuildRequest.fromJson(json['getBuild'] as Map<String, dynamic>),
      searchBuilds: json['searchBuilds'] == null
          ? null
          : SearchBuildsRequest.fromJson(json['searchBuilds'] as Map<String, dynamic>),
      scheduleBuild: json['scheduleBuild'] == null
          ? null
          : ScheduleBuildRequest.fromJson(json['scheduleBuild'] as Map<String, dynamic>),
      cancelBuild:
          json['cancelBuild'] == null ? null : CancelBuildRequest.fromJson(json['cancelBuild'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RequestToJson(Request instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('getBuild', instance.getBuild);
  writeNotNull('searchBuilds', instance.searchBuilds);
  writeNotNull('scheduleBuild', instance.scheduleBuild);
  writeNotNull('cancelBuild', instance.cancelBuild);
  return val;
}

BatchResponse _$BatchResponseFromJson(Map<String, dynamic> json) => BatchResponse(
      responses:
          (json['responses'] as List<dynamic>?)?.map((e) => Response.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$BatchResponseToJson(BatchResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('responses', instance.responses);
  return val;
}

Response _$ResponseFromJson(Map<String, dynamic> json) => Response(
      getBuild: json['getBuild'] == null ? null : Build.fromJson(json['getBuild'] as Map<String, dynamic>),
      searchBuilds: json['searchBuilds'] == null
          ? null
          : SearchBuildsResponse.fromJson(json['searchBuilds'] as Map<String, dynamic>),
      scheduleBuild:
          json['scheduleBuild'] == null ? null : Build.fromJson(json['scheduleBuild'] as Map<String, dynamic>),
      cancelBuild: json['cancelBuild'] == null ? null : Build.fromJson(json['cancelBuild'] as Map<String, dynamic>),
      error: json['error'] == null ? null : GrpcStatus.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ResponseToJson(Response instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('getBuild', instance.getBuild);
  writeNotNull('searchBuilds', instance.searchBuilds);
  writeNotNull('scheduleBuild', instance.scheduleBuild);
  writeNotNull('cancelBuild', instance.cancelBuild);
  writeNotNull('error', instance.error);
  return val;
}

GetBuildRequest _$GetBuildRequestFromJson(Map<String, dynamic> json) => GetBuildRequest(
      id: json['id'] as String?,
      builderId: json['builder'] == null ? null : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      buildNumber: json['buildNumber'] as int?,
      fields: json['fields'] as String?,
    );

Map<String, dynamic> _$GetBuildRequestToJson(GetBuildRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('builder', instance.builderId);
  writeNotNull('buildNumber', instance.buildNumber);
  writeNotNull('fields', instance.fields);
  return val;
}

GetBuilderRequest _$GetBuilderRequestFromJson(Map<String, dynamic> json) => GetBuilderRequest(
      builderId: json['builderId'] == null ? null : BuilderId.fromJson(json['builderId'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GetBuilderRequestToJson(GetBuilderRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('builderId', instance.builderId);
  return val;
}

BuilderConfig _$BuilderConfigFromJson(Map<String, dynamic> json) => BuilderConfig(
      name: json['name'] as String?,
    );

Map<String, dynamic> _$BuilderConfigToJson(BuilderConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('name', instance.name);
  return val;
}

BuilderItem _$BuilderItemFromJson(Map<String, dynamic> json) => BuilderItem(
      id: json['id'] == null ? null : BuilderId.fromJson(json['id'] as Map<String, dynamic>),
      config: json['config'] == null ? null : BuilderConfig.fromJson(json['config'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$BuilderItemToJson(BuilderItem instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('config', instance.config);
  return val;
}

ListBuildersRequest _$ListBuildersRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['project'],
  );
  return ListBuildersRequest(
    project: json['project'] as String,
    bucket: json['bucket'] as String?,
    pageSize: json['pageSize'] as int? ?? 1000,
    pageToken: json['pageToken'] as String?,
  );
}

Map<String, dynamic> _$ListBuildersRequestToJson(ListBuildersRequest instance) {
  final val = <String, dynamic>{
    'project': instance.project,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('bucket', instance.bucket);
  writeNotNull('pageSize', instance.pageSize);
  writeNotNull('pageToken', instance.pageToken);
  return val;
}

ListBuildersResponse _$ListBuildersResponseFromJson(Map<String, dynamic> json) => ListBuildersResponse(
      builders:
          (json['builders'] as List<dynamic>?)?.map((e) => BuilderItem.fromJson(e as Map<String, dynamic>)).toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );

Map<String, dynamic> _$ListBuildersResponseToJson(ListBuildersResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('builders', instance.builders);
  writeNotNull('nextPageToken', instance.nextPageToken);
  return val;
}

CancelBuildRequest _$CancelBuildRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['id', 'summaryMarkdown'],
  );
  return CancelBuildRequest(
    id: json['id'] as String,
    summaryMarkdown: json['summaryMarkdown'] as String,
  );
}

Map<String, dynamic> _$CancelBuildRequestToJson(CancelBuildRequest instance) => <String, dynamic>{
      'id': instance.id,
      'summaryMarkdown': instance.summaryMarkdown,
    };

SearchBuildsRequest _$SearchBuildsRequestFromJson(Map<String, dynamic> json) => SearchBuildsRequest(
      predicate: BuildPredicate.fromJson(json['predicate'] as Map<String, dynamic>),
      pageSize: json['pageSize'] as int?,
      pageToken: json['pageToken'] as String?,
      fields: json['fields'] as String?,
    );

Map<String, dynamic> _$SearchBuildsRequestToJson(SearchBuildsRequest instance) {
  final val = <String, dynamic>{
    'predicate': instance.predicate,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('pageSize', instance.pageSize);
  writeNotNull('pageToken', instance.pageToken);
  writeNotNull('fields', instance.fields);
  return val;
}

BuildPredicate _$BuildPredicateFromJson(Map<String, dynamic> json) => BuildPredicate(
      builderId: json['builder'] == null ? null : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      createdBy: json['createdBy'] as String?,
      tags: const TagsConverter().fromJson(json['tags'] as List?),
      includeExperimental: json['includeExperimental'] as bool?,
    );

Map<String, dynamic> _$BuildPredicateToJson(BuildPredicate instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('builder', instance.builderId);
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('includeExperimental', instance.includeExperimental);
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

SearchBuildsResponse _$SearchBuildsResponseFromJson(Map<String, dynamic> json) => SearchBuildsResponse(
      builds: (json['builds'] as List<dynamic>?)?.map((e) => Build.fromJson(e as Map<String, dynamic>)).toList(),
      nextPageToken: json['nextPageToken'] as String?,
    );

Map<String, dynamic> _$SearchBuildsResponseToJson(SearchBuildsResponse instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('builds', instance.builds);
  writeNotNull('nextPageToken', instance.nextPageToken);
  return val;
}

ScheduleBuildRequest _$ScheduleBuildRequestFromJson(Map<String, dynamic> json) => ScheduleBuildRequest(
      requestId: json['requestId'] as String?,
      builderId: BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      canary: json['canary'] as bool?,
      experimental: $enumDecodeNullable(_$TrinaryEnumMap, json['experimental']),
      gitilesCommit:
          json['gitilesCommit'] == null ? null : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      dimensions: (json['dimensions'] as List<dynamic>?)
          ?.map((e) => RequestedDimension.fromJson(e as Map<String, dynamic>))
          .toList(),
      priority: json['priority'] as int?,
      tags: const TagsConverter().fromJson(json['tags'] as List?),
      notify: json['notify'] == null ? null : NotificationConfig.fromJson(json['notify'] as Map<String, dynamic>),
      fields: json['fields'] as String?,
      exe: json['exe'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ScheduleBuildRequestToJson(ScheduleBuildRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('requestId', instance.requestId);
  val['builder'] = instance.builderId;
  writeNotNull('canary', instance.canary);
  writeNotNull('experimental', _$TrinaryEnumMap[instance.experimental]);
  writeNotNull('properties', instance.properties);
  writeNotNull('gitilesCommit', instance.gitilesCommit);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('dimensions', instance.dimensions);
  writeNotNull('priority', instance.priority);
  writeNotNull('notify', instance.notify);
  writeNotNull('fields', instance.fields);
  writeNotNull('exe', instance.exe);
  return val;
}

const _$TrinaryEnumMap = {
  Trinary.yes: 'YES',
  Trinary.no: 'NO',
  Trinary.unset: 'UNSET',
};

Build _$BuildFromJson(Map<String, dynamic> json) => Build(
      id: json['id'] as String,
      builderId: BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
      number: json['number'] as int?,
      createdBy: json['createdBy'] as String?,
      canceledBy: json['canceledBy'] as String?,
      startTime: json['startTime'] == null ? null : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null ? null : DateTime.parse(json['endTime'] as String),
      status: $enumDecodeNullable(_$StatusEnumMap, json['status']),
      tags: const TagsConverter().fromJson(json['tags'] as List?),
      input: json['input'] == null ? null : Input.fromJson(json['input'] as Map<String, dynamic>),
      summaryMarkdown: json['summaryMarkdown'] as String?,
      critical: $enumDecodeNullable(_$TrinaryEnumMap, json['critical']),
    );

Map<String, dynamic> _$BuildToJson(Build instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'builder': instance.builderId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('number', instance.number);
  writeNotNull('createdBy', instance.createdBy);
  writeNotNull('canceledBy', instance.canceledBy);
  writeNotNull('startTime', instance.startTime?.toIso8601String());
  writeNotNull('endTime', instance.endTime?.toIso8601String());
  writeNotNull('status', _$StatusEnumMap[instance.status]);
  writeNotNull('summaryMarkdown', instance.summaryMarkdown);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('critical', _$TrinaryEnumMap[instance.critical]);
  writeNotNull('input', instance.input);
  return val;
}

BuilderId _$BuilderIdFromJson(Map<String, dynamic> json) => BuilderId(
      project: json['project'] as String?,
      bucket: json['bucket'] as String?,
      builder: json['builder'] as String?,
    );

Map<String, dynamic> _$BuilderIdToJson(BuilderId instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('project', instance.project);
  writeNotNull('bucket', instance.bucket);
  writeNotNull('builder', instance.builder);
  return val;
}

NotificationConfig _$NotificationConfigFromJson(Map<String, dynamic> json) => NotificationConfig(
      pubsubTopic: json['pubsubTopic'] as String?,
      userData: _$JsonConverterFromJson<String, String>(json['userData'], const Base64Converter().fromJson),
    );

Map<String, dynamic> _$NotificationConfigToJson(NotificationConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('pubsubTopic', instance.pubsubTopic);
  writeNotNull('userData', _$JsonConverterToJson<String, String>(instance.userData, const Base64Converter().toJson));
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

Input _$InputFromJson(Map<String, dynamic> json) => Input(
      properties: (json['properties'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as Object),
      ),
      gitilesCommit:
          json['gitilesCommit'] == null ? null : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
      experimental: json['experimental'] as bool?,
    );

Map<String, dynamic> _$InputToJson(Input instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('properties', instance.properties);
  writeNotNull('gitilesCommit', instance.gitilesCommit);
  writeNotNull('experimental', instance.experimental);
  return val;
}

GitilesCommit _$GitilesCommitFromJson(Map<String, dynamic> json) => GitilesCommit(
      host: json['host'] as String?,
      project: json['project'] as String?,
      ref: json['ref'] as String?,
      hash: json['id'] as String?,
    );

Map<String, dynamic> _$GitilesCommitToJson(GitilesCommit instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('host', instance.host);
  writeNotNull('project', instance.project);
  writeNotNull('id', instance.hash);
  writeNotNull('ref', instance.ref);
  return val;
}

RequestedDimension _$RequestedDimensionFromJson(Map<String, dynamic> json) => RequestedDimension(
      key: json['key'] as String,
      value: json['value'] as String?,
      expiration: json['expiration'] as String?,
    );

Map<String, dynamic> _$RequestedDimensionToJson(RequestedDimension instance) {
  final val = <String, dynamic>{
    'key': instance.key,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('value', instance.value);
  writeNotNull('expiration', instance.expiration);
  return val;
}
