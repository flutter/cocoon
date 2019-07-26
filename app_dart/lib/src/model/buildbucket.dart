// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'buildbucket.g.dart';

@visibleForTesting
List<Map<String, String>> tagsToJson(Map<String, String> tags) {
  assert(tags != null);
  if (tags.isEmpty) {
    return const <Map<String, String>>[];
  }
  List<Map<String, String>> result = List<Map<String, String>>(tags.length);
  int i = 0;
  for (String key in tags.keys) {
    result[i++] = <String, String>{
      'key': key,
      'value': tags[key],
    };
  }
  return result;
}

@visibleForTesting
Map<String, String> tagsFromJson(List<dynamic> tags) {
  Map<String, String> result = <String, String>{};
  for (Map<String, dynamic> tag in tags.cast<Map<String, dynamic>>()) {
    result[tag['key']] = tag['value'] as String;
  }
  return result;
}

/// Used for Json serialization of a 64 bit int to a string.
String _intToString(int i) => i.toString();

abstract class Jsonable {
  Map<String, dynamic> toJson();
}

@JsonSerializable()
class BatchRequest implements Jsonable {
  const BatchRequest({
    this.requests,
  });

  static BatchRequest fromJson(Map<String, dynamic> json) => _$BatchRequestFromJson(json);

  final List<Request> requests;

  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);
}

@JsonSerializable()
class Request implements Jsonable {
  /// Only one of these should be set.
  const Request({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  });

  static Request fromJson(Map<String, dynamic> json) => _$RequestFromJson(json);

  @JsonKey(name: 'getBuild')
  final GetBuildRequest getBuild;

  @JsonKey(name: 'searchBuilds')
  final SearchBuildsRequest searchBuilds;

  @JsonKey(name: 'scheduleBuild')
  final ScheduleBuildRequest scheduleBuild;

  @JsonKey(name: 'cancelBuild')
  final CancelBuildRequest cancelBuild;

  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

@JsonSerializable()
class BatchResponse implements Jsonable {
  const BatchResponse({
    this.responses,
  });

  static BatchResponse fromJson(Map<String, dynamic> json) => _$BatchResponseFromJson(json);

  @JsonKey(name: 'responses')
  final List<Response> responses;

  Map<String, dynamic> toJson() => _$BatchResponseToJson(this);
}

@JsonSerializable()
class Response implements Jsonable {
  /// Only one of these should be set.
  const Response({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  });

  static Response fromJson(Map<String, dynamic> json) => _$ResponseFromJson(json);

  @JsonKey(name: 'getBuild')
  final Build getBuild;

  @JsonKey(name: 'searchBuilds')
  final SearchBuildsResponse searchBuilds;

  @JsonKey(name: 'scheduleBuild')
  final Build scheduleBuild;

  @JsonKey(name: 'cancelBuild')
  final Build cancelBuild;

  Map<String, dynamic> toJson() => _$ResponseToJson(this);
}

@JsonSerializable()
class GetBuildRequest implements Jsonable {
  const GetBuildRequest({
    this.id,
    this.builderId,
    this.buildNumber,
  });

  static GetBuildRequest fromJson(Map<String, dynamic> json) => _$GetBuildRequestFromJson(json);

  @JsonKey(name: 'id', fromJson: int.parse, toJson: _intToString)
  final int id;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  @JsonKey(name: 'buildNumber')
  final int buildNumber;

  Map<String, dynamic> toJson() => _$GetBuildRequestToJson(this);
}

@JsonSerializable()
class CancelBuildRequest implements Jsonable {
  const CancelBuildRequest({
    @required this.id,
    @required this.summaryMarkdown,
  })  : assert(id != null),
        assert(summaryMarkdown != null);

  static CancelBuildRequest fromJson(Map<String, dynamic> json) => _$CancelBuildRequestFromJson(json);

  @JsonKey(name: 'id', fromJson: int.parse, toJson: _intToString, nullable: false, required: true)
  final int id;

  @JsonKey(name: 'summaryMarkdown', nullable: false, required: true)
  final String summaryMarkdown;

  Map<String, dynamic> toJson() => _$CancelBuildRequestToJson(this);
}

@JsonSerializable()
class SearchBuildsRequest implements Jsonable {
  const SearchBuildsRequest({
    this.predicate,
    this.pageSize,
    this.pageToken,
  });

  static SearchBuildsRequest fromJson(Map<String, dynamic> json) => _$SearchBuildsRequestFromJson(json);

  @JsonKey(name: 'predicate')
  final BuildPredicate predicate;

  @JsonKey(name: 'pageSize')
  final int pageSize;

  @JsonKey(name: 'pageToken')
  final String pageToken;

  Map<String, dynamic> toJson() => _$SearchBuildsRequestToJson(this);
}

@JsonSerializable()
class BuildPredicate implements Jsonable {
  const BuildPredicate({
    this.builderId,
    this.status,
    this.createdBy,
    this.tags,
  });

  static BuildPredicate fromJson(Map<String, dynamic> json) => _$BuildPredicateFromJson(json);

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  @JsonKey(name: 'status')
  final Status status;

  @JsonKey(name: 'createdBy')
  final String createdBy;

  @JsonKey(name: 'tags')
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => _$BuildPredicateToJson(this);
}

@JsonSerializable()
class SearchBuildsResponse implements Jsonable {
  const SearchBuildsResponse({
    this.builds,
    this.nextPageToken,
  });

  static SearchBuildsResponse fromJson(Map<String, dynamic> json) => _$SearchBuildsResponseFromJson(json);

  @JsonKey(name: 'builds')
  final List<Build> builds;

  @JsonKey(name: 'nextPageToken')
  final String nextPageToken;

  Map<String, dynamic> toJson() => _$SearchBuildsResponseToJson(this);
}

@JsonSerializable()
class ScheduleBuildRequest implements Jsonable {
  const ScheduleBuildRequest({
    this.requestId,
    this.builderId,
    this.canary,
    this.experimental,
    this.properties,
    this.tags,
  });

  static ScheduleBuildRequest fromJson(Map<String, dynamic> json) => _$ScheduleBuildRequestFromJson(json);

  @JsonKey(name: 'requestId')
  final String requestId;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  @JsonKey(name: 'canary')
  final Trinary canary;

  @JsonKey(name: 'experimental')
  final Trinary experimental;

  @JsonKey(name: 'properties')
  final Map<String, String> properties;

  @JsonKey(name: 'tags', toJson: tagsToJson, fromJson: tagsFromJson)
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => _$ScheduleBuildRequestToJson(this);
}

@JsonSerializable()
class Build implements Jsonable {
  const Build({
    this.id,
    this.builderId,
    this.number,
    this.createdBy,
    this.canceledBy,
    this.startTime,
    this.endTime,
    this.status,
    this.tags,
    this.input,
  });

  static Build fromJson(Map<String, dynamic> json) => _$BuildFromJson(json);

  @JsonKey(name: 'id', fromJson: int.parse, toJson: _intToString)
  final int id;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  @JsonKey(name: 'number')
  final int number;

  @JsonKey(name: 'createdBy')
  final String createdBy;

  @JsonKey(name: 'canceledBy')
  final String canceledBy;

  @JsonKey(name: 'startTime')
  final DateTime startTime;

  @JsonKey(name: 'endTime')
  final DateTime endTime;

  @JsonKey(name: 'status')
  final Status status;

  @JsonKey(name: 'tags', toJson: tagsToJson, fromJson: tagsFromJson)
  final Map<String, String> tags;

  @JsonKey(name: 'input')
  final Input input;

  Map<String, dynamic> toJson() => _$BuildToJson(this);
}

@JsonSerializable()
class BuilderId implements Jsonable {
  const BuilderId({
    this.project,
    this.bucket,
    this.builder,
  });

  static BuilderId fromJson(Map<String, dynamic> json) => _$BuilderIdFromJson(json);

  @JsonKey(name: 'project')
  final String project;

  @JsonKey(name: 'bucket')
  final String bucket;

  @JsonKey(name: 'builder')
  final String builder;

  Map<String, dynamic> toJson() => _$BuilderIdToJson(this);
}

@JsonSerializable()
class Input implements Jsonable {
  const Input({
    this.properties,
    this.gitilesCommit,
    this.experimental,
  });

  static Input fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  @JsonKey(name: 'properties')
  final Map<String, String> properties;

  @JsonKey(name: 'gitilesCommit')
  final GitilesCommit gitilesCommit;

  @JsonKey(name: 'experimental')
  final Trinary experimental;

  Map<String, dynamic> toJson() => _$InputToJson(this);
}

@JsonSerializable()
class GitilesCommit implements Jsonable {
  const GitilesCommit({
    this.host,
    this.project,
    this.ref,
    this.hash,
  });

  static GitilesCommit fromJson(Map<String, dynamic> json) => _$GitilesCommitFromJson(json);

  @JsonKey(name: 'host')
  final String host;

  @JsonKey(name: 'project')
  final String project;

  @JsonKey(name: 'id')
  final String hash;

  @JsonKey(name: 'ref')
  final String ref;

  Map<String, dynamic> toJson() => _$GitilesCommitToJson(this);
}

enum Status {
  @JsonValue('STATUS_UNSPECIFIED')
  unspecified,
  @JsonValue('SCHEDULED')
  scheduled,

  /// A mask of `succes | failure | infraFailure | canceled`.
  @JsonValue('ENDED_MASK')
  ended,
  @JsonValue('SUCCESS')
  success,
  @JsonValue('FAILURE')
  failure,
  @JsonValue('INFRA_FAILURE')
  infraFailure,
  @JsonValue('CANCELED')
  canceled,
}

// This type doesn't quite map to a bool, because there are actually four states
// when you include whether it's present or not.
enum Trinary {
  @JsonValue('YES')
  yes,
  @JsonValue('NO')
  no,
  @JsonValue('UNSET')
  unset,
}
