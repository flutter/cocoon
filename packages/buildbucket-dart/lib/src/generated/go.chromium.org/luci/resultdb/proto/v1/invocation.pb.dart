//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
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

class Invocation extends $pb.GeneratedMessage {
  factory Invocation() => create();
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

  @$pb.TagNumber(5)
  $core.List<$1.StringPair> get tags => $_getList(3);

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

  @$pb.TagNumber(8)
  $core.List<$core.String> get includedInvocations => $_getList(6);

  @$pb.TagNumber(9)
  $core.List<BigQueryExport> get bigqueryExports => $_getList(7);

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

class BigQueryExport_TestResults extends $pb.GeneratedMessage {
  factory BigQueryExport_TestResults() => create();
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

class BigQueryExport_TextArtifacts extends $pb.GeneratedMessage {
  factory BigQueryExport_TextArtifacts() => create();
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

class BigQueryExport extends $pb.GeneratedMessage {
  factory BigQueryExport() => create();
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
  $core.String get dataset => $_getSZ(1);
  @$pb.TagNumber(2)
  set dataset($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDataset() => $_has(1);
  @$pb.TagNumber(2)
  void clearDataset() => clearField(2);

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

class HistoryOptions extends $pb.GeneratedMessage {
  factory HistoryOptions() => create();
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

class SourceSpec extends $pb.GeneratedMessage {
  factory SourceSpec() => create();
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

class Sources extends $pb.GeneratedMessage {
  factory Sources() => create();
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

  @$pb.TagNumber(2)
  $core.List<$1.GerritChange> get changelists => $_getList(1);

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
