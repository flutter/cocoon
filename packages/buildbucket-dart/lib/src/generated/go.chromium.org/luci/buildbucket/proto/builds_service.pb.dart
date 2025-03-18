//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builds_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $8;
import '../../../../google/protobuf/field_mask.pb.dart' as $3;
import '../../../../google/protobuf/struct.pb.dart' as $5;
import '../../../../google/rpc/status.pb.dart' as $4;
import '../../common/proto/structmask/structmask.pb.dart' as $9;
import 'build.pb.dart' as $1;
import 'builder_common.pb.dart' as $2;
import 'common.pb.dart' as $6;
import 'common.pbenum.dart' as $6;
import 'notification.pb.dart' as $7;

/// A request message for GetBuild RPC.
class GetBuildRequest extends $pb.GeneratedMessage {
  factory GetBuildRequest({
    $fixnum.Int64? id,
    $2.BuilderID? builder,
    $core.int? buildNumber,
    @$core.Deprecated('This field is deprecated.') $3.FieldMask? fields,
    BuildMask? mask,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    if (buildNumber != null) {
      $result.buildNumber = buildNumber;
    }
    if (fields != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.fields = fields;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  GetBuildRequest._() : super();
  factory GetBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder',
        subBuilder: $2.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetBuildRequest clone() => GetBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetBuildRequest copyWith(void Function(GetBuildRequest) updates) =>
      super.copyWith((message) => updates(message as GetBuildRequest))
          as GetBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBuildRequest create() => GetBuildRequest._();
  GetBuildRequest createEmptyInstance() => create();
  static $pb.PbList<GetBuildRequest> createRepeated() =>
      $pb.PbList<GetBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBuildRequest>(create);
  static GetBuildRequest? _defaultInstance;

  /// Build ID.
  /// Mutually exclusive with builder and number.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Builder of the build.
  /// Requires number. Mutually exclusive with id.
  @$pb.TagNumber(2)
  $2.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($2.BuilderID v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $2.BuilderID ensureBuilder() => $_ensure(1);

  /// Build number.
  /// Requires builder. Mutually exclusive with id.
  @$pb.TagNumber(3)
  $core.int get buildNumber => $_getIZ(2);
  @$pb.TagNumber(3)
  set buildNumber($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBuildNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuildNumber() => clearField(3);

  ///  Fields to include in the response.
  ///
  ///  DEPRECATED: Use mask instead.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  ///
  ///  Supports advanced semantics, see
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/f9ae69a37c4bdd0e08a8b0f7e123f6e403e774eb/appengine/components/components/protoutil/field_masks.py#7
  ///  In particular, if the client needs only some output properties, they
  ///  can be requested with paths "output.properties.fields.foo".
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask get fields => $_getN(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  set fields($3.FieldMask v) {
    setField(100, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $core.bool hasFields() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  void clearFields() => clearField(100);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask ensureFields() => $_ensure(3);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(101)
  BuildMask get mask => $_getN(4);
  @$pb.TagNumber(101)
  set mask(BuildMask v) {
    setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasMask() => $_has(4);
  @$pb.TagNumber(101)
  void clearMask() => clearField(101);
  @$pb.TagNumber(101)
  BuildMask ensureMask() => $_ensure(4);
}

/// A request message for SearchBuilds RPC.
class SearchBuildsRequest extends $pb.GeneratedMessage {
  factory SearchBuildsRequest({
    BuildPredicate? predicate,
    @$core.Deprecated('This field is deprecated.') $3.FieldMask? fields,
    $core.int? pageSize,
    $core.String? pageToken,
    BuildMask? mask,
  }) {
    final $result = create();
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (fields != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.fields = fields;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  SearchBuildsRequest._() : super();
  factory SearchBuildsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchBuildsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchBuildsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<BuildPredicate>(1, _omitFieldNames ? '' : 'predicate',
        subBuilder: BuildPredicate.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..a<$core.int>(101, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(102, _omitFieldNames ? '' : 'pageToken')
    ..aOM<BuildMask>(103, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchBuildsRequest clone() => SearchBuildsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchBuildsRequest copyWith(void Function(SearchBuildsRequest) updates) =>
      super.copyWith((message) => updates(message as SearchBuildsRequest))
          as SearchBuildsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchBuildsRequest create() => SearchBuildsRequest._();
  SearchBuildsRequest createEmptyInstance() => create();
  static $pb.PbList<SearchBuildsRequest> createRepeated() =>
      $pb.PbList<SearchBuildsRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchBuildsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchBuildsRequest>(create);
  static SearchBuildsRequest? _defaultInstance;

  /// Returned builds must satisfy this predicate. Required.
  @$pb.TagNumber(1)
  BuildPredicate get predicate => $_getN(0);
  @$pb.TagNumber(1)
  set predicate(BuildPredicate v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPredicate() => $_has(0);
  @$pb.TagNumber(1)
  void clearPredicate() => clearField(1);
  @$pb.TagNumber(1)
  BuildPredicate ensurePredicate() => $_ensure(0);

  ///  Fields to include in the response, see GetBuildRequest.fields.
  ///
  ///  DEPRECATED: Use mask instead.
  ///
  ///  Note that this applies to the response, not each build, so e.g. steps must
  ///  be requested with a path "builds.*.steps".
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask get fields => $_getN(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  set fields($3.FieldMask v) {
    setField(100, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $core.bool hasFields() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  void clearFields() => clearField(100);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask ensureFields() => $_ensure(1);

  /// Number of builds to return.
  /// Defaults to 100.
  /// Any value >1000 is interpreted as 1000.
  @$pb.TagNumber(101)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(101)
  set pageSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(101)
  void clearPageSize() => clearField(101);

  /// Value of SearchBuildsResponse.next_page_token from the previous response.
  /// Use it to continue searching.
  /// The predicate and page_size in this request MUST be exactly same as in the
  /// previous request.
  @$pb.TagNumber(102)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(102)
  set pageToken($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(102)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(102)
  void clearPageToken() => clearField(102);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(103)
  BuildMask get mask => $_getN(4);
  @$pb.TagNumber(103)
  set mask(BuildMask v) {
    setField(103, v);
  }

  @$pb.TagNumber(103)
  $core.bool hasMask() => $_has(4);
  @$pb.TagNumber(103)
  void clearMask() => clearField(103);
  @$pb.TagNumber(103)
  BuildMask ensureMask() => $_ensure(4);
}

/// A response message for SearchBuilds RPC.
class SearchBuildsResponse extends $pb.GeneratedMessage {
  factory SearchBuildsResponse({
    $core.Iterable<$1.Build>? builds,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (builds != null) {
      $result.builds.addAll(builds);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  SearchBuildsResponse._() : super();
  factory SearchBuildsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchBuildsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SearchBuildsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..pc<$1.Build>(1, _omitFieldNames ? '' : 'builds', $pb.PbFieldType.PM,
        subBuilder: $1.Build.create)
    ..aOS(100, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchBuildsResponse clone() =>
      SearchBuildsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchBuildsResponse copyWith(void Function(SearchBuildsResponse) updates) =>
      super.copyWith((message) => updates(message as SearchBuildsResponse))
          as SearchBuildsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchBuildsResponse create() => SearchBuildsResponse._();
  SearchBuildsResponse createEmptyInstance() => create();
  static $pb.PbList<SearchBuildsResponse> createRepeated() =>
      $pb.PbList<SearchBuildsResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchBuildsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SearchBuildsResponse>(create);
  static SearchBuildsResponse? _defaultInstance;

  ///  Search results.
  ///
  ///  Ordered by build ID, descending. IDs are monotonically decreasing, so in
  ///  other words the order is newest-to-oldest.
  @$pb.TagNumber(1)
  $core.List<$1.Build> get builds => $_getList(0);

  /// Value for SearchBuildsRequest.page_token to continue searching.
  @$pb.TagNumber(100)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(100)
  set nextPageToken($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(100)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(100)
  void clearNextPageToken() => clearField(100);
}

enum BatchRequest_Request_Request {
  getBuild,
  searchBuilds,
  scheduleBuild,
  cancelBuild,
  getBuildStatus,
  notSet
}

/// One request in a batch.
class BatchRequest_Request extends $pb.GeneratedMessage {
  factory BatchRequest_Request({
    GetBuildRequest? getBuild,
    SearchBuildsRequest? searchBuilds,
    ScheduleBuildRequest? scheduleBuild,
    CancelBuildRequest? cancelBuild,
    GetBuildStatusRequest? getBuildStatus,
  }) {
    final $result = create();
    if (getBuild != null) {
      $result.getBuild = getBuild;
    }
    if (searchBuilds != null) {
      $result.searchBuilds = searchBuilds;
    }
    if (scheduleBuild != null) {
      $result.scheduleBuild = scheduleBuild;
    }
    if (cancelBuild != null) {
      $result.cancelBuild = cancelBuild;
    }
    if (getBuildStatus != null) {
      $result.getBuildStatus = getBuildStatus;
    }
    return $result;
  }
  BatchRequest_Request._() : super();
  factory BatchRequest_Request.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchRequest_Request.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BatchRequest_Request_Request>
      _BatchRequest_Request_RequestByTag = {
    1: BatchRequest_Request_Request.getBuild,
    2: BatchRequest_Request_Request.searchBuilds,
    3: BatchRequest_Request_Request.scheduleBuild,
    4: BatchRequest_Request_Request.cancelBuild,
    5: BatchRequest_Request_Request.getBuildStatus,
    0: BatchRequest_Request_Request.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchRequest.Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<GetBuildRequest>(1, _omitFieldNames ? '' : 'getBuild',
        subBuilder: GetBuildRequest.create)
    ..aOM<SearchBuildsRequest>(2, _omitFieldNames ? '' : 'searchBuilds',
        subBuilder: SearchBuildsRequest.create)
    ..aOM<ScheduleBuildRequest>(3, _omitFieldNames ? '' : 'scheduleBuild',
        subBuilder: ScheduleBuildRequest.create)
    ..aOM<CancelBuildRequest>(4, _omitFieldNames ? '' : 'cancelBuild',
        subBuilder: CancelBuildRequest.create)
    ..aOM<GetBuildStatusRequest>(5, _omitFieldNames ? '' : 'getBuildStatus',
        subBuilder: GetBuildStatusRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchRequest_Request clone() =>
      BatchRequest_Request()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchRequest_Request copyWith(void Function(BatchRequest_Request) updates) =>
      super.copyWith((message) => updates(message as BatchRequest_Request))
          as BatchRequest_Request;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchRequest_Request create() => BatchRequest_Request._();
  BatchRequest_Request createEmptyInstance() => create();
  static $pb.PbList<BatchRequest_Request> createRepeated() =>
      $pb.PbList<BatchRequest_Request>();
  @$core.pragma('dart2js:noInline')
  static BatchRequest_Request getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchRequest_Request>(create);
  static BatchRequest_Request? _defaultInstance;

  BatchRequest_Request_Request whichRequest() =>
      _BatchRequest_Request_RequestByTag[$_whichOneof(0)]!;
  void clearRequest() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  GetBuildRequest get getBuild => $_getN(0);
  @$pb.TagNumber(1)
  set getBuild(GetBuildRequest v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasGetBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearGetBuild() => clearField(1);
  @$pb.TagNumber(1)
  GetBuildRequest ensureGetBuild() => $_ensure(0);

  @$pb.TagNumber(2)
  SearchBuildsRequest get searchBuilds => $_getN(1);
  @$pb.TagNumber(2)
  set searchBuilds(SearchBuildsRequest v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSearchBuilds() => $_has(1);
  @$pb.TagNumber(2)
  void clearSearchBuilds() => clearField(2);
  @$pb.TagNumber(2)
  SearchBuildsRequest ensureSearchBuilds() => $_ensure(1);

  @$pb.TagNumber(3)
  ScheduleBuildRequest get scheduleBuild => $_getN(2);
  @$pb.TagNumber(3)
  set scheduleBuild(ScheduleBuildRequest v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasScheduleBuild() => $_has(2);
  @$pb.TagNumber(3)
  void clearScheduleBuild() => clearField(3);
  @$pb.TagNumber(3)
  ScheduleBuildRequest ensureScheduleBuild() => $_ensure(2);

  @$pb.TagNumber(4)
  CancelBuildRequest get cancelBuild => $_getN(3);
  @$pb.TagNumber(4)
  set cancelBuild(CancelBuildRequest v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCancelBuild() => $_has(3);
  @$pb.TagNumber(4)
  void clearCancelBuild() => clearField(4);
  @$pb.TagNumber(4)
  CancelBuildRequest ensureCancelBuild() => $_ensure(3);

  @$pb.TagNumber(5)
  GetBuildStatusRequest get getBuildStatus => $_getN(4);
  @$pb.TagNumber(5)
  set getBuildStatus(GetBuildStatusRequest v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasGetBuildStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearGetBuildStatus() => clearField(5);
  @$pb.TagNumber(5)
  GetBuildStatusRequest ensureGetBuildStatus() => $_ensure(4);
}

/// A request message for Batch RPC.
class BatchRequest extends $pb.GeneratedMessage {
  factory BatchRequest({
    $core.Iterable<BatchRequest_Request>? requests,
  }) {
    final $result = create();
    if (requests != null) {
      $result.requests.addAll(requests);
    }
    return $result;
  }
  BatchRequest._() : super();
  factory BatchRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..pc<BatchRequest_Request>(
        1, _omitFieldNames ? '' : 'requests', $pb.PbFieldType.PM,
        subBuilder: BatchRequest_Request.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchRequest clone() => BatchRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchRequest copyWith(void Function(BatchRequest) updates) =>
      super.copyWith((message) => updates(message as BatchRequest))
          as BatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchRequest create() => BatchRequest._();
  BatchRequest createEmptyInstance() => create();
  static $pb.PbList<BatchRequest> createRepeated() =>
      $pb.PbList<BatchRequest>();
  @$core.pragma('dart2js:noInline')
  static BatchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchRequest>(create);
  static BatchRequest? _defaultInstance;

  ///  Requests to execute in a single batch.
  ///
  ///  * All requests are executed in their own individual transactions.
  ///  * BatchRequest as a whole is not transactional.
  ///  * There's no guaranteed order of execution between batch items (i.e.
  ///    consider them to all operate independently).
  ///  * There is a limit of 200 requests per batch.
  @$pb.TagNumber(1)
  $core.List<BatchRequest_Request> get requests => $_getList(0);
}

enum BatchResponse_Response_Response {
  getBuild,
  searchBuilds,
  scheduleBuild,
  cancelBuild,
  getBuildStatus,
  error,
  notSet
}

/// Response a BatchRequest.Response.
class BatchResponse_Response extends $pb.GeneratedMessage {
  factory BatchResponse_Response({
    $1.Build? getBuild,
    SearchBuildsResponse? searchBuilds,
    $1.Build? scheduleBuild,
    $1.Build? cancelBuild,
    $1.Build? getBuildStatus,
    $4.Status? error,
  }) {
    final $result = create();
    if (getBuild != null) {
      $result.getBuild = getBuild;
    }
    if (searchBuilds != null) {
      $result.searchBuilds = searchBuilds;
    }
    if (scheduleBuild != null) {
      $result.scheduleBuild = scheduleBuild;
    }
    if (cancelBuild != null) {
      $result.cancelBuild = cancelBuild;
    }
    if (getBuildStatus != null) {
      $result.getBuildStatus = getBuildStatus;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  BatchResponse_Response._() : super();
  factory BatchResponse_Response.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchResponse_Response.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BatchResponse_Response_Response>
      _BatchResponse_Response_ResponseByTag = {
    1: BatchResponse_Response_Response.getBuild,
    2: BatchResponse_Response_Response.searchBuilds,
    3: BatchResponse_Response_Response.scheduleBuild,
    4: BatchResponse_Response_Response.cancelBuild,
    5: BatchResponse_Response_Response.getBuildStatus,
    100: BatchResponse_Response_Response.error,
    0: BatchResponse_Response_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchResponse.Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 100])
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'getBuild',
        subBuilder: $1.Build.create)
    ..aOM<SearchBuildsResponse>(2, _omitFieldNames ? '' : 'searchBuilds',
        subBuilder: SearchBuildsResponse.create)
    ..aOM<$1.Build>(3, _omitFieldNames ? '' : 'scheduleBuild',
        subBuilder: $1.Build.create)
    ..aOM<$1.Build>(4, _omitFieldNames ? '' : 'cancelBuild',
        subBuilder: $1.Build.create)
    ..aOM<$1.Build>(5, _omitFieldNames ? '' : 'getBuildStatus',
        subBuilder: $1.Build.create)
    ..aOM<$4.Status>(100, _omitFieldNames ? '' : 'error',
        subBuilder: $4.Status.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchResponse_Response clone() =>
      BatchResponse_Response()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchResponse_Response copyWith(
          void Function(BatchResponse_Response) updates) =>
      super.copyWith((message) => updates(message as BatchResponse_Response))
          as BatchResponse_Response;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchResponse_Response create() => BatchResponse_Response._();
  BatchResponse_Response createEmptyInstance() => create();
  static $pb.PbList<BatchResponse_Response> createRepeated() =>
      $pb.PbList<BatchResponse_Response>();
  @$core.pragma('dart2js:noInline')
  static BatchResponse_Response getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchResponse_Response>(create);
  static BatchResponse_Response? _defaultInstance;

  BatchResponse_Response_Response whichResponse() =>
      _BatchResponse_Response_ResponseByTag[$_whichOneof(0)]!;
  void clearResponse() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $1.Build get getBuild => $_getN(0);
  @$pb.TagNumber(1)
  set getBuild($1.Build v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasGetBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearGetBuild() => clearField(1);
  @$pb.TagNumber(1)
  $1.Build ensureGetBuild() => $_ensure(0);

  @$pb.TagNumber(2)
  SearchBuildsResponse get searchBuilds => $_getN(1);
  @$pb.TagNumber(2)
  set searchBuilds(SearchBuildsResponse v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSearchBuilds() => $_has(1);
  @$pb.TagNumber(2)
  void clearSearchBuilds() => clearField(2);
  @$pb.TagNumber(2)
  SearchBuildsResponse ensureSearchBuilds() => $_ensure(1);

  @$pb.TagNumber(3)
  $1.Build get scheduleBuild => $_getN(2);
  @$pb.TagNumber(3)
  set scheduleBuild($1.Build v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasScheduleBuild() => $_has(2);
  @$pb.TagNumber(3)
  void clearScheduleBuild() => clearField(3);
  @$pb.TagNumber(3)
  $1.Build ensureScheduleBuild() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.Build get cancelBuild => $_getN(3);
  @$pb.TagNumber(4)
  set cancelBuild($1.Build v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCancelBuild() => $_has(3);
  @$pb.TagNumber(4)
  void clearCancelBuild() => clearField(4);
  @$pb.TagNumber(4)
  $1.Build ensureCancelBuild() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.Build get getBuildStatus => $_getN(4);
  @$pb.TagNumber(5)
  set getBuildStatus($1.Build v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasGetBuildStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearGetBuildStatus() => clearField(5);
  @$pb.TagNumber(5)
  $1.Build ensureGetBuildStatus() => $_ensure(4);

  /// Error code and details of the unsuccessful RPC.
  @$pb.TagNumber(100)
  $4.Status get error => $_getN(5);
  @$pb.TagNumber(100)
  set error($4.Status v) {
    setField(100, v);
  }

  @$pb.TagNumber(100)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(100)
  void clearError() => clearField(100);
  @$pb.TagNumber(100)
  $4.Status ensureError() => $_ensure(5);
}

/// A response message for Batch RPC.
class BatchResponse extends $pb.GeneratedMessage {
  factory BatchResponse({
    $core.Iterable<BatchResponse_Response>? responses,
  }) {
    final $result = create();
    if (responses != null) {
      $result.responses.addAll(responses);
    }
    return $result;
  }
  BatchResponse._() : super();
  factory BatchResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..pc<BatchResponse_Response>(
        1, _omitFieldNames ? '' : 'responses', $pb.PbFieldType.PM,
        subBuilder: BatchResponse_Response.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchResponse clone() => BatchResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchResponse copyWith(void Function(BatchResponse) updates) =>
      super.copyWith((message) => updates(message as BatchResponse))
          as BatchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchResponse create() => BatchResponse._();
  BatchResponse createEmptyInstance() => create();
  static $pb.PbList<BatchResponse> createRepeated() =>
      $pb.PbList<BatchResponse>();
  @$core.pragma('dart2js:noInline')
  static BatchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchResponse>(create);
  static BatchResponse? _defaultInstance;

  /// Responses in the same order as BatchRequest.requests.
  @$pb.TagNumber(1)
  $core.List<BatchResponse_Response> get responses => $_getList(0);
}

/// A request message for UpdateBuild RPC.
class UpdateBuildRequest extends $pb.GeneratedMessage {
  factory UpdateBuildRequest({
    $1.Build? build,
    $3.FieldMask? updateMask,
    @$core.Deprecated('This field is deprecated.') $3.FieldMask? fields,
    BuildMask? mask,
  }) {
    final $result = create();
    if (build != null) {
      $result.build = build;
    }
    if (updateMask != null) {
      $result.updateMask = updateMask;
    }
    if (fields != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.fields = fields;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  UpdateBuildRequest._() : super();
  factory UpdateBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UpdateBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build',
        subBuilder: $1.Build.create)
    ..aOM<$3.FieldMask>(2, _omitFieldNames ? '' : 'updateMask',
        subBuilder: $3.FieldMask.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UpdateBuildRequest clone() => UpdateBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UpdateBuildRequest copyWith(void Function(UpdateBuildRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateBuildRequest))
          as UpdateBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateBuildRequest create() => UpdateBuildRequest._();
  UpdateBuildRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateBuildRequest> createRepeated() =>
      $pb.PbList<UpdateBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateBuildRequest>(create);
  static UpdateBuildRequest? _defaultInstance;

  /// Build to update, with new field values.
  @$pb.TagNumber(1)
  $1.Build get build => $_getN(0);
  @$pb.TagNumber(1)
  set build($1.Build v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuild() => clearField(1);
  @$pb.TagNumber(1)
  $1.Build ensureBuild() => $_ensure(0);

  ///  Build fields to update.
  ///  See also
  ///  https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  ///  Currently supports only the following path strings:
  ///  - build.output
  ///  - build.output.properties
  ///  - build.output.gitiles_commit
  ///  - build.output.status
  ///  - build.output.status_details
  ///  - build.output.summary_markdown
  ///  - build.status
  ///  - build.status_details
  ///  - build.steps
  ///  - build.summary_markdown
  ///  - build.tags
  ///  - build.infra.buildbucket.agent.output
  ///  - build.infra.buildbucket.agent.purposes
  ///
  ///  Note, "build.output.status" is required explicitly to update the field.
  ///  If there is only "build.output" in update_mask, build.output.status will not
  ///  be updated.
  ///
  ///  If omitted, Buildbucket will update the Build's update_time, but nothing else.
  @$pb.TagNumber(2)
  $3.FieldMask get updateMask => $_getN(1);
  @$pb.TagNumber(2)
  set updateMask($3.FieldMask v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUpdateMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateMask() => clearField(2);
  @$pb.TagNumber(2)
  $3.FieldMask ensureUpdateMask() => $_ensure(1);

  ///  Fields to include in the response. See also GetBuildRequest.fields.
  ///
  ///  DEPRECATED: Use mask instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask get fields => $_getN(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  set fields($3.FieldMask v) {
    setField(100, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $core.bool hasFields() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  void clearFields() => clearField(100);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask ensureFields() => $_ensure(2);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, an empty build will be returned.
  @$pb.TagNumber(101)
  BuildMask get mask => $_getN(3);
  @$pb.TagNumber(101)
  set mask(BuildMask v) {
    setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasMask() => $_has(3);
  @$pb.TagNumber(101)
  void clearMask() => clearField(101);
  @$pb.TagNumber(101)
  BuildMask ensureMask() => $_ensure(3);
}

/// Swarming specific part of the build request.
class ScheduleBuildRequest_Swarming extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest_Swarming({
    $core.String? parentRunId,
  }) {
    final $result = create();
    if (parentRunId != null) {
      $result.parentRunId = parentRunId;
    }
    return $result;
  }
  ScheduleBuildRequest_Swarming._() : super();
  factory ScheduleBuildRequest_Swarming.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest_Swarming.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScheduleBuildRequest.Swarming',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parentRunId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_Swarming clone() =>
      ScheduleBuildRequest_Swarming()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_Swarming copyWith(
          void Function(ScheduleBuildRequest_Swarming) updates) =>
      super.copyWith(
              (message) => updates(message as ScheduleBuildRequest_Swarming))
          as ScheduleBuildRequest_Swarming;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_Swarming create() =>
      ScheduleBuildRequest_Swarming._();
  ScheduleBuildRequest_Swarming createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest_Swarming> createRepeated() =>
      $pb.PbList<ScheduleBuildRequest_Swarming>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_Swarming getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest_Swarming>(create);
  static ScheduleBuildRequest_Swarming? _defaultInstance;

  ///  If specified, parent_run_id should match actual Swarming task run ID the
  ///  caller is running as and results in swarming server ensuring that the newly
  ///  triggered build will not outlive its parent.
  ///
  ///  Typical use is for triggering and waiting on child build(s) from within
  ///  1 parent build and if child build(s) on their own aren't useful. Then,
  ///  if parent build ends for whatever reason, all not yet finished child
  ///  builds aren't useful and it's desirable to terminate them, too.
  ///
  ///  If the Builder config does not specify a swarming backend, the request
  ///  will fail with InvalidArgument error code.
  ///
  ///  The parent_run_id is assumed to be from the same swarming server as the
  ///  one the new build is to be executed on. The ScheduleBuildRequest doesn't
  ///  check if parent_run_id refers to actually existing task, but eventually
  ///  the new build will fail if so.
  @$pb.TagNumber(1)
  $core.String get parentRunId => $_getSZ(0);
  @$pb.TagNumber(1)
  set parentRunId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParentRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearParentRunId() => clearField(1);
}

/// Information for scheduling a build as a shadow build.
class ScheduleBuildRequest_ShadowInput extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest_ShadowInput() => create();
  ScheduleBuildRequest_ShadowInput._() : super();
  factory ScheduleBuildRequest_ShadowInput.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest_ShadowInput.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScheduleBuildRequest.ShadowInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_ShadowInput clone() =>
      ScheduleBuildRequest_ShadowInput()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_ShadowInput copyWith(
          void Function(ScheduleBuildRequest_ShadowInput) updates) =>
      super.copyWith(
              (message) => updates(message as ScheduleBuildRequest_ShadowInput))
          as ScheduleBuildRequest_ShadowInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_ShadowInput create() =>
      ScheduleBuildRequest_ShadowInput._();
  ScheduleBuildRequest_ShadowInput createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest_ShadowInput> createRepeated() =>
      $pb.PbList<ScheduleBuildRequest_ShadowInput>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_ShadowInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest_ShadowInput>(
          create);
  static ScheduleBuildRequest_ShadowInput? _defaultInstance;
}

///  A request message for ScheduleBuild RPC.
///
///  Next ID: 24.
class ScheduleBuildRequest extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest({
    $core.String? requestId,
    $fixnum.Int64? templateBuildId,
    $2.BuilderID? builder,
    $6.Trinary? canary,
    $6.Trinary? experimental,
    $5.Struct? properties,
    $6.GitilesCommit? gitilesCommit,
    $core.Iterable<$6.GerritChange>? gerritChanges,
    $core.Iterable<$6.StringPair>? tags,
    $core.Iterable<$6.RequestedDimension>? dimensions,
    $core.int? priority,
    $7.NotificationConfig? notify,
    $6.Trinary? critical,
    $6.Executable? exe,
    ScheduleBuildRequest_Swarming? swarming,
    $core.Map<$core.String, $core.bool>? experiments,
    $8.Duration? schedulingTimeout,
    $8.Duration? executionTimeout,
    $8.Duration? gracePeriod,
    $core.bool? dryRun,
    $6.Trinary? canOutliveParent,
    $6.Trinary? retriable,
    ScheduleBuildRequest_ShadowInput? shadowInput,
    @$core.Deprecated('This field is deprecated.') $3.FieldMask? fields,
    BuildMask? mask,
  }) {
    final $result = create();
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (templateBuildId != null) {
      $result.templateBuildId = templateBuildId;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    if (canary != null) {
      $result.canary = canary;
    }
    if (experimental != null) {
      $result.experimental = experimental;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    if (gitilesCommit != null) {
      $result.gitilesCommit = gitilesCommit;
    }
    if (gerritChanges != null) {
      $result.gerritChanges.addAll(gerritChanges);
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (dimensions != null) {
      $result.dimensions.addAll(dimensions);
    }
    if (priority != null) {
      $result.priority = priority;
    }
    if (notify != null) {
      $result.notify = notify;
    }
    if (critical != null) {
      $result.critical = critical;
    }
    if (exe != null) {
      $result.exe = exe;
    }
    if (swarming != null) {
      $result.swarming = swarming;
    }
    if (experiments != null) {
      $result.experiments.addAll(experiments);
    }
    if (schedulingTimeout != null) {
      $result.schedulingTimeout = schedulingTimeout;
    }
    if (executionTimeout != null) {
      $result.executionTimeout = executionTimeout;
    }
    if (gracePeriod != null) {
      $result.gracePeriod = gracePeriod;
    }
    if (dryRun != null) {
      $result.dryRun = dryRun;
    }
    if (canOutliveParent != null) {
      $result.canOutliveParent = canOutliveParent;
    }
    if (retriable != null) {
      $result.retriable = retriable;
    }
    if (shadowInput != null) {
      $result.shadowInput = shadowInput;
    }
    if (fields != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.fields = fields;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  ScheduleBuildRequest._() : super();
  factory ScheduleBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ScheduleBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aInt64(2, _omitFieldNames ? '' : 'templateBuildId')
    ..aOM<$2.BuilderID>(3, _omitFieldNames ? '' : 'builder',
        subBuilder: $2.BuilderID.create)
    ..e<$6.Trinary>(4, _omitFieldNames ? '' : 'canary', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..e<$6.Trinary>(
        5, _omitFieldNames ? '' : 'experimental', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..aOM<$5.Struct>(6, _omitFieldNames ? '' : 'properties',
        subBuilder: $5.Struct.create)
    ..aOM<$6.GitilesCommit>(7, _omitFieldNames ? '' : 'gitilesCommit',
        subBuilder: $6.GitilesCommit.create)
    ..pc<$6.GerritChange>(
        8, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $6.GerritChange.create)
    ..pc<$6.StringPair>(9, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM,
        subBuilder: $6.StringPair.create)
    ..pc<$6.RequestedDimension>(
        10, _omitFieldNames ? '' : 'dimensions', $pb.PbFieldType.PM,
        subBuilder: $6.RequestedDimension.create)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.O3)
    ..aOM<$7.NotificationConfig>(12, _omitFieldNames ? '' : 'notify',
        subBuilder: $7.NotificationConfig.create)
    ..e<$6.Trinary>(13, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..aOM<$6.Executable>(14, _omitFieldNames ? '' : 'exe',
        subBuilder: $6.Executable.create)
    ..aOM<ScheduleBuildRequest_Swarming>(15, _omitFieldNames ? '' : 'swarming',
        subBuilder: ScheduleBuildRequest_Swarming.create)
    ..m<$core.String, $core.bool>(16, _omitFieldNames ? '' : 'experiments',
        entryClassName: 'ScheduleBuildRequest.ExperimentsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<$8.Duration>(17, _omitFieldNames ? '' : 'schedulingTimeout',
        subBuilder: $8.Duration.create)
    ..aOM<$8.Duration>(18, _omitFieldNames ? '' : 'executionTimeout',
        subBuilder: $8.Duration.create)
    ..aOM<$8.Duration>(19, _omitFieldNames ? '' : 'gracePeriod',
        subBuilder: $8.Duration.create)
    ..aOB(20, _omitFieldNames ? '' : 'dryRun')
    ..e<$6.Trinary>(
        21, _omitFieldNames ? '' : 'canOutliveParent', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..e<$6.Trinary>(22, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..aOM<ScheduleBuildRequest_ShadowInput>(
        23, _omitFieldNames ? '' : 'shadowInput',
        subBuilder: ScheduleBuildRequest_ShadowInput.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest clone() =>
      ScheduleBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest copyWith(void Function(ScheduleBuildRequest) updates) =>
      super.copyWith((message) => updates(message as ScheduleBuildRequest))
          as ScheduleBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest create() => ScheduleBuildRequest._();
  ScheduleBuildRequest createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest> createRepeated() =>
      $pb.PbList<ScheduleBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest>(create);
  static ScheduleBuildRequest? _defaultInstance;

  /// ** STRONGLY RECOMMENDED **.
  /// A unique string id used for detecting duplicate requests.
  /// Should be unique at least per requesting identity.
  /// Used to dedup build scheduling requests with same id within 1 min.
  /// If a build was successfully scheduled with the same request id in the past
  /// minute, the existing build will be returned.
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => clearField(1);

  /// ID of a build to retry as is or altered.
  /// When specified, fields below default to the values in the template build.
  @$pb.TagNumber(2)
  $fixnum.Int64 get templateBuildId => $_getI64(1);
  @$pb.TagNumber(2)
  set templateBuildId($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTemplateBuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTemplateBuildId() => clearField(2);

  /// Value for Build.builder. See its comments.
  /// Required, unless template_build_id is specified.
  @$pb.TagNumber(3)
  $2.BuilderID get builder => $_getN(2);
  @$pb.TagNumber(3)
  set builder($2.BuilderID v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBuilder() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuilder() => clearField(3);
  @$pb.TagNumber(3)
  $2.BuilderID ensureBuilder() => $_ensure(2);

  ///  DEPRECATED
  ///
  ///  Set "luci.buildbucket.canary_software" in `experiments` instead.
  ///
  ///  YES sets "luci.buildbucket.canary_software" to true in `experiments`.
  ///  NO sets "luci.buildbucket.canary_software" to false in `experiments`.
  @$pb.TagNumber(4)
  $6.Trinary get canary => $_getN(3);
  @$pb.TagNumber(4)
  set canary($6.Trinary v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCanary() => $_has(3);
  @$pb.TagNumber(4)
  void clearCanary() => clearField(4);

  ///  DEPRECATED
  ///
  ///  Set "luci.non_production" in `experiments` instead.
  ///
  ///  YES sets "luci.non_production" to true in `experiments`.
  ///  NO sets "luci.non_production" to false in `experiments`.
  @$pb.TagNumber(5)
  $6.Trinary get experimental => $_getN(4);
  @$pb.TagNumber(5)
  set experimental($6.Trinary v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasExperimental() => $_has(4);
  @$pb.TagNumber(5)
  void clearExperimental() => clearField(5);

  ///  Properties to include in Build.input.properties.
  ///
  ///  Input properties of the created build are result of merging server-defined
  ///  properties and properties in this field.
  ///  Each property in this field defines a new or replaces an existing property
  ///  on the server.
  ///  If the server config does not allow overriding/adding the property, the
  ///  request will fail with InvalidArgument error code.
  ///  A server-defined property cannot be removed, but its value can be
  ///  replaced with null.
  ///
  ///  Reserved property paths:
  ///    ["$recipe_engine/buildbucket"]
  ///    ["$recipe_engine/runtime", "is_experimental"]
  ///    ["$recipe_engine/runtime", "is_luci"]
  ///    ["branch"]
  ///    ["buildbucket"]
  ///    ["buildername"]
  ///    ["repository"]
  ///
  ///  The Builder configuration specifies which top-level property names are
  ///  overridable via the `allowed_property_overrides` field. ScheduleBuild
  ///  requests which attempt to override a property which isn't allowed will
  ///  fail with InvalidArgument.
  ///
  ///  V1 equivalent: corresponds to "properties" key in "parameters_json".
  @$pb.TagNumber(6)
  $5.Struct get properties => $_getN(5);
  @$pb.TagNumber(6)
  set properties($5.Struct v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasProperties() => $_has(5);
  @$pb.TagNumber(6)
  void clearProperties() => clearField(6);
  @$pb.TagNumber(6)
  $5.Struct ensureProperties() => $_ensure(5);

  ///  Value for Build.input.gitiles_commit.
  ///
  ///  Setting this field will cause the created build to have a "buildset"
  ///  tag with value "commit/gitiles/{hostname}/{project}/+/{id}".
  ///
  ///  GitilesCommit objects MUST have host, project, ref fields set.
  ///
  ///  V1 equivalent: supersedes "revision" property and "buildset"
  ///  tag that starts with "commit/gitiles/".
  @$pb.TagNumber(7)
  $6.GitilesCommit get gitilesCommit => $_getN(6);
  @$pb.TagNumber(7)
  set gitilesCommit($6.GitilesCommit v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasGitilesCommit() => $_has(6);
  @$pb.TagNumber(7)
  void clearGitilesCommit() => clearField(7);
  @$pb.TagNumber(7)
  $6.GitilesCommit ensureGitilesCommit() => $_ensure(6);

  ///  Value for Build.input.gerrit_changes.
  ///  Usually present in tryjobs, set by CQ, Gerrit, git-cl-try.
  ///  Applied on top of gitiles_commit if specified, otherwise tip of the tree.
  ///  All GerritChange fields are required.
  ///
  ///  Setting this field will cause the created build to have a "buildset"
  ///  tag with value "patch/gerrit/{hostname}/{change}/{patchset}"
  ///  for each change.
  ///
  ///  V1 equivalent: supersedes patch_* properties and "buildset"
  ///  tag that starts with "patch/gerrit/".
  @$pb.TagNumber(8)
  $core.List<$6.GerritChange> get gerritChanges => $_getList(7);

  /// Tags to include in Build.tags of the created build, see Build.tags
  /// comments.
  /// Note: tags of the created build may include other tags defined on the
  /// server.
  @$pb.TagNumber(9)
  $core.List<$6.StringPair> get tags => $_getList(8);

  ///  Overrides default dimensions defined by builder config or template build.
  ///
  ///  A set of entries with the same key defines a new or replaces an existing
  ///  dimension with the same key.
  ///  If the config does not allow overriding/adding the dimension, the request
  ///  will fail with InvalidArgument error code.
  ///
  ///  After merging, dimensions with empty value will be excluded.
  ///
  ///  Note: For the same key dimensions, it won't allow to pass empty and
  ///  non-empty values at the same time in the request.
  ///
  ///  Note: "caches" and "pool" dimensions may only be specified in builder
  ///  configs. Setting them hear will fail the request.
  ///
  ///  A dimension expiration must be a multiple of 1min.
  @$pb.TagNumber(10)
  $core.List<$6.RequestedDimension> get dimensions => $_getList(9);

  /// If not zero, overrides swarming task priority.
  /// See also Build.infra.swarming.priority.
  @$pb.TagNumber(11)
  $core.int get priority => $_getIZ(10);
  @$pb.TagNumber(11)
  set priority($core.int v) {
    $_setSignedInt32(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasPriority() => $_has(10);
  @$pb.TagNumber(11)
  void clearPriority() => clearField(11);

  /// A per-build notification configuration.
  @$pb.TagNumber(12)
  $7.NotificationConfig get notify => $_getN(11);
  @$pb.TagNumber(12)
  set notify($7.NotificationConfig v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasNotify() => $_has(11);
  @$pb.TagNumber(12)
  void clearNotify() => clearField(12);
  @$pb.TagNumber(12)
  $7.NotificationConfig ensureNotify() => $_ensure(11);

  /// Value for Build.critical.
  @$pb.TagNumber(13)
  $6.Trinary get critical => $_getN(12);
  @$pb.TagNumber(13)
  set critical($6.Trinary v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasCritical() => $_has(12);
  @$pb.TagNumber(13)
  void clearCritical() => clearField(13);

  /// Overrides Builder.exe in the config.
  /// Supported subfields: cipd_version.
  @$pb.TagNumber(14)
  $6.Executable get exe => $_getN(13);
  @$pb.TagNumber(14)
  set exe($6.Executable v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasExe() => $_has(13);
  @$pb.TagNumber(14)
  void clearExe() => clearField(14);
  @$pb.TagNumber(14)
  $6.Executable ensureExe() => $_ensure(13);

  /// Swarming specific part of the build request.
  @$pb.TagNumber(15)
  ScheduleBuildRequest_Swarming get swarming => $_getN(14);
  @$pb.TagNumber(15)
  set swarming(ScheduleBuildRequest_Swarming v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasSwarming() => $_has(14);
  @$pb.TagNumber(15)
  void clearSwarming() => clearField(15);
  @$pb.TagNumber(15)
  ScheduleBuildRequest_Swarming ensureSwarming() => $_ensure(14);

  ///  Sets (or prevents) these experiments on the scheduled build.
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(16)
  $core.Map<$core.String, $core.bool> get experiments => $_getMap(15);

  ///  Maximum build pending time.
  ///
  ///  If set, overrides the default `expiration_secs` set in builder config.
  ///  Only supports seconds precision for now.
  ///  For more information, see Build.scheduling_timeout in build.proto.
  @$pb.TagNumber(17)
  $8.Duration get schedulingTimeout => $_getN(16);
  @$pb.TagNumber(17)
  set schedulingTimeout($8.Duration v) {
    setField(17, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasSchedulingTimeout() => $_has(16);
  @$pb.TagNumber(17)
  void clearSchedulingTimeout() => clearField(17);
  @$pb.TagNumber(17)
  $8.Duration ensureSchedulingTimeout() => $_ensure(16);

  ///  Maximum build execution time.
  ///
  ///  If set, overrides the default `execution_timeout_secs` set in builder config.
  ///  Only supports seconds precision for now.
  ///  For more information, see Build.execution_timeout in build.proto.
  @$pb.TagNumber(18)
  $8.Duration get executionTimeout => $_getN(17);
  @$pb.TagNumber(18)
  set executionTimeout($8.Duration v) {
    setField(18, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasExecutionTimeout() => $_has(17);
  @$pb.TagNumber(18)
  void clearExecutionTimeout() => clearField(18);
  @$pb.TagNumber(18)
  $8.Duration ensureExecutionTimeout() => $_ensure(17);

  ///  Amount of cleanup time after execution_timeout.
  ///
  ///  If set, overrides the default `grace_period` set in builder config.
  ///  Only supports seconds precision for now.
  ///  For more information, see Build.grace_period in build.proto.
  @$pb.TagNumber(19)
  $8.Duration get gracePeriod => $_getN(18);
  @$pb.TagNumber(19)
  set gracePeriod($8.Duration v) {
    setField(19, v);
  }

  @$pb.TagNumber(19)
  $core.bool hasGracePeriod() => $_has(18);
  @$pb.TagNumber(19)
  void clearGracePeriod() => clearField(19);
  @$pb.TagNumber(19)
  $8.Duration ensureGracePeriod() => $_ensure(18);

  ///  Whether or not this request constitutes a dry run.
  ///
  ///  A dry run returns the build proto without actually scheduling it. All
  ///  fields except those which can only be computed at run-time are filled in.
  ///  Does not cause side-effects. When batching, all requests must specify the
  ///  same value for dry_run.
  @$pb.TagNumber(20)
  $core.bool get dryRun => $_getBF(19);
  @$pb.TagNumber(20)
  set dryRun($core.bool v) {
    $_setBool(19, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasDryRun() => $_has(19);
  @$pb.TagNumber(20)
  void clearDryRun() => clearField(20);

  ///  Flag to control if the build can outlive its parent.
  ///
  ///  If the value is UNSET, it means this build doesn't have any parent, so
  ///  the request must not have a head with any BuildToken.
  ///
  ///  If the value is anything other than UNSET, then the BuildToken for the
  ///  parent build must be set as a header.
  ///  Note: it's not currently possible to establish parent/child relationship
  ///  except via the parent build at the time the build is launched.
  ///
  ///  If the value is NO, it means that the build SHOULD reach a terminal status
  ///  (SUCCESS, FAILURE, INFRA_FAILURE or CANCELED) before its parent. If the
  ///  child fails to do so, Buildbucket will cancel it some time after the
  ///  parent build reaches a terminal status.
  ///
  ///  A build that can outlive its parent can also outlive its parent's ancestors.
  ///
  ///  If schedule a build without parent, this field must be UNSET.
  ///
  ///  If schedule a build with parent, this field should be YES or NO.
  ///  But UNSET is also accepted for now, and it has the same effect as YES.
  ///  TODO(crbug.com/1031205): after the parent tracking feature is stable,
  ///  require this field to be set when scheduling a build with parent.
  @$pb.TagNumber(21)
  $6.Trinary get canOutliveParent => $_getN(20);
  @$pb.TagNumber(21)
  set canOutliveParent($6.Trinary v) {
    setField(21, v);
  }

  @$pb.TagNumber(21)
  $core.bool hasCanOutliveParent() => $_has(20);
  @$pb.TagNumber(21)
  void clearCanOutliveParent() => clearField(21);

  /// Value for Build.retriable.
  @$pb.TagNumber(22)
  $6.Trinary get retriable => $_getN(21);
  @$pb.TagNumber(22)
  set retriable($6.Trinary v) {
    setField(22, v);
  }

  @$pb.TagNumber(22)
  $core.bool hasRetriable() => $_has(21);
  @$pb.TagNumber(22)
  void clearRetriable() => clearField(22);

  ///  Input for scheduling a build in the shadow bucket.
  ///
  ///  If this field is set, it means the build to be scheduled will
  ///  * be scheduled in the shadow bucket of the requested bucket, with shadow
  ///    adjustments on service_account, dimensions and properties.
  ///  * inherit its parent build's agent input and agent source if it has a parent.
  @$pb.TagNumber(23)
  ScheduleBuildRequest_ShadowInput get shadowInput => $_getN(22);
  @$pb.TagNumber(23)
  set shadowInput(ScheduleBuildRequest_ShadowInput v) {
    setField(23, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasShadowInput() => $_has(22);
  @$pb.TagNumber(23)
  void clearShadowInput() => clearField(23);
  @$pb.TagNumber(23)
  ScheduleBuildRequest_ShadowInput ensureShadowInput() => $_ensure(22);

  ///  Fields to include in the response. See also GetBuildRequest.fields.
  ///
  ///  DEPRECATED: Use mask instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask get fields => $_getN(23);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  set fields($3.FieldMask v) {
    setField(100, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $core.bool hasFields() => $_has(23);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  void clearFields() => clearField(100);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask ensureFields() => $_ensure(23);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(101)
  BuildMask get mask => $_getN(24);
  @$pb.TagNumber(101)
  set mask(BuildMask v) {
    setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasMask() => $_has(24);
  @$pb.TagNumber(101)
  void clearMask() => clearField(101);
  @$pb.TagNumber(101)
  BuildMask ensureMask() => $_ensure(24);
}

/// A request message for CancelBuild RPC.
class CancelBuildRequest extends $pb.GeneratedMessage {
  factory CancelBuildRequest({
    $fixnum.Int64? id,
    $core.String? summaryMarkdown,
    @$core.Deprecated('This field is deprecated.') $3.FieldMask? fields,
    BuildMask? mask,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    if (fields != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.fields = fields;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  CancelBuildRequest._() : super();
  factory CancelBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CancelBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CancelBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'summaryMarkdown')
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CancelBuildRequest clone() => CancelBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CancelBuildRequest copyWith(void Function(CancelBuildRequest) updates) =>
      super.copyWith((message) => updates(message as CancelBuildRequest))
          as CancelBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelBuildRequest create() => CancelBuildRequest._();
  CancelBuildRequest createEmptyInstance() => create();
  static $pb.PbList<CancelBuildRequest> createRepeated() =>
      $pb.PbList<CancelBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CancelBuildRequest>(create);
  static CancelBuildRequest? _defaultInstance;

  /// ID of the build to cancel.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Required. Value for Build.cancellation_markdown. Will be appended to
  /// Build.summary_markdown when exporting to bigquery and returned via GetBuild.
  @$pb.TagNumber(2)
  $core.String get summaryMarkdown => $_getSZ(1);
  @$pb.TagNumber(2)
  set summaryMarkdown($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSummaryMarkdown() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummaryMarkdown() => clearField(2);

  ///  Fields to include in the response. See also GetBuildRequest.fields.
  ///
  ///  DEPRECATED: Use mask instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask get fields => $_getN(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  set fields($3.FieldMask v) {
    setField(100, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $core.bool hasFields() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  void clearFields() => clearField(100);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(100)
  $3.FieldMask ensureFields() => $_ensure(2);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(101)
  BuildMask get mask => $_getN(3);
  @$pb.TagNumber(101)
  set mask(BuildMask v) {
    setField(101, v);
  }

  @$pb.TagNumber(101)
  $core.bool hasMask() => $_has(3);
  @$pb.TagNumber(101)
  void clearMask() => clearField(101);
  @$pb.TagNumber(101)
  BuildMask ensureMask() => $_ensure(3);
}

/// A request message for CreateBuild RPC.
class CreateBuildRequest extends $pb.GeneratedMessage {
  factory CreateBuildRequest({
    $1.Build? build,
    $core.String? requestId,
    BuildMask? mask,
  }) {
    final $result = create();
    if (build != null) {
      $result.build = build;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (mask != null) {
      $result.mask = mask;
    }
    return $result;
  }
  CreateBuildRequest._() : super();
  factory CreateBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CreateBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build',
        subBuilder: $1.Build.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<BuildMask>(3, _omitFieldNames ? '' : 'mask',
        subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CreateBuildRequest clone() => CreateBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CreateBuildRequest copyWith(void Function(CreateBuildRequest) updates) =>
      super.copyWith((message) => updates(message as CreateBuildRequest))
          as CreateBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateBuildRequest create() => CreateBuildRequest._();
  CreateBuildRequest createEmptyInstance() => create();
  static $pb.PbList<CreateBuildRequest> createRepeated() =>
      $pb.PbList<CreateBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateBuildRequest>(create);
  static CreateBuildRequest? _defaultInstance;

  /// The Build to be created.
  @$pb.TagNumber(1)
  $1.Build get build => $_getN(0);
  @$pb.TagNumber(1)
  set build($1.Build v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuild() => clearField(1);
  @$pb.TagNumber(1)
  $1.Build ensureBuild() => $_ensure(0);

  /// A unique identifier for this request.
  /// A random UUID is recommended.
  /// This request is only idempotent if a `request_id` is provided.
  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  ///  What portion of the Build message to return.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(3)
  BuildMask get mask => $_getN(2);
  @$pb.TagNumber(3)
  set mask(BuildMask v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMask() => $_has(2);
  @$pb.TagNumber(3)
  void clearMask() => clearField(3);
  @$pb.TagNumber(3)
  BuildMask ensureMask() => $_ensure(2);
}

/// A request message for SynthesizeBuild RPC.
class SynthesizeBuildRequest extends $pb.GeneratedMessage {
  factory SynthesizeBuildRequest({
    $fixnum.Int64? templateBuildId,
    $2.BuilderID? builder,
    $core.Map<$core.String, $core.bool>? experiments,
  }) {
    final $result = create();
    if (templateBuildId != null) {
      $result.templateBuildId = templateBuildId;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    if (experiments != null) {
      $result.experiments.addAll(experiments);
    }
    return $result;
  }
  SynthesizeBuildRequest._() : super();
  factory SynthesizeBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SynthesizeBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SynthesizeBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'templateBuildId')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder',
        subBuilder: $2.BuilderID.create)
    ..m<$core.String, $core.bool>(3, _omitFieldNames ? '' : 'experiments',
        entryClassName: 'SynthesizeBuildRequest.ExperimentsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SynthesizeBuildRequest clone() =>
      SynthesizeBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SynthesizeBuildRequest copyWith(
          void Function(SynthesizeBuildRequest) updates) =>
      super.copyWith((message) => updates(message as SynthesizeBuildRequest))
          as SynthesizeBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SynthesizeBuildRequest create() => SynthesizeBuildRequest._();
  SynthesizeBuildRequest createEmptyInstance() => create();
  static $pb.PbList<SynthesizeBuildRequest> createRepeated() =>
      $pb.PbList<SynthesizeBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static SynthesizeBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SynthesizeBuildRequest>(create);
  static SynthesizeBuildRequest? _defaultInstance;

  /// ID of a build to use as the template.
  /// Mutually exclusive with builder.
  @$pb.TagNumber(1)
  $fixnum.Int64 get templateBuildId => $_getI64(0);
  @$pb.TagNumber(1)
  set templateBuildId($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTemplateBuildId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemplateBuildId() => clearField(1);

  /// Value for Build.builder. See its comments.
  /// Required, unless template_build_id is specified.
  @$pb.TagNumber(2)
  $2.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($2.BuilderID v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $2.BuilderID ensureBuilder() => $_ensure(1);

  ///  Sets (or prevents) these experiments on the synthesized build.
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(3)
  $core.Map<$core.String, $core.bool> get experiments => $_getMap(2);
}

/// A request message for StartBuild RPC.
class StartBuildRequest extends $pb.GeneratedMessage {
  factory StartBuildRequest({
    $core.String? requestId,
    $fixnum.Int64? buildId,
    $core.String? taskId,
  }) {
    final $result = create();
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (buildId != null) {
      $result.buildId = buildId;
    }
    if (taskId != null) {
      $result.taskId = taskId;
    }
    return $result;
  }
  StartBuildRequest._() : super();
  factory StartBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aInt64(2, _omitFieldNames ? '' : 'buildId')
    ..aOS(3, _omitFieldNames ? '' : 'taskId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartBuildRequest clone() => StartBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartBuildRequest copyWith(void Function(StartBuildRequest) updates) =>
      super.copyWith((message) => updates(message as StartBuildRequest))
          as StartBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildRequest create() => StartBuildRequest._();
  StartBuildRequest createEmptyInstance() => create();
  static $pb.PbList<StartBuildRequest> createRepeated() =>
      $pb.PbList<StartBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static StartBuildRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartBuildRequest>(create);
  static StartBuildRequest? _defaultInstance;

  /// A nonce to deduplicate requests.
  @$pb.TagNumber(1)
  $core.String get requestId => $_getSZ(0);
  @$pb.TagNumber(1)
  set requestId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasRequestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRequestId() => clearField(1);

  /// Id of the build to start.
  @$pb.TagNumber(2)
  $fixnum.Int64 get buildId => $_getI64(1);
  @$pb.TagNumber(2)
  set buildId($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildId() => clearField(2);

  /// Id of the task running the started build.
  @$pb.TagNumber(3)
  $core.String get taskId => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskId($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTaskId() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskId() => clearField(3);
}

/// A response message for StartBuild RPC.
class StartBuildResponse extends $pb.GeneratedMessage {
  factory StartBuildResponse({
    $1.Build? build,
    $core.String? updateBuildToken,
  }) {
    final $result = create();
    if (build != null) {
      $result.build = build;
    }
    if (updateBuildToken != null) {
      $result.updateBuildToken = updateBuildToken;
    }
    return $result;
  }
  StartBuildResponse._() : super();
  factory StartBuildResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartBuildResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build',
        subBuilder: $1.Build.create)
    ..aOS(2, _omitFieldNames ? '' : 'updateBuildToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartBuildResponse clone() => StartBuildResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartBuildResponse copyWith(void Function(StartBuildResponse) updates) =>
      super.copyWith((message) => updates(message as StartBuildResponse))
          as StartBuildResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildResponse create() => StartBuildResponse._();
  StartBuildResponse createEmptyInstance() => create();
  static $pb.PbList<StartBuildResponse> createRepeated() =>
      $pb.PbList<StartBuildResponse>();
  @$core.pragma('dart2js:noInline')
  static StartBuildResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartBuildResponse>(create);
  static StartBuildResponse? _defaultInstance;

  /// The whole proto of the started build.
  @$pb.TagNumber(1)
  $1.Build get build => $_getN(0);
  @$pb.TagNumber(1)
  set build($1.Build v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuild() => clearField(1);
  @$pb.TagNumber(1)
  $1.Build ensureBuild() => $_ensure(0);

  /// a build token for agent to use when making subsequent UpdateBuild calls.
  @$pb.TagNumber(2)
  $core.String get updateBuildToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set updateBuildToken($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUpdateBuildToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateBuildToken() => clearField(2);
}

/// A request message for GetBuildStatus RPC.
class GetBuildStatusRequest extends $pb.GeneratedMessage {
  factory GetBuildStatusRequest({
    $fixnum.Int64? id,
    $2.BuilderID? builder,
    $core.int? buildNumber,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    if (buildNumber != null) {
      $result.buildNumber = buildNumber;
    }
    return $result;
  }
  GetBuildStatusRequest._() : super();
  factory GetBuildStatusRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetBuildStatusRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBuildStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder',
        subBuilder: $2.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetBuildStatusRequest clone() =>
      GetBuildStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetBuildStatusRequest copyWith(
          void Function(GetBuildStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetBuildStatusRequest))
          as GetBuildStatusRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBuildStatusRequest create() => GetBuildStatusRequest._();
  GetBuildStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetBuildStatusRequest> createRepeated() =>
      $pb.PbList<GetBuildStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBuildStatusRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBuildStatusRequest>(create);
  static GetBuildStatusRequest? _defaultInstance;

  /// Build ID.
  /// Mutually exclusive with builder and number.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Builder of the build.
  /// Requires number. Mutually exclusive with id.
  @$pb.TagNumber(2)
  $2.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($2.BuilderID v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $2.BuilderID ensureBuilder() => $_ensure(1);

  /// Build number.
  /// Requires builder. Mutually exclusive with id.
  @$pb.TagNumber(3)
  $core.int get buildNumber => $_getIZ(2);
  @$pb.TagNumber(3)
  set buildNumber($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBuildNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuildNumber() => clearField(3);
}

/// Defines a subset of Build fields and properties to return.
class BuildMask extends $pb.GeneratedMessage {
  factory BuildMask({
    $3.FieldMask? fields,
    $core.Iterable<$9.StructMask>? inputProperties,
    $core.Iterable<$9.StructMask>? outputProperties,
    $core.Iterable<$9.StructMask>? requestedProperties,
    $core.bool? allFields,
    $core.Iterable<$6.Status>? stepStatus,
  }) {
    final $result = create();
    if (fields != null) {
      $result.fields = fields;
    }
    if (inputProperties != null) {
      $result.inputProperties.addAll(inputProperties);
    }
    if (outputProperties != null) {
      $result.outputProperties.addAll(outputProperties);
    }
    if (requestedProperties != null) {
      $result.requestedProperties.addAll(requestedProperties);
    }
    if (allFields != null) {
      $result.allFields = allFields;
    }
    if (stepStatus != null) {
      $result.stepStatus.addAll(stepStatus);
    }
    return $result;
  }
  BuildMask._() : super();
  factory BuildMask.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildMask.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildMask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$3.FieldMask>(1, _omitFieldNames ? '' : 'fields',
        subBuilder: $3.FieldMask.create)
    ..pc<$9.StructMask>(
        2, _omitFieldNames ? '' : 'inputProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..pc<$9.StructMask>(
        3, _omitFieldNames ? '' : 'outputProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..pc<$9.StructMask>(
        4, _omitFieldNames ? '' : 'requestedProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..aOB(5, _omitFieldNames ? '' : 'allFields')
    ..pc<$6.Status>(6, _omitFieldNames ? '' : 'stepStatus', $pb.PbFieldType.KE,
        valueOf: $6.Status.valueOf,
        enumValues: $6.Status.values,
        defaultEnumValue: $6.Status.STATUS_UNSPECIFIED)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildMask clone() => BuildMask()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildMask copyWith(void Function(BuildMask) updates) =>
      super.copyWith((message) => updates(message as BuildMask)) as BuildMask;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildMask create() => BuildMask._();
  BuildMask createEmptyInstance() => create();
  static $pb.PbList<BuildMask> createRepeated() => $pb.PbList<BuildMask>();
  @$core.pragma('dart2js:noInline')
  static BuildMask getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildMask>(create);
  static BuildMask? _defaultInstance;

  ///  Fields of the Build proto to include.
  ///
  ///  Follows the standard FieldMask semantics as documented at e.g.
  ///  https://pkg.go.dev/google.golang.org/protobuf/types/known/fieldmaskpb.
  ///
  ///  If not set, the default mask is used, see Build message comments for the
  ///  list of fields returned by default.
  @$pb.TagNumber(1)
  $3.FieldMask get fields => $_getN(0);
  @$pb.TagNumber(1)
  set fields($3.FieldMask v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFields() => $_has(0);
  @$pb.TagNumber(1)
  void clearFields() => clearField(1);
  @$pb.TagNumber(1)
  $3.FieldMask ensureFields() => $_ensure(0);

  ///  Defines a subset of `input.properties` to return.
  ///
  ///  When not empty, implicitly adds the corresponding field to `fields`.
  @$pb.TagNumber(2)
  $core.List<$9.StructMask> get inputProperties => $_getList(1);

  ///  Defines a subset of `output.properties` to return.
  ///
  ///  When not empty, implicitly adds the corresponding field to `fields`.
  @$pb.TagNumber(3)
  $core.List<$9.StructMask> get outputProperties => $_getList(2);

  ///  Defines a subset of `infra.buildbucket.requested_properties` to return.
  ///
  ///  When not empty, implicitly adds the corresponding field to `fields`.
  @$pb.TagNumber(4)
  $core.List<$9.StructMask> get requestedProperties => $_getList(3);

  ///  Flag for including all fields.
  ///
  ///  Mutually exclusive with `fields`, `input_properties`, `output_properties`,
  ///  and `requested_properties`.
  @$pb.TagNumber(5)
  $core.bool get allFields => $_getBF(4);
  @$pb.TagNumber(5)
  set allFields($core.bool v) {
    $_setBool(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAllFields() => $_has(4);
  @$pb.TagNumber(5)
  void clearAllFields() => clearField(5);

  ///  A status to filter returned `steps` by. If unspecified, no filter is
  ///  applied. Otherwise filters by the union of the given statuses.
  ///
  ///  No effect unless `fields` specifies that `steps` should be returned or
  ///  `all_fields` is true.
  @$pb.TagNumber(6)
  $core.List<$6.Status> get stepStatus => $_getList(5);
}

///  A build predicate.
///
///  At least one of the following fields is required: builder, gerrit_changes and
///  git_commits.
///  If a field value is empty, it is ignored, unless stated otherwise.
class BuildPredicate extends $pb.GeneratedMessage {
  factory BuildPredicate({
    $2.BuilderID? builder,
    $6.Status? status,
    $core.Iterable<$6.GerritChange>? gerritChanges,
    $6.GitilesCommit? outputGitilesCommit,
    $core.String? createdBy,
    $core.Iterable<$6.StringPair>? tags,
    $6.TimeRange? createTime,
    $core.bool? includeExperimental,
    BuildRange? build,
    $6.Trinary? canary,
    $core.Iterable<$core.String>? experiments,
    $fixnum.Int64? descendantOf,
    $fixnum.Int64? childOf,
  }) {
    final $result = create();
    if (builder != null) {
      $result.builder = builder;
    }
    if (status != null) {
      $result.status = status;
    }
    if (gerritChanges != null) {
      $result.gerritChanges.addAll(gerritChanges);
    }
    if (outputGitilesCommit != null) {
      $result.outputGitilesCommit = outputGitilesCommit;
    }
    if (createdBy != null) {
      $result.createdBy = createdBy;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (includeExperimental != null) {
      $result.includeExperimental = includeExperimental;
    }
    if (build != null) {
      $result.build = build;
    }
    if (canary != null) {
      $result.canary = canary;
    }
    if (experiments != null) {
      $result.experiments.addAll(experiments);
    }
    if (descendantOf != null) {
      $result.descendantOf = descendantOf;
    }
    if (childOf != null) {
      $result.childOf = childOf;
    }
    return $result;
  }
  BuildPredicate._() : super();
  factory BuildPredicate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildPredicate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildPredicate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$2.BuilderID>(1, _omitFieldNames ? '' : 'builder',
        subBuilder: $2.BuilderID.create)
    ..e<$6.Status>(2, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Status.STATUS_UNSPECIFIED,
        valueOf: $6.Status.valueOf,
        enumValues: $6.Status.values)
    ..pc<$6.GerritChange>(
        3, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $6.GerritChange.create)
    ..aOM<$6.GitilesCommit>(4, _omitFieldNames ? '' : 'outputGitilesCommit',
        subBuilder: $6.GitilesCommit.create)
    ..aOS(5, _omitFieldNames ? '' : 'createdBy')
    ..pc<$6.StringPair>(6, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM,
        subBuilder: $6.StringPair.create)
    ..aOM<$6.TimeRange>(7, _omitFieldNames ? '' : 'createTime',
        subBuilder: $6.TimeRange.create)
    ..aOB(8, _omitFieldNames ? '' : 'includeExperimental')
    ..aOM<BuildRange>(9, _omitFieldNames ? '' : 'build',
        subBuilder: BuildRange.create)
    ..e<$6.Trinary>(10, _omitFieldNames ? '' : 'canary', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET,
        valueOf: $6.Trinary.valueOf,
        enumValues: $6.Trinary.values)
    ..pPS(11, _omitFieldNames ? '' : 'experiments')
    ..aInt64(12, _omitFieldNames ? '' : 'descendantOf')
    ..aInt64(13, _omitFieldNames ? '' : 'childOf')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildPredicate clone() => BuildPredicate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildPredicate copyWith(void Function(BuildPredicate) updates) =>
      super.copyWith((message) => updates(message as BuildPredicate))
          as BuildPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildPredicate create() => BuildPredicate._();
  BuildPredicate createEmptyInstance() => create();
  static $pb.PbList<BuildPredicate> createRepeated() =>
      $pb.PbList<BuildPredicate>();
  @$core.pragma('dart2js:noInline')
  static BuildPredicate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildPredicate>(create);
  static BuildPredicate? _defaultInstance;

  /// A build must be in this builder.
  @$pb.TagNumber(1)
  $2.BuilderID get builder => $_getN(0);
  @$pb.TagNumber(1)
  set builder($2.BuilderID v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuilder() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuilder() => clearField(1);
  @$pb.TagNumber(1)
  $2.BuilderID ensureBuilder() => $_ensure(0);

  /// A build must have this status.
  @$pb.TagNumber(2)
  $6.Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($6.Status v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  /// A build's Build.Input.gerrit_changes must include ALL of these changes.
  @$pb.TagNumber(3)
  $core.List<$6.GerritChange> get gerritChanges => $_getList(2);

  ///  DEPRECATED
  ///
  ///  Never implemented.
  @$pb.TagNumber(4)
  $6.GitilesCommit get outputGitilesCommit => $_getN(3);
  @$pb.TagNumber(4)
  set outputGitilesCommit($6.GitilesCommit v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasOutputGitilesCommit() => $_has(3);
  @$pb.TagNumber(4)
  void clearOutputGitilesCommit() => clearField(4);
  @$pb.TagNumber(4)
  $6.GitilesCommit ensureOutputGitilesCommit() => $_ensure(3);

  /// A build must be created by this identity.
  @$pb.TagNumber(5)
  $core.String get createdBy => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdBy($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCreatedBy() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedBy() => clearField(5);

  /// A build must have ALL of these tags.
  /// For "ANY of these tags" make separate RPCs.
  @$pb.TagNumber(6)
  $core.List<$6.StringPair> get tags => $_getList(5);

  /// A build must have been created within the specified range.
  /// Both boundaries are optional.
  @$pb.TagNumber(7)
  $6.TimeRange get createTime => $_getN(6);
  @$pb.TagNumber(7)
  set createTime($6.TimeRange v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasCreateTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreateTime() => clearField(7);
  @$pb.TagNumber(7)
  $6.TimeRange ensureCreateTime() => $_ensure(6);

  ///  If false (the default), equivalent to filtering by experiment
  ///  "-luci.non_production".
  ///
  ///  If true, has no effect (both production and non_production builds will be
  ///  returned).
  ///
  ///  NOTE: If you explicitly search for non_production builds with the experiment
  ///  filter "+luci.non_production", this is implied to be true.
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(8)
  $core.bool get includeExperimental => $_getBF(7);
  @$pb.TagNumber(8)
  set includeExperimental($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasIncludeExperimental() => $_has(7);
  @$pb.TagNumber(8)
  void clearIncludeExperimental() => clearField(8);

  /// A build must be in this build range.
  @$pb.TagNumber(9)
  BuildRange get build => $_getN(8);
  @$pb.TagNumber(9)
  set build(BuildRange v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasBuild() => $_has(8);
  @$pb.TagNumber(9)
  void clearBuild() => clearField(9);
  @$pb.TagNumber(9)
  BuildRange ensureBuild() => $_ensure(8);

  ///  DEPRECATED
  ///
  ///  If YES, equivalent to filtering by experiment
  ///  "+luci.buildbucket.canary_software".
  ///
  ///  If NO, equivalent to filtering by experiment
  ///  "-luci.buildbucket.canary_software".
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(10)
  $6.Trinary get canary => $_getN(9);
  @$pb.TagNumber(10)
  set canary($6.Trinary v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasCanary() => $_has(9);
  @$pb.TagNumber(10)
  void clearCanary() => clearField(10);

  ///  A list of experiments to include or exclude from the search results.
  ///
  ///  Each entry should look like "[-+]$experiment_name".
  ///
  ///  A "+" prefix means that returned builds MUST have that experiment set.
  ///  A "-" prefix means that returned builds MUST NOT have that experiment set
  ///    AND that experiment was known for the builder at the time the build
  ///    was scheduled (either via `Builder.experiments` or via
  ///    `ScheduleBuildRequest.experiments`). Well-known experiments are always
  ///    considered to be available.
  @$pb.TagNumber(11)
  $core.List<$core.String> get experiments => $_getList(10);

  ///  A build ID.
  ///
  ///  Returned builds will be descendants of this build (e.g. "100" means
  ///  "any build transitively scheduled starting from build 100").
  ///
  ///  Mutually exclusive with `child_of`.
  @$pb.TagNumber(12)
  $fixnum.Int64 get descendantOf => $_getI64(11);
  @$pb.TagNumber(12)
  set descendantOf($fixnum.Int64 v) {
    $_setInt64(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasDescendantOf() => $_has(11);
  @$pb.TagNumber(12)
  void clearDescendantOf() => clearField(12);

  ///  A build ID.
  ///
  ///  Returned builds will be only the immediate children of this build.
  ///
  ///  Mutually exclusive with `descendant_of`.
  @$pb.TagNumber(13)
  $fixnum.Int64 get childOf => $_getI64(12);
  @$pb.TagNumber(13)
  set childOf($fixnum.Int64 v) {
    $_setInt64(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasChildOf() => $_has(12);
  @$pb.TagNumber(13)
  void clearChildOf() => clearField(13);
}

/// Open build range.
class BuildRange extends $pb.GeneratedMessage {
  factory BuildRange({
    $fixnum.Int64? startBuildId,
    $fixnum.Int64? endBuildId,
  }) {
    final $result = create();
    if (startBuildId != null) {
      $result.startBuildId = startBuildId;
    }
    if (endBuildId != null) {
      $result.endBuildId = endBuildId;
    }
    return $result;
  }
  BuildRange._() : super();
  factory BuildRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildRange.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'startBuildId')
    ..aInt64(2, _omitFieldNames ? '' : 'endBuildId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildRange clone() => BuildRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildRange copyWith(void Function(BuildRange) updates) =>
      super.copyWith((message) => updates(message as BuildRange)) as BuildRange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildRange create() => BuildRange._();
  BuildRange createEmptyInstance() => create();
  static $pb.PbList<BuildRange> createRepeated() => $pb.PbList<BuildRange>();
  @$core.pragma('dart2js:noInline')
  static BuildRange getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildRange>(create);
  static BuildRange? _defaultInstance;

  /// Inclusive lower (less recent build) boundary. Optional.
  @$pb.TagNumber(1)
  $fixnum.Int64 get startBuildId => $_getI64(0);
  @$pb.TagNumber(1)
  set startBuildId($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStartBuildId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartBuildId() => clearField(1);

  /// Inclusive upper (more recent build) boundary. Optional.
  @$pb.TagNumber(2)
  $fixnum.Int64 get endBuildId => $_getI64(1);
  @$pb.TagNumber(2)
  set endBuildId($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEndBuildId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndBuildId() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
