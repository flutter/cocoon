// GENERATED CODE - DO NOT MODIFY BY HAND

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

Map<String, dynamic> _$BatchRequestToJson(BatchRequest instance) =>
    <String, dynamic>{
      'requests': instance.requests,
    };

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

Map<String, dynamic> _$RequestToJson(Request instance) => <String, dynamic>{
      'getBuild': instance.getBuild,
      'searchBuilds': instance.searchBuilds,
      'scheduleBuild': instance.scheduleBuild,
      'cancelBuild': instance.cancelBuild,
    };

BatchResponse _$BatchResponseFromJson(Map<String, dynamic> json) {
  return BatchResponse(
    responses: (json['responses'] as List)
        ?.map((e) =>
            e == null ? null : Response.fromJson(e as Map<String, dynamic>))
        ?.toList(),
  );
}

Map<String, dynamic> _$BatchResponseToJson(BatchResponse instance) =>
    <String, dynamic>{
      'responses': instance.responses,
    };

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

Map<String, dynamic> _$ResponseToJson(Response instance) => <String, dynamic>{
      'getBuild': instance.getBuild,
      'searchBuilds': instance.searchBuilds,
      'scheduleBuild': instance.scheduleBuild,
      'cancelBuild': instance.cancelBuild,
    };

GetBuildRequest _$GetBuildRequestFromJson(Map<String, dynamic> json) {
  return GetBuildRequest(
    id: const _Int64Converter().fromJson(json['id'] as String),
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    buildNumber: json['buildNumber'] as int,
  );
}

Map<String, dynamic> _$GetBuildRequestToJson(GetBuildRequest instance) =>
    <String, dynamic>{
      'id': const _Int64Converter().toJson(instance.id),
      'builder': instance.builderId,
      'buildNumber': instance.buildNumber,
    };

CancelBuildRequest _$CancelBuildRequestFromJson(Map<String, dynamic> json) {
  $checkKeys(json, requiredKeys: const ['id', 'summaryMarkdown']);
  return CancelBuildRequest(
    id: const _Int64Converter().fromJson(json['id'] as String),
    summaryMarkdown: json['summaryMarkdown'] as String,
  );
}

Map<String, dynamic> _$CancelBuildRequestToJson(CancelBuildRequest instance) =>
    <String, dynamic>{
      'id': const _Int64Converter().toJson(instance.id),
      'summaryMarkdown': instance.summaryMarkdown,
    };

SearchBuildsRequest _$SearchBuildsRequestFromJson(Map<String, dynamic> json) {
  return SearchBuildsRequest(
    predicate: json['predicate'] == null
        ? null
        : BuildPredicate.fromJson(json['predicate'] as Map<String, dynamic>),
    pageSize: json['pageSize'] as int,
    pageToken: json['pageToken'] as String,
  );
}

Map<String, dynamic> _$SearchBuildsRequestToJson(
        SearchBuildsRequest instance) =>
    <String, dynamic>{
      'predicate': instance.predicate,
      'pageSize': instance.pageSize,
      'pageToken': instance.pageToken,
    };

BuildPredicate _$BuildPredicateFromJson(Map<String, dynamic> json) {
  return BuildPredicate(
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    status: _$enumDecodeNullable(_$StatusEnumMap, json['status']),
    createdBy: json['createdBy'] as String,
    tags: const TagsConverter().fromJson(json['tags'] as List),
  );
}

Map<String, dynamic> _$BuildPredicateToJson(BuildPredicate instance) =>
    <String, dynamic>{
      'builder': instance.builderId,
      'status': _$StatusEnumMap[instance.status],
      'createdBy': instance.createdBy,
      'tags': const TagsConverter().toJson(instance.tags),
    };

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

const _$StatusEnumMap = <Status, dynamic>{
  Status.unspecified: 'STATUS_UNSPECIFIED',
  Status.scheduled: 'SCHEDULED',
  Status.ended: 'ENDED_MASK',
  Status.success: 'SUCCESS',
  Status.failure: 'FAILURE',
  Status.infraFailure: 'INFRA_FAILURE',
  Status.canceled: 'CANCELED'
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
        SearchBuildsResponse instance) =>
    <String, dynamic>{
      'builds': instance.builds,
      'nextPageToken': instance.nextPageToken,
    };

ScheduleBuildRequest _$ScheduleBuildRequestFromJson(Map<String, dynamic> json) {
  return ScheduleBuildRequest(
    requestId: json['requestId'] as String,
    builderId: json['builder'] == null
        ? null
        : BuilderId.fromJson(json['builder'] as Map<String, dynamic>),
    canary: _$enumDecodeNullable(_$TrinaryEnumMap, json['canary']),
    experimental: _$enumDecodeNullable(_$TrinaryEnumMap, json['experimental']),
    gitilesCommit: json['gitilesCommit'] == null
        ? null
        : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
    properties: (json['properties'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    tags: const TagsConverter().fromJson(json['tags'] as List),
  );
}

Map<String, dynamic> _$ScheduleBuildRequestToJson(
        ScheduleBuildRequest instance) =>
    <String, dynamic>{
      'requestId': instance.requestId,
      'builder': instance.builderId,
      'canary': _$TrinaryEnumMap[instance.canary],
      'experimental': _$TrinaryEnumMap[instance.experimental],
      'properties': instance.properties,
      'gitilesCommit': instance.gitilesCommit,
      'tags': const TagsConverter().toJson(instance.tags),
    };

const _$TrinaryEnumMap = <Trinary, dynamic>{
  Trinary.yes: 'YES',
  Trinary.no: 'NO',
  Trinary.unset: 'UNSET'
};

Build _$BuildFromJson(Map<String, dynamic> json) {
  return Build(
    id: const _Int64Converter().fromJson(json['id'] as String),
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

Map<String, dynamic> _$BuildToJson(Build instance) => <String, dynamic>{
      'id': const _Int64Converter().toJson(instance.id),
      'builder': instance.builderId,
      'number': instance.number,
      'createdBy': instance.createdBy,
      'canceledBy': instance.canceledBy,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'status': _$StatusEnumMap[instance.status],
      'summaryMarkdown': instance.summaryMarkdown,
      'tags': const TagsConverter().toJson(instance.tags),
      'critical': _$TrinaryEnumMap[instance.critical],
      'input': instance.input,
    };

BuilderId _$BuilderIdFromJson(Map<String, dynamic> json) {
  return BuilderId(
    project: json['project'] as String,
    bucket: json['bucket'] as String,
    builder: json['builder'] as String,
  );
}

Map<String, dynamic> _$BuilderIdToJson(BuilderId instance) => <String, dynamic>{
      'project': instance.project,
      'bucket': instance.bucket,
      'builder': instance.builder,
    };

Input _$InputFromJson(Map<String, dynamic> json) {
  return Input(
    properties: (json['properties'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    gitilesCommit: json['gitilesCommit'] == null
        ? null
        : GitilesCommit.fromJson(json['gitilesCommit'] as Map<String, dynamic>),
    experimental: _$enumDecodeNullable(_$TrinaryEnumMap, json['experimental']),
  );
}

Map<String, dynamic> _$InputToJson(Input instance) => <String, dynamic>{
      'properties': instance.properties,
      'gitilesCommit': instance.gitilesCommit,
      'experimental': _$TrinaryEnumMap[instance.experimental],
    };

GitilesCommit _$GitilesCommitFromJson(Map<String, dynamic> json) {
  return GitilesCommit(
    host: json['host'] as String,
    project: json['project'] as String,
    ref: json['ref'] as String,
    hash: json['id'] as String,
  );
}

Map<String, dynamic> _$GitilesCommitToJson(GitilesCommit instance) =>
    <String, dynamic>{
      'host': instance.host,
      'project': instance.project,
      'id': instance.hash,
      'ref': instance.ref,
    };
