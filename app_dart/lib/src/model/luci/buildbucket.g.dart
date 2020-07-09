// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'buildbucket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BatchRequest _$BatchRequestFromJson(Map<String, dynamic> json) {
  return BatchRequest(
    requests: (json['requests'] as List)
        ?.map((e) =>
            e == null ? null : Request.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

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

Request _$RequestFromJson(Map<String, dynamic> json) {
  return Request(
    getBuild: json['getBuild'] == null
        ? null
        : GetBuildRequest.fromJson(json['getBuild'] as Map<String, dynamic>),
    searchBuilds: json['searchBuilds'] == null
        ? null
        : SearchBuildsRequest.fromJson(
            json['searchBuilds'] as Map<String, dynamic>),
    scheduleBuild: json['scheduleBuild'] == null
        ? null
        : ScheduleBuildRequest.fromJson(
            json['scheduleBuild'] as Map<String, dynamic>),
    cancelBuild: json['cancelBuild'] == null
        ? null
        : CancelBuildRequest.fromJson(
            json['cancelBuild'] as Map<String, dynamic>),
  );
}

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

BatchResponse _$BatchResponseFromJson(Map<String, dynamic> json) {
  return BatchResponse(
    responses: (json['responses'] as List)
        ?.map((e) =>
            e == null ? null : Response.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

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

Response _$ResponseFromJson(Map<String, dynamic> json) {
  return Response(
    getBuild: json['getBuild'] == null
        ? null
        : Build.fromJson(json['getBuild'] as Map<String, dynamic>),
    searchBuilds: json['searchBuilds'] == null
        ? null
        : SearchBuildsResponse.fromJson(
            json['searchBuilds'] as Map<String, dynamic>),
    scheduleBuild: json['scheduleBuild'] == null
        ? null
        : Build.fromJson(json['scheduleBuild'] as Map<String, dynamic>),
    cancelBuild: json['cancelBuild'] == null
        ? null
        : Build.fromJson(json['cancelBuild'] as Map<String, dynamic>),
  );
}

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
  return val;
}

GetBuildRequest _$GetBuildRequestFromJson(Map<String, dynamic> json) {
  return GetBuildRequest(
    id: const Int64Converter().fromJson(json['id'] as String),
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    buildNumber: json['buildNumber'] as int,
    fields: json['fields'] as String,
  );
}

Map<String, dynamic> _$GetBuildRequestToJson(GetBuildRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', const Int64Converter().toJson(instance.id));
  writeNotNull('builder', instance.builderId);
  writeNotNull('buildNumber', instance.buildNumber);
  writeNotNull('fields', instance.fields);
  return val;
}

CancelBuildRequest _$CancelBuildRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['id', 'summaryMarkdown']);
  return CancelBuildRequest(
    id: const Int64Converter().fromJson(json['id'] as String),
    summaryMarkdown: json['summaryMarkdown'] as String,
  );
}

Map<String, dynamic> _$CancelBuildRequestToJson(CancelBuildRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', const Int64Converter().toJson(instance.id));
  val['summaryMarkdown'] = instance.summaryMarkdown;
  return val;
}

SearchBuildsRequest _$SearchBuildsRequestFromJson(Map<String, dynamic> json) {
  return SearchBuildsRequest(
    predicate: json['predicate'] == null
        ? null
        : BuildPredicate.fromJson(json['predicate'] as Map<String, dynamic>),
    pageSize: json['pageSize'] as int,
    pageToken: json['pageToken'] as String,
    fields: json['fields'] as String,
  );
}

Map<String, dynamic> _$SearchBuildsRequestToJson(SearchBuildsRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('predicate', instance.predicate);
  writeNotNull('pageSize', instance.pageSize);
  writeNotNull('pageToken', instance.pageToken);
  writeNotNull('fields', instance.fields);
  return val;
}

BuildPredicate _$BuildPredicateFromJson(Map<String, dynamic> json) {
  return BuildPredicate(
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    status: _$enumDecodeNullable(_$StatusEnumMap, json['status']),
    createdBy: json['createdBy'] as String,
    tags: const TagsConverter().fromJson(json['tags'] as List),
    includeExperimental: json['includeExperimental'] as bool,
  );
}

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

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
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

SearchBuildsResponse _$SearchBuildsResponseFromJson(Map<String, dynamic> json) {
  return SearchBuildsResponse(
    builds: (json['builds'] as List)
        ?.map(
            (e) => e == null ? null : Build.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    nextPageToken: json['nextPageToken'] as String,
  );
}

Map<String, dynamic> _$SearchBuildsResponseToJson(
    SearchBuildsResponse instance) {
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

ScheduleBuildRequest _$ScheduleBuildRequestFromJson(Map<String, dynamic> json) {
  return ScheduleBuildRequest(
    requestId: json['requestId'] as String,
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    canary: json['canary'] as bool,
    experimental: _$enumDecodeNullable(_$TrinaryEnumMap, json['experimental']),
    gitilesCommit: json['gitilesCommit'] == null
        ? null
        : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
    properties: (json['properties'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    tags: const TagsConverter().fromJson(json['tags'] as List),
    notify: json['notify'] == null
        ? null
        : NotificationConfig.fromJson(json['notify'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ScheduleBuildRequestToJson(
    ScheduleBuildRequest instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('requestId', instance.requestId);
  writeNotNull('builder', instance.builderId);
  writeNotNull('canary', instance.canary);
  writeNotNull('experimental', _$TrinaryEnumMap[instance.experimental]);
  writeNotNull('properties', instance.properties);
  writeNotNull('gitilesCommit', instance.gitilesCommit);
  writeNotNull('tags', const TagsConverter().toJson(instance.tags));
  writeNotNull('notify', instance.notify);
  return val;
}

const _$TrinaryEnumMap = {
  Trinary.yes: 'YES',
  Trinary.no: 'NO',
  Trinary.unset: 'UNSET',
};

Build _$BuildFromJson(Map<String, dynamic> json) {
  return Build(
    id: const Int64Converter().fromJson(json['id'] as String),
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    number: json['number'] as int,
    createdBy: json['createdBy'] as String,
    canceledBy: json['canceledBy'] as String,
    startTime: json['startTime'] == null
        ? null
        : DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] == null
        ? null
        : DateTime.parse(json['endTime'] as String),
    status: _$enumDecodeNullable(_$StatusEnumMap, json['status']),
    tags: const TagsConverter().fromJson(json['tags'] as List),
    input: json['input'] == null
        ? null
        : Input.fromJson(json['input'] as Map<String, dynamic>),
    summaryMarkdown: json['summaryMarkdown'] as String,
    critical: _$enumDecodeNullable(_$TrinaryEnumMap, json['critical']),
  );
}

Map<String, dynamic> _$BuildToJson(Build instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', const Int64Converter().toJson(instance.id));
  writeNotNull('builder', instance.builderId);
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

BuilderId _$BuilderIdFromJson(Map<String, dynamic> json) {
  return BuilderId(
    project: json['project'] as String,
    bucket: json['bucket'] as String,
    builder: json['builder'] as String,
  );
}

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

NotificationConfig _$NotificationConfigFromJson(Map<String, dynamic> json) {
  return NotificationConfig(
    pubsubTopic: json['pubsubTopic'] as String,
    userData: const Base64Converter().fromJson(json['userData'] as String),
  );
}

Map<String, dynamic> _$NotificationConfigToJson(NotificationConfig instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('pubsubTopic', instance.pubsubTopic);
  writeNotNull('userData', const Base64Converter().toJson(instance.userData));
  return val;
}

Input _$InputFromJson(Map<String, dynamic> json) {
  return Input(
    properties: (json['properties'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    gitilesCommit: json['gitilesCommit'] == null
        ? null
        : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
    experimental: json['experimental'] as bool,
  );
}

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

GitilesCommit _$GitilesCommitFromJson(Map<String, dynamic> json) {
  return GitilesCommit(
    host: json['host'] as String,
    project: json['project'] as String,
    ref: json['ref'] as String,
    hash: json['id'] as String,
  );
}

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
