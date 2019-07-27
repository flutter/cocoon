// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../request_handling/api_response.dart';

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

@JsonSerializable()
class BatchRequest implements ApiResponse {
  const BatchRequest({
    this.requests,
  });

  static BatchRequest fromJson(Map<String, dynamic> json) => _$BatchRequestFromJson(json);

  final List<Request> requests;

  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);
}

@JsonSerializable()
class Request implements ApiResponse {
  /// Only one of these should be set.
  const Request({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  });

  static Request fromJson(Map<String, dynamic> json) => _$RequestFromJson(json);

  final GetBuildRequest getBuild;

  final SearchBuildsRequest searchBuilds;

  final ScheduleBuildRequest scheduleBuild;

  final CancelBuildRequest cancelBuild;

  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

@JsonSerializable()
class BatchResponse implements ApiResponse {
  const BatchResponse({
    this.responses,
  });

  static BatchResponse fromJson(Map<String, dynamic> json) => _$BatchResponseFromJson(json);

  final List<Response> responses;

  Map<String, dynamic> toJson() => _$BatchResponseToJson(this);
}

@JsonSerializable()
class Response implements ApiResponse {
  /// Only one of these should be set.
  const Response({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  });

  static Response fromJson(Map<String, dynamic> json) => _$ResponseFromJson(json);

  final Build getBuild;

  final SearchBuildsResponse searchBuilds;

  final Build scheduleBuild;

  final Build cancelBuild;

  Map<String, dynamic> toJson() => _$ResponseToJson(this);
}

@JsonSerializable()
class GetBuildRequest implements ApiResponse {
  const GetBuildRequest({
    this.id,
    this.builderId,
    this.buildNumber,
  });

  static GetBuildRequest fromJson(Map<String, dynamic> json) => _$GetBuildRequestFromJson(json);

  @JsonKey(fromJson: int.parse, toJson: _intToString)
  final int id;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  final int buildNumber;

  Map<String, dynamic> toJson() => _$GetBuildRequestToJson(this);
}

@JsonSerializable()
class CancelBuildRequest implements ApiResponse {
  const CancelBuildRequest({
    @required this.id,
    @required this.summaryMarkdown,
  })  : assert(id != null),
        assert(summaryMarkdown != null);

  static CancelBuildRequest fromJson(Map<String, dynamic> json) => _$CancelBuildRequestFromJson(json);

  @JsonKey(fromJson: int.parse, toJson: _intToString, nullable: false, required: true)
  final int id;

  @JsonKey(nullable: false, required: true)
  final String summaryMarkdown;

  Map<String, dynamic> toJson() => _$CancelBuildRequestToJson(this);
}

@JsonSerializable()
class SearchBuildsRequest implements ApiResponse {
  const SearchBuildsRequest({
    this.predicate,
    this.pageSize,
    this.pageToken,
  });

  static SearchBuildsRequest fromJson(Map<String, dynamic> json) => _$SearchBuildsRequestFromJson(json);

  final BuildPredicate predicate;

  final int pageSize;

  final String pageToken;

  Map<String, dynamic> toJson() => _$SearchBuildsRequestToJson(this);
}

@JsonSerializable()
class BuildPredicate implements ApiResponse {
  const BuildPredicate({
    this.builderId,
    this.status,
    this.createdBy,
    this.tags,
  });

  static BuildPredicate fromJson(Map<String, dynamic> json) => _$BuildPredicateFromJson(json);

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  final Status status;

  final String createdBy;

  @JsonKey(toJson: tagsToJson, fromJson: tagsFromJson)
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => _$BuildPredicateToJson(this);
}

@JsonSerializable()
class SearchBuildsResponse implements ApiResponse {
  const SearchBuildsResponse({
    this.builds,
    this.nextPageToken,
  });

  static SearchBuildsResponse fromJson(Map<String, dynamic> json) => _$SearchBuildsResponseFromJson(json);

  final List<Build> builds;

  final String nextPageToken;

  Map<String, dynamic> toJson() => _$SearchBuildsResponseToJson(this);
}

@JsonSerializable()
class ScheduleBuildRequest implements ApiResponse {
  const ScheduleBuildRequest({
    this.requestId,
    this.builderId,
    this.canary,
    this.experimental,
    this.properties,
    this.tags,
  });

  static ScheduleBuildRequest fromJson(Map<String, dynamic> json) => _$ScheduleBuildRequestFromJson(json);

  final String requestId;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  final Trinary canary;

  final Trinary experimental;

  final Map<String, String> properties;

  @JsonKey(toJson: tagsToJson, fromJson: tagsFromJson)
  final Map<String, String> tags;

  Map<String, dynamic> toJson() => _$ScheduleBuildRequestToJson(this);
}

@JsonSerializable()
class Build implements ApiResponse {
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

  @JsonKey(fromJson: int.parse, toJson: _intToString)
  final int id;

  @JsonKey(name: 'builder')
  final BuilderId builderId;

  final int number;

  final String createdBy;

  final String canceledBy;

  final DateTime startTime;

  final DateTime endTime;

  final Status status;

  @JsonKey(toJson: tagsToJson, fromJson: tagsFromJson)
  final Map<String, String> tags;

  final Input input;

  Map<String, dynamic> toJson() => _$BuildToJson(this);
}

@JsonSerializable()
class BuilderId implements ApiResponse {
  const BuilderId({
    this.project,
    this.bucket,
    this.builder,
  });

  static BuilderId fromJson(Map<String, dynamic> json) => _$BuilderIdFromJson(json);

  final String project;

  final String bucket;

  final String builder;

  Map<String, dynamic> toJson() => _$BuilderIdToJson(this);
}

@JsonSerializable()
class Input implements ApiResponse {
  const Input({
    this.properties,
    this.gitilesCommit,
    this.experimental,
  });

  static Input fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  final Map<String, String> properties;

  final GitilesCommit gitilesCommit;

  final Trinary experimental;

  Map<String, dynamic> toJson() => _$InputToJson(this);
}

@JsonSerializable()
class GitilesCommit implements ApiResponse {
  const GitilesCommit({
    this.host,
    this.project,
    this.ref,
    this.hash,
  });

  static GitilesCommit fromJson(Map<String, dynamic> json) => _$GitilesCommitFromJson(json);

  final String host;

  final String project;

  @JsonKey(name: 'id')
  final String hash;

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
