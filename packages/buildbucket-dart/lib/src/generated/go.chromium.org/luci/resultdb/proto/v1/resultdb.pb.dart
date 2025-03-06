//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/resultdb.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/field_mask.pb.dart' as $4;
import 'artifact.pb.dart' as $3;
import 'invocation.pb.dart' as $1;
import 'predicate.pb.dart' as $5;
import 'test_metadata.pb.dart' as $7;
import 'test_result.pb.dart' as $2;
import 'test_variant.pb.dart' as $6;

/// A request message for GetInvocation RPC.
class GetInvocationRequest extends $pb.GeneratedMessage {
  factory GetInvocationRequest({
    $core.String? name,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  GetInvocationRequest._() : super();
  factory GetInvocationRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetInvocationRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetInvocationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetInvocationRequest clone() =>
      GetInvocationRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetInvocationRequest copyWith(void Function(GetInvocationRequest) updates) =>
      super.copyWith((message) => updates(message as GetInvocationRequest))
          as GetInvocationRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetInvocationRequest create() => GetInvocationRequest._();
  GetInvocationRequest createEmptyInstance() => create();
  static $pb.PbList<GetInvocationRequest> createRepeated() =>
      $pb.PbList<GetInvocationRequest>();
  @$core.pragma('dart2js:noInline')
  static GetInvocationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetInvocationRequest>(create);
  static GetInvocationRequest? _defaultInstance;

  /// The name of the invocation to request, see Invocation.name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

/// A request message for GetTestResult RPC.
class GetTestResultRequest extends $pb.GeneratedMessage {
  factory GetTestResultRequest({
    $core.String? name,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  GetTestResultRequest._() : super();
  factory GetTestResultRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetTestResultRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTestResultRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetTestResultRequest clone() =>
      GetTestResultRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetTestResultRequest copyWith(void Function(GetTestResultRequest) updates) =>
      super.copyWith((message) => updates(message as GetTestResultRequest))
          as GetTestResultRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTestResultRequest create() => GetTestResultRequest._();
  GetTestResultRequest createEmptyInstance() => create();
  static $pb.PbList<GetTestResultRequest> createRepeated() =>
      $pb.PbList<GetTestResultRequest>();
  @$core.pragma('dart2js:noInline')
  static GetTestResultRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTestResultRequest>(create);
  static GetTestResultRequest? _defaultInstance;

  /// The name of the test result to request, see TestResult.name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

/// A request message for ListTestResults RPC.
class ListTestResultsRequest extends $pb.GeneratedMessage {
  factory ListTestResultsRequest({
    $core.String? invocation,
    $core.int? pageSize,
    $core.String? pageToken,
    $4.FieldMask? readMask,
  }) {
    final $result = create();
    if (invocation != null) {
      $result.invocation = invocation;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    if (readMask != null) {
      $result.readMask = readMask;
    }
    return $result;
  }
  ListTestResultsRequest._() : super();
  factory ListTestResultsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListTestResultsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTestResultsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invocation')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..aOM<$4.FieldMask>(4, _omitFieldNames ? '' : 'readMask',
        subBuilder: $4.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListTestResultsRequest clone() =>
      ListTestResultsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListTestResultsRequest copyWith(
          void Function(ListTestResultsRequest) updates) =>
      super.copyWith((message) => updates(message as ListTestResultsRequest))
          as ListTestResultsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTestResultsRequest create() => ListTestResultsRequest._();
  ListTestResultsRequest createEmptyInstance() => create();
  static $pb.PbList<ListTestResultsRequest> createRepeated() =>
      $pb.PbList<ListTestResultsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListTestResultsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTestResultsRequest>(create);
  static ListTestResultsRequest? _defaultInstance;

  /// Name of the invocation, e.g. "invocations/{id}".
  @$pb.TagNumber(1)
  $core.String get invocation => $_getSZ(0);
  @$pb.TagNumber(1)
  set invocation($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInvocation() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvocation() => clearField(1);

  ///  The maximum number of test results to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 test results will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => clearField(2);

  ///  A page token, received from a previous `ListTestResults` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `ListTestResults` MUST
  ///  match the call that provided the page token.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => clearField(3);

  /// Fields to include in the response.
  /// If not set, the default mask is used where summary_html and tags are
  /// excluded.
  /// Test result names will always be included even if "name" is not a part of
  /// the mask.
  @$pb.TagNumber(4)
  $4.FieldMask get readMask => $_getN(3);
  @$pb.TagNumber(4)
  set readMask($4.FieldMask v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasReadMask() => $_has(3);
  @$pb.TagNumber(4)
  void clearReadMask() => clearField(4);
  @$pb.TagNumber(4)
  $4.FieldMask ensureReadMask() => $_ensure(3);
}

/// A response message for ListTestResults RPC.
class ListTestResultsResponse extends $pb.GeneratedMessage {
  factory ListTestResultsResponse({
    $core.Iterable<$2.TestResult>? testResults,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (testResults != null) {
      $result.testResults.addAll(testResults);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  ListTestResultsResponse._() : super();
  factory ListTestResultsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListTestResultsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTestResultsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$2.TestResult>(
        1, _omitFieldNames ? '' : 'testResults', $pb.PbFieldType.PM,
        subBuilder: $2.TestResult.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListTestResultsResponse clone() =>
      ListTestResultsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListTestResultsResponse copyWith(
          void Function(ListTestResultsResponse) updates) =>
      super.copyWith((message) => updates(message as ListTestResultsResponse))
          as ListTestResultsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTestResultsResponse create() => ListTestResultsResponse._();
  ListTestResultsResponse createEmptyInstance() => create();
  static $pb.PbList<ListTestResultsResponse> createRepeated() =>
      $pb.PbList<ListTestResultsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListTestResultsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTestResultsResponse>(create);
  static ListTestResultsResponse? _defaultInstance;

  /// The test results from the specified invocation.
  @$pb.TagNumber(1)
  $core.List<$2.TestResult> get testResults => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
  /// If the invocation is not finalized, more results may appear later.
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

/// A request message for GetTestExoneration RPC.
class GetTestExonerationRequest extends $pb.GeneratedMessage {
  factory GetTestExonerationRequest({
    $core.String? name,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  GetTestExonerationRequest._() : super();
  factory GetTestExonerationRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetTestExonerationRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetTestExonerationRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetTestExonerationRequest clone() =>
      GetTestExonerationRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetTestExonerationRequest copyWith(
          void Function(GetTestExonerationRequest) updates) =>
      super.copyWith((message) => updates(message as GetTestExonerationRequest))
          as GetTestExonerationRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetTestExonerationRequest create() => GetTestExonerationRequest._();
  GetTestExonerationRequest createEmptyInstance() => create();
  static $pb.PbList<GetTestExonerationRequest> createRepeated() =>
      $pb.PbList<GetTestExonerationRequest>();
  @$core.pragma('dart2js:noInline')
  static GetTestExonerationRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetTestExonerationRequest>(create);
  static GetTestExonerationRequest? _defaultInstance;

  /// The name of the test exoneration to request, see TestExoneration.name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

/// A request message for ListTestExonerations RPC.
class ListTestExonerationsRequest extends $pb.GeneratedMessage {
  factory ListTestExonerationsRequest({
    $core.String? invocation,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final $result = create();
    if (invocation != null) {
      $result.invocation = invocation;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    return $result;
  }
  ListTestExonerationsRequest._() : super();
  factory ListTestExonerationsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListTestExonerationsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTestExonerationsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invocation')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListTestExonerationsRequest clone() =>
      ListTestExonerationsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListTestExonerationsRequest copyWith(
          void Function(ListTestExonerationsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as ListTestExonerationsRequest))
          as ListTestExonerationsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTestExonerationsRequest create() =>
      ListTestExonerationsRequest._();
  ListTestExonerationsRequest createEmptyInstance() => create();
  static $pb.PbList<ListTestExonerationsRequest> createRepeated() =>
      $pb.PbList<ListTestExonerationsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListTestExonerationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTestExonerationsRequest>(create);
  static ListTestExonerationsRequest? _defaultInstance;

  /// Name of the invocation, e.g. "invocations/{id}".
  @$pb.TagNumber(1)
  $core.String get invocation => $_getSZ(0);
  @$pb.TagNumber(1)
  set invocation($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInvocation() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvocation() => clearField(1);

  ///  The maximum number of test exonerations to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 test exonerations will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => clearField(2);

  ///  A page token, received from a previous `ListTestExonerations` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `ListTestExonerations`
  ///  MUST match the call that provided the page token.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => clearField(3);
}

/// A response message for ListTestExonerations RPC.
class ListTestExonerationsResponse extends $pb.GeneratedMessage {
  factory ListTestExonerationsResponse({
    $core.Iterable<$2.TestExoneration>? testExonerations,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (testExonerations != null) {
      $result.testExonerations.addAll(testExonerations);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  ListTestExonerationsResponse._() : super();
  factory ListTestExonerationsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListTestExonerationsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListTestExonerationsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$2.TestExoneration>(
        1, _omitFieldNames ? '' : 'testExonerations', $pb.PbFieldType.PM,
        subBuilder: $2.TestExoneration.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListTestExonerationsResponse clone() =>
      ListTestExonerationsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListTestExonerationsResponse copyWith(
          void Function(ListTestExonerationsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as ListTestExonerationsResponse))
          as ListTestExonerationsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListTestExonerationsResponse create() =>
      ListTestExonerationsResponse._();
  ListTestExonerationsResponse createEmptyInstance() => create();
  static $pb.PbList<ListTestExonerationsResponse> createRepeated() =>
      $pb.PbList<ListTestExonerationsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListTestExonerationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListTestExonerationsResponse>(create);
  static ListTestExonerationsResponse? _defaultInstance;

  /// The test exonerations from the specified invocation.
  @$pb.TagNumber(1)
  $core.List<$2.TestExoneration> get testExonerations => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
  /// If the invocation is not finalized, more results may appear later.
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

/// A request message for QueryTestResults RPC.
class QueryTestResultsRequest extends $pb.GeneratedMessage {
  factory QueryTestResultsRequest({
    $core.Iterable<$core.String>? invocations,
    $5.TestResultPredicate? predicate,
    $core.int? pageSize,
    $core.String? pageToken,
    $4.FieldMask? readMask,
  }) {
    final $result = create();
    if (invocations != null) {
      $result.invocations.addAll(invocations);
    }
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    if (readMask != null) {
      $result.readMask = readMask;
    }
    return $result;
  }
  QueryTestResultsRequest._() : super();
  factory QueryTestResultsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestResultsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestResultsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'invocations')
    ..aOM<$5.TestResultPredicate>(2, _omitFieldNames ? '' : 'predicate',
        subBuilder: $5.TestResultPredicate.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'pageToken')
    ..aOM<$4.FieldMask>(6, _omitFieldNames ? '' : 'readMask',
        subBuilder: $4.FieldMask.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestResultsRequest clone() =>
      QueryTestResultsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestResultsRequest copyWith(
          void Function(QueryTestResultsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryTestResultsRequest))
          as QueryTestResultsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestResultsRequest create() => QueryTestResultsRequest._();
  QueryTestResultsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryTestResultsRequest> createRepeated() =>
      $pb.PbList<QueryTestResultsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryTestResultsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestResultsRequest>(create);
  static QueryTestResultsRequest? _defaultInstance;

  ///  Retrieve test results included in these invocations, directly or indirectly
  ///  (via Invocation.included_invocations).
  ///
  ///  Specifying multiple invocations is equivalent to querying one invocation
  ///  that includes these.
  @$pb.TagNumber(1)
  $core.List<$core.String> get invocations => $_getList(0);

  /// A test result in the response must satisfy this predicate.
  @$pb.TagNumber(2)
  $5.TestResultPredicate get predicate => $_getN(1);
  @$pb.TagNumber(2)
  set predicate($5.TestResultPredicate v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPredicate() => $_has(1);
  @$pb.TagNumber(2)
  void clearPredicate() => clearField(2);
  @$pb.TagNumber(2)
  $5.TestResultPredicate ensurePredicate() => $_ensure(1);

  ///  The maximum number of test results to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 test results will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(4)
  set pageSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(4)
  void clearPageSize() => clearField(4);

  ///  A page token, received from a previous `QueryTestResults` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `QueryTestResults` MUST
  ///  match the call that provided the page token.
  @$pb.TagNumber(5)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(5)
  set pageToken($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(5)
  void clearPageToken() => clearField(5);

  /// Fields to include in the response.
  /// If not set, the default mask is used where summary_html and tags are
  /// excluded.
  /// Test result names will always be included even if "name" is not a part of
  /// the mask.
  @$pb.TagNumber(6)
  $4.FieldMask get readMask => $_getN(4);
  @$pb.TagNumber(6)
  set readMask($4.FieldMask v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasReadMask() => $_has(4);
  @$pb.TagNumber(6)
  void clearReadMask() => clearField(6);
  @$pb.TagNumber(6)
  $4.FieldMask ensureReadMask() => $_ensure(4);
}

/// A response message for QueryTestResults RPC.
class QueryTestResultsResponse extends $pb.GeneratedMessage {
  factory QueryTestResultsResponse({
    $core.Iterable<$2.TestResult>? testResults,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (testResults != null) {
      $result.testResults.addAll(testResults);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  QueryTestResultsResponse._() : super();
  factory QueryTestResultsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestResultsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestResultsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$2.TestResult>(
        1, _omitFieldNames ? '' : 'testResults', $pb.PbFieldType.PM,
        subBuilder: $2.TestResult.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestResultsResponse clone() =>
      QueryTestResultsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestResultsResponse copyWith(
          void Function(QueryTestResultsResponse) updates) =>
      super.copyWith((message) => updates(message as QueryTestResultsResponse))
          as QueryTestResultsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestResultsResponse create() => QueryTestResultsResponse._();
  QueryTestResultsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryTestResultsResponse> createRepeated() =>
      $pb.PbList<QueryTestResultsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryTestResultsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestResultsResponse>(create);
  static QueryTestResultsResponse? _defaultInstance;

  /// Matched test results.
  /// Ordered by parent invocation ID, test ID and result ID.
  @$pb.TagNumber(1)
  $core.List<$2.TestResult> get testResults => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
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

/// A request message for QueryTestExonerations RPC.
class QueryTestExonerationsRequest extends $pb.GeneratedMessage {
  factory QueryTestExonerationsRequest({
    $core.Iterable<$core.String>? invocations,
    $5.TestExonerationPredicate? predicate,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final $result = create();
    if (invocations != null) {
      $result.invocations.addAll(invocations);
    }
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    return $result;
  }
  QueryTestExonerationsRequest._() : super();
  factory QueryTestExonerationsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestExonerationsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestExonerationsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'invocations')
    ..aOM<$5.TestExonerationPredicate>(2, _omitFieldNames ? '' : 'predicate',
        subBuilder: $5.TestExonerationPredicate.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestExonerationsRequest clone() =>
      QueryTestExonerationsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestExonerationsRequest copyWith(
          void Function(QueryTestExonerationsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as QueryTestExonerationsRequest))
          as QueryTestExonerationsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestExonerationsRequest create() =>
      QueryTestExonerationsRequest._();
  QueryTestExonerationsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryTestExonerationsRequest> createRepeated() =>
      $pb.PbList<QueryTestExonerationsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryTestExonerationsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestExonerationsRequest>(create);
  static QueryTestExonerationsRequest? _defaultInstance;

  ///  Retrieve test exonerations included in these invocations, directly or
  ///  indirectly (via Invocation.included_invocations).
  ///
  ///  Specifying multiple invocations is equivalent to querying one invocation
  ///  that includes these.
  @$pb.TagNumber(1)
  $core.List<$core.String> get invocations => $_getList(0);

  /// A test exoneration in the response must satisfy this predicate.
  @$pb.TagNumber(2)
  $5.TestExonerationPredicate get predicate => $_getN(1);
  @$pb.TagNumber(2)
  set predicate($5.TestExonerationPredicate v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPredicate() => $_has(1);
  @$pb.TagNumber(2)
  void clearPredicate() => clearField(2);
  @$pb.TagNumber(2)
  $5.TestExonerationPredicate ensurePredicate() => $_ensure(1);

  ///  The maximum number of test exonerations to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 test exonerations will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(4)
  set pageSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(4)
  void clearPageSize() => clearField(4);

  ///  A page token, received from a previous `QueryTestExonerations` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `QueryTestExonerations`
  ///  MUST match the call that provided the page token.
  @$pb.TagNumber(5)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(5)
  set pageToken($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(5)
  void clearPageToken() => clearField(5);
}

/// A response message for QueryTestExonerations RPC.
class QueryTestExonerationsResponse extends $pb.GeneratedMessage {
  factory QueryTestExonerationsResponse({
    $core.Iterable<$2.TestExoneration>? testExonerations,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (testExonerations != null) {
      $result.testExonerations.addAll(testExonerations);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  QueryTestExonerationsResponse._() : super();
  factory QueryTestExonerationsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestExonerationsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestExonerationsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$2.TestExoneration>(
        1, _omitFieldNames ? '' : 'testExonerations', $pb.PbFieldType.PM,
        subBuilder: $2.TestExoneration.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestExonerationsResponse clone() =>
      QueryTestExonerationsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestExonerationsResponse copyWith(
          void Function(QueryTestExonerationsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as QueryTestExonerationsResponse))
          as QueryTestExonerationsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestExonerationsResponse create() =>
      QueryTestExonerationsResponse._();
  QueryTestExonerationsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryTestExonerationsResponse> createRepeated() =>
      $pb.PbList<QueryTestExonerationsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryTestExonerationsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestExonerationsResponse>(create);
  static QueryTestExonerationsResponse? _defaultInstance;

  /// The test exonerations matching the predicate.
  /// Ordered by parent invocation ID, test ID and exoneration ID.
  @$pb.TagNumber(1)
  $core.List<$2.TestExoneration> get testExonerations => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
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

/// A request message for QueryTestResultStatistics RPC.
class QueryTestResultStatisticsRequest extends $pb.GeneratedMessage {
  factory QueryTestResultStatisticsRequest({
    $core.Iterable<$core.String>? invocations,
  }) {
    final $result = create();
    if (invocations != null) {
      $result.invocations.addAll(invocations);
    }
    return $result;
  }
  QueryTestResultStatisticsRequest._() : super();
  factory QueryTestResultStatisticsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestResultStatisticsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestResultStatisticsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'invocations')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestResultStatisticsRequest clone() =>
      QueryTestResultStatisticsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestResultStatisticsRequest copyWith(
          void Function(QueryTestResultStatisticsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as QueryTestResultStatisticsRequest))
          as QueryTestResultStatisticsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestResultStatisticsRequest create() =>
      QueryTestResultStatisticsRequest._();
  QueryTestResultStatisticsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryTestResultStatisticsRequest> createRepeated() =>
      $pb.PbList<QueryTestResultStatisticsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryTestResultStatisticsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestResultStatisticsRequest>(
          create);
  static QueryTestResultStatisticsRequest? _defaultInstance;

  ///  Retrieve statistics of test result belong to these invocations,
  ///  directly or indirectly (via Invocation.included_invocations).
  ///
  ///  Specifying multiple invocations is equivalent to requesting one invocation
  ///  that includes these.
  @$pb.TagNumber(1)
  $core.List<$core.String> get invocations => $_getList(0);
}

/// A response message for QueryTestResultStatistics RPC.
class QueryTestResultStatisticsResponse extends $pb.GeneratedMessage {
  factory QueryTestResultStatisticsResponse({
    $fixnum.Int64? totalTestResults,
  }) {
    final $result = create();
    if (totalTestResults != null) {
      $result.totalTestResults = totalTestResults;
    }
    return $result;
  }
  QueryTestResultStatisticsResponse._() : super();
  factory QueryTestResultStatisticsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestResultStatisticsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestResultStatisticsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'totalTestResults')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestResultStatisticsResponse clone() =>
      QueryTestResultStatisticsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestResultStatisticsResponse copyWith(
          void Function(QueryTestResultStatisticsResponse) updates) =>
      super.copyWith((message) =>
              updates(message as QueryTestResultStatisticsResponse))
          as QueryTestResultStatisticsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestResultStatisticsResponse create() =>
      QueryTestResultStatisticsResponse._();
  QueryTestResultStatisticsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryTestResultStatisticsResponse> createRepeated() =>
      $pb.PbList<QueryTestResultStatisticsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryTestResultStatisticsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestResultStatisticsResponse>(
          create);
  static QueryTestResultStatisticsResponse? _defaultInstance;

  /// Total number of test results.
  @$pb.TagNumber(1)
  $fixnum.Int64 get totalTestResults => $_getI64(0);
  @$pb.TagNumber(1)
  set totalTestResults($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTotalTestResults() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalTestResults() => clearField(1);
}

/// A request message for GetArtifact RPC.
class GetArtifactRequest extends $pb.GeneratedMessage {
  factory GetArtifactRequest({
    $core.String? name,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  GetArtifactRequest._() : super();
  factory GetArtifactRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GetArtifactRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetArtifactRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GetArtifactRequest clone() => GetArtifactRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GetArtifactRequest copyWith(void Function(GetArtifactRequest) updates) =>
      super.copyWith((message) => updates(message as GetArtifactRequest))
          as GetArtifactRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetArtifactRequest create() => GetArtifactRequest._();
  GetArtifactRequest createEmptyInstance() => create();
  static $pb.PbList<GetArtifactRequest> createRepeated() =>
      $pb.PbList<GetArtifactRequest>();
  @$core.pragma('dart2js:noInline')
  static GetArtifactRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetArtifactRequest>(create);
  static GetArtifactRequest? _defaultInstance;

  /// The name of the artifact to request, see Artifact.name.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);
}

/// A request message for ListArtifacts RPC.
class ListArtifactsRequest extends $pb.GeneratedMessage {
  factory ListArtifactsRequest({
    $core.String? parent,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final $result = create();
    if (parent != null) {
      $result.parent = parent;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    return $result;
  }
  ListArtifactsRequest._() : super();
  factory ListArtifactsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListArtifactsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListArtifactsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'parent')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListArtifactsRequest clone() =>
      ListArtifactsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListArtifactsRequest copyWith(void Function(ListArtifactsRequest) updates) =>
      super.copyWith((message) => updates(message as ListArtifactsRequest))
          as ListArtifactsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListArtifactsRequest create() => ListArtifactsRequest._();
  ListArtifactsRequest createEmptyInstance() => create();
  static $pb.PbList<ListArtifactsRequest> createRepeated() =>
      $pb.PbList<ListArtifactsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListArtifactsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListArtifactsRequest>(create);
  static ListArtifactsRequest? _defaultInstance;

  /// Name of the parent, e.g. an invocation (see Invocation.name) or
  /// a test result (see TestResult.name).
  @$pb.TagNumber(1)
  $core.String get parent => $_getSZ(0);
  @$pb.TagNumber(1)
  set parent($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasParent() => $_has(0);
  @$pb.TagNumber(1)
  void clearParent() => clearField(1);

  ///  The maximum number of artifacts to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 artifacts will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(2)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(2)
  set pageSize($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(2)
  void clearPageSize() => clearField(2);

  ///  A page token, received from a previous `ListArtifacts` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `ListArtifacts` MUST
  ///  match the call that provided the page token.
  @$pb.TagNumber(3)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set pageToken($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearPageToken() => clearField(3);
}

/// A response message for ListArtifacts RPC.
class ListArtifactsResponse extends $pb.GeneratedMessage {
  factory ListArtifactsResponse({
    $core.Iterable<$3.Artifact>? artifacts,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (artifacts != null) {
      $result.artifacts.addAll(artifacts);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  ListArtifactsResponse._() : super();
  factory ListArtifactsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ListArtifactsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListArtifactsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$3.Artifact>(1, _omitFieldNames ? '' : 'artifacts', $pb.PbFieldType.PM,
        subBuilder: $3.Artifact.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ListArtifactsResponse clone() =>
      ListArtifactsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ListArtifactsResponse copyWith(
          void Function(ListArtifactsResponse) updates) =>
      super.copyWith((message) => updates(message as ListArtifactsResponse))
          as ListArtifactsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListArtifactsResponse create() => ListArtifactsResponse._();
  ListArtifactsResponse createEmptyInstance() => create();
  static $pb.PbList<ListArtifactsResponse> createRepeated() =>
      $pb.PbList<ListArtifactsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListArtifactsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListArtifactsResponse>(create);
  static ListArtifactsResponse? _defaultInstance;

  /// The artifacts from the specified parent.
  @$pb.TagNumber(1)
  $core.List<$3.Artifact> get artifacts => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
  /// If the invocation is not finalized, more results may appear later.
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

/// A request message for QueryArtifacts RPC.
class QueryArtifactsRequest extends $pb.GeneratedMessage {
  factory QueryArtifactsRequest({
    $core.Iterable<$core.String>? invocations,
    $5.ArtifactPredicate? predicate,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final $result = create();
    if (invocations != null) {
      $result.invocations.addAll(invocations);
    }
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    return $result;
  }
  QueryArtifactsRequest._() : super();
  factory QueryArtifactsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryArtifactsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryArtifactsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'invocations')
    ..aOM<$5.ArtifactPredicate>(2, _omitFieldNames ? '' : 'predicate',
        subBuilder: $5.ArtifactPredicate.create)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryArtifactsRequest clone() =>
      QueryArtifactsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryArtifactsRequest copyWith(
          void Function(QueryArtifactsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryArtifactsRequest))
          as QueryArtifactsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryArtifactsRequest create() => QueryArtifactsRequest._();
  QueryArtifactsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryArtifactsRequest> createRepeated() =>
      $pb.PbList<QueryArtifactsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryArtifactsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryArtifactsRequest>(create);
  static QueryArtifactsRequest? _defaultInstance;

  ///  Retrieve artifacts included in these invocations, directly or indirectly
  ///  (via Invocation.included_invocations and via contained test results).
  ///
  ///  Specifying multiple invocations is equivalent to querying one invocation
  ///  that includes these.
  @$pb.TagNumber(1)
  $core.List<$core.String> get invocations => $_getList(0);

  /// An artifact in the response must satisfy this predicate.
  @$pb.TagNumber(2)
  $5.ArtifactPredicate get predicate => $_getN(1);
  @$pb.TagNumber(2)
  set predicate($5.ArtifactPredicate v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPredicate() => $_has(1);
  @$pb.TagNumber(2)
  void clearPredicate() => clearField(2);
  @$pb.TagNumber(2)
  $5.ArtifactPredicate ensurePredicate() => $_ensure(1);

  ///  The maximum number of artifacts to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 artifacts will be returned.
  ///  The maximum value is 1000; values above 1000 will be coerced to 1000.
  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(2);
  @$pb.TagNumber(4)
  set pageSize($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(2);
  @$pb.TagNumber(4)
  void clearPageSize() => clearField(4);

  ///  A page token, received from a previous `QueryArtifacts` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `QueryArtifacts` MUST
  ///  match the call that provided the page token.
  @$pb.TagNumber(5)
  $core.String get pageToken => $_getSZ(3);
  @$pb.TagNumber(5)
  set pageToken($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPageToken() => $_has(3);
  @$pb.TagNumber(5)
  void clearPageToken() => clearField(5);
}

/// A response message for QueryArtifacts RPC.
class QueryArtifactsResponse extends $pb.GeneratedMessage {
  factory QueryArtifactsResponse({
    $core.Iterable<$3.Artifact>? artifacts,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (artifacts != null) {
      $result.artifacts.addAll(artifacts);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  QueryArtifactsResponse._() : super();
  factory QueryArtifactsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryArtifactsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryArtifactsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$3.Artifact>(1, _omitFieldNames ? '' : 'artifacts', $pb.PbFieldType.PM,
        subBuilder: $3.Artifact.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryArtifactsResponse clone() =>
      QueryArtifactsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryArtifactsResponse copyWith(
          void Function(QueryArtifactsResponse) updates) =>
      super.copyWith((message) => updates(message as QueryArtifactsResponse))
          as QueryArtifactsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryArtifactsResponse create() => QueryArtifactsResponse._();
  QueryArtifactsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryArtifactsResponse> createRepeated() =>
      $pb.PbList<QueryArtifactsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryArtifactsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryArtifactsResponse>(create);
  static QueryArtifactsResponse? _defaultInstance;

  /// Matched artifacts.
  /// First invocation-level artifacts, then test-result-level artifacts
  /// ordered by parent invocation ID, test ID and artifact ID.
  @$pb.TagNumber(1)
  $core.List<$3.Artifact> get artifacts => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
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

/// A request message for QueryTestVariants RPC.
/// Next id: 9.
class QueryTestVariantsRequest extends $pb.GeneratedMessage {
  factory QueryTestVariantsRequest({
    $core.Iterable<$core.String>? invocations,
    $core.int? pageSize,
    $core.String? pageToken,
    $6.TestVariantPredicate? predicate,
    $4.FieldMask? readMask,
    $core.int? resultLimit,
  }) {
    final $result = create();
    if (invocations != null) {
      $result.invocations.addAll(invocations);
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (readMask != null) {
      $result.readMask = readMask;
    }
    if (resultLimit != null) {
      $result.resultLimit = resultLimit;
    }
    return $result;
  }
  QueryTestVariantsRequest._() : super();
  factory QueryTestVariantsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestVariantsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestVariantsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pPS(2, _omitFieldNames ? '' : 'invocations')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(5, _omitFieldNames ? '' : 'pageToken')
    ..aOM<$6.TestVariantPredicate>(6, _omitFieldNames ? '' : 'predicate',
        subBuilder: $6.TestVariantPredicate.create)
    ..aOM<$4.FieldMask>(7, _omitFieldNames ? '' : 'readMask',
        subBuilder: $4.FieldMask.create)
    ..a<$core.int>(8, _omitFieldNames ? '' : 'resultLimit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestVariantsRequest clone() =>
      QueryTestVariantsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestVariantsRequest copyWith(
          void Function(QueryTestVariantsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryTestVariantsRequest))
          as QueryTestVariantsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestVariantsRequest create() => QueryTestVariantsRequest._();
  QueryTestVariantsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryTestVariantsRequest> createRepeated() =>
      $pb.PbList<QueryTestVariantsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryTestVariantsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestVariantsRequest>(create);
  static QueryTestVariantsRequest? _defaultInstance;

  ///  Retrieve test variants included in these invocations, directly or indirectly
  ///  (via Invocation.included_invocations).
  ///
  ///  Specifying multiple invocations is equivalent to querying one invocation
  ///  that includes these.
  @$pb.TagNumber(2)
  $core.List<$core.String> get invocations => $_getList(0);

  ///  The maximum number of test variants to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 100 test variants will be returned.
  ///  The maximum value is 10,000; values above 10,000 will be coerced to 10,000.
  @$pb.TagNumber(4)
  $core.int get pageSize => $_getIZ(1);
  @$pb.TagNumber(4)
  set pageSize($core.int v) {
    $_setSignedInt32(1, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPageSize() => $_has(1);
  @$pb.TagNumber(4)
  void clearPageSize() => clearField(4);

  ///  A page token, received from a previous `QueryTestVariants` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `QueryTestVariants` MUST
  ///  match the call that provided the page token.
  @$pb.TagNumber(5)
  $core.String get pageToken => $_getSZ(2);
  @$pb.TagNumber(5)
  set pageToken($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPageToken() => $_has(2);
  @$pb.TagNumber(5)
  void clearPageToken() => clearField(5);

  /// A test variant must satisfy this predicate.
  @$pb.TagNumber(6)
  $6.TestVariantPredicate get predicate => $_getN(3);
  @$pb.TagNumber(6)
  set predicate($6.TestVariantPredicate v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasPredicate() => $_has(3);
  @$pb.TagNumber(6)
  void clearPredicate() => clearField(6);
  @$pb.TagNumber(6)
  $6.TestVariantPredicate ensurePredicate() => $_ensure(3);

  ///  Fields to include in the response.
  ///  If not set, the default mask is used where all fields are included.
  ///
  ///  The following fields in results.*.result will NEVER be included even when
  ///  specified:
  ///  * test_id
  ///  * variant_hash
  ///  * variant
  ///  * test_metadata
  ///  Those values can be found in the parent test variant objects.
  ///
  ///  The following fields will ALWAYS be included even when NOT specified:
  ///  * test_id
  ///  * variant_hash
  ///  * status
  @$pb.TagNumber(7)
  $4.FieldMask get readMask => $_getN(4);
  @$pb.TagNumber(7)
  set readMask($4.FieldMask v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasReadMask() => $_has(4);
  @$pb.TagNumber(7)
  void clearReadMask() => clearField(7);
  @$pb.TagNumber(7)
  $4.FieldMask ensureReadMask() => $_ensure(4);

  ///  The maximum number of test results to be included in a test variant.
  ///
  ///  If a test variant has more results than the limit, the remaining results
  ///  will not be returned.
  ///  If unspecified, at most 10 results will be included in a test variant.
  ///  The maximum value is 100; values above 100 will be coerced to 100.
  @$pb.TagNumber(8)
  $core.int get resultLimit => $_getIZ(5);
  @$pb.TagNumber(8)
  set resultLimit($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasResultLimit() => $_has(5);
  @$pb.TagNumber(8)
  void clearResultLimit() => clearField(8);
}

/// A response message for QueryTestVariants RPC.
class QueryTestVariantsResponse extends $pb.GeneratedMessage {
  factory QueryTestVariantsResponse({
    $core.Iterable<$6.TestVariant>? testVariants,
    $core.String? nextPageToken,
    $core.Map<$core.String, $1.Sources>? sources,
  }) {
    final $result = create();
    if (testVariants != null) {
      $result.testVariants.addAll(testVariants);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    if (sources != null) {
      $result.sources.addAll(sources);
    }
    return $result;
  }
  QueryTestVariantsResponse._() : super();
  factory QueryTestVariantsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestVariantsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestVariantsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$6.TestVariant>(
        1, _omitFieldNames ? '' : 'testVariants', $pb.PbFieldType.PM,
        subBuilder: $6.TestVariant.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..m<$core.String, $1.Sources>(3, _omitFieldNames ? '' : 'sources',
        entryClassName: 'QueryTestVariantsResponse.SourcesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: $1.Sources.create,
        valueDefaultOrMaker: $1.Sources.getDefault,
        packageName: const $pb.PackageName('luci.resultdb.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestVariantsResponse clone() =>
      QueryTestVariantsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestVariantsResponse copyWith(
          void Function(QueryTestVariantsResponse) updates) =>
      super.copyWith((message) => updates(message as QueryTestVariantsResponse))
          as QueryTestVariantsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestVariantsResponse create() => QueryTestVariantsResponse._();
  QueryTestVariantsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryTestVariantsResponse> createRepeated() =>
      $pb.PbList<QueryTestVariantsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryTestVariantsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestVariantsResponse>(create);
  static QueryTestVariantsResponse? _defaultInstance;

  /// Matched test variants.
  /// Ordered by TestVariantStatus, test_id, then variant_hash
  @$pb.TagNumber(1)
  $core.List<$6.TestVariant> get testVariants => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
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

  ///  The code sources tested by the returned test variants. The sources are keyed
  ///  by an ID which allows them to be cross-referenced from TestVariant.sources_id.
  ///
  ///  The sources are returned via this map instead of directly on the TestVariant
  ///  to avoid excessive response size. Each source message could be up to a few
  ///  kilobytes and there are usually no more than a handful of different sources
  ///  tested in an invocation, so deduplicating them here reduces response size.
  @$pb.TagNumber(3)
  $core.Map<$core.String, $1.Sources> get sources => $_getMap(2);
}

class BatchGetTestVariantsRequest_TestVariantIdentifier
    extends $pb.GeneratedMessage {
  factory BatchGetTestVariantsRequest_TestVariantIdentifier({
    $core.String? testId,
    $core.String? variantHash,
  }) {
    final $result = create();
    if (testId != null) {
      $result.testId = testId;
    }
    if (variantHash != null) {
      $result.variantHash = variantHash;
    }
    return $result;
  }
  BatchGetTestVariantsRequest_TestVariantIdentifier._() : super();
  factory BatchGetTestVariantsRequest_TestVariantIdentifier.fromBuffer(
          $core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchGetTestVariantsRequest_TestVariantIdentifier.fromJson(
          $core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'BatchGetTestVariantsRequest.TestVariantIdentifier',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'testId')
    ..aOS(2, _omitFieldNames ? '' : 'variantHash')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsRequest_TestVariantIdentifier clone() =>
      BatchGetTestVariantsRequest_TestVariantIdentifier()
        ..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsRequest_TestVariantIdentifier copyWith(
          void Function(BatchGetTestVariantsRequest_TestVariantIdentifier)
              updates) =>
      super.copyWith((message) => updates(
              message as BatchGetTestVariantsRequest_TestVariantIdentifier))
          as BatchGetTestVariantsRequest_TestVariantIdentifier;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsRequest_TestVariantIdentifier create() =>
      BatchGetTestVariantsRequest_TestVariantIdentifier._();
  BatchGetTestVariantsRequest_TestVariantIdentifier createEmptyInstance() =>
      create();
  static $pb.PbList<BatchGetTestVariantsRequest_TestVariantIdentifier>
      createRepeated() =>
          $pb.PbList<BatchGetTestVariantsRequest_TestVariantIdentifier>();
  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsRequest_TestVariantIdentifier getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          BatchGetTestVariantsRequest_TestVariantIdentifier>(create);
  static BatchGetTestVariantsRequest_TestVariantIdentifier? _defaultInstance;

  /// The unique identifier of the test in a LUCI project. See the comment on
  /// TestResult.test_id for full documentation.
  @$pb.TagNumber(1)
  $core.String get testId => $_getSZ(0);
  @$pb.TagNumber(1)
  set testId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTestId() => clearField(1);

  /// Hash of the variant. See the comment on TestResult.variant_hash for full
  /// documentation.
  @$pb.TagNumber(2)
  $core.String get variantHash => $_getSZ(1);
  @$pb.TagNumber(2)
  set variantHash($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVariantHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariantHash() => clearField(2);
}

/// A request message for BatchGetTestVariants RPC.
class BatchGetTestVariantsRequest extends $pb.GeneratedMessage {
  factory BatchGetTestVariantsRequest({
    $core.String? invocation,
    $core.Iterable<BatchGetTestVariantsRequest_TestVariantIdentifier>?
        testVariants,
    $core.int? resultLimit,
  }) {
    final $result = create();
    if (invocation != null) {
      $result.invocation = invocation;
    }
    if (testVariants != null) {
      $result.testVariants.addAll(testVariants);
    }
    if (resultLimit != null) {
      $result.resultLimit = resultLimit;
    }
    return $result;
  }
  BatchGetTestVariantsRequest._() : super();
  factory BatchGetTestVariantsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchGetTestVariantsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchGetTestVariantsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invocation')
    ..pc<BatchGetTestVariantsRequest_TestVariantIdentifier>(
        2, _omitFieldNames ? '' : 'testVariants', $pb.PbFieldType.PM,
        subBuilder: BatchGetTestVariantsRequest_TestVariantIdentifier.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'resultLimit', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsRequest clone() =>
      BatchGetTestVariantsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsRequest copyWith(
          void Function(BatchGetTestVariantsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as BatchGetTestVariantsRequest))
          as BatchGetTestVariantsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsRequest create() =>
      BatchGetTestVariantsRequest._();
  BatchGetTestVariantsRequest createEmptyInstance() => create();
  static $pb.PbList<BatchGetTestVariantsRequest> createRepeated() =>
      $pb.PbList<BatchGetTestVariantsRequest>();
  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchGetTestVariantsRequest>(create);
  static BatchGetTestVariantsRequest? _defaultInstance;

  /// Name of the invocation that the test variants are in.
  @$pb.TagNumber(1)
  $core.String get invocation => $_getSZ(0);
  @$pb.TagNumber(1)
  set invocation($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInvocation() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvocation() => clearField(1);

  /// A list of test IDs and variant hashes, identifying the requested test
  /// variants. Size is limited to 500. Any request for more than 500 variants
  /// will return an error.
  @$pb.TagNumber(2)
  $core.List<BatchGetTestVariantsRequest_TestVariantIdentifier>
      get testVariants => $_getList(1);

  ///  The maximum number of test results to be included in a test variant.
  ///
  ///  If a test variant has more results than the limit, the remaining results
  ///  will not be returned.
  ///  If unspecified, at most 10 results will be included in a test variant.
  ///  The maximum value is 100; values above 100 will be coerced to 100.
  @$pb.TagNumber(3)
  $core.int get resultLimit => $_getIZ(2);
  @$pb.TagNumber(3)
  set resultLimit($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasResultLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearResultLimit() => clearField(3);
}

/// A response message for BatchGetTestVariants RPC.
class BatchGetTestVariantsResponse extends $pb.GeneratedMessage {
  factory BatchGetTestVariantsResponse({
    $core.Iterable<$6.TestVariant>? testVariants,
    $core.Map<$core.String, $1.Sources>? sources,
  }) {
    final $result = create();
    if (testVariants != null) {
      $result.testVariants.addAll(testVariants);
    }
    if (sources != null) {
      $result.sources.addAll(sources);
    }
    return $result;
  }
  BatchGetTestVariantsResponse._() : super();
  factory BatchGetTestVariantsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BatchGetTestVariantsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BatchGetTestVariantsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$6.TestVariant>(
        1, _omitFieldNames ? '' : 'testVariants', $pb.PbFieldType.PM,
        subBuilder: $6.TestVariant.create)
    ..m<$core.String, $1.Sources>(2, _omitFieldNames ? '' : 'sources',
        entryClassName: 'BatchGetTestVariantsResponse.SourcesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: $1.Sources.create,
        valueDefaultOrMaker: $1.Sources.getDefault,
        packageName: const $pb.PackageName('luci.resultdb.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsResponse clone() =>
      BatchGetTestVariantsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BatchGetTestVariantsResponse copyWith(
          void Function(BatchGetTestVariantsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as BatchGetTestVariantsResponse))
          as BatchGetTestVariantsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsResponse create() =>
      BatchGetTestVariantsResponse._();
  BatchGetTestVariantsResponse createEmptyInstance() => create();
  static $pb.PbList<BatchGetTestVariantsResponse> createRepeated() =>
      $pb.PbList<BatchGetTestVariantsResponse>();
  @$core.pragma('dart2js:noInline')
  static BatchGetTestVariantsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BatchGetTestVariantsResponse>(create);
  static BatchGetTestVariantsResponse? _defaultInstance;

  /// Test variants matching the requests. Any variants that weren't found are
  /// omitted from the response. Clients shouldn't rely on the ordering of this
  /// field, as no particular order is guaranteed.
  @$pb.TagNumber(1)
  $core.List<$6.TestVariant> get testVariants => $_getList(0);

  ///  The code sources tested by the returned test variants. The sources are keyed
  ///  by an ID which allows them to be cross-referenced from TestVariant.sources_id.
  ///
  ///  The sources are returned via this map instead of directly on the TestVariant
  ///  to avoid excessive response size. Each source message could be up to a few
  ///  kilobytes and there are usually no more than a handful of different sources
  ///  tested in an invocation, so deduplicating them here reduces response size.
  @$pb.TagNumber(2)
  $core.Map<$core.String, $1.Sources> get sources => $_getMap(1);
}

/// A request message for QueryTestMetadata RPC.
class QueryTestMetadataRequest extends $pb.GeneratedMessage {
  factory QueryTestMetadataRequest({
    $core.String? project,
    $5.TestMetadataPredicate? predicate,
    $core.int? pageSize,
    $core.String? pageToken,
  }) {
    final $result = create();
    if (project != null) {
      $result.project = project;
    }
    if (predicate != null) {
      $result.predicate = predicate;
    }
    if (pageSize != null) {
      $result.pageSize = pageSize;
    }
    if (pageToken != null) {
      $result.pageToken = pageToken;
    }
    return $result;
  }
  QueryTestMetadataRequest._() : super();
  factory QueryTestMetadataRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestMetadataRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestMetadataRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..aOM<$5.TestMetadataPredicate>(2, _omitFieldNames ? '' : 'predicate',
        subBuilder: $5.TestMetadataPredicate.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'pageSize', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'pageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestMetadataRequest clone() =>
      QueryTestMetadataRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestMetadataRequest copyWith(
          void Function(QueryTestMetadataRequest) updates) =>
      super.copyWith((message) => updates(message as QueryTestMetadataRequest))
          as QueryTestMetadataRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestMetadataRequest create() => QueryTestMetadataRequest._();
  QueryTestMetadataRequest createEmptyInstance() => create();
  static $pb.PbList<QueryTestMetadataRequest> createRepeated() =>
      $pb.PbList<QueryTestMetadataRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryTestMetadataRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestMetadataRequest>(create);
  static QueryTestMetadataRequest? _defaultInstance;

  /// The LUCI Project to query.
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

  /// Filters to apply to the returned test metadata.
  @$pb.TagNumber(2)
  $5.TestMetadataPredicate get predicate => $_getN(1);
  @$pb.TagNumber(2)
  set predicate($5.TestMetadataPredicate v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPredicate() => $_has(1);
  @$pb.TagNumber(2)
  void clearPredicate() => clearField(2);
  @$pb.TagNumber(2)
  $5.TestMetadataPredicate ensurePredicate() => $_ensure(1);

  ///  The maximum number of test metadata entries to return.
  ///
  ///  The service may return fewer than this value.
  ///  If unspecified, at most 1000 test metadata entries will be returned.
  ///  The maximum value is 100K; values above 100K will be coerced to 100K.
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

  ///  A page token, received from a previous `QueryTestMetadata` call.
  ///  Provide this to retrieve the subsequent page.
  ///
  ///  When paginating, all other parameters provided to `QueryTestMetadata` MUST
  ///  match the call that provided the page token.
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

/// A response message for QueryTestMetadata RPC.
class QueryTestMetadataResponse extends $pb.GeneratedMessage {
  factory QueryTestMetadataResponse({
    $core.Iterable<$7.TestMetadataDetail>? testMetadata,
    $core.String? nextPageToken,
  }) {
    final $result = create();
    if (testMetadata != null) {
      $result.testMetadata.addAll(testMetadata);
    }
    if (nextPageToken != null) {
      $result.nextPageToken = nextPageToken;
    }
    return $result;
  }
  QueryTestMetadataResponse._() : super();
  factory QueryTestMetadataResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryTestMetadataResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryTestMetadataResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..pc<$7.TestMetadataDetail>(
        1, _omitFieldNames ? '' : 'testMetadata', $pb.PbFieldType.PM,
        protoName: 'testMetadata', subBuilder: $7.TestMetadataDetail.create)
    ..aOS(2, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryTestMetadataResponse clone() =>
      QueryTestMetadataResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryTestMetadataResponse copyWith(
          void Function(QueryTestMetadataResponse) updates) =>
      super.copyWith((message) => updates(message as QueryTestMetadataResponse))
          as QueryTestMetadataResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryTestMetadataResponse create() => QueryTestMetadataResponse._();
  QueryTestMetadataResponse createEmptyInstance() => create();
  static $pb.PbList<QueryTestMetadataResponse> createRepeated() =>
      $pb.PbList<QueryTestMetadataResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryTestMetadataResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryTestMetadataResponse>(create);
  static QueryTestMetadataResponse? _defaultInstance;

  /// The matched testMetadata.
  @$pb.TagNumber(1)
  $core.List<$7.TestMetadataDetail> get testMetadata => $_getList(0);

  /// A token, which can be sent as `page_token` to retrieve the next page.
  /// If this field is omitted, there were no subsequent pages at the time of
  /// request.
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

/// A request message for QueryNewTestVariants RPC.
/// To use this RPC, callers need:
/// - resultdb.baselines.get in the realm the <baseline_project>:@project, where
///   baseline_project is the LUCI project that contains the baseline.
/// - resultdb.testResults.list in the realm of the invocation which is being
///   queried.
class QueryNewTestVariantsRequest extends $pb.GeneratedMessage {
  factory QueryNewTestVariantsRequest({
    $core.String? invocation,
    $core.String? baseline,
  }) {
    final $result = create();
    if (invocation != null) {
      $result.invocation = invocation;
    }
    if (baseline != null) {
      $result.baseline = baseline;
    }
    return $result;
  }
  QueryNewTestVariantsRequest._() : super();
  factory QueryNewTestVariantsRequest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryNewTestVariantsRequest.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryNewTestVariantsRequest',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'invocation')
    ..aOS(2, _omitFieldNames ? '' : 'baseline')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsRequest clone() =>
      QueryNewTestVariantsRequest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsRequest copyWith(
          void Function(QueryNewTestVariantsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as QueryNewTestVariantsRequest))
          as QueryNewTestVariantsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsRequest create() =>
      QueryNewTestVariantsRequest._();
  QueryNewTestVariantsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryNewTestVariantsRequest> createRepeated() =>
      $pb.PbList<QueryNewTestVariantsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryNewTestVariantsRequest>(create);
  static QueryNewTestVariantsRequest? _defaultInstance;

  /// Name of the invocation, e.g. "invocations/{id}".
  @$pb.TagNumber(1)
  $core.String get invocation => $_getSZ(0);
  @$pb.TagNumber(1)
  set invocation($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInvocation() => $_has(0);
  @$pb.TagNumber(1)
  void clearInvocation() => clearField(1);

  /// The baseline to compare test variants against, to determine if they are new.
  /// e.g. “projects/{project}/baselines/{baseline_id}”.
  /// For example, in the project "chromium", the baseline_id may be
  /// "try:linux-rel".
  @$pb.TagNumber(2)
  $core.String get baseline => $_getSZ(1);
  @$pb.TagNumber(2)
  set baseline($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBaseline() => $_has(1);
  @$pb.TagNumber(2)
  void clearBaseline() => clearField(2);
}

/// Represents a new test, which contains minimal information to uniquely identify a TestVariant.
class QueryNewTestVariantsResponse_NewTestVariant extends $pb.GeneratedMessage {
  factory QueryNewTestVariantsResponse_NewTestVariant({
    $core.String? testId,
    $core.String? variantHash,
  }) {
    final $result = create();
    if (testId != null) {
      $result.testId = testId;
    }
    if (variantHash != null) {
      $result.variantHash = variantHash;
    }
    return $result;
  }
  QueryNewTestVariantsResponse_NewTestVariant._() : super();
  factory QueryNewTestVariantsResponse_NewTestVariant.fromBuffer(
          $core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryNewTestVariantsResponse_NewTestVariant.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryNewTestVariantsResponse.NewTestVariant',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'testId')
    ..aOS(2, _omitFieldNames ? '' : 'variantHash')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsResponse_NewTestVariant clone() =>
      QueryNewTestVariantsResponse_NewTestVariant()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsResponse_NewTestVariant copyWith(
          void Function(QueryNewTestVariantsResponse_NewTestVariant) updates) =>
      super.copyWith((message) =>
              updates(message as QueryNewTestVariantsResponse_NewTestVariant))
          as QueryNewTestVariantsResponse_NewTestVariant;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsResponse_NewTestVariant create() =>
      QueryNewTestVariantsResponse_NewTestVariant._();
  QueryNewTestVariantsResponse_NewTestVariant createEmptyInstance() => create();
  static $pb.PbList<QueryNewTestVariantsResponse_NewTestVariant>
      createRepeated() =>
          $pb.PbList<QueryNewTestVariantsResponse_NewTestVariant>();
  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsResponse_NewTestVariant getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          QueryNewTestVariantsResponse_NewTestVariant>(create);
  static QueryNewTestVariantsResponse_NewTestVariant? _defaultInstance;

  ///  A unique identifier of the test in a LUCI project.
  ///  Regex: ^[[::print::]]{1,256}$
  ///
  ///  Refer to TestResult.test_id for details.
  @$pb.TagNumber(1)
  $core.String get testId => $_getSZ(0);
  @$pb.TagNumber(1)
  set testId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTestId() => clearField(1);

  /// Hash of the variant.
  /// hex(sha256(sorted(''.join('%s:%s\n' for k, v in variant.items())))).
  @$pb.TagNumber(2)
  $core.String get variantHash => $_getSZ(1);
  @$pb.TagNumber(2)
  set variantHash($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVariantHash() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariantHash() => clearField(2);
}

/// A response message for QueryNewTestVariants RPC.
class QueryNewTestVariantsResponse extends $pb.GeneratedMessage {
  factory QueryNewTestVariantsResponse({
    $core.bool? isBaselineReady,
    $core.Iterable<QueryNewTestVariantsResponse_NewTestVariant>?
        newTestVariants,
  }) {
    final $result = create();
    if (isBaselineReady != null) {
      $result.isBaselineReady = isBaselineReady;
    }
    if (newTestVariants != null) {
      $result.newTestVariants.addAll(newTestVariants);
    }
    return $result;
  }
  QueryNewTestVariantsResponse._() : super();
  factory QueryNewTestVariantsResponse.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory QueryNewTestVariantsResponse.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QueryNewTestVariantsResponse',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'isBaselineReady')
    ..pc<QueryNewTestVariantsResponse_NewTestVariant>(
        2, _omitFieldNames ? '' : 'newTestVariants', $pb.PbFieldType.PM,
        subBuilder: QueryNewTestVariantsResponse_NewTestVariant.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsResponse clone() =>
      QueryNewTestVariantsResponse()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  QueryNewTestVariantsResponse copyWith(
          void Function(QueryNewTestVariantsResponse) updates) =>
      super.copyWith(
              (message) => updates(message as QueryNewTestVariantsResponse))
          as QueryNewTestVariantsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsResponse create() =>
      QueryNewTestVariantsResponse._();
  QueryNewTestVariantsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryNewTestVariantsResponse> createRepeated() =>
      $pb.PbList<QueryNewTestVariantsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryNewTestVariantsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QueryNewTestVariantsResponse>(create);
  static QueryNewTestVariantsResponse? _defaultInstance;

  /// Indicates whether the baseline has been populated with at least 72 hours
  /// of data and the results can be relied upon.
  @$pb.TagNumber(1)
  $core.bool get isBaselineReady => $_getBF(0);
  @$pb.TagNumber(1)
  set isBaselineReady($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasIsBaselineReady() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsBaselineReady() => clearField(1);

  /// Test variants that are new, meaning that they have not been part of
  /// a submitted run prior.
  @$pb.TagNumber(2)
  $core.List<QueryNewTestVariantsResponse_NewTestVariant> get newTestVariants =>
      $_getList(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
