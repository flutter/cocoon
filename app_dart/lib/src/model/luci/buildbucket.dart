// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

import '../../request_handling/body.dart';

part 'buildbucket.g.dart';

// The classes in this file are based on protos found in:
// https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/build.proto
// https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/common.proto
// https://chromium.googlesource.com/infra/luci/luci-go/+/master/buildbucket/proto/rpc.proto
//
// The `fromJson` methods in this class are static rather than factories so that
// they can be passed as arguments to other functions looking for a parser.

/// A converter for tags.
///
/// The JSON format is:
///
/// ```json
/// [
///   {
///     "key": "tag_key",
///     "value": "tag_value"
///   }
/// ]
/// ```
///
/// Which is flattened out as a `Map<String, List<String>>`.
class TagsConverter implements JsonConverter<Map<String, List<String>>, List<dynamic>> {
  const TagsConverter();

  @override
  Map<String, List<String>> fromJson(List<dynamic> json) {
    if (json == null) {
      return null;
    }
    final Map<String, List<String>> result = <String, List<String>>{};
    for (Map<String, dynamic> tag in json.cast<Map<String, dynamic>>()) {
      result[tag['key']] ??= <String>[];
      result[tag['key']].add(tag['value']);
    }
    return result;
  }

  @override
  List<Map<String, dynamic>> toJson(Map<String, List<String>> object) {
    if (object == null) {
      return null;
    }
    if (object.isEmpty) {
      return const <Map<String, List<String>>>[];
    }
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (String key in object.keys) {
      for (String value in object[key]) {
        result.add(<String, String>{
          'key': key,
          'value': value,
        });
      }
    }
    return result;
  }
}

/// A convert for BuildBucket IDs.
///
/// These are int64s, which are not safely representable as JSON numbers.
///
/// In JSON format, they're converted to Strings, but they're always int64s,
/// which are safe to use in the Dart VM.
class _Int64Converter implements JsonConverter<int, String> {
  const _Int64Converter();

  @override
  int fromJson(String json) {
    return int.parse(json);
  }

  @override
  String toJson(int object) {
    return object.toString();
  }
}

/// A request for the Batch RPC.
///
/// This message can be used to find, get, schedule, or cancle multiple builds.
@JsonSerializable()
class BatchRequest implements Body {
  /// Creates a request for the Batch RPC.
  const BatchRequest({
    this.requests,
  });

  /// Creates a [BatchRequest] from JSON.
  static BatchRequest fromJson(Map<String, dynamic> json) => _$BatchRequestFromJson(json);

  /// The batch of [Request]s to make.
  final List<Request> requests;

  @override
  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);
}

/// A container for one request in a batch.
///
/// A single request must contain only one object.
@JsonSerializable()
class Request implements Body {
  /// Creates a request for the Batch RPC.
  ///
  /// One and only one argument should be set.
  const Request({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  }) : assert((getBuild != null &&
                searchBuilds == null &&
                scheduleBuild == null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds != null &&
                scheduleBuild == null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds == null &&
                scheduleBuild != null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds == null &&
                scheduleBuild == null &&
                cancelBuild != null));

  /// Creates a [Request] object from JSON.
  static Request fromJson(Map<String, dynamic> json) => _$RequestFromJson(json);

  /// A request to get build information.
  final GetBuildRequest getBuild;

  /// A request to find builds.
  final SearchBuildsRequest searchBuilds;

  /// A request to schedule a build.
  ///
  /// All schedule build requests are executed before other requests by LUCI.
  final ScheduleBuildRequest scheduleBuild;

  /// A request to cancel a build.
  final CancelBuildRequest cancelBuild;

  @override
  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

/// A response from the Batch RPC.
@JsonSerializable()
class BatchResponse implements Body {
  /// Creates a response for the Batch RPC.
  const BatchResponse({
    this.responses,
  });

  /// Creates a [BatchResponse] from JSON.
  static BatchResponse fromJson(Map<String, dynamic> json) => _$BatchResponseFromJson(json);

  /// The collected responses from the Batch request.
  final List<Response> responses;

  @override
  Map<String, dynamic> toJson() => _$BatchResponseToJson(this);
}

/// An individual response from a batch request.
@JsonSerializable()
class Response implements Body {
  /// Creates a response for the response from the Batch RPC.
  ///
  /// One and only one of these should be set.
  const Response({
    this.getBuild,
    this.searchBuilds,
    this.scheduleBuild,
    this.cancelBuild,
  }) : assert((getBuild != null &&
                searchBuilds == null &&
                scheduleBuild == null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds != null &&
                scheduleBuild == null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds == null &&
                scheduleBuild != null &&
                cancelBuild == null) ||
            (getBuild == null &&
                searchBuilds == null &&
                scheduleBuild == null &&
                cancelBuild != null));

  /// Creates a [Response] from JSON.
  static Response fromJson(Map<String, dynamic> json) => _$ResponseFromJson(json);

  /// The [Build] response corresponding to a getBuild request.
  final Build getBuild;

  /// The [SearchBuildsResponse] corresponding to a searchBuilds request.
  final SearchBuildsResponse searchBuilds;

  /// The [Build] response corresponding to a scheduleBuild request.
  final Build scheduleBuild;

  /// The [Build] response corresponding to a cancelBuild request.
  final Build cancelBuild;

  @override
  Map<String, dynamic> toJson() => _$ResponseToJson(this);
}

/// A request for the GetBuild RPC.
@JsonSerializable()
class GetBuildRequest implements Body {
  /// Creates a request for the GetBuild RPC.
  const GetBuildRequest({
    this.id,
    this.builderId,
    this.buildNumber,
  }) : assert((id == null && builderId != null && buildNumber != null) ||
            (id != null && builderId == null && buildNumber == null));

  /// Creates a [GetBuildRequest] from JSON.
  static GetBuildRequest fromJson(Map<String, dynamic> json) => _$GetBuildRequestFromJson(json);

  /// The BuildBucket build ID.
  ///
  /// If specified, [builderId] and [buildNumber] must be null.
  @_Int64Converter()
  final int id;

  /// The BuildBucket [BuilderId].
  ///
  /// If specified, [buildNumber] must be specified, and [id] must be null.
  @JsonKey(name: 'builder')
  final BuilderId builderId;

  /// The BuildBucket build number.
  ///
  /// If specified, [builderId] must be specified, and [id] must be null.
  final int buildNumber;

  @override
  Map<String, dynamic> toJson() => _$GetBuildRequestToJson(this);
}

/// A request for the CancelBuild RPC.
@JsonSerializable()
class CancelBuildRequest implements Body {
  /// Creates a request object for the CancelBuild RPC.
  ///
  /// Both [id] and [summaryMarkdown] are required.
  const CancelBuildRequest({
    @required this.id,
    @required this.summaryMarkdown,
  })  : assert(id != null),
        assert(summaryMarkdown != null);

  /// Creates a [CancelBuildRequest] from JSON.
  static CancelBuildRequest fromJson(Map<String, dynamic> json) =>
      _$CancelBuildRequestFromJson(json);

  /// The BuildBucket ID for the build to cancel.
  @JsonKey(nullable: false, required: true)
  @_Int64Converter()
  final int id;

  /// A summary of the reason for canceling.
  @JsonKey(nullable: false, required: true)
  final String summaryMarkdown;

  @override
  Map<String, dynamic> toJson() => _$CancelBuildRequestToJson(this);
}

/// A request object for the SearchBuilds RPC.
@JsonSerializable()
class SearchBuildsRequest implements Body {
  /// Creates a request object for the SearchBuilds RPC.
  ///
  /// The [predicate] is required.
  ///
  /// The [pageSize] defaults to 100 if not specified.
  ///
  /// The [pageToken] from a previous request can be used to page through
  /// results.
  const SearchBuildsRequest({
    @required this.predicate,
    this.pageSize,
    this.pageToken,
  }) : assert(predicate != null);

  /// Creates a [SearchBuildsReqeuest] object from JSON.
  static SearchBuildsRequest fromJson(Map<String, dynamic> json) =>
      _$SearchBuildsRequestFromJson(json);

  /// The predicate for searching.
  final BuildPredicate predicate;

  /// The number of builds to return per request.  Defaults to 100.
  ///
  /// Any value over 1000 is treated as 1000.
  final int pageSize;

  /// The value of the [SearchBuildsResponse.nextPageToken] from a previous ]
  /// request.
  ///
  /// This can be used to continue paging through results when there are more
  /// than [pageSize] builds available.
  final String pageToken;

  @override
  Map<String, dynamic> toJson() => _$SearchBuildsRequestToJson(this);
}

/// A predicate to apply when searching for builds in the SearchBuilds RPC.
@JsonSerializable()
class BuildPredicate implements Body {
  /// Creates a predicate to apply when searching for builds in the SearchBuilds
  /// RPC.
  ///
  /// All items specified must match for the predicate to return.
  const BuildPredicate({
    this.builderId,
    this.status,
    this.createdBy,
    this.tags,
  });

  /// Creates a [BuildPredicate] from JSON.
  static BuildPredicate fromJson(Map<String, dynamic> json) => _$BuildPredicateFromJson(json);

  /// The [BuilderId] to search for.
  @JsonKey(name: 'builder')
  final BuilderId builderId;

  /// The [Status] to search for.
  final Status status;

  /// Used to find builds created by the specified user.
  final String createdBy;

  /// Used to return builds containing all of the specified tags.
  @TagsConverter()
  final Map<String, List<String>> tags;

  @override
  Map<String, dynamic> toJson() => _$BuildPredicateToJson(this);
}

/// The response object from a SearchBuilds RPC.
@JsonSerializable()
class SearchBuildsResponse implements Body {
  /// Creates a new response object from the SearchBuilds RPC.
  ///
  /// The [nextPageToken] can be used to coninue searching if there are more
  /// builds available than the [pageSize] of the request (which is always
  /// capped at 1000). It will be null if no further builds are available.
  const SearchBuildsResponse({
    this.builds,
    this.nextPageToken,
  });

  /// Creates a [SearchBuildsResponse] from JSON.
  static SearchBuildsResponse fromJson(Map<String, dynamic> json) =>
      _$SearchBuildsResponseFromJson(json);

  /// The [Build]s returned by the search.
  final List<Build> builds;

  /// A token that can be used as the [SearchBuildsRequest.pageToken].
  ///
  /// This value will only be specified if further results are available;
  /// otherwise, it will be null.
  final String nextPageToken;

  @override
  Map<String, dynamic> toJson() => _$SearchBuildsResponseToJson(this);
}

/// A request object for the ScheduleBuild RPC.
@JsonSerializable()
class ScheduleBuildRequest implements Body {
  /// Creates a new request object for the ScheduleBuild RPC.
  ///
  /// The [requestId] is "strongly recommended", and is used by the back end to
  /// deduplicate recent requests.
  ///
  /// The [builderId] is required.
  const ScheduleBuildRequest({
    this.requestId,
    @required this.builderId,
    this.canary,
    this.experimental,
    this.gitilesCommit,
    this.properties,
    this.tags,
  }) : assert(builderId != null);

  /// Creates a [ScheduleBuildRequest] from JSON.
  static ScheduleBuildRequest fromJson(Map<String, dynamic> json) =>
      _$ScheduleBuildRequestFromJson(json);

  /// A unique identifier per request that is used by the backend to deduplicate
  /// requests.
  ///
  /// This is "strongly recommended", but not required.
  final String requestId;

  /// The [BuilderId] to schedule on. Required.
  @JsonKey(name: 'builder')
  final BuilderId builderId;

  /// If specified, overrides the server-defined value of
  /// Build.infra.buildbucket.canary.
  final Trinary canary;

  /// If specified, overrides the server-defined value of
  /// Build.input.experimental.
  ///
  /// This value comes into the recipe as `api.runtime.is_experimental`.
  final Trinary experimental;

  /// Properties to include in Build.input.properties.
  /// Input properties of the created build are result of merging server-defined
  /// properties and properties in this field.
  /// Each property in this field defines a new or replaces an existing property
  /// on the server.
  /// If the server config does not allow overriding/adding the property, the
  /// request will fail with InvalidArgument error code.
  /// A server-defined property cannot be removed, but its value can be
  /// replaced with null.
  ///
  /// Reserved property paths:
  /// * ["buildbucket"]
  /// * ["buildername"]
  /// * ["blamelist""]
  /// * ["$recipe_engine/runtime", "is_luci"]
  /// * ["$recipe_engine/runtime", "is_experimental"]
  final Map<String, String> properties;

  /// The value for Build.input.gitiles_commit.
  ///
  /// Setting this field will cause the created build to have a "buildset"
  /// tag with value "commit/gitiles/{hostname}/{project}/+/{id}".
  ///
  /// GitilesCommit objects MUST have host, project, ref fields set.
  final GitilesCommit gitilesCommit;

  /// Tags to include in Build.tags of the created build.
  ///
  /// Note: tags of the created build may include other tags defined on the
  /// server.
  @TagsConverter()
  final Map<String, List<String>> tags;

  @override
  Map<String, dynamic> toJson() => _$ScheduleBuildRequestToJson(this);
}

/// A single build, identified by an int64 [id], belonging to a builder.
///
/// See also:
///   * [BuilderId]
///   * [GetBuildRequest]
@JsonSerializable()
class Build implements Body {
  /// Creates a build object.
  ///
  /// The [id] and [builderId] parameter is required.
  const Build({
    @required this.id,
    @required this.builderId,
    this.number,
    this.createdBy,
    this.canceledBy,
    this.startTime,
    this.endTime,
    this.status,
    this.tags,
    this.input,
    this.summaryMarkdown,
    this.critical,
  })  : assert(id != null),
        assert(builderId != null);

  /// Creates a [Build] object from JSON.
  static Build fromJson(Map<String, dynamic> json) => _$BuildFromJson(json);

  /// The BuildBucket ID for the build. Required.
  @_Int64Converter()
  final int id;

  /// The [BuilderId] for the build.  Required.
  @JsonKey(name: 'builder')
  final BuilderId builderId;

  /// The LUCI build number for the build.
  ///
  /// This number corresponds to the order of builds, but build numbers may have
  /// gaps.
  final int number;

  /// The verified LUCI identity that created the build.
  final String createdBy;

  /// The verified LUCI identity that canceled the build.
  final String canceledBy;

  /// The start time of the build.
  ///
  /// Required if and only if the [status] is [Status.started], [Status.success],
  /// or [Status.failure].
  final DateTime startTime;

  /// The end time of the build.
  ///
  /// Required if and only if the [status] is terminal. Must not be before
  /// [startTime].
  final DateTime endTime;

  /// The build status.
  ///
  /// Must be specified, and must not be [Status.unspecified].
  final Status status;

  /// Human readable summary of the build in Markdown format.
  ///
  /// Up to 4kb.
  final String summaryMarkdown;

  /// Arbitrary annotations for the build.
  ///
  /// The same key for a tag may be used multiple times.
  @TagsConverter()
  final Map<String, List<String>> tags;

  /// If [Trinary.no], then the build status should not be used to assess the
  /// correctness of the input gitilesCommit or gerritChanges.
  final Trinary critical;

  /// The build input values.
  final Input input;

  @override
  Map<String, dynamic> toJson() => _$BuildToJson(this);
}

/// A unique handle to a builder on BuildBucket.
@JsonSerializable()
class BuilderId implements Body {
  /// Creates a unique handle to a builder on BuildBucket.
  ///
  /// The bucket and builder control what ACLs for the infra, as specified in
  /// cr-buildbucket.cfg.
  const BuilderId({
    this.project,
    this.bucket,
    this.builder,
  });

  /// Creates a [BuilderId] object from JSON.
  static BuilderId fromJson(Map<String, dynamic> json) => _$BuilderIdFromJson(json);

  /// The project, e.g. "flutter", for the builder.
  final String project;

  /// The bucket, e.g. "try" or "prod", for the builder.
  ///
  /// By convention, "prod" is for assets that will be released, "ci" is for
  /// reviewed code, and "try" is for untrusted code.
  final String bucket;

  /// The builder from cr-buildbucket.cfg, e.g. "Linux" or "Linux Host Engine".
  final String builder;

  @override
  Map<String, dynamic> toJson() => _$BuilderIdToJson(this);
}

/// The build inputs for a build.
@JsonSerializable()
class Input implements Body {
  /// Creates a set of build inputs for a build.
  const Input({
    this.properties,
    this.gitilesCommit,
    this.experimental,
  });

  /// Creates an [Input] object from JSON.
  static Input fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

  /// The build properties of a build.
  final Map<String, String> properties;

  /// The [GitilesCommit] information for a build.
  final GitilesCommit gitilesCommit;

  /// Whether the build is experimental or not. Passed into the recipe as
  /// `api.runtime.is_experimental`.
  final Trinary experimental;

  @override
  Map<String, dynamic> toJson() => _$InputToJson(this);
}

/// A landed Git commit hosted on Gitiles.
@JsonSerializable()
class GitilesCommit implements Body {
  /// Creates a object corresponding to a landed Git commit hosted on Gitiles.
  const GitilesCommit({
    this.host,
    this.project,
    this.ref,
    this.hash,
  });

  /// Creates a [GitilesCommit] object from JSON.
  static GitilesCommit fromJson(Map<String, dynamic> json) => _$GitilesCommitFromJson(json);

  /// The Gitiles host name, e.g. "chromium.googlesource.com"
  final String host;

  /// The repository name on the host, e.g. "externa/github.com/flutter/flutter".
  final String project;

  /// The Git hash of the commit.
  @JsonKey(name: 'id')
  final String hash;

  /// The Git ref of the commit, e.g. "refs/heads/master".
  final String ref;

  @override
  Map<String, dynamic> toJson() => _$GitilesCommitToJson(this);
}

/// Build status values.
enum Status {
  /// Should not be used.
  @JsonValue('STATUS_UNSPECIFIED')
  unspecified,

  /// The status of a scheduled or pending build.
  @JsonValue('SCHEDULED')
  scheduled,

  /// The status of a started (running) build.
  @JsonValue('STARTED')
  started,

  /// A mask of `succes | failure | infraFailure | canceled`.
  @JsonValue('ENDED_MASK')
  ended,

  /// The build has successfully completed.
  @JsonValue('SUCCESS')
  success,

  /// The build has failed to complete some step due to a faulty test or commit.
  @JsonValue('FAILURE')
  failure,

  /// The build has failed due to an infrastructure related failure.
  @JsonValue('INFRA_FAILURE')
  infraFailure,

  /// The build was canceled.
  @JsonValue('CANCELED')
  canceled,
}

/// This type doesn't quite map to a bool, because there are actually four states
/// when you include whether it's present or not.
enum Trinary {
  /// A true value.
  @JsonValue('YES')
  yes,

  /// A false value.
  @JsonValue('NO')
  no,

  /// An explicit null value, which may or may not be treated differently from
  /// setting the JSON field to null.
  @JsonValue('UNSET')
  unset,
}
