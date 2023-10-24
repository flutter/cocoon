//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builds_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
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
import 'launcher.pb.dart' as $11;
import 'notification.pb.dart' as $7;
import 'task.pb.dart' as $10;

class GetBuildRequest extends $pb.GeneratedMessage {
  factory GetBuildRequest() => create();
  GetBuildRequest._() : super();
  factory GetBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder', subBuilder: $2.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetBuildRequest clone() => GetBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetBuildRequest copyWith(void Function(GetBuildRequest) updates) =>
      super.copyWith((message) => updates(message as GetBuildRequest)) as GetBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBuildRequest create() => GetBuildRequest._();
  GetBuildRequest createEmptyInstance() => create();
  static $pb.PbList<GetBuildRequest> createRepeated() => $pb.PbList<GetBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBuildRequest>(create);
  static GetBuildRequest? _defaultInstance;

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

class SearchBuildsRequest extends $pb.GeneratedMessage {
  factory SearchBuildsRequest() => create();
  SearchBuildsRequest._() : super();
  factory SearchBuildsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchBuildsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchBuildsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildPredicate>(1, _omitFieldNames ? '' : 'predicate', subBuilder: BuildPredicate.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..a<$core.int>(101, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(102, _omitFieldNames ? '' : 'pageToken')
    ..aOM<BuildMask>(103, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchBuildsRequest clone() => SearchBuildsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchBuildsRequest copyWith(void Function(SearchBuildsRequest) updates) =>
      super.copyWith((message) => updates(message as SearchBuildsRequest)) as SearchBuildsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchBuildsRequest create() => SearchBuildsRequest._();
  SearchBuildsRequest createEmptyInstance() => create();
  static $pb.PbList<SearchBuildsRequest> createRepeated() => $pb.PbList<SearchBuildsRequest>();
  @$core.pragma('dart2js:noInline')
  static SearchBuildsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchBuildsRequest>(create);
  static SearchBuildsRequest? _defaultInstance;

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

class SearchBuildsResponse extends $pb.GeneratedMessage {
  factory SearchBuildsResponse() => create();
  SearchBuildsResponse._() : super();
  factory SearchBuildsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SearchBuildsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SearchBuildsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<$1.Build>(1, _omitFieldNames ? '' : 'builds', $pb.PbFieldType.PM, subBuilder: $1.Build.create)
    ..aOS(100, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SearchBuildsResponse clone() => SearchBuildsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SearchBuildsResponse copyWith(void Function(SearchBuildsResponse) updates) =>
      super.copyWith((message) => updates(message as SearchBuildsResponse)) as SearchBuildsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SearchBuildsResponse create() => SearchBuildsResponse._();
  SearchBuildsResponse createEmptyInstance() => create();
  static $pb.PbList<SearchBuildsResponse> createRepeated() => $pb.PbList<SearchBuildsResponse>();
  @$core.pragma('dart2js:noInline')
  static SearchBuildsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SearchBuildsResponse>(create);
  static SearchBuildsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$1.Build> get builds => $_getList(0);

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

enum BatchRequest_Request_Request { getBuild, searchBuilds, scheduleBuild, cancelBuild, getBuildStatus, notSet }

class BatchRequest_Request extends $pb.GeneratedMessage {
  factory BatchRequest_Request() => create();
  BatchRequest_Request._() : super();
  factory BatchRequest_Request.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchRequest_Request.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BatchRequest_Request_Request> _BatchRequest_Request_RequestByTag = {
    1: BatchRequest_Request_Request.getBuild,
    2: BatchRequest_Request_Request.searchBuilds,
    3: BatchRequest_Request_Request.scheduleBuild,
    4: BatchRequest_Request_Request.cancelBuild,
    5: BatchRequest_Request_Request.getBuildStatus,
    0: BatchRequest_Request_Request.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BatchRequest.Request',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5])
    ..aOM<GetBuildRequest>(1, _omitFieldNames ? '' : 'getBuild', subBuilder: GetBuildRequest.create)
    ..aOM<SearchBuildsRequest>(2, _omitFieldNames ? '' : 'searchBuilds', subBuilder: SearchBuildsRequest.create)
    ..aOM<ScheduleBuildRequest>(3, _omitFieldNames ? '' : 'scheduleBuild', subBuilder: ScheduleBuildRequest.create)
    ..aOM<CancelBuildRequest>(4, _omitFieldNames ? '' : 'cancelBuild', subBuilder: CancelBuildRequest.create)
    ..aOM<GetBuildStatusRequest>(5, _omitFieldNames ? '' : 'getBuildStatus', subBuilder: GetBuildStatusRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchRequest_Request clone() => BatchRequest_Request()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchRequest_Request copyWith(void Function(BatchRequest_Request) updates) =>
      super.copyWith((message) => updates(message as BatchRequest_Request)) as BatchRequest_Request;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchRequest_Request create() => BatchRequest_Request._();
  BatchRequest_Request createEmptyInstance() => create();
  static $pb.PbList<BatchRequest_Request> createRepeated() => $pb.PbList<BatchRequest_Request>();
  @$core.pragma('dart2js:noInline')
  static BatchRequest_Request getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatchRequest_Request>(create);
  static BatchRequest_Request? _defaultInstance;

  BatchRequest_Request_Request whichRequest() => _BatchRequest_Request_RequestByTag[$_whichOneof(0)]!;
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

class BatchRequest extends $pb.GeneratedMessage {
  factory BatchRequest() => create();
  BatchRequest._() : super();
  factory BatchRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BatchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<BatchRequest_Request>(1, _omitFieldNames ? '' : 'requests', $pb.PbFieldType.PM,
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
      super.copyWith((message) => updates(message as BatchRequest)) as BatchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchRequest create() => BatchRequest._();
  BatchRequest createEmptyInstance() => create();
  static $pb.PbList<BatchRequest> createRepeated() => $pb.PbList<BatchRequest>();
  @$core.pragma('dart2js:noInline')
  static BatchRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatchRequest>(create);
  static BatchRequest? _defaultInstance;

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

class BatchResponse_Response extends $pb.GeneratedMessage {
  factory BatchResponse_Response() => create();
  BatchResponse_Response._() : super();
  factory BatchResponse_Response.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchResponse_Response.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BatchResponse_Response_Response> _BatchResponse_Response_ResponseByTag = {
    1: BatchResponse_Response_Response.getBuild,
    2: BatchResponse_Response_Response.searchBuilds,
    3: BatchResponse_Response_Response.scheduleBuild,
    4: BatchResponse_Response_Response.cancelBuild,
    5: BatchResponse_Response_Response.getBuildStatus,
    100: BatchResponse_Response_Response.error,
    0: BatchResponse_Response_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BatchResponse.Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 100])
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'getBuild', subBuilder: $1.Build.create)
    ..aOM<SearchBuildsResponse>(2, _omitFieldNames ? '' : 'searchBuilds', subBuilder: SearchBuildsResponse.create)
    ..aOM<$1.Build>(3, _omitFieldNames ? '' : 'scheduleBuild', subBuilder: $1.Build.create)
    ..aOM<$1.Build>(4, _omitFieldNames ? '' : 'cancelBuild', subBuilder: $1.Build.create)
    ..aOM<$1.Build>(5, _omitFieldNames ? '' : 'getBuildStatus', subBuilder: $1.Build.create)
    ..aOM<$4.Status>(100, _omitFieldNames ? '' : 'error', subBuilder: $4.Status.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchResponse_Response clone() => BatchResponse_Response()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchResponse_Response copyWith(void Function(BatchResponse_Response) updates) =>
      super.copyWith((message) => updates(message as BatchResponse_Response)) as BatchResponse_Response;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchResponse_Response create() => BatchResponse_Response._();
  BatchResponse_Response createEmptyInstance() => create();
  static $pb.PbList<BatchResponse_Response> createRepeated() => $pb.PbList<BatchResponse_Response>();
  @$core.pragma('dart2js:noInline')
  static BatchResponse_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatchResponse_Response>(create);
  static BatchResponse_Response? _defaultInstance;

  BatchResponse_Response_Response whichResponse() => _BatchResponse_Response_ResponseByTag[$_whichOneof(0)]!;
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

class BatchResponse extends $pb.GeneratedMessage {
  factory BatchResponse() => create();
  BatchResponse._() : super();
  factory BatchResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BatchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<BatchResponse_Response>(1, _omitFieldNames ? '' : 'responses', $pb.PbFieldType.PM,
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
      super.copyWith((message) => updates(message as BatchResponse)) as BatchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchResponse create() => BatchResponse._();
  BatchResponse createEmptyInstance() => create();
  static $pb.PbList<BatchResponse> createRepeated() => $pb.PbList<BatchResponse>();
  @$core.pragma('dart2js:noInline')
  static BatchResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BatchResponse>(create);
  static BatchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BatchResponse_Response> get responses => $_getList(0);
}

class UpdateBuildRequest extends $pb.GeneratedMessage {
  factory UpdateBuildRequest() => create();
  UpdateBuildRequest._() : super();
  factory UpdateBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory UpdateBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build', subBuilder: $1.Build.create)
    ..aOM<$3.FieldMask>(2, _omitFieldNames ? '' : 'updateMask', subBuilder: $3.FieldMask.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  UpdateBuildRequest clone() => UpdateBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  UpdateBuildRequest copyWith(void Function(UpdateBuildRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateBuildRequest)) as UpdateBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateBuildRequest create() => UpdateBuildRequest._();
  UpdateBuildRequest createEmptyInstance() => create();
  static $pb.PbList<UpdateBuildRequest> createRepeated() => $pb.PbList<UpdateBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static UpdateBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateBuildRequest>(create);
  static UpdateBuildRequest? _defaultInstance;

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

class ScheduleBuildRequest_Swarming extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest_Swarming() => create();
  ScheduleBuildRequest_Swarming._() : super();
  factory ScheduleBuildRequest_Swarming.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest_Swarming.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ScheduleBuildRequest.Swarming',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parentRunId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_Swarming clone() => ScheduleBuildRequest_Swarming()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_Swarming copyWith(void Function(ScheduleBuildRequest_Swarming) updates) =>
      super.copyWith((message) => updates(message as ScheduleBuildRequest_Swarming)) as ScheduleBuildRequest_Swarming;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_Swarming create() => ScheduleBuildRequest_Swarming._();
  ScheduleBuildRequest_Swarming createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest_Swarming> createRepeated() => $pb.PbList<ScheduleBuildRequest_Swarming>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_Swarming getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest_Swarming>(create);
  static ScheduleBuildRequest_Swarming? _defaultInstance;

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

class ScheduleBuildRequest_ShadowInput extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest_ShadowInput() => create();
  ScheduleBuildRequest_ShadowInput._() : super();
  factory ScheduleBuildRequest_ShadowInput.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest_ShadowInput.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ScheduleBuildRequest.ShadowInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_ShadowInput clone() => ScheduleBuildRequest_ShadowInput()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest_ShadowInput copyWith(void Function(ScheduleBuildRequest_ShadowInput) updates) =>
      super.copyWith((message) => updates(message as ScheduleBuildRequest_ShadowInput))
          as ScheduleBuildRequest_ShadowInput;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_ShadowInput create() => ScheduleBuildRequest_ShadowInput._();
  ScheduleBuildRequest_ShadowInput createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest_ShadowInput> createRepeated() =>
      $pb.PbList<ScheduleBuildRequest_ShadowInput>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest_ShadowInput getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest_ShadowInput>(create);
  static ScheduleBuildRequest_ShadowInput? _defaultInstance;
}

class ScheduleBuildRequest extends $pb.GeneratedMessage {
  factory ScheduleBuildRequest() => create();
  ScheduleBuildRequest._() : super();
  factory ScheduleBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ScheduleBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ScheduleBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aInt64(2, _omitFieldNames ? '' : 'templateBuildId')
    ..aOM<$2.BuilderID>(3, _omitFieldNames ? '' : 'builder', subBuilder: $2.BuilderID.create)
    ..e<$6.Trinary>(4, _omitFieldNames ? '' : 'canary', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
    ..e<$6.Trinary>(5, _omitFieldNames ? '' : 'experimental', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
    ..aOM<$5.Struct>(6, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOM<$6.GitilesCommit>(7, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $6.GitilesCommit.create)
    ..pc<$6.GerritChange>(8, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $6.GerritChange.create)
    ..pc<$6.StringPair>(9, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $6.StringPair.create)
    ..pc<$6.RequestedDimension>(10, _omitFieldNames ? '' : 'dimensions', $pb.PbFieldType.PM,
        subBuilder: $6.RequestedDimension.create)
    ..a<$core.int>(11, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.O3)
    ..aOM<$7.NotificationConfig>(12, _omitFieldNames ? '' : 'notify', subBuilder: $7.NotificationConfig.create)
    ..e<$6.Trinary>(13, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
    ..aOM<$6.Executable>(14, _omitFieldNames ? '' : 'exe', subBuilder: $6.Executable.create)
    ..aOM<ScheduleBuildRequest_Swarming>(15, _omitFieldNames ? '' : 'swarming',
        subBuilder: ScheduleBuildRequest_Swarming.create)
    ..m<$core.String, $core.bool>(16, _omitFieldNames ? '' : 'experiments',
        entryClassName: 'ScheduleBuildRequest.ExperimentsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<$8.Duration>(17, _omitFieldNames ? '' : 'schedulingTimeout', subBuilder: $8.Duration.create)
    ..aOM<$8.Duration>(18, _omitFieldNames ? '' : 'executionTimeout', subBuilder: $8.Duration.create)
    ..aOM<$8.Duration>(19, _omitFieldNames ? '' : 'gracePeriod', subBuilder: $8.Duration.create)
    ..aOB(20, _omitFieldNames ? '' : 'dryRun')
    ..e<$6.Trinary>(21, _omitFieldNames ? '' : 'canOutliveParent', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
    ..e<$6.Trinary>(22, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
    ..aOM<ScheduleBuildRequest_ShadowInput>(23, _omitFieldNames ? '' : 'shadowInput',
        subBuilder: ScheduleBuildRequest_ShadowInput.create)
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest clone() => ScheduleBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ScheduleBuildRequest copyWith(void Function(ScheduleBuildRequest) updates) =>
      super.copyWith((message) => updates(message as ScheduleBuildRequest)) as ScheduleBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest create() => ScheduleBuildRequest._();
  ScheduleBuildRequest createEmptyInstance() => create();
  static $pb.PbList<ScheduleBuildRequest> createRepeated() => $pb.PbList<ScheduleBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static ScheduleBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ScheduleBuildRequest>(create);
  static ScheduleBuildRequest? _defaultInstance;

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

  @$pb.TagNumber(8)
  $core.List<$6.GerritChange> get gerritChanges => $_getList(7);

  @$pb.TagNumber(9)
  $core.List<$6.StringPair> get tags => $_getList(8);

  @$pb.TagNumber(10)
  $core.List<$6.RequestedDimension> get dimensions => $_getList(9);

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

  @$pb.TagNumber(16)
  $core.Map<$core.String, $core.bool> get experiments => $_getMap(15);

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

class CancelBuildRequest extends $pb.GeneratedMessage {
  factory CancelBuildRequest() => create();
  CancelBuildRequest._() : super();
  factory CancelBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CancelBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CancelBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'summaryMarkdown')
    ..aOM<$3.FieldMask>(100, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..aOM<BuildMask>(101, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CancelBuildRequest clone() => CancelBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CancelBuildRequest copyWith(void Function(CancelBuildRequest) updates) =>
      super.copyWith((message) => updates(message as CancelBuildRequest)) as CancelBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CancelBuildRequest create() => CancelBuildRequest._();
  CancelBuildRequest createEmptyInstance() => create();
  static $pb.PbList<CancelBuildRequest> createRepeated() => $pb.PbList<CancelBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static CancelBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CancelBuildRequest>(create);
  static CancelBuildRequest? _defaultInstance;

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

class CreateBuildRequest extends $pb.GeneratedMessage {
  factory CreateBuildRequest() => create();
  CreateBuildRequest._() : super();
  factory CreateBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CreateBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build', subBuilder: $1.Build.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<BuildMask>(3, _omitFieldNames ? '' : 'mask', subBuilder: BuildMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CreateBuildRequest clone() => CreateBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CreateBuildRequest copyWith(void Function(CreateBuildRequest) updates) =>
      super.copyWith((message) => updates(message as CreateBuildRequest)) as CreateBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateBuildRequest create() => CreateBuildRequest._();
  CreateBuildRequest createEmptyInstance() => create();
  static $pb.PbList<CreateBuildRequest> createRepeated() => $pb.PbList<CreateBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static CreateBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CreateBuildRequest>(create);
  static CreateBuildRequest? _defaultInstance;

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

class SynthesizeBuildRequest extends $pb.GeneratedMessage {
  factory SynthesizeBuildRequest() => create();
  SynthesizeBuildRequest._() : super();
  factory SynthesizeBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SynthesizeBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SynthesizeBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'templateBuildId')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder', subBuilder: $2.BuilderID.create)
    ..m<$core.String, $core.bool>(3, _omitFieldNames ? '' : 'experiments',
        entryClassName: 'SynthesizeBuildRequest.ExperimentsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OB,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SynthesizeBuildRequest clone() => SynthesizeBuildRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SynthesizeBuildRequest copyWith(void Function(SynthesizeBuildRequest) updates) =>
      super.copyWith((message) => updates(message as SynthesizeBuildRequest)) as SynthesizeBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SynthesizeBuildRequest create() => SynthesizeBuildRequest._();
  SynthesizeBuildRequest createEmptyInstance() => create();
  static $pb.PbList<SynthesizeBuildRequest> createRepeated() => $pb.PbList<SynthesizeBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static SynthesizeBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SynthesizeBuildRequest>(create);
  static SynthesizeBuildRequest? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.Map<$core.String, $core.bool> get experiments => $_getMap(2);
}

class StartBuildRequest extends $pb.GeneratedMessage {
  factory StartBuildRequest() => create();
  StartBuildRequest._() : super();
  factory StartBuildRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartBuildRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
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
      super.copyWith((message) => updates(message as StartBuildRequest)) as StartBuildRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildRequest create() => StartBuildRequest._();
  StartBuildRequest createEmptyInstance() => create();
  static $pb.PbList<StartBuildRequest> createRepeated() => $pb.PbList<StartBuildRequest>();
  @$core.pragma('dart2js:noInline')
  static StartBuildRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartBuildRequest>(create);
  static StartBuildRequest? _defaultInstance;

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

class StartBuildResponse extends $pb.GeneratedMessage {
  factory StartBuildResponse() => create();
  StartBuildResponse._() : super();
  factory StartBuildResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartBuildResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$1.Build>(1, _omitFieldNames ? '' : 'build', subBuilder: $1.Build.create)
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
      super.copyWith((message) => updates(message as StartBuildResponse)) as StartBuildResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildResponse create() => StartBuildResponse._();
  StartBuildResponse createEmptyInstance() => create();
  static $pb.PbList<StartBuildResponse> createRepeated() => $pb.PbList<StartBuildResponse>();
  @$core.pragma('dart2js:noInline')
  static StartBuildResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartBuildResponse>(create);
  static StartBuildResponse? _defaultInstance;

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

class GetBuildStatusRequest extends $pb.GeneratedMessage {
  factory GetBuildStatusRequest() => create();
  GetBuildStatusRequest._() : super();
  factory GetBuildStatusRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetBuildStatusRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBuildStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$2.BuilderID>(2, _omitFieldNames ? '' : 'builder', subBuilder: $2.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetBuildStatusRequest clone() => GetBuildStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetBuildStatusRequest copyWith(void Function(GetBuildStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetBuildStatusRequest)) as GetBuildStatusRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBuildStatusRequest create() => GetBuildStatusRequest._();
  GetBuildStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetBuildStatusRequest> createRepeated() => $pb.PbList<GetBuildStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBuildStatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBuildStatusRequest>(create);
  static GetBuildStatusRequest? _defaultInstance;

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

class BuildMask extends $pb.GeneratedMessage {
  factory BuildMask() => create();
  BuildMask._() : super();
  factory BuildMask.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildMask.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildMask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$3.FieldMask>(1, _omitFieldNames ? '' : 'fields', subBuilder: $3.FieldMask.create)
    ..pc<$9.StructMask>(2, _omitFieldNames ? '' : 'inputProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..pc<$9.StructMask>(3, _omitFieldNames ? '' : 'outputProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..pc<$9.StructMask>(4, _omitFieldNames ? '' : 'requestedProperties', $pb.PbFieldType.PM,
        subBuilder: $9.StructMask.create)
    ..aOB(5, _omitFieldNames ? '' : 'allFields')
    ..pc<$6.Status>(6, _omitFieldNames ? '' : 'stepStatus', $pb.PbFieldType.KE,
        valueOf: $6.Status.valueOf, enumValues: $6.Status.values, defaultEnumValue: $6.Status.STATUS_UNSPECIFIED)
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
  static BuildMask getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildMask>(create);
  static BuildMask? _defaultInstance;

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

  @$pb.TagNumber(2)
  $core.List<$9.StructMask> get inputProperties => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$9.StructMask> get outputProperties => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$9.StructMask> get requestedProperties => $_getList(3);

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

  @$pb.TagNumber(6)
  $core.List<$6.Status> get stepStatus => $_getList(5);
}

class BuildPredicate extends $pb.GeneratedMessage {
  factory BuildPredicate() => create();
  BuildPredicate._() : super();
  factory BuildPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildPredicate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$2.BuilderID>(1, _omitFieldNames ? '' : 'builder', subBuilder: $2.BuilderID.create)
    ..e<$6.Status>(2, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Status.STATUS_UNSPECIFIED, valueOf: $6.Status.valueOf, enumValues: $6.Status.values)
    ..pc<$6.GerritChange>(3, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $6.GerritChange.create)
    ..aOM<$6.GitilesCommit>(4, _omitFieldNames ? '' : 'outputGitilesCommit', subBuilder: $6.GitilesCommit.create)
    ..aOS(5, _omitFieldNames ? '' : 'createdBy')
    ..pc<$6.StringPair>(6, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $6.StringPair.create)
    ..aOM<$6.TimeRange>(7, _omitFieldNames ? '' : 'createTime', subBuilder: $6.TimeRange.create)
    ..aOB(8, _omitFieldNames ? '' : 'includeExperimental')
    ..aOM<BuildRange>(9, _omitFieldNames ? '' : 'build', subBuilder: BuildRange.create)
    ..e<$6.Trinary>(10, _omitFieldNames ? '' : 'canary', $pb.PbFieldType.OE,
        defaultOrMaker: $6.Trinary.UNSET, valueOf: $6.Trinary.valueOf, enumValues: $6.Trinary.values)
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
      super.copyWith((message) => updates(message as BuildPredicate)) as BuildPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildPredicate create() => BuildPredicate._();
  BuildPredicate createEmptyInstance() => create();
  static $pb.PbList<BuildPredicate> createRepeated() => $pb.PbList<BuildPredicate>();
  @$core.pragma('dart2js:noInline')
  static BuildPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildPredicate>(create);
  static BuildPredicate? _defaultInstance;

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

  @$pb.TagNumber(3)
  $core.List<$6.GerritChange> get gerritChanges => $_getList(2);

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

  @$pb.TagNumber(6)
  $core.List<$6.StringPair> get tags => $_getList(5);

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

  @$pb.TagNumber(11)
  $core.List<$core.String> get experiments => $_getList(10);

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

class BuildRange extends $pb.GeneratedMessage {
  factory BuildRange() => create();
  BuildRange._() : super();
  factory BuildRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
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
  static BuildRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildRange>(create);
  static BuildRange? _defaultInstance;

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

class StartBuildTaskRequest extends $pb.GeneratedMessage {
  factory StartBuildTaskRequest() => create();
  StartBuildTaskRequest._() : super();
  factory StartBuildTaskRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildTaskRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartBuildTaskRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'requestId')
    ..aInt64(2, _omitFieldNames ? '' : 'buildId')
    ..aOM<$10.Task>(3, _omitFieldNames ? '' : 'task', subBuilder: $10.Task.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartBuildTaskRequest clone() => StartBuildTaskRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartBuildTaskRequest copyWith(void Function(StartBuildTaskRequest) updates) =>
      super.copyWith((message) => updates(message as StartBuildTaskRequest)) as StartBuildTaskRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildTaskRequest create() => StartBuildTaskRequest._();
  StartBuildTaskRequest createEmptyInstance() => create();
  static $pb.PbList<StartBuildTaskRequest> createRepeated() => $pb.PbList<StartBuildTaskRequest>();
  @$core.pragma('dart2js:noInline')
  static StartBuildTaskRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartBuildTaskRequest>(create);
  static StartBuildTaskRequest? _defaultInstance;

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

  @$pb.TagNumber(3)
  $10.Task get task => $_getN(2);
  @$pb.TagNumber(3)
  set task($10.Task v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTask() => $_has(2);
  @$pb.TagNumber(3)
  void clearTask() => clearField(3);
  @$pb.TagNumber(3)
  $10.Task ensureTask() => $_ensure(2);
}

class StartBuildTaskResponse extends $pb.GeneratedMessage {
  factory StartBuildTaskResponse() => create();
  StartBuildTaskResponse._() : super();
  factory StartBuildTaskResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StartBuildTaskResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartBuildTaskResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$11.BuildSecrets>(1, _omitFieldNames ? '' : 'secrets', subBuilder: $11.BuildSecrets.create)
    ..aOS(2, _omitFieldNames ? '' : 'pubsubTopic')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StartBuildTaskResponse clone() => StartBuildTaskResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StartBuildTaskResponse copyWith(void Function(StartBuildTaskResponse) updates) =>
      super.copyWith((message) => updates(message as StartBuildTaskResponse)) as StartBuildTaskResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartBuildTaskResponse create() => StartBuildTaskResponse._();
  StartBuildTaskResponse createEmptyInstance() => create();
  static $pb.PbList<StartBuildTaskResponse> createRepeated() => $pb.PbList<StartBuildTaskResponse>();
  @$core.pragma('dart2js:noInline')
  static StartBuildTaskResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartBuildTaskResponse>(create);
  static StartBuildTaskResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $11.BuildSecrets get secrets => $_getN(0);
  @$pb.TagNumber(1)
  set secrets($11.BuildSecrets v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSecrets() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecrets() => clearField(1);
  @$pb.TagNumber(1)
  $11.BuildSecrets ensureSecrets() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get pubsubTopic => $_getSZ(1);
  @$pb.TagNumber(2)
  set pubsubTopic($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPubsubTopic() => $_has(1);
  @$pb.TagNumber(2)
  void clearPubsubTopic() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
