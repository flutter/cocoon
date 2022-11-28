///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/predicate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;

import 'predicate.pbenum.dart';

export 'predicate.pbenum.dart';

class TestResultPredicate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TestResultPredicate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'testIdRegexp')
    ..aOM<VariantPredicate>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'variant', subBuilder: VariantPredicate.create)
    ..e<TestResultPredicate_Expectancy>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expectancy', $pb.PbFieldType.OE, defaultOrMaker: TestResultPredicate_Expectancy.ALL, valueOf: TestResultPredicate_Expectancy.valueOf, enumValues: TestResultPredicate_Expectancy.values)
    ..aOB(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'excludeExonerated')
    ..hasRequiredFields = false
  ;

  TestResultPredicate._() : super();
  factory TestResultPredicate({
    $core.String? testIdRegexp,
    VariantPredicate? variant,
    TestResultPredicate_Expectancy? expectancy,
    $core.bool? excludeExonerated,
  }) {
    final _result = create();
    if (testIdRegexp != null) {
      _result.testIdRegexp = testIdRegexp;
    }
    if (variant != null) {
      _result.variant = variant;
    }
    if (expectancy != null) {
      _result.expectancy = expectancy;
    }
    if (excludeExonerated != null) {
      _result.excludeExonerated = excludeExonerated;
    }
    return _result;
  }
  factory TestResultPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestResultPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestResultPredicate clone() => TestResultPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestResultPredicate copyWith(void Function(TestResultPredicate) updates) => super.copyWith((message) => updates(message as TestResultPredicate)) as TestResultPredicate; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TestExonerationPredicate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'testIdRegexp')
    ..aOM<VariantPredicate>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'variant', subBuilder: VariantPredicate.create)
    ..hasRequiredFields = false
  ;

  TestExonerationPredicate._() : super();
  factory TestExonerationPredicate({
    $core.String? testIdRegexp,
    VariantPredicate? variant,
  }) {
    final _result = create();
    if (testIdRegexp != null) {
      _result.testIdRegexp = testIdRegexp;
    }
    if (variant != null) {
      _result.variant = variant;
    }
    return _result;
  }
  factory TestExonerationPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TestExonerationPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TestExonerationPredicate clone() => TestExonerationPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TestExonerationPredicate copyWith(void Function(TestExonerationPredicate) updates) => super.copyWith((message) => updates(message as TestExonerationPredicate)) as TestExonerationPredicate; // ignore: deprecated_member_use
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
  static const $core.Map<$core.int, VariantPredicate_Predicate> _VariantPredicate_PredicateByTag = {
    1 : VariantPredicate_Predicate.equals,
    2 : VariantPredicate_Predicate.contains,
    0 : VariantPredicate_Predicate.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'VariantPredicate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<$0.Variant>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'equals', subBuilder: $0.Variant.create)
    ..aOM<$0.Variant>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'contains', subBuilder: $0.Variant.create)
    ..hasRequiredFields = false
  ;

  VariantPredicate._() : super();
  factory VariantPredicate({
    $0.Variant? equals,
    $0.Variant? contains,
  }) {
    final _result = create();
    if (equals != null) {
      _result.equals = equals;
    }
    if (contains != null) {
      _result.contains = contains;
    }
    return _result;
  }
  factory VariantPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory VariantPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  VariantPredicate clone() => VariantPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  VariantPredicate copyWith(void Function(VariantPredicate) updates) => super.copyWith((message) => updates(message as VariantPredicate)) as VariantPredicate; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ArtifactPredicate.EdgeTypeSet', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'includedInvocations')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'testResults')
    ..hasRequiredFields = false
  ;

  ArtifactPredicate_EdgeTypeSet._() : super();
  factory ArtifactPredicate_EdgeTypeSet({
    $core.bool? includedInvocations,
    $core.bool? testResults,
  }) {
    final _result = create();
    if (includedInvocations != null) {
      _result.includedInvocations = includedInvocations;
    }
    if (testResults != null) {
      _result.testResults = testResults;
    }
    return _result;
  }
  factory ArtifactPredicate_EdgeTypeSet.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ArtifactPredicate_EdgeTypeSet.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ArtifactPredicate_EdgeTypeSet clone() => ArtifactPredicate_EdgeTypeSet()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ArtifactPredicate_EdgeTypeSet copyWith(void Function(ArtifactPredicate_EdgeTypeSet) updates) => super.copyWith((message) => updates(message as ArtifactPredicate_EdgeTypeSet)) as ArtifactPredicate_EdgeTypeSet; // ignore: deprecated_member_use
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ArtifactPredicate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<ArtifactPredicate_EdgeTypeSet>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'followEdges', subBuilder: ArtifactPredicate_EdgeTypeSet.create)
    ..aOM<TestResultPredicate>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'testResultPredicate', subBuilder: TestResultPredicate.create)
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'contentTypeRegexp')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'artifactIdRegexp')
    ..hasRequiredFields = false
  ;

  ArtifactPredicate._() : super();
  factory ArtifactPredicate({
    ArtifactPredicate_EdgeTypeSet? followEdges,
    TestResultPredicate? testResultPredicate,
    $core.String? contentTypeRegexp,
    $core.String? artifactIdRegexp,
  }) {
    final _result = create();
    if (followEdges != null) {
      _result.followEdges = followEdges;
    }
    if (testResultPredicate != null) {
      _result.testResultPredicate = testResultPredicate;
    }
    if (contentTypeRegexp != null) {
      _result.contentTypeRegexp = contentTypeRegexp;
    }
    if (artifactIdRegexp != null) {
      _result.artifactIdRegexp = artifactIdRegexp;
    }
    return _result;
  }
  factory ArtifactPredicate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ArtifactPredicate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ArtifactPredicate clone() => ArtifactPredicate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ArtifactPredicate copyWith(void Function(ArtifactPredicate) updates) => super.copyWith((message) => updates(message as ArtifactPredicate)) as ArtifactPredicate; // ignore: deprecated_member_use
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

