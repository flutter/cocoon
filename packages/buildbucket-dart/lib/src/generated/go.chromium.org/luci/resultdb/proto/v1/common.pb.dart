///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/timestamp.pb.dart' as $0;

class Variant extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Variant', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'def', entryClassName: 'Variant.DefEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('luci.resultdb.v1'))
    ..hasRequiredFields = false
  ;

  Variant._() : super();
  factory Variant({
    $core.Map<$core.String, $core.String>? def,
  }) {
    final _result = create();
    if (def != null) {
      _result.def.addAll(def);
    }
    return _result;
  }
  factory Variant.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Variant.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Variant clone() => Variant()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Variant copyWith(void Function(Variant) updates) => super.copyWith((message) => updates(message as Variant)) as Variant; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Variant create() => Variant._();
  Variant createEmptyInstance() => create();
  static $pb.PbList<Variant> createRepeated() => $pb.PbList<Variant>();
  @$core.pragma('dart2js:noInline')
  static Variant getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Variant>(create);
  static Variant? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, $core.String> get def => $_getMap(0);
}

class StringPair extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'StringPair', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'value')
    ..hasRequiredFields = false
  ;

  StringPair._() : super();
  factory StringPair({
    $core.String? key,
    $core.String? value,
  }) {
    final _result = create();
    if (key != null) {
      _result.key = key;
    }
    if (value != null) {
      _result.value = value;
    }
    return _result;
  }
  factory StringPair.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StringPair.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StringPair clone() => StringPair()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StringPair copyWith(void Function(StringPair) updates) => super.copyWith((message) => updates(message as StringPair)) as StringPair; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static StringPair create() => StringPair._();
  StringPair createEmptyInstance() => create();
  static $pb.PbList<StringPair> createRepeated() => $pb.PbList<StringPair>();
  @$core.pragma('dart2js:noInline')
  static StringPair getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StringPair>(create);
  static StringPair? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

class CommitPosition extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CommitPosition', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'host')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'project')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ref')
    ..aInt64(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'position')
    ..hasRequiredFields = false
  ;

  CommitPosition._() : super();
  factory CommitPosition({
    $core.String? host,
    $core.String? project,
    $core.String? ref,
    $fixnum.Int64? position,
  }) {
    final _result = create();
    if (host != null) {
      _result.host = host;
    }
    if (project != null) {
      _result.project = project;
    }
    if (ref != null) {
      _result.ref = ref;
    }
    if (position != null) {
      _result.position = position;
    }
    return _result;
  }
  factory CommitPosition.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CommitPosition.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CommitPosition clone() => CommitPosition()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CommitPosition copyWith(void Function(CommitPosition) updates) => super.copyWith((message) => updates(message as CommitPosition)) as CommitPosition; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitPosition create() => CommitPosition._();
  CommitPosition createEmptyInstance() => create();
  static $pb.PbList<CommitPosition> createRepeated() => $pb.PbList<CommitPosition>();
  @$core.pragma('dart2js:noInline')
  static CommitPosition getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitPosition>(create);
  static CommitPosition? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ref => $_getSZ(2);
  @$pb.TagNumber(3)
  set ref($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRef() => $_has(2);
  @$pb.TagNumber(3)
  void clearRef() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get position => $_getI64(3);
  @$pb.TagNumber(4)
  set position($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => clearField(4);
}

class CommitPositionRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'CommitPositionRange', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<CommitPosition>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'earliest', subBuilder: CommitPosition.create)
    ..aOM<CommitPosition>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latest', subBuilder: CommitPosition.create)
    ..hasRequiredFields = false
  ;

  CommitPositionRange._() : super();
  factory CommitPositionRange({
    CommitPosition? earliest,
    CommitPosition? latest,
  }) {
    final _result = create();
    if (earliest != null) {
      _result.earliest = earliest;
    }
    if (latest != null) {
      _result.latest = latest;
    }
    return _result;
  }
  factory CommitPositionRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CommitPositionRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CommitPositionRange clone() => CommitPositionRange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CommitPositionRange copyWith(void Function(CommitPositionRange) updates) => super.copyWith((message) => updates(message as CommitPositionRange)) as CommitPositionRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitPositionRange create() => CommitPositionRange._();
  CommitPositionRange createEmptyInstance() => create();
  static $pb.PbList<CommitPositionRange> createRepeated() => $pb.PbList<CommitPositionRange>();
  @$core.pragma('dart2js:noInline')
  static CommitPositionRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitPositionRange>(create);
  static CommitPositionRange? _defaultInstance;

  @$pb.TagNumber(1)
  CommitPosition get earliest => $_getN(0);
  @$pb.TagNumber(1)
  set earliest(CommitPosition v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasEarliest() => $_has(0);
  @$pb.TagNumber(1)
  void clearEarliest() => clearField(1);
  @$pb.TagNumber(1)
  CommitPosition ensureEarliest() => $_ensure(0);

  @$pb.TagNumber(2)
  CommitPosition get latest => $_getN(1);
  @$pb.TagNumber(2)
  set latest(CommitPosition v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatest() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatest() => clearField(2);
  @$pb.TagNumber(2)
  CommitPosition ensureLatest() => $_ensure(1);
}

class TimeRange extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'TimeRange', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'earliest', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'latest', subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false
  ;

  TimeRange._() : super();
  factory TimeRange({
    $0.Timestamp? earliest,
    $0.Timestamp? latest,
  }) {
    final _result = create();
    if (earliest != null) {
      _result.earliest = earliest;
    }
    if (latest != null) {
      _result.latest = latest;
    }
    return _result;
  }
  factory TimeRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TimeRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TimeRange clone() => TimeRange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TimeRange copyWith(void Function(TimeRange) updates) => super.copyWith((message) => updates(message as TimeRange)) as TimeRange; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static TimeRange create() => TimeRange._();
  TimeRange createEmptyInstance() => create();
  static $pb.PbList<TimeRange> createRepeated() => $pb.PbList<TimeRange>();
  @$core.pragma('dart2js:noInline')
  static TimeRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeRange>(create);
  static TimeRange? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Timestamp get earliest => $_getN(0);
  @$pb.TagNumber(1)
  set earliest($0.Timestamp v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasEarliest() => $_has(0);
  @$pb.TagNumber(1)
  void clearEarliest() => clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureEarliest() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Timestamp get latest => $_getN(1);
  @$pb.TagNumber(2)
  set latest($0.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasLatest() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatest() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureLatest() => $_ensure(1);
}

