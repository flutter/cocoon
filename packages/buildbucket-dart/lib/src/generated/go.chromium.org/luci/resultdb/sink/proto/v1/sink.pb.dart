//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/sink.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'test_result.pb.dart' as $2;

class ReportTestResultsRequest extends $pb.GeneratedMessage {
  factory ReportTestResultsRequest({
    $core.Iterable<$2.TestResult>? testResults,
  }) {
    final $result = create();
    if (testResults != null) {
      $result.testResults.addAll(testResults);
    }
    return $result;
  }
  ReportTestResultsRequest._() : super();
  factory ReportTestResultsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReportTestResultsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReportTestResultsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..pc<$2.TestResult>(1, _omitFieldNames ? '' : 'testResults', $pb.PbFieldType.PM, subBuilder: $2.TestResult.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReportTestResultsRequest clone() => ReportTestResultsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReportTestResultsRequest copyWith(void Function(ReportTestResultsRequest) updates) => super.copyWith((message) => updates(message as ReportTestResultsRequest)) as ReportTestResultsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportTestResultsRequest create() => ReportTestResultsRequest._();
  ReportTestResultsRequest createEmptyInstance() => create();
  static $pb.PbList<ReportTestResultsRequest> createRepeated() => $pb.PbList<ReportTestResultsRequest>();
  @$core.pragma('dart2js:noInline')
  static ReportTestResultsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReportTestResultsRequest>(create);
  static ReportTestResultsRequest? _defaultInstance;

  /// Test results to report.
  @$pb.TagNumber(1)
  $core.List<$2.TestResult> get testResults => $_getList(0);
}

class ReportTestResultsResponse extends $pb.GeneratedMessage {
  factory ReportTestResultsResponse({
    $core.Iterable<$core.String>? testResultNames,
  }) {
    final $result = create();
    if (testResultNames != null) {
      $result.testResultNames.addAll(testResultNames);
    }
    return $result;
  }
  ReportTestResultsResponse._() : super();
  factory ReportTestResultsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReportTestResultsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReportTestResultsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'testResultNames')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReportTestResultsResponse clone() => ReportTestResultsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReportTestResultsResponse copyWith(void Function(ReportTestResultsResponse) updates) => super.copyWith((message) => updates(message as ReportTestResultsResponse)) as ReportTestResultsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportTestResultsResponse create() => ReportTestResultsResponse._();
  ReportTestResultsResponse createEmptyInstance() => create();
  static $pb.PbList<ReportTestResultsResponse> createRepeated() => $pb.PbList<ReportTestResultsResponse>();
  @$core.pragma('dart2js:noInline')
  static ReportTestResultsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReportTestResultsResponse>(create);
  static ReportTestResultsResponse? _defaultInstance;

  /// List of unique identifiers that can be used to link to these results
  /// or requested via luci.resultdb.v1.ResultDB service.
  @$pb.TagNumber(1)
  $core.List<$core.String> get testResultNames => $_getList(0);
}

class ReportInvocationLevelArtifactsRequest extends $pb.GeneratedMessage {
  factory ReportInvocationLevelArtifactsRequest({
    $core.Map<$core.String, $2.Artifact>? artifacts,
  }) {
    final $result = create();
    if (artifacts != null) {
      $result.artifacts.addAll(artifacts);
    }
    return $result;
  }
  ReportInvocationLevelArtifactsRequest._() : super();
  factory ReportInvocationLevelArtifactsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ReportInvocationLevelArtifactsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ReportInvocationLevelArtifactsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..m<$core.String, $2.Artifact>(1, _omitFieldNames ? '' : 'artifacts', entryClassName: 'ReportInvocationLevelArtifactsRequest.ArtifactsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: $2.Artifact.create, valueDefaultOrMaker: $2.Artifact.getDefault, packageName: const $pb.PackageName('luci.resultsink.v1'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ReportInvocationLevelArtifactsRequest clone() => ReportInvocationLevelArtifactsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ReportInvocationLevelArtifactsRequest copyWith(void Function(ReportInvocationLevelArtifactsRequest) updates) => super.copyWith((message) => updates(message as ReportInvocationLevelArtifactsRequest)) as ReportInvocationLevelArtifactsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportInvocationLevelArtifactsRequest create() => ReportInvocationLevelArtifactsRequest._();
  ReportInvocationLevelArtifactsRequest createEmptyInstance() => create();
  static $pb.PbList<ReportInvocationLevelArtifactsRequest> createRepeated() => $pb.PbList<ReportInvocationLevelArtifactsRequest>();
  @$core.pragma('dart2js:noInline')
  static ReportInvocationLevelArtifactsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReportInvocationLevelArtifactsRequest>(create);
  static ReportInvocationLevelArtifactsRequest? _defaultInstance;

  /// Invocation-level artifacts to report.
  /// The map key is an artifact id.
  @$pb.TagNumber(1)
  $core.Map<$core.String, $2.Artifact> get artifacts => $_getMap(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
