//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/struct.pb.dart' as $2;
import '../../../../../google/protobuf/timestamp.pb.dart' as $0;
import 'common.pb.dart' as $1;
import 'invocation.pbenum.dart';
import 'predicate.pb.dart' as $3;

export 'invocation.pbenum.dart';

///  A conceptual container of results. Immutable once finalized.
///  It represents all results of some computation; examples: swarming task,
///  buildbucket build, CQ attempt.
///  Composable: can include other invocations, see inclusion.proto.
///
///  Next id: 17.
class Invocation extends $pb.GeneratedMessage {
  factory Invocation({
    $core.String? name,
    Invocation_State? state,
    $0.Timestamp? createTime,
    $core.Iterable<$1.StringPair>? tags,
    $0.Timestamp? finalizeTime,
    $0.Timestamp? deadline,
    $core.Iterable<$core.String>? includedInvocations,
    $core.Iterable<BigQueryExport>? bigqueryExports,
    $core.String? createdBy,
    $core.String? producerResource,
    $core.String? realm,
    HistoryOptions? historyOptions,
    $2.Struct? properties,
    SourceSpec? sourceSpec,
    $core.String? baselineId,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (state != null) {
      $result.state = state;
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (finalizeTime != null) {
      $result.finalizeTime = finalizeTime;
    }
    if (deadline != null) {
      $result.deadline = deadline;
    }
    if (includedInvocations != null) {
      $result.includedInvocations.addAll(includedInvocations);
    }
    if (bigqueryExports != null) {
      $result.bigqueryExports.addAll(bigqueryExports);
    }
    if (createdBy != null) {
      $result.createdBy = createdBy;
    }
    if (producerResource != null) {
      $result.producerResource = producerResource;
    }
    if (realm != null) {
      $result.realm = realm;
    }
    if (historyOptions != null) {
      $result.historyOptions = historyOptions;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    if (sourceSpec != null) {
      $result.sourceSpec = sourceSpec;
    }
    if (baselineId != null) {
      $result.baselineId = baselineId;
    }
    return $result;
  }
  Invocation._() : super();
  factory Invocation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Invocation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Invocation',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<Invocation_State>(2, _omitFieldNames ? '' : 'state', $pb.PbFieldType.OE,
        defaultOrMaker: Invocation_State.STATE_UNSPECIFIED,
        valueOf: Invocation_State.valueOf,
        enumValues: Invocation_State.values)
    ..aOM<$0.Timestamp>(4, _omitFieldNames ? '' : 'createTime', subBuilder: $0.Timestamp.create)
    ..pc<$1.StringPair>(5, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $1.StringPair.create)
    ..aOM<$0.Timestamp>(6, _omitFieldNames ? '' : 'finalizeTime', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'deadline', subBuilder: $0.Timestamp.create)
    ..pPS(8, _omitFieldNames ? '' : 'includedInvocations')
    ..pc<BigQueryExport>(9, _omitFieldNames ? '' : 'bigqueryExports', $pb.PbFieldType.PM,
        subBuilder: BigQueryExport.create)
    ..aOS(10, _omitFieldNames ? '' : 'createdBy')
    ..aOS(11, _omitFieldNames ? '' : 'producerResource')
    ..aOS(12, _omitFieldNames ? '' : 'realm')
    ..aOM<HistoryOptions>(13, _omitFieldNames ? '' : 'historyOptions', subBuilder: HistoryOptions.create)
    ..aOM<$2.Struct>(14, _omitFieldNames ? '' : 'properties', subBuilder: $2.Struct.create)
    ..aOM<SourceSpec>(15, _omitFieldNames ? '' : 'sourceSpec', subBuilder: SourceSpec.create)
    ..aOS(16, _omitFieldNames ? '' : 'baselineId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Invocation clone() => Invocation()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Invocation copyWith(void Function(Invocation) updates) =>
      super.copyWith((message) => updates(message as Invocation)) as Invocation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Invocation create() => Invocation._();
  Invocation createEmptyInstance() => create();
  static $pb.PbList<Invocation> createRepeated() => $pb.PbList<Invocation>();
  @$core.pragma('dart2js:noInline')
  static Invocation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Invocation>(create);
  static Invocation? _defaultInstance;

  ///  Can be used to refer to this invocation, e.g. in ResultDB.GetInvocation
  ///  RPC.
  ///  Format: invocations/{INVOCATION_ID}
  ///  See also https://aip.dev/122.
  ///
  ///  Output only.
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

  ///  Current state of the invocation.
  ///
  ///  At creation time this can be set to FINALIZING e.g. if this invocation is
  ///  a simple wrapper of another and will itself not be modified.
  ///
  ///  Otherwise this is an output only field.
  @$pb.TagNumber(2)
  Invocation_State get state => $_getN(1);
  @$pb.TagNumber(2)
  set state(Invocation_State v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasState() => $_has(1);
  @$pb.TagNumber(2)
  void clearState() => clearField(2);

  /// When the invocation was created.
  /// Output only.
  @$pb.TagNumber(4)
  $0.Timestamp get createTime => $_getN(2);
  @$pb.TagNumber(4)
  set createTime($0.Timestamp v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCreateTime() => $_has(2);
  @$pb.TagNumber(4)
  void clearCreateTime() => clearField(4);
  @$pb.TagNumber(4)
  $0.Timestamp ensureCreateTime() => $_ensure(2);

  /// Invocation-level string key-value pairs.
  /// A key can be repeated.
  @$pb.TagNumber(5)
  $core.List<$1.StringPair> get tags => $_getList(3);

  ///  When the invocation was finalized, i.e. transitioned to FINALIZED state.
  ///  If this field is set, implies that the invocation is finalized.
  ///
  ///  Output only.
  @$pb.TagNumber(6)
  $0.Timestamp get finalizeTime => $_getN(4);
  @$pb.TagNumber(6)
  set finalizeTime($0.Timestamp v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasFinalizeTime() => $_has(4);
  @$pb.TagNumber(6)
  void clearFinalizeTime() => clearField(6);
  @$pb.TagNumber(6)
  $0.Timestamp ensureFinalizeTime() => $_ensure(4);

  /// Timestamp when the invocation will be forcefully finalized.
  /// Can be extended with UpdateInvocation until finalized.
  @$pb.TagNumber(7)
  $0.Timestamp get deadline => $_getN(5);
  @$pb.TagNumber(7)
  set deadline($0.Timestamp v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDeadline() => $_has(5);
  @$pb.TagNumber(7)
  void clearDeadline() => clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureDeadline() => $_ensure(5);

  ///  Names of invocations included into this one. Overall results of this
  ///  invocation is a UNION of results directly included into this invocation
  ///  and results from the included invocations, recursively.
  ///  For example, a Buildbucket build invocation may include invocations of its
  ///  child swarming tasks and represent overall result of the build,
  ///  encapsulating the internal structure of the build.
  ///
  ///  The graph is directed.
  ///  There can be at most one edge between a given pair of invocations.
  ///  The shape of the graph does not matter. What matters is only the set of
  ///  reachable invocations. Thus cycles are allowed and are noop.
  ///
  ///  QueryTestResults returns test results from the transitive closure of
  ///  invocations.
  ///
  ///  This field can be set under Recorder.CreateInvocationsRequest to include
  ///  existing invocations at the moment of invocation creation.
  ///  New invocations created in the same batch (via
  ///  Recorder.BatchCreateInvocationsRequest) are also allowed.
  ///  Otherwise, this field is to be treated as Output only.
  ///
  ///  To modify included invocations, use Recorder.UpdateIncludedInvocations in
  ///  all other cases.
  @$pb.TagNumber(8)
  $core.List<$core.String> get includedInvocations => $_getList(6);

  /// bigquery_exports indicates what BigQuery table(s) that results in this
  /// invocation should export to.
  @$pb.TagNumber(9)
  $core.List<BigQueryExport> get bigqueryExports => $_getList(7);

  ///  LUCI identity (e.g. "user:<email>") who created the invocation.
  ///  Typically, a LUCI service account (e.g.
  ///  "user:cr-buildbucket@appspot.gserviceaccount.com"), but can also be a user
  ///  (e.g. "user:johndoe@example.com").
  ///
  ///  Output only.
  @$pb.TagNumber(10)
  $core.String get createdBy => $_getSZ(8);
  @$pb.TagNumber(10)
  set createdBy($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasCreatedBy() => $_has(8);
  @$pb.TagNumber(10)
  void clearCreatedBy() => clearField(10);

  /// Full name of the resource that produced results in this invocation.
  /// See also https://aip.dev/122#full-resource-names
  /// Typical examples:
  /// - Swarming task: "//chromium-swarm.appspot.com/tasks/deadbeef"
  /// - Buildbucket build: "//cr-buildbucket.appspot.com/builds/1234567890".
  @$pb.TagNumber(11)
  $core.String get producerResource => $_getSZ(9);
  @$pb.TagNumber(11)
  set producerResource($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasProducerResource() => $_has(9);
  @$pb.TagNumber(11)
  void clearProducerResource() => clearField(11);

  /// Realm that the invocation exists under.
  /// See https://chromium.googlesource.com/infra/luci/luci-py/+/refs/heads/main/appengine/auth_service/proto/realms_config.proto
  @$pb.TagNumber(12)
  $core.String get realm => $_getSZ(10);
  @$pb.TagNumber(12)
  set realm($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasRealm() => $_has(10);
  @$pb.TagNumber(12)
  void clearRealm() => clearField(12);

  /// Deprecated. Values specified here are ignored.
  @$pb.TagNumber(13)
  HistoryOptions get historyOptions => $_getN(11);
  @$pb.TagNumber(13)
  set historyOptions(HistoryOptions v) {
    setField(13, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasHistoryOptions() => $_has(11);
  @$pb.TagNumber(13)
  void clearHistoryOptions() => clearField(13);
  @$pb.TagNumber(13)
  HistoryOptions ensureHistoryOptions() => $_ensure(11);

  ///  Arbitrary JSON object that contains structured, domain-specific properties
  ///  of the invocation.
  ///
  ///  The serialized size must be <= 4096 bytes.
  @$pb.TagNumber(14)
  $2.Struct get properties => $_getN(12);
  @$pb.TagNumber(14)
  set properties($2.Struct v) {
    setField(14, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasProperties() => $_has(12);
  @$pb.TagNumber(14)
  void clearProperties() => clearField(14);
  @$pb.TagNumber(14)
  $2.Struct ensureProperties() => $_ensure(12);

  ///  The code sources which were tested by this invocation.
  ///  This is used to index test results for test history, and for
  ///  related analyses (e.g. culprit analysis / changepoint analyses).
  ///
  ///  The sources specified here applies only to:
  ///  - the test results directly contained in this invocation, and
  ///  - any directly included invocations which set their source_spec.inherit to
  ///  true.
  ///
  ///  Clients should be careful to ensure the uploaded source spec is consistent
  ///  between included invocations that upload the same test variants.
  ///  Verdicts are associated with the sources of *any* of their constituent
  ///  test results, so if there is inconsistency between included invocations,
  ///  the position of the verdict becomes not well defined.
  @$pb.TagNumber(15)
  SourceSpec get sourceSpec => $_getN(13);
  @$pb.TagNumber(15)
  set sourceSpec(SourceSpec v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasSourceSpec() => $_has(13);
  @$pb.TagNumber(15)
  void clearSourceSpec() => clearField(15);
  @$pb.TagNumber(15)
  SourceSpec ensureSourceSpec() => $_ensure(13);

  ///  A user-specified baseline identifier that maps to a set of test variants.
  ///  Often, this will be the source that generated the test result, such as the
  ///  builder name for Chromium. For example, the baseline identifier may be
  ///  try:linux-rel. The supported syntax for a baseline identifier is
  ///  ^[a-z0-9\-_.]{1,100}:[a-zA-Z0-9\-_.\(\) ]{1,128}`$. This syntax was selected
  ///  to allow <buildbucket bucket name>:<buildbucket builder name> as a valid
  ///  baseline ID.
  ///  See go/src/go.chromium.org/luci/buildbucket/proto/builder_common.proto for
  ///  character lengths for buildbucket bucket name and builder name.
  ///
  ///  Baselines are used to identify new tests; a subtraction between the set of
  ///  test variants for a baseline in the Baselines table and test variants from
  ///  a given invocation determines whether a test is new.
  ///
  ///  The caller must have `resultdb.baselines.put` to be able to
  ///  modify this field.
  @$pb.TagNumber(16)
  $core.String get baselineId => $_getSZ(14);
  @$pb.TagNumber(16)
  set baselineId($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasBaselineId() => $_has(14);
  @$pb.TagNumber(16)
  void clearBaselineId() => clearField(16);
}

/// TestResults indicates that test results should be exported.
class BigQueryExport_TestResults extends $pb.GeneratedMessage {
  factory BigQueryExport_TestResults({
    $3.TestResultPredicate? predicate,
  }) {
    final $result = create();
    if (predicate != null) {
      $result.predicate = predicate;
    }
    return $result;
  }
  BigQueryExport_TestResults._() : super();
  factory BigQueryExport_TestResults.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BigQueryExport_TestResults.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BigQueryExport.TestResults',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<$3.TestResultPredicate>(1, _omitFieldNames ? '' : 'predicate', subBuilder: $3.TestResultPredicate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BigQueryExport_TestResults clone() => BigQueryExport_TestResults()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BigQueryExport_TestResults copyWith(void Function(BigQueryExport_TestResults) updates) =>
      super.copyWith((message) => updates(message as BigQueryExport_TestResults)) as BigQueryExport_TestResults;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BigQueryExport_TestResults create() => BigQueryExport_TestResults._();
  BigQueryExport_TestResults createEmptyInstance() => create();
  static $pb.PbList<BigQueryExport_TestResults> createRepeated() => $pb.PbList<BigQueryExport_TestResults>();
  @$core.pragma('dart2js:noInline')
  static BigQueryExport_TestResults getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BigQueryExport_TestResults>(create);
  static BigQueryExport_TestResults? _defaultInstance;

  /// Use predicate to query test results that should be exported to
  /// BigQuery table.
  @$pb.TagNumber(1)
  $3.TestResultPredicate get predicate => $_getN(0);
  @$pb.TagNumber(1)
  set predicate($3.TestResultPredicate v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPredicate() => $_has(0);
  @$pb.TagNumber(1)
  void clearPredicate() => clearField(1);
  @$pb.TagNumber(1)
  $3.TestResultPredicate ensurePredicate() => $_ensure(0);
}

/// TextArtifacts indicates that text artifacts should be exported.
class BigQueryExport_TextArtifacts extends $pb.GeneratedMessage {
  factory BigQueryExport_TextArtifacts({
    $3.ArtifactPredicate? predicate,
  }) {
    final $result = create();
    if (predicate != null) {
      $result.predicate = predicate;
    }
    return $result;
  }
  BigQueryExport_TextArtifacts._() : super();
  factory BigQueryExport_TextArtifacts.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BigQueryExport_TextArtifacts.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BigQueryExport.TextArtifacts',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<$3.ArtifactPredicate>(1, _omitFieldNames ? '' : 'predicate', subBuilder: $3.ArtifactPredicate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BigQueryExport_TextArtifacts clone() => BigQueryExport_TextArtifacts()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BigQueryExport_TextArtifacts copyWith(void Function(BigQueryExport_TextArtifacts) updates) =>
      super.copyWith((message) => updates(message as BigQueryExport_TextArtifacts)) as BigQueryExport_TextArtifacts;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BigQueryExport_TextArtifacts create() => BigQueryExport_TextArtifacts._();
  BigQueryExport_TextArtifacts createEmptyInstance() => create();
  static $pb.PbList<BigQueryExport_TextArtifacts> createRepeated() => $pb.PbList<BigQueryExport_TextArtifacts>();
  @$core.pragma('dart2js:noInline')
  static BigQueryExport_TextArtifacts getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BigQueryExport_TextArtifacts>(create);
  static BigQueryExport_TextArtifacts? _defaultInstance;

  ///  Use predicate to query artifacts that should be exported to
  ///  BigQuery table.
  ///
  ///  Sub-field predicate.content_type_regexp defaults to "text/.*".
  @$pb.TagNumber(1)
  $3.ArtifactPredicate get predicate => $_getN(0);
  @$pb.TagNumber(1)
  set predicate($3.ArtifactPredicate v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPredicate() => $_has(0);
  @$pb.TagNumber(1)
  void clearPredicate() => clearField(1);
  @$pb.TagNumber(1)
  $3.ArtifactPredicate ensurePredicate() => $_ensure(0);
}

enum BigQueryExport_ResultType { testResults, textArtifacts, notSet }

/// BigQueryExport indicates that results in this invocation should be exported
/// to BigQuery after finalization.
class BigQueryExport extends $pb.GeneratedMessage {
  factory BigQueryExport({
    $core.String? project,
    $core.String? dataset,
    $core.String? table,
    BigQueryExport_TestResults? testResults,
    BigQueryExport_TextArtifacts? textArtifacts,
  }) {
    final $result = create();
    if (project != null) {
      $result.project = project;
    }
    if (dataset != null) {
      $result.dataset = dataset;
    }
    if (table != null) {
      $result.table = table;
    }
    if (testResults != null) {
      $result.testResults = testResults;
    }
    if (textArtifacts != null) {
      $result.textArtifacts = textArtifacts;
    }
    return $result;
  }
  BigQueryExport._() : super();
  factory BigQueryExport.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BigQueryExport.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BigQueryExport_ResultType> _BigQueryExport_ResultTypeByTag = {
    4: BigQueryExport_ResultType.testResults,
    6: BigQueryExport_ResultType.textArtifacts,
    0: BigQueryExport_ResultType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BigQueryExport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..oo(0, [4, 6])
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..aOS(2, _omitFieldNames ? '' : 'dataset')
    ..aOS(3, _omitFieldNames ? '' : 'table')
    ..aOM<BigQueryExport_TestResults>(4, _omitFieldNames ? '' : 'testResults',
        subBuilder: BigQueryExport_TestResults.create)
    ..aOM<BigQueryExport_TextArtifacts>(6, _omitFieldNames ? '' : 'textArtifacts',
        subBuilder: BigQueryExport_TextArtifacts.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BigQueryExport clone() => BigQueryExport()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BigQueryExport copyWith(void Function(BigQueryExport) updates) =>
      super.copyWith((message) => updates(message as BigQueryExport)) as BigQueryExport;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BigQueryExport create() => BigQueryExport._();
  BigQueryExport createEmptyInstance() => create();
  static $pb.PbList<BigQueryExport> createRepeated() => $pb.PbList<BigQueryExport>();
  @$core.pragma('dart2js:noInline')
  static BigQueryExport getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BigQueryExport>(create);
  static BigQueryExport? _defaultInstance;

  BigQueryExport_ResultType whichResultType() => _BigQueryExport_ResultTypeByTag[$_whichOneof(0)]!;
  void clearResultType() => clearField($_whichOneof(0));

  /// Name of the BigQuery project.
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

  /// Name of the BigQuery Dataset.
  @$pb.TagNumber(2)
  $core.String get dataset => $_getSZ(1);
  @$pb.TagNumber(2)
  set dataset($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDataset() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataset() => clearField(2);

  /// Name of the BigQuery Table.
  @$pb.TagNumber(3)
  $core.String get table => $_getSZ(2);
  @$pb.TagNumber(3)
  set table($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTable() => $_has(2);
  @$pb.TagNumber(3)
  void clearTable() => clearField(3);

  @$pb.TagNumber(4)
  BigQueryExport_TestResults get testResults => $_getN(3);
  @$pb.TagNumber(4)
  set testResults(BigQueryExport_TestResults v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTestResults() => $_has(3);
  @$pb.TagNumber(4)
  void clearTestResults() => clearField(4);
  @$pb.TagNumber(4)
  BigQueryExport_TestResults ensureTestResults() => $_ensure(3);

  @$pb.TagNumber(6)
  BigQueryExport_TextArtifacts get textArtifacts => $_getN(4);
  @$pb.TagNumber(6)
  set textArtifacts(BigQueryExport_TextArtifacts v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTextArtifacts() => $_has(4);
  @$pb.TagNumber(6)
  void clearTextArtifacts() => clearField(6);
  @$pb.TagNumber(6)
  BigQueryExport_TextArtifacts ensureTextArtifacts() => $_ensure(4);
}

/// HistoryOptions indicates how the invocations should be indexed, so that their
/// results can be queried over a range of time or of commits.
/// Deprecated: do not use.
class HistoryOptions extends $pb.GeneratedMessage {
  factory HistoryOptions({
    $core.bool? useInvocationTimestamp,
    $1.CommitPosition? commit,
  }) {
    final $result = create();
    if (useInvocationTimestamp != null) {
      $result.useInvocationTimestamp = useInvocationTimestamp;
    }
    if (commit != null) {
      $result.commit = commit;
    }
    return $result;
  }
  HistoryOptions._() : super();
  factory HistoryOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HistoryOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HistoryOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'useInvocationTimestamp')
    ..aOM<$1.CommitPosition>(2, _omitFieldNames ? '' : 'commit', subBuilder: $1.CommitPosition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HistoryOptions clone() => HistoryOptions()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HistoryOptions copyWith(void Function(HistoryOptions) updates) =>
      super.copyWith((message) => updates(message as HistoryOptions)) as HistoryOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HistoryOptions create() => HistoryOptions._();
  HistoryOptions createEmptyInstance() => create();
  static $pb.PbList<HistoryOptions> createRepeated() => $pb.PbList<HistoryOptions>();
  @$core.pragma('dart2js:noInline')
  static HistoryOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HistoryOptions>(create);
  static HistoryOptions? _defaultInstance;

  /// Set this to index the results by the containing invocation's create_time.
  @$pb.TagNumber(1)
  $core.bool get useInvocationTimestamp => $_getBF(0);
  @$pb.TagNumber(1)
  set useInvocationTimestamp($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasUseInvocationTimestamp() => $_has(0);
  @$pb.TagNumber(1)
  void clearUseInvocationTimestamp() => clearField(1);

  /// Set this to index by commit position.
  /// It's up to the creator of the invocation to set this consistently over
  /// time across the same test variant.
  @$pb.TagNumber(2)
  $1.CommitPosition get commit => $_getN(1);
  @$pb.TagNumber(2)
  set commit($1.CommitPosition v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => clearField(2);
  @$pb.TagNumber(2)
  $1.CommitPosition ensureCommit() => $_ensure(1);
}

/// Specifies the source code that was tested in an invocation, either directly
/// (via the sources field) or indirectly (via inherit_sources).
class SourceSpec extends $pb.GeneratedMessage {
  factory SourceSpec({
    Sources? sources,
    $core.bool? inherit,
  }) {
    final $result = create();
    if (sources != null) {
      $result.sources = sources;
    }
    if (inherit != null) {
      $result.inherit = inherit;
    }
    return $result;
  }
  SourceSpec._() : super();
  factory SourceSpec.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SourceSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SourceSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<Sources>(1, _omitFieldNames ? '' : 'sources', subBuilder: Sources.create)
    ..aOB(2, _omitFieldNames ? '' : 'inherit')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SourceSpec clone() => SourceSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SourceSpec copyWith(void Function(SourceSpec) updates) =>
      super.copyWith((message) => updates(message as SourceSpec)) as SourceSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SourceSpec create() => SourceSpec._();
  SourceSpec createEmptyInstance() => create();
  static $pb.PbList<SourceSpec> createRepeated() => $pb.PbList<SourceSpec>();
  @$core.pragma('dart2js:noInline')
  static SourceSpec getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SourceSpec>(create);
  static SourceSpec? _defaultInstance;

  /// Specifies the source position that was tested.
  /// Either this or inherit_sources may be set, but not both.
  @$pb.TagNumber(1)
  Sources get sources => $_getN(0);
  @$pb.TagNumber(1)
  set sources(Sources v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSources() => $_has(0);
  @$pb.TagNumber(1)
  void clearSources() => clearField(1);
  @$pb.TagNumber(1)
  Sources ensureSources() => $_ensure(0);

  ///  Specifies that the source position of the invocation is inherited
  ///  from the parent invocation it is included in.
  ///
  ///  # Use case
  ///  This is useful in situations where the testing infrastructure deduplicates
  ///  execution of tests on identical binaries (e.g. using swarming's task
  ///  deduplication feature).
  ///
  ///  Let A be the invocation for a swarming task that receives only a
  ///  test binary as input, with task deduplication enabled.
  ///  Let B be the invocation for a buildbucket build which built the
  ///  binary from sources (or at the very least knew the sources)
  ///  and triggered invocation A.
  ///  Invocation B includes invocation A.
  ///
  ///  By setting A's source_spec to inherit, and specifying the sources
  ///  on invocation B, the test results in A will be associated with
  ///  the sources specified on invocation B, when queried via invocation B.
  ///
  ///  This allows further invocations B2, B3 ... BN to be created which also
  ///  re-use the test results in A but associate them with possibly different
  ///  sources when queried via B2 ... BN (this is valid so long as the sources
  ///  produce a binary-identical testing input).
  ///
  ///  # Multiple inclusion paths
  ///  It is possible for an invocation A to be included in the reachable
  ///  invocation graph for an invocation C in more than one way.
  ///
  ///  For example, we may have:
  ///    A -> B1 -> C
  ///    A -> B2 -> C
  ///  as two paths of inclusion.
  ///
  ///  If A sets inherit to true, the commit position assigned to its
  ///  test results will be selected via *one* of the paths of inclusion
  ///  into C (i.e. from B1 or B2).
  ///
  ///  However, which path is selected is not guaranteed, so if clients
  ///  must include the same invocation multiple times, they should
  ///  make the source position via all paths the same.
  @$pb.TagNumber(2)
  $core.bool get inherit => $_getBF(1);
  @$pb.TagNumber(2)
  set inherit($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInherit() => $_has(1);
  @$pb.TagNumber(2)
  void clearInherit() => clearField(2);
}

/// Specifies the source code that was tested.
class Sources extends $pb.GeneratedMessage {
  factory Sources({
    $1.GitilesCommit? gitilesCommit,
    $core.Iterable<$1.GerritChange>? changelists,
    $core.bool? isDirty,
  }) {
    final $result = create();
    if (gitilesCommit != null) {
      $result.gitilesCommit = gitilesCommit;
    }
    if (changelists != null) {
      $result.changelists.addAll(changelists);
    }
    if (isDirty != null) {
      $result.isDirty = isDirty;
    }
    return $result;
  }
  Sources._() : super();
  factory Sources.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Sources.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Sources',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<$1.GitilesCommit>(1, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $1.GitilesCommit.create)
    ..pc<$1.GerritChange>(2, _omitFieldNames ? '' : 'changelists', $pb.PbFieldType.PM,
        subBuilder: $1.GerritChange.create)
    ..aOB(3, _omitFieldNames ? '' : 'isDirty')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Sources clone() => Sources()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Sources copyWith(void Function(Sources) updates) =>
      super.copyWith((message) => updates(message as Sources)) as Sources;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Sources create() => Sources._();
  Sources createEmptyInstance() => create();
  static $pb.PbList<Sources> createRepeated() => $pb.PbList<Sources>();
  @$core.pragma('dart2js:noInline')
  static Sources getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Sources>(create);
  static Sources? _defaultInstance;

  /// The base version of code sources checked out. Mandatory.
  /// If necessary, we could add support for non-gitiles sources here in
  /// future, using a oneof statement. E.g.
  /// oneof system {
  ///    GitilesCommit gitiles_commit = 1;
  ///    SubversionRevision svn_revision = 4;
  ///    ...
  /// }
  @$pb.TagNumber(1)
  $1.GitilesCommit get gitilesCommit => $_getN(0);
  @$pb.TagNumber(1)
  set gitilesCommit($1.GitilesCommit v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasGitilesCommit() => $_has(0);
  @$pb.TagNumber(1)
  void clearGitilesCommit() => clearField(1);
  @$pb.TagNumber(1)
  $1.GitilesCommit ensureGitilesCommit() => $_ensure(0);

  ///  The changelist(s) which were applied upon the base version of sources
  ///  checked out. E.g. in commit queue tryjobs.
  ///
  ///  At most 10 changelist(s) may be specified here. If there
  ///  are more, only include the first 10 and set is_dirty.
  @$pb.TagNumber(2)
  $core.List<$1.GerritChange> get changelists => $_getList(1);

  ///  Whether there were any changes made to the sources, not described above.
  ///  For example, a version of a dependency was upgraded before testing (e.g.
  ///  in an autoroller recipe).
  ///
  ///  Cherry-picking a changelist on top of the base checkout is not considered
  ///  making the sources dirty as it is reported separately above.
  @$pb.TagNumber(3)
  $core.bool get isDirty => $_getBF(2);
  @$pb.TagNumber(3)
  set isDirty($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasIsDirty() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDirty() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
