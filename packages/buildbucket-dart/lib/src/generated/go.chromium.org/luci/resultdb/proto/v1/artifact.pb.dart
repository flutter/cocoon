//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/artifact.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/timestamp.pb.dart' as $0;
import 'test_result.pbenum.dart' as $1;

///  A file produced during a build/test, typically a test artifact.
///  The parent resource is either a TestResult or an Invocation.
///
///  An invocation-level artifact might be related to tests, or it might not, for
///  example it may be used to store build step logs when streaming support is
///  added.
///  Next id: 10.
class Artifact extends $pb.GeneratedMessage {
  factory Artifact({
    $core.String? name,
    $core.String? artifactId,
    $core.String? fetchUrl,
    $0.Timestamp? fetchUrlExpiration,
    $core.String? contentType,
    $fixnum.Int64? sizeBytes,
    $core.List<$core.int>? contents,
    $core.String? gcsUri,
    $1.TestStatus? testStatus,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (artifactId != null) {
      $result.artifactId = artifactId;
    }
    if (fetchUrl != null) {
      $result.fetchUrl = fetchUrl;
    }
    if (fetchUrlExpiration != null) {
      $result.fetchUrlExpiration = fetchUrlExpiration;
    }
    if (contentType != null) {
      $result.contentType = contentType;
    }
    if (sizeBytes != null) {
      $result.sizeBytes = sizeBytes;
    }
    if (contents != null) {
      $result.contents = contents;
    }
    if (gcsUri != null) {
      $result.gcsUri = gcsUri;
    }
    if (testStatus != null) {
      $result.testStatus = testStatus;
    }
    return $result;
  }
  Artifact._() : super();
  factory Artifact.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Artifact.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Artifact',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'artifactId')
    ..aOS(3, _omitFieldNames ? '' : 'fetchUrl')
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'fetchUrlExpiration', subBuilder: $0.Timestamp.create)
    ..aOS(5, _omitFieldNames ? '' : 'contentType')
    ..aInt64(6, _omitFieldNames ? '' : 'sizeBytes')
    ..a<$core.List<$core.int>>(7, _omitFieldNames ? '' : 'contents', $pb.PbFieldType.OY)
    ..aOS(8, _omitFieldNames ? '' : 'gcsUri')
    ..e<$1.TestStatus>(9, _omitFieldNames ? '' : 'testStatus', $pb.PbFieldType.OE,
        defaultOrMaker: $1.TestStatus.STATUS_UNSPECIFIED,
        valueOf: $1.TestStatus.valueOf,
        enumValues: $1.TestStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Artifact clone() => Artifact()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Artifact copyWith(void Function(Artifact) updates) =>
      super.copyWith((message) => updates(message as Artifact)) as Artifact;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Artifact create() => Artifact._();
  Artifact createEmptyInstance() => create();
  static $pb.PbList<Artifact> createRepeated() => $pb.PbList<Artifact>();
  @$core.pragma('dart2js:noInline')
  static Artifact getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Artifact>(create);
  static Artifact? _defaultInstance;

  /// Can be used to refer to this artifact.
  /// Format:
  /// - For invocation-level artifacts:
  ///   "invocations/{INVOCATION_ID}/artifacts/{ARTIFACT_ID}".
  /// - For test-result-level artifacts:
  ///   "invocations/{INVOCATION_ID}/tests/{URL_ESCAPED_TEST_ID}/results/{RESULT_ID}/artifacts/{ARTIFACT_ID}".
  /// where URL_ESCAPED_TEST_ID is the test_id escaped with
  /// https://golang.org/pkg/net/url/#PathEscape (see also https://aip.dev/122),
  /// and ARTIFACT_ID is documented below.
  /// Examples: "screenshot.png", "traces/a.txt".
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

  /// A local identifier of the artifact, unique within the parent resource.
  /// MAY have slashes, but MUST NOT start with a slash.
  /// SHOULD not use backslashes.
  /// Regex: ^(?:[[:word:]]|\.)([\p{L}\p{M}\p{N}\p{P}\p{S}\p{Zs}]{0,254}[[:word:]])?$
  @$pb.TagNumber(2)
  $core.String get artifactId => $_getSZ(1);
  @$pb.TagNumber(2)
  set artifactId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasArtifactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearArtifactId() => clearField(2);

  /// A signed short-lived URL to fetch the contents of the artifact.
  /// See also fetch_url_expiration.
  @$pb.TagNumber(3)
  $core.String get fetchUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set fetchUrl($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasFetchUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearFetchUrl() => clearField(3);

  /// When fetch_url expires. If expired, re-request this Artifact.
  @$pb.TagNumber(4)
  $0.Timestamp get fetchUrlExpiration => $_getN(3);
  @$pb.TagNumber(4)
  set fetchUrlExpiration($0.Timestamp v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasFetchUrlExpiration() => $_has(3);
  @$pb.TagNumber(4)
  void clearFetchUrlExpiration() => clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureFetchUrlExpiration() => $_ensure(3);

  /// Media type of the artifact.
  /// Logs are typically "text/plain" and screenshots are typically "image/png".
  /// Optional.
  @$pb.TagNumber(5)
  $core.String get contentType => $_getSZ(4);
  @$pb.TagNumber(5)
  set contentType($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasContentType() => $_has(4);
  @$pb.TagNumber(5)
  void clearContentType() => clearField(5);

  /// Size of the file.
  /// Can be used in UI to decide between displaying the artifact inline or only
  /// showing a link if it is too large.
  /// If you are using the gcs_uri, this field is not verified, but only treated as a hint.
  @$pb.TagNumber(6)
  $fixnum.Int64 get sizeBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set sizeBytes($fixnum.Int64 v) {
    $_setInt64(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasSizeBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearSizeBytes() => clearField(6);

  /// Contents of the artifact.
  /// This is INPUT_ONLY, and taken by BatchCreateArtifacts().
  /// All getter RPCs, such as ListArtifacts(), do not populate values into
  /// the field in the response.
  /// If specified, `gcs_uri` must be empty.
  @$pb.TagNumber(7)
  $core.List<$core.int> get contents => $_getN(6);
  @$pb.TagNumber(7)
  set contents($core.List<$core.int> v) {
    $_setBytes(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasContents() => $_has(6);
  @$pb.TagNumber(7)
  void clearContents() => clearField(7);

  /// The GCS URI of the artifact if it's stored in GCS.  If specified, `contents` must be empty.
  @$pb.TagNumber(8)
  $core.String get gcsUri => $_getSZ(7);
  @$pb.TagNumber(8)
  set gcsUri($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasGcsUri() => $_has(7);
  @$pb.TagNumber(8)
  void clearGcsUri() => clearField(8);

  /// Status of the test result that the artifact belongs to.
  /// This is only applicable for test-level artifacts, not invocation-level artifacts.
  /// We need this field because when an artifact is created (for example, with BatchCreateArtifact),
  /// the containing test result may or may not be created yet, as they
  /// are created in different channels from result sink.
  /// Having the test status here allows setting the correct status of artifact in BigQuery.
  @$pb.TagNumber(9)
  $1.TestStatus get testStatus => $_getN(8);
  @$pb.TagNumber(9)
  set testStatus($1.TestStatus v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasTestStatus() => $_has(8);
  @$pb.TagNumber(9)
  void clearTestStatus() => clearField(9);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
