//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/test_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../../google/protobuf/duration.pb.dart' as $1;
import '../../../../../../google/protobuf/struct.pb.dart' as $5;
import '../../../../../../google/protobuf/timestamp.pb.dart' as $0;
import '../../../proto/v1/common.pb.dart' as $2;
import '../../../proto/v1/failure_reason.pb.dart' as $4;
import '../../../proto/v1/test_metadata.pb.dart' as $3;
import '../../../proto/v1/test_result.pbenum.dart' as $6;
import 'test_result.pbenum.dart';

export 'test_result.pbenum.dart';

/// A local equivalent of luci.resultdb.TestResult message
/// in ../../v1/test_result.proto.
/// See its comments for details.
class TestResult extends $pb.GeneratedMessage {
  factory TestResult({
    $core.String? testId,
    $core.String? resultId,
    $core.bool? expected,
    $6.TestStatus? status,
    $core.String? summaryHtml,
    $0.Timestamp? startTime,
    $1.Duration? duration,
    $core.Iterable<$2.StringPair>? tags,
    $core.Map<$core.String, Artifact>? artifacts,
    $3.TestMetadata? testMetadata,
    $4.FailureReason? failureReason,
    $2.Variant? variant,
    $5.Struct? properties,
  }) {
    final $result = create();
    if (testId != null) {
      $result.testId = testId;
    }
    if (resultId != null) {
      $result.resultId = resultId;
    }
    if (expected != null) {
      $result.expected = expected;
    }
    if (status != null) {
      $result.status = status;
    }
    if (summaryHtml != null) {
      $result.summaryHtml = summaryHtml;
    }
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (duration != null) {
      $result.duration = duration;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (artifacts != null) {
      $result.artifacts.addAll(artifacts);
    }
    if (testMetadata != null) {
      $result.testMetadata = testMetadata;
    }
    if (failureReason != null) {
      $result.failureReason = failureReason;
    }
    if (variant != null) {
      $result.variant = variant;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    return $result;
  }
  TestResult._() : super();
  factory TestResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'testId')
    ..aOS(2, _omitFieldNames ? '' : 'resultId')
    ..aOB(3, _omitFieldNames ? '' : 'expected')
    ..e<$6.TestStatus>(4, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: $6.TestStatus.STATUS_UNSPECIFIED, valueOf: $6.TestStatus.valueOf, enumValues: $6.TestStatus.values)
    ..aOS(5, _omitFieldNames ? '' : 'summaryHtml')
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'startTime', subBuilder: $0.Timestamp.create)
    ..aOM<$1.Duration>(7, _omitFieldNames ? '' : 'duration', subBuilder: $1.Duration.create)
    ..pc<$2.StringPair>(8, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $2.StringPair.create)
    ..m<$core.String, Artifact>(9, _omitFieldNames ? '' : 'artifacts', entryClassName: 'TestResult.ArtifactsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: Artifact.create, valueDefaultOrMaker: Artifact.getDefault, packageName: const $pb.PackageName('luci.resultsink.v1'))
    ..aOM<$3.TestMetadata>(11, _omitFieldNames ? '' : 'testMetadata', subBuilder: $3.TestMetadata.create)
    ..aOM<$4.FailureReason>(12, _omitFieldNames ? '' : 'failureReason', subBuilder: $4.FailureReason.create)
    ..aOM<$2.Variant>(13, _omitFieldNames ? '' : 'variant', subBuilder: $2.Variant.create)
    ..aOM<$5.Struct>(14, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestResult clone() => TestResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestResult copyWith(void Function(TestResult) updates) => super.copyWith((message) => updates(message as TestResult)) as TestResult;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestResult create() => TestResult._();
  TestResult createEmptyInstance() => create();
  static $pb.PbList<TestResult> createRepeated() => $pb.PbList<TestResult>();
  @$core.pragma('dart2js:noInline')
  static TestResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestResult>(create);
  static TestResult? _defaultInstance;

  /// Equivalent of luci.resultdb.v1.TestResult.TestId.
  @$pb.TagNumber(1)
  $core.String get testId => $_getSZ(0);
  @$pb.TagNumber(1)
  set testId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTestId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTestId() => clearField(1);

  ///  Equivalent of luci.resultdb.v1.TestResult.result_id.
  ///
  ///  If omitted, a random, unique ID is generated..
  @$pb.TagNumber(2)
  $core.String get resultId => $_getSZ(1);
  @$pb.TagNumber(2)
  set resultId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasResultId() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultId() => clearField(2);

  /// Equivalent of luci.resultdb.v1.TestResult.expected.
  @$pb.TagNumber(3)
  $core.bool get expected => $_getBF(2);
  @$pb.TagNumber(3)
  set expected($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpected() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpected() => clearField(3);

  /// Equivalent of luci.resultdb.v1.TestResult.status.
  @$pb.TagNumber(4)
  $6.TestStatus get status => $_getN(3);
  @$pb.TagNumber(4)
  set status($6.TestStatus v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => clearField(4);

  /// Equivalent of luci.resultdb.v1.TestResult.summary_html.
  @$pb.TagNumber(5)
  $core.String get summaryHtml => $_getSZ(4);
  @$pb.TagNumber(5)
  set summaryHtml($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSummaryHtml() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummaryHtml() => clearField(5);

  /// Equivalent of luci.resultdb.v1.TestResult.start_time.
  @$pb.TagNumber(6)
  $0.Timestamp get startTime => $_getN(5);
  @$pb.TagNumber(6)
  set startTime($0.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasStartTime() => $_has(5);
  @$pb.TagNumber(6)
  void clearStartTime() => clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureStartTime() => $_ensure(5);

  /// Equivalent of luci.resultdb.v1.TestResult.duration.
  @$pb.TagNumber(7)
  $1.Duration get duration => $_getN(6);
  @$pb.TagNumber(7)
  set duration($1.Duration v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDuration() => $_has(6);
  @$pb.TagNumber(7)
  void clearDuration() => clearField(7);
  @$pb.TagNumber(7)
  $1.Duration ensureDuration() => $_ensure(6);

  /// Equivalent of luci.resultdb.v1.TestResult.tags.
  @$pb.TagNumber(8)
  $core.List<$2.StringPair> get tags => $_getList(7);

  /// Artifacts to upload and associate with this test result.
  /// The map key is an artifact id.
  @$pb.TagNumber(9)
  $core.Map<$core.String, Artifact> get artifacts => $_getMap(8);

  /// Equivalent of luci.resultdb.v1.TestResult.test_metadata.
  @$pb.TagNumber(11)
  $3.TestMetadata get testMetadata => $_getN(9);
  @$pb.TagNumber(11)
  set testMetadata($3.TestMetadata v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasTestMetadata() => $_has(9);
  @$pb.TagNumber(11)
  void clearTestMetadata() => clearField(11);
  @$pb.TagNumber(11)
  $3.TestMetadata ensureTestMetadata() => $_ensure(9);

  /// Equivalent of luci.resultdb.v1.TestResult.failure_reason.
  @$pb.TagNumber(12)
  $4.FailureReason get failureReason => $_getN(10);
  @$pb.TagNumber(12)
  set failureReason($4.FailureReason v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasFailureReason() => $_has(10);
  @$pb.TagNumber(12)
  void clearFailureReason() => clearField(12);
  @$pb.TagNumber(12)
  $4.FailureReason ensureFailureReason() => $_ensure(10);

  /// Equivalent of luci.resultdb.v1.TestResult.variant.
  /// The variant for all test cases should be passed by command line args to rdb
  /// stream, however you can override or add to the variant on a per test case
  /// basis using this field.
  @$pb.TagNumber(13)
  $2.Variant get variant => $_getN(11);
  @$pb.TagNumber(13)
  set variant($2.Variant v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasVariant() => $_has(11);
  @$pb.TagNumber(13)
  void clearVariant() => clearField(13);
  @$pb.TagNumber(13)
  $2.Variant ensureVariant() => $_ensure(11);

  ///  Arbitrary JSON object that contains structured, domain-specific properties
  ///  of the test result.
  ///
  ///  The serialized size must be <= 4096 bytes.
  @$pb.TagNumber(14)
  $5.Struct get properties => $_getN(12);
  @$pb.TagNumber(14)
  set properties($5.Struct v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasProperties() => $_has(12);
  @$pb.TagNumber(14)
  void clearProperties() => clearField(14);
  @$pb.TagNumber(14)
  $5.Struct ensureProperties() => $_ensure(12);
}

enum Artifact_Body {
  filePath, 
  contents, 
  gcsUri, 
  notSet
}

/// A local equivalent of luci.resultdb.Artifact message
/// in ../../rpc/v1/artifact.proto.
/// See its comments for details.
/// Does not have a name or artifact_id because they are represented by the
/// TestResult.artifacts map key.
/// Next id: 5
class Artifact extends $pb.GeneratedMessage {
  factory Artifact({
    $core.String? filePath,
    $core.List<$core.int>? contents,
    $core.String? contentType,
    $core.String? gcsUri,
  }) {
    final $result = create();
    if (filePath != null) {
      $result.filePath = filePath;
    }
    if (contents != null) {
      $result.contents = contents;
    }
    if (contentType != null) {
      $result.contentType = contentType;
    }
    if (gcsUri != null) {
      $result.gcsUri = gcsUri;
    }
    return $result;
  }
  Artifact._() : super();
  factory Artifact.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Artifact.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Artifact_Body> _Artifact_BodyByTag = {
    1 : Artifact_Body.filePath,
    2 : Artifact_Body.contents,
    4 : Artifact_Body.gcsUri,
    0 : Artifact_Body.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Artifact', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2, 4])
    ..aOS(1, _omitFieldNames ? '' : 'filePath')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'contents', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'contentType')
    ..aOS(4, _omitFieldNames ? '' : 'gcsUri')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Artifact clone() => Artifact()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Artifact copyWith(void Function(Artifact) updates) => super.copyWith((message) => updates(message as Artifact)) as Artifact;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Artifact create() => Artifact._();
  Artifact createEmptyInstance() => create();
  static $pb.PbList<Artifact> createRepeated() => $pb.PbList<Artifact>();
  @$core.pragma('dart2js:noInline')
  static Artifact getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Artifact>(create);
  static Artifact? _defaultInstance;

  Artifact_Body whichBody() => _Artifact_BodyByTag[$_whichOneof(0)]!;
  void clearBody() => clearField($_whichOneof(0));

  /// Absolute path to the artifact file on the same machine as the
  /// ResultSink server.
  @$pb.TagNumber(1)
  $core.String get filePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set filePath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFilePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearFilePath() => clearField(1);

  /// Contents of the artifact. Useful when sending a file from a different
  /// machine.
  /// TODO(nodir, sajjadm): allow sending contents in chunks.
  @$pb.TagNumber(2)
  $core.List<$core.int> get contents => $_getN(1);
  @$pb.TagNumber(2)
  set contents($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasContents() => $_has(1);
  @$pb.TagNumber(2)
  void clearContents() => clearField(2);

  /// Equivalent of luci.resultdb.v1.Artifact.content_type.
  @$pb.TagNumber(3)
  $core.String get contentType => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentType($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContentType() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentType() => clearField(3);

  /// The GCS URI of the artifact if it's stored in GCS.
  @$pb.TagNumber(4)
  $core.String get gcsUri => $_getSZ(3);
  @$pb.TagNumber(4)
  set gcsUri($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasGcsUri() => $_has(3);
  @$pb.TagNumber(4)
  void clearGcsUri() => clearField(4);
}

/// A file with test results.
class TestResultFile extends $pb.GeneratedMessage {
  factory TestResultFile({
    $core.String? path,
    TestResultFile_Format? format,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (format != null) {
      $result.format = format;
    }
    return $result;
  }
  TestResultFile._() : super();
  factory TestResultFile.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestResultFile.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestResultFile', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultsink.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..e<TestResultFile_Format>(2, _omitFieldNames ? '' : 'format', $pb.PbFieldType.OE, defaultOrMaker: TestResultFile_Format.LUCI, valueOf: TestResultFile_Format.valueOf, enumValues: TestResultFile_Format.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestResultFile clone() => TestResultFile()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestResultFile copyWith(void Function(TestResultFile) updates) => super.copyWith((message) => updates(message as TestResultFile)) as TestResultFile;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestResultFile create() => TestResultFile._();
  TestResultFile createEmptyInstance() => create();
  static $pb.PbList<TestResultFile> createRepeated() => $pb.PbList<TestResultFile>();
  @$core.pragma('dart2js:noInline')
  static TestResultFile getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestResultFile>(create);
  static TestResultFile? _defaultInstance;

  /// Absolute OS-native path to the results file on the same machine as the
  /// ResultSink server.
  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  /// Format of the file.
  @$pb.TagNumber(2)
  TestResultFile_Format get format => $_getN(1);
  @$pb.TagNumber(2)
  set format(TestResultFile_Format v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
