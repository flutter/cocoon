//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/predicate.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;
import 'predicate.pbenum.dart';

export 'predicate.pbenum.dart';

class TestResultPredicate extends $pb.GeneratedMessage {
  factory TestResultPredicate() => create();
  TestResultPredicate._() : super();
  factory TestResultPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestResultPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestResultPredicate', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'testIdRegexp')
    ..aOM<VariantPredicate>(2, _omitFieldNames ? '' : 'variant', subBuilder: VariantPredicate.create)
    ..e<TestResultPredicate_Expectancy>(3, _omitFieldNames ? '' : 'expectancy', $pb.PbFieldType.OE, defaultOrMaker: TestResultPredicate_Expectancy.ALL, valueOf: TestResultPredicate_Expectancy.valueOf, enumValues: TestResultPredicate_Expectancy.values)
    ..aOB(4, _omitFieldNames ? '' : 'excludeExonerated')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestResultPredicate clone() => TestResultPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestResultPredicate copyWith(void Function(TestResultPredicate) updates) => super.copyWith((message) => updates(message as TestResultPredicate)) as TestResultPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestResultPredicate create() => TestResultPredicate._();
  TestResultPredicate createEmptyInstance() => create();
  static $pb.PbList<TestResultPredicate> createRepeated() => $pb.PbList<TestResultPredicate>();
  @$core.pragma('dart2js:noInline')
  static TestResultPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestResultPredicate>(create);
  static TestResultPredicate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get testIdRegexp => $_getSZ(0);
  @$pb.TagNumber(1)
  set testIdRegexp($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTestIdRegexp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTestIdRegexp() => clearField(1);

  @$pb.TagNumber(2)
  VariantPredicate get variant => $_getN(1);
  @$pb.TagNumber(2)
  set variant(VariantPredicate v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasVariant() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariant() => clearField(2);
  @$pb.TagNumber(2)
  VariantPredicate ensureVariant() => $_ensure(1);

  @$pb.TagNumber(3)
  TestResultPredicate_Expectancy get expectancy => $_getN(2);
  @$pb.TagNumber(3)
  set expectancy(TestResultPredicate_Expectancy v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpectancy() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpectancy() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get excludeExonerated => $_getBF(3);
  @$pb.TagNumber(4)
  set excludeExonerated($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasExcludeExonerated() => $_has(3);
  @$pb.TagNumber(4)
  void clearExcludeExonerated() => clearField(4);
}

class TestExonerationPredicate extends $pb.GeneratedMessage {
  factory TestExonerationPredicate() => create();
  TestExonerationPredicate._() : super();
  factory TestExonerationPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestExonerationPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestExonerationPredicate', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'testIdRegexp')
    ..aOM<VariantPredicate>(2, _omitFieldNames ? '' : 'variant', subBuilder: VariantPredicate.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestExonerationPredicate clone() => TestExonerationPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestExonerationPredicate copyWith(void Function(TestExonerationPredicate) updates) => super.copyWith((message) => updates(message as TestExonerationPredicate)) as TestExonerationPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestExonerationPredicate create() => TestExonerationPredicate._();
  TestExonerationPredicate createEmptyInstance() => create();
  static $pb.PbList<TestExonerationPredicate> createRepeated() => $pb.PbList<TestExonerationPredicate>();
  @$core.pragma('dart2js:noInline')
  static TestExonerationPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestExonerationPredicate>(create);
  static TestExonerationPredicate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get testIdRegexp => $_getSZ(0);
  @$pb.TagNumber(1)
  set testIdRegexp($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTestIdRegexp() => $_has(0);
  @$pb.TagNumber(1)
  void clearTestIdRegexp() => clearField(1);

  @$pb.TagNumber(2)
  VariantPredicate get variant => $_getN(1);
  @$pb.TagNumber(2)
  set variant(VariantPredicate v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasVariant() => $_has(1);
  @$pb.TagNumber(2)
  void clearVariant() => clearField(2);
  @$pb.TagNumber(2)
  VariantPredicate ensureVariant() => $_ensure(1);
}

enum VariantPredicate_Predicate {
  equals, 
  contains, 
  notSet
}

class VariantPredicate extends $pb.GeneratedMessage {
  factory VariantPredicate() => create();
  VariantPredicate._() : super();
  factory VariantPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VariantPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, VariantPredicate_Predicate> _VariantPredicate_PredicateByTag = {
    1 : VariantPredicate_Predicate.equals,
    2 : VariantPredicate_Predicate.contains,
    0 : VariantPredicate_Predicate.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VariantPredicate', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Variant>(1, _omitFieldNames ? '' : 'equals', subBuilder: $0.Variant.create)
    ..aOM<$0.Variant>(2, _omitFieldNames ? '' : 'contains', subBuilder: $0.Variant.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VariantPredicate clone() => VariantPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VariantPredicate copyWith(void Function(VariantPredicate) updates) => super.copyWith((message) => updates(message as VariantPredicate)) as VariantPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VariantPredicate create() => VariantPredicate._();
  VariantPredicate createEmptyInstance() => create();
  static $pb.PbList<VariantPredicate> createRepeated() => $pb.PbList<VariantPredicate>();
  @$core.pragma('dart2js:noInline')
  static VariantPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VariantPredicate>(create);
  static VariantPredicate? _defaultInstance;

  VariantPredicate_Predicate whichPredicate() => _VariantPredicate_PredicateByTag[$_whichOneof(0)]!;
  void clearPredicate() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $0.Variant get equals => $_getN(0);
  @$pb.TagNumber(1)
  set equals($0.Variant v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasEquals() => $_has(0);
  @$pb.TagNumber(1)
  void clearEquals() => clearField(1);
  @$pb.TagNumber(1)
  $0.Variant ensureEquals() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Variant get contains => $_getN(1);
  @$pb.TagNumber(2)
  set contains($0.Variant v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasContains() => $_has(1);
  @$pb.TagNumber(2)
  void clearContains() => clearField(2);
  @$pb.TagNumber(2)
  $0.Variant ensureContains() => $_ensure(1);
}

class ArtifactPredicate_EdgeTypeSet extends $pb.GeneratedMessage {
  factory ArtifactPredicate_EdgeTypeSet() => create();
  ArtifactPredicate_EdgeTypeSet._() : super();
  factory ArtifactPredicate_EdgeTypeSet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ArtifactPredicate_EdgeTypeSet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ArtifactPredicate.EdgeTypeSet', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'includedInvocations')
    ..aOB(2, _omitFieldNames ? '' : 'testResults')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ArtifactPredicate_EdgeTypeSet clone() => ArtifactPredicate_EdgeTypeSet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ArtifactPredicate_EdgeTypeSet copyWith(void Function(ArtifactPredicate_EdgeTypeSet) updates) => super.copyWith((message) => updates(message as ArtifactPredicate_EdgeTypeSet)) as ArtifactPredicate_EdgeTypeSet;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactPredicate_EdgeTypeSet create() => ArtifactPredicate_EdgeTypeSet._();
  ArtifactPredicate_EdgeTypeSet createEmptyInstance() => create();
  static $pb.PbList<ArtifactPredicate_EdgeTypeSet> createRepeated() => $pb.PbList<ArtifactPredicate_EdgeTypeSet>();
  @$core.pragma('dart2js:noInline')
  static ArtifactPredicate_EdgeTypeSet getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArtifactPredicate_EdgeTypeSet>(create);
  static ArtifactPredicate_EdgeTypeSet? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get includedInvocations => $_getBF(0);
  @$pb.TagNumber(1)
  set includedInvocations($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasIncludedInvocations() => $_has(0);
  @$pb.TagNumber(1)
  void clearIncludedInvocations() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get testResults => $_getBF(1);
  @$pb.TagNumber(2)
  set testResults($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTestResults() => $_has(1);
  @$pb.TagNumber(2)
  void clearTestResults() => clearField(2);
}

class ArtifactPredicate extends $pb.GeneratedMessage {
  factory ArtifactPredicate() => create();
  ArtifactPredicate._() : super();
  factory ArtifactPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ArtifactPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ArtifactPredicate', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<ArtifactPredicate_EdgeTypeSet>(1, _omitFieldNames ? '' : 'followEdges', subBuilder: ArtifactPredicate_EdgeTypeSet.create)
    ..aOM<TestResultPredicate>(2, _omitFieldNames ? '' : 'testResultPredicate', subBuilder: TestResultPredicate.create)
    ..aOS(3, _omitFieldNames ? '' : 'contentTypeRegexp')
    ..aOS(4, _omitFieldNames ? '' : 'artifactIdRegexp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ArtifactPredicate clone() => ArtifactPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ArtifactPredicate copyWith(void Function(ArtifactPredicate) updates) => super.copyWith((message) => updates(message as ArtifactPredicate)) as ArtifactPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ArtifactPredicate create() => ArtifactPredicate._();
  ArtifactPredicate createEmptyInstance() => create();
  static $pb.PbList<ArtifactPredicate> createRepeated() => $pb.PbList<ArtifactPredicate>();
  @$core.pragma('dart2js:noInline')
  static ArtifactPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ArtifactPredicate>(create);
  static ArtifactPredicate? _defaultInstance;

  @$pb.TagNumber(1)
  ArtifactPredicate_EdgeTypeSet get followEdges => $_getN(0);
  @$pb.TagNumber(1)
  set followEdges(ArtifactPredicate_EdgeTypeSet v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFollowEdges() => $_has(0);
  @$pb.TagNumber(1)
  void clearFollowEdges() => clearField(1);
  @$pb.TagNumber(1)
  ArtifactPredicate_EdgeTypeSet ensureFollowEdges() => $_ensure(0);

  @$pb.TagNumber(2)
  TestResultPredicate get testResultPredicate => $_getN(1);
  @$pb.TagNumber(2)
  set testResultPredicate(TestResultPredicate v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTestResultPredicate() => $_has(1);
  @$pb.TagNumber(2)
  void clearTestResultPredicate() => clearField(2);
  @$pb.TagNumber(2)
  TestResultPredicate ensureTestResultPredicate() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.String get contentTypeRegexp => $_getSZ(2);
  @$pb.TagNumber(3)
  set contentTypeRegexp($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContentTypeRegexp() => $_has(2);
  @$pb.TagNumber(3)
  void clearContentTypeRegexp() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get artifactIdRegexp => $_getSZ(3);
  @$pb.TagNumber(4)
  set artifactIdRegexp($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasArtifactIdRegexp() => $_has(3);
  @$pb.TagNumber(4)
  void clearArtifactIdRegexp() => clearField(4);
}

class TestMetadataPredicate extends $pb.GeneratedMessage {
  factory TestMetadataPredicate() => create();
  TestMetadataPredicate._() : super();
  factory TestMetadataPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestMetadataPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestMetadataPredicate', package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'testIds')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestMetadataPredicate clone() => TestMetadataPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestMetadataPredicate copyWith(void Function(TestMetadataPredicate) updates) => super.copyWith((message) => updates(message as TestMetadataPredicate)) as TestMetadataPredicate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TestMetadataPredicate create() => TestMetadataPredicate._();
  TestMetadataPredicate createEmptyInstance() => create();
  static $pb.PbList<TestMetadataPredicate> createRepeated() => $pb.PbList<TestMetadataPredicate>();
  @$core.pragma('dart2js:noInline')
  static TestMetadataPredicate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TestMetadataPredicate>(create);
  static TestMetadataPredicate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get testIds => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
