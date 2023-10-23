//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/empty.pb.dart' as $3;
import '../../../../google/rpc/status.pb.dart' as $4;
import 'builder_common.pb.dart' as $1;
import 'builder_service.pbenum.dart';
import 'common.pb.dart' as $2;

export 'builder_service.pbenum.dart';

class GetBuilderRequest extends $pb.GeneratedMessage {
  factory GetBuilderRequest() => create();
  GetBuilderRequest._() : super();
  factory GetBuilderRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetBuilderRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetBuilderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$1.BuilderID>(1, _omitFieldNames ? '' : 'id', subBuilder: $1.BuilderID.create)
    ..aOM<BuilderMask>(2, _omitFieldNames ? '' : 'mask', subBuilder: BuilderMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetBuilderRequest clone() => GetBuilderRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetBuilderRequest copyWith(void Function(GetBuilderRequest) updates) =>
      super.copyWith((message) => updates(message as GetBuilderRequest)) as GetBuilderRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBuilderRequest create() => GetBuilderRequest._();
  GetBuilderRequest createEmptyInstance() => create();
  static $pb.PbList<GetBuilderRequest> createRepeated() => $pb.PbList<GetBuilderRequest>();
  @$core.pragma('dart2js:noInline')
  static GetBuilderRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetBuilderRequest>(create);
  static GetBuilderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.BuilderID get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($1.BuilderID v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
  @$pb.TagNumber(1)
  $1.BuilderID ensureId() => $_ensure(0);

  @$pb.TagNumber(2)
  BuilderMask get mask => $_getN(1);
  @$pb.TagNumber(2)
  set mask(BuilderMask v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasMask() => $_has(1);
  @$pb.TagNumber(2)
  void clearMask() => clearField(2);
  @$pb.TagNumber(2)
  BuilderMask ensureMask() => $_ensure(1);
}

class ListBuildersRequest extends $pb.GeneratedMessage {
  factory ListBuildersRequest() => create();
  ListBuildersRequest._() : super();
  factory ListBuildersRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListBuildersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListBuildersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..aOS(2, _omitFieldNames ? '' : 'bucket')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListBuildersRequest clone() => ListBuildersRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListBuildersRequest copyWith(void Function(ListBuildersRequest) updates) =>
      super.copyWith((message) => updates(message as ListBuildersRequest)) as ListBuildersRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBuildersRequest create() => ListBuildersRequest._();
  ListBuildersRequest createEmptyInstance() => create();
  static $pb.PbList<ListBuildersRequest> createRepeated() => $pb.PbList<ListBuildersRequest>();
  @$core.pragma('dart2js:noInline')
  static ListBuildersRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListBuildersRequest>(create);
  static ListBuildersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get bucket => $_getSZ(1);
  @$pb.TagNumber(2)
  set bucket($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBucket() => $_has(1);
  @$pb.TagNumber(2)
  void clearBucket() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set pageSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageSize() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(4)
  set pageToken($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(4)
  void clearPageToken() => clearField(4);
}

class ListBuildersResponse extends $pb.GeneratedMessage {
  factory ListBuildersResponse() => create();
  ListBuildersResponse._() : super();
  factory ListBuildersResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListBuildersResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListBuildersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<$1.BuilderItem>(1, _omitFieldNames ? '' : 'builders', $pb.PbFieldType.PM, subBuilder: $1.BuilderItem.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListBuildersResponse clone() => ListBuildersResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListBuildersResponse copyWith(void Function(ListBuildersResponse) updates) =>
      super.copyWith((message) => updates(message as ListBuildersResponse)) as ListBuildersResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListBuildersResponse create() => ListBuildersResponse._();
  ListBuildersResponse createEmptyInstance() => create();
  static $pb.PbList<ListBuildersResponse> createRepeated() => $pb.PbList<ListBuildersResponse>();
  @$core.pragma('dart2js:noInline')
  static ListBuildersResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListBuildersResponse>(create);
  static ListBuildersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$1.BuilderItem> get builders => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get nextPageToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set nextPageToken($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNextPageToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearNextPageToken() => clearField(2);
}

class SetBuilderHealthRequest_BuilderHealth extends $pb.GeneratedMessage {
  factory SetBuilderHealthRequest_BuilderHealth() => create();
  SetBuilderHealthRequest_BuilderHealth._() : super();
  factory SetBuilderHealthRequest_BuilderHealth.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SetBuilderHealthRequest_BuilderHealth.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetBuilderHealthRequest.BuilderHealth',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$1.BuilderID>(1, _omitFieldNames ? '' : 'id', subBuilder: $1.BuilderID.create)
    ..aOM<$2.HealthStatus>(2, _omitFieldNames ? '' : 'health', subBuilder: $2.HealthStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SetBuilderHealthRequest_BuilderHealth clone() => SetBuilderHealthRequest_BuilderHealth()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SetBuilderHealthRequest_BuilderHealth copyWith(void Function(SetBuilderHealthRequest_BuilderHealth) updates) =>
      super.copyWith((message) => updates(message as SetBuilderHealthRequest_BuilderHealth))
          as SetBuilderHealthRequest_BuilderHealth;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthRequest_BuilderHealth create() => SetBuilderHealthRequest_BuilderHealth._();
  SetBuilderHealthRequest_BuilderHealth createEmptyInstance() => create();
  static $pb.PbList<SetBuilderHealthRequest_BuilderHealth> createRepeated() =>
      $pb.PbList<SetBuilderHealthRequest_BuilderHealth>();
  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthRequest_BuilderHealth getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetBuilderHealthRequest_BuilderHealth>(create);
  static SetBuilderHealthRequest_BuilderHealth? _defaultInstance;

  @$pb.TagNumber(1)
  $1.BuilderID get id => $_getN(0);
  @$pb.TagNumber(1)
  set id($1.BuilderID v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
  @$pb.TagNumber(1)
  $1.BuilderID ensureId() => $_ensure(0);

  @$pb.TagNumber(2)
  $2.HealthStatus get health => $_getN(1);
  @$pb.TagNumber(2)
  set health($2.HealthStatus v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasHealth() => $_has(1);
  @$pb.TagNumber(2)
  void clearHealth() => clearField(2);
  @$pb.TagNumber(2)
  $2.HealthStatus ensureHealth() => $_ensure(1);
}

class SetBuilderHealthRequest extends $pb.GeneratedMessage {
  factory SetBuilderHealthRequest() => create();
  SetBuilderHealthRequest._() : super();
  factory SetBuilderHealthRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SetBuilderHealthRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetBuilderHealthRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<SetBuilderHealthRequest_BuilderHealth>(1, _omitFieldNames ? '' : 'health', $pb.PbFieldType.PM,
        subBuilder: SetBuilderHealthRequest_BuilderHealth.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SetBuilderHealthRequest clone() => SetBuilderHealthRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SetBuilderHealthRequest copyWith(void Function(SetBuilderHealthRequest) updates) =>
      super.copyWith((message) => updates(message as SetBuilderHealthRequest)) as SetBuilderHealthRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthRequest create() => SetBuilderHealthRequest._();
  SetBuilderHealthRequest createEmptyInstance() => create();
  static $pb.PbList<SetBuilderHealthRequest> createRepeated() => $pb.PbList<SetBuilderHealthRequest>();
  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetBuilderHealthRequest>(create);
  static SetBuilderHealthRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SetBuilderHealthRequest_BuilderHealth> get health => $_getList(0);
}

enum SetBuilderHealthResponse_Response_Response { result, error, notSet }

class SetBuilderHealthResponse_Response extends $pb.GeneratedMessage {
  factory SetBuilderHealthResponse_Response() => create();
  SetBuilderHealthResponse_Response._() : super();
  factory SetBuilderHealthResponse_Response.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SetBuilderHealthResponse_Response.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SetBuilderHealthResponse_Response_Response>
      _SetBuilderHealthResponse_Response_ResponseByTag = {
    1: SetBuilderHealthResponse_Response_Response.result,
    100: SetBuilderHealthResponse_Response_Response.error,
    0: SetBuilderHealthResponse_Response_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetBuilderHealthResponse.Response',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 100])
    ..aOM<$3.Empty>(1, _omitFieldNames ? '' : 'result', subBuilder: $3.Empty.create)
    ..aOM<$4.Status>(100, _omitFieldNames ? '' : 'error', subBuilder: $4.Status.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SetBuilderHealthResponse_Response clone() => SetBuilderHealthResponse_Response()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SetBuilderHealthResponse_Response copyWith(void Function(SetBuilderHealthResponse_Response) updates) =>
      super.copyWith((message) => updates(message as SetBuilderHealthResponse_Response))
          as SetBuilderHealthResponse_Response;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthResponse_Response create() => SetBuilderHealthResponse_Response._();
  SetBuilderHealthResponse_Response createEmptyInstance() => create();
  static $pb.PbList<SetBuilderHealthResponse_Response> createRepeated() =>
      $pb.PbList<SetBuilderHealthResponse_Response>();
  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthResponse_Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetBuilderHealthResponse_Response>(create);
  static SetBuilderHealthResponse_Response? _defaultInstance;

  SetBuilderHealthResponse_Response_Response whichResponse() =>
      _SetBuilderHealthResponse_Response_ResponseByTag[$_whichOneof(0)]!;
  void clearResponse() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $3.Empty get result => $_getN(0);
  @$pb.TagNumber(1)
  set result($3.Empty v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);
  @$pb.TagNumber(1)
  $3.Empty ensureResult() => $_ensure(0);

  @$pb.TagNumber(100)
  $4.Status get error => $_getN(1);
  @$pb.TagNumber(100)
  set error($4.Status v) {
    setField(100, v);
  }

  @$pb.TagNumber(100)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(100)
  void clearError() => clearField(100);
  @$pb.TagNumber(100)
  $4.Status ensureError() => $_ensure(1);
}

class SetBuilderHealthResponse extends $pb.GeneratedMessage {
  factory SetBuilderHealthResponse() => create();
  SetBuilderHealthResponse._() : super();
  factory SetBuilderHealthResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SetBuilderHealthResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetBuilderHealthResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<SetBuilderHealthResponse_Response>(1, _omitFieldNames ? '' : 'responses', $pb.PbFieldType.PM,
        subBuilder: SetBuilderHealthResponse_Response.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SetBuilderHealthResponse clone() => SetBuilderHealthResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SetBuilderHealthResponse copyWith(void Function(SetBuilderHealthResponse) updates) =>
      super.copyWith((message) => updates(message as SetBuilderHealthResponse)) as SetBuilderHealthResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthResponse create() => SetBuilderHealthResponse._();
  SetBuilderHealthResponse createEmptyInstance() => create();
  static $pb.PbList<SetBuilderHealthResponse> createRepeated() => $pb.PbList<SetBuilderHealthResponse>();
  @$core.pragma('dart2js:noInline')
  static SetBuilderHealthResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetBuilderHealthResponse>(create);
  static SetBuilderHealthResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SetBuilderHealthResponse_Response> get responses => $_getList(0);
}

class BuilderMask extends $pb.GeneratedMessage {
  factory BuilderMask() => create();
  BuilderMask._() : super();
  factory BuilderMask.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderMask.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderMask',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..e<BuilderMask_BuilderMaskType>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: BuilderMask_BuilderMaskType.BUILDER_MASK_TYPE_UNSPECIFIED,
        valueOf: BuilderMask_BuilderMaskType.valueOf,
        enumValues: BuilderMask_BuilderMaskType.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderMask clone() => BuilderMask()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderMask copyWith(void Function(BuilderMask) updates) =>
      super.copyWith((message) => updates(message as BuilderMask)) as BuilderMask;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderMask create() => BuilderMask._();
  BuilderMask createEmptyInstance() => create();
  static $pb.PbList<BuilderMask> createRepeated() => $pb.PbList<BuilderMask>();
  @$core.pragma('dart2js:noInline')
  static BuilderMask getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderMask>(create);
  static BuilderMask? _defaultInstance;

  @$pb.TagNumber(1)
  BuilderMask_BuilderMaskType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(BuilderMask_BuilderMaskType v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
