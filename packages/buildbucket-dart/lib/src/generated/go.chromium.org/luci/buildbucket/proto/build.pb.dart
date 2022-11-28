///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'builder_common.pb.dart' as $0;
import '../../../../google/protobuf/timestamp.pb.dart' as $1;
import 'step.pb.dart' as $2;
import 'common.pb.dart' as $3;
import '../../../../google/protobuf/duration.pb.dart' as $4;
import '../../../../google/protobuf/struct.pb.dart' as $5;
import 'task.pb.dart' as $6;

import 'common.pbenum.dart' as $3;
import 'build.pbenum.dart';

export 'build.pbenum.dart';

class Build_Input extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Build.Input', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOM<$3.GitilesCommit>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.GerritChange>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gerritChanges', $pb.PbFieldType.PM, subBuilder: $3.GerritChange.create)
    ..aOB(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'experimental')
    ..pPS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'experiments')
    ..hasRequiredFields = false
  ;

  Build_Input._() : super();
  factory Build_Input({
    $5.Struct? properties,
    $3.GitilesCommit? gitilesCommit,
    $core.Iterable<$3.GerritChange>? gerritChanges,
    $core.bool? experimental,
    $core.Iterable<$core.String>? experiments,
  }) {
    final _result = create();
    if (properties != null) {
      _result.properties = properties;
    }
    if (gitilesCommit != null) {
      _result.gitilesCommit = gitilesCommit;
    }
    if (gerritChanges != null) {
      _result.gerritChanges.addAll(gerritChanges);
    }
    if (experimental != null) {
      _result.experimental = experimental;
    }
    if (experiments != null) {
      _result.experiments.addAll(experiments);
    }
    return _result;
  }
  factory Build_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Build_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Build_Input clone() => Build_Input()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Build_Input copyWith(void Function(Build_Input) updates) => super.copyWith((message) => updates(message as Build_Input)) as Build_Input; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Build_Input create() => Build_Input._();
  Build_Input createEmptyInstance() => create();
  static $pb.PbList<Build_Input> createRepeated() => $pb.PbList<Build_Input>();
  @$core.pragma('dart2js:noInline')
  static Build_Input getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_Input>(create);
  static Build_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $5.Struct get properties => $_getN(0);
  @$pb.TagNumber(1)
  set properties($5.Struct v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  @$pb.TagNumber(2)
  $3.GitilesCommit get gitilesCommit => $_getN(1);
  @$pb.TagNumber(2)
  set gitilesCommit($3.GitilesCommit v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGitilesCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearGitilesCommit() => clearField(2);
  @$pb.TagNumber(2)
  $3.GitilesCommit ensureGitilesCommit() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$3.GerritChange> get gerritChanges => $_getList(2);

  @$pb.TagNumber(5)
  $core.bool get experimental => $_getBF(3);
  @$pb.TagNumber(5)
  set experimental($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasExperimental() => $_has(3);
  @$pb.TagNumber(5)
  void clearExperimental() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.String> get experiments => $_getList(4);
}

class Build_Output extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Build.Output', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOM<$3.GitilesCommit>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.Log>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logs', $pb.PbFieldType.PM, subBuilder: $3.Log.create)
    ..hasRequiredFields = false
  ;

  Build_Output._() : super();
  factory Build_Output({
    $5.Struct? properties,
    $3.GitilesCommit? gitilesCommit,
    $core.Iterable<$3.Log>? logs,
  }) {
    final _result = create();
    if (properties != null) {
      _result.properties = properties;
    }
    if (gitilesCommit != null) {
      _result.gitilesCommit = gitilesCommit;
    }
    if (logs != null) {
      _result.logs.addAll(logs);
    }
    return _result;
  }
  factory Build_Output.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Build_Output.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Build_Output clone() => Build_Output()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Build_Output copyWith(void Function(Build_Output) updates) => super.copyWith((message) => updates(message as Build_Output)) as Build_Output; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Build_Output create() => Build_Output._();
  Build_Output createEmptyInstance() => create();
  static $pb.PbList<Build_Output> createRepeated() => $pb.PbList<Build_Output>();
  @$core.pragma('dart2js:noInline')
  static Build_Output getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_Output>(create);
  static Build_Output? _defaultInstance;

  @$pb.TagNumber(1)
  $5.Struct get properties => $_getN(0);
  @$pb.TagNumber(1)
  set properties($5.Struct v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  @$pb.TagNumber(3)
  $3.GitilesCommit get gitilesCommit => $_getN(1);
  @$pb.TagNumber(3)
  set gitilesCommit($3.GitilesCommit v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGitilesCommit() => $_has(1);
  @$pb.TagNumber(3)
  void clearGitilesCommit() => clearField(3);
  @$pb.TagNumber(3)
  $3.GitilesCommit ensureGitilesCommit() => $_ensure(1);

  @$pb.TagNumber(5)
  $core.List<$3.Log> get logs => $_getList(2);
}

class Build extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Build', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id')
    ..aOM<$0.BuilderID>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'builder', subBuilder: $0.BuilderID.create)
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'number', $pb.PbFieldType.O3)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createdBy')
    ..aOM<$1.Timestamp>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'createTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'updateTime', subBuilder: $1.Timestamp.create)
    ..e<$3.Status>(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<Build_Input>(15, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'input', subBuilder: Build_Input.create)
    ..aOM<Build_Output>(16, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'output', subBuilder: Build_Output.create)
    ..pc<$2.Step>(17, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'steps', $pb.PbFieldType.PM, subBuilder: $2.Step.create)
    ..aOM<BuildInfra>(18, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'infra', subBuilder: BuildInfra.create)
    ..pc<$3.StringPair>(19, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..aOS(20, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'summaryMarkdown')
    ..e<$3.Trinary>(21, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'critical', $pb.PbFieldType.OE, defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<$3.StatusDetails>(22, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(23, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'canceledBy')
    ..aOM<$3.Executable>(24, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exe', subBuilder: $3.Executable.create)
    ..aOB(25, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'canary')
    ..aOM<$4.Duration>(26, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'schedulingTimeout', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(27, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'executionTimeout', subBuilder: $4.Duration.create)
    ..aOB(28, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'waitForCapacity')
    ..aOM<$4.Duration>(29, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gracePeriod', subBuilder: $4.Duration.create)
    ..aOB(30, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'canOutliveParent')
    ..p<$fixnum.Int64>(31, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'ancestorIds', $pb.PbFieldType.K6)
    ..aOM<$1.Timestamp>(32, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cancelTime', subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false
  ;

  Build._() : super();
  factory Build({
    $fixnum.Int64? id,
    $0.BuilderID? builder,
    $core.int? number,
    $core.String? createdBy,
    $1.Timestamp? createTime,
    $1.Timestamp? startTime,
    $1.Timestamp? endTime,
    $1.Timestamp? updateTime,
    $3.Status? status,
    Build_Input? input,
    Build_Output? output,
    $core.Iterable<$2.Step>? steps,
    BuildInfra? infra,
    $core.Iterable<$3.StringPair>? tags,
    $core.String? summaryMarkdown,
    $3.Trinary? critical,
    $3.StatusDetails? statusDetails,
    $core.String? canceledBy,
    $3.Executable? exe,
    $core.bool? canary,
    $4.Duration? schedulingTimeout,
    $4.Duration? executionTimeout,
    $core.bool? waitForCapacity,
    $4.Duration? gracePeriod,
    $core.bool? canOutliveParent,
    $core.Iterable<$fixnum.Int64>? ancestorIds,
    $1.Timestamp? cancelTime,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (builder != null) {
      _result.builder = builder;
    }
    if (number != null) {
      _result.number = number;
    }
    if (createdBy != null) {
      _result.createdBy = createdBy;
    }
    if (createTime != null) {
      _result.createTime = createTime;
    }
    if (startTime != null) {
      _result.startTime = startTime;
    }
    if (endTime != null) {
      _result.endTime = endTime;
    }
    if (updateTime != null) {
      _result.updateTime = updateTime;
    }
    if (status != null) {
      _result.status = status;
    }
    if (input != null) {
      _result.input = input;
    }
    if (output != null) {
      _result.output = output;
    }
    if (steps != null) {
      _result.steps.addAll(steps);
    }
    if (infra != null) {
      _result.infra = infra;
    }
    if (tags != null) {
      _result.tags.addAll(tags);
    }
    if (summaryMarkdown != null) {
      _result.summaryMarkdown = summaryMarkdown;
    }
    if (critical != null) {
      _result.critical = critical;
    }
    if (statusDetails != null) {
      _result.statusDetails = statusDetails;
    }
    if (canceledBy != null) {
      _result.canceledBy = canceledBy;
    }
    if (exe != null) {
      _result.exe = exe;
    }
    if (canary != null) {
      _result.canary = canary;
    }
    if (schedulingTimeout != null) {
      _result.schedulingTimeout = schedulingTimeout;
    }
    if (executionTimeout != null) {
      _result.executionTimeout = executionTimeout;
    }
    if (waitForCapacity != null) {
      _result.waitForCapacity = waitForCapacity;
    }
    if (gracePeriod != null) {
      _result.gracePeriod = gracePeriod;
    }
    if (canOutliveParent != null) {
      _result.canOutliveParent = canOutliveParent;
    }
    if (ancestorIds != null) {
      _result.ancestorIds.addAll(ancestorIds);
    }
    if (cancelTime != null) {
      _result.cancelTime = cancelTime;
    }
    return _result;
  }
  factory Build.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Build.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Build clone() => Build()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Build copyWith(void Function(Build) updates) => super.copyWith((message) => updates(message as Build)) as Build; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Build create() => Build._();
  Build createEmptyInstance() => create();
  static $pb.PbList<Build> createRepeated() => $pb.PbList<Build>();
  @$core.pragma('dart2js:noInline')
  static Build getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build>(create);
  static Build? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $0.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($0.BuilderID v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $0.BuilderID ensureBuilder() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get number => $_getIZ(2);
  @$pb.TagNumber(3)
  set number($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get createdBy => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdBy($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedBy() => clearField(4);

  @$pb.TagNumber(6)
  $1.Timestamp get createTime => $_getN(4);
  @$pb.TagNumber(6)
  set createTime($1.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(4);
  @$pb.TagNumber(6)
  void clearCreateTime() => clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreateTime() => $_ensure(4);

  @$pb.TagNumber(7)
  $1.Timestamp get startTime => $_getN(5);
  @$pb.TagNumber(7)
  set startTime($1.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasStartTime() => $_has(5);
  @$pb.TagNumber(7)
  void clearStartTime() => clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureStartTime() => $_ensure(5);

  @$pb.TagNumber(8)
  $1.Timestamp get endTime => $_getN(6);
  @$pb.TagNumber(8)
  set endTime($1.Timestamp v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasEndTime() => $_has(6);
  @$pb.TagNumber(8)
  void clearEndTime() => clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureEndTime() => $_ensure(6);

  @$pb.TagNumber(9)
  $1.Timestamp get updateTime => $_getN(7);
  @$pb.TagNumber(9)
  set updateTime($1.Timestamp v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasUpdateTime() => $_has(7);
  @$pb.TagNumber(9)
  void clearUpdateTime() => clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureUpdateTime() => $_ensure(7);

  @$pb.TagNumber(12)
  $3.Status get status => $_getN(8);
  @$pb.TagNumber(12)
  set status($3.Status v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(12)
  void clearStatus() => clearField(12);

  @$pb.TagNumber(15)
  Build_Input get input => $_getN(9);
  @$pb.TagNumber(15)
  set input(Build_Input v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasInput() => $_has(9);
  @$pb.TagNumber(15)
  void clearInput() => clearField(15);
  @$pb.TagNumber(15)
  Build_Input ensureInput() => $_ensure(9);

  @$pb.TagNumber(16)
  Build_Output get output => $_getN(10);
  @$pb.TagNumber(16)
  set output(Build_Output v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasOutput() => $_has(10);
  @$pb.TagNumber(16)
  void clearOutput() => clearField(16);
  @$pb.TagNumber(16)
  Build_Output ensureOutput() => $_ensure(10);

  @$pb.TagNumber(17)
  $core.List<$2.Step> get steps => $_getList(11);

  @$pb.TagNumber(18)
  BuildInfra get infra => $_getN(12);
  @$pb.TagNumber(18)
  set infra(BuildInfra v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasInfra() => $_has(12);
  @$pb.TagNumber(18)
  void clearInfra() => clearField(18);
  @$pb.TagNumber(18)
  BuildInfra ensureInfra() => $_ensure(12);

  @$pb.TagNumber(19)
  $core.List<$3.StringPair> get tags => $_getList(13);

  @$pb.TagNumber(20)
  $core.String get summaryMarkdown => $_getSZ(14);
  @$pb.TagNumber(20)
  set summaryMarkdown($core.String v) { $_setString(14, v); }
  @$pb.TagNumber(20)
  $core.bool hasSummaryMarkdown() => $_has(14);
  @$pb.TagNumber(20)
  void clearSummaryMarkdown() => clearField(20);

  @$pb.TagNumber(21)
  $3.Trinary get critical => $_getN(15);
  @$pb.TagNumber(21)
  set critical($3.Trinary v) { setField(21, v); }
  @$pb.TagNumber(21)
  $core.bool hasCritical() => $_has(15);
  @$pb.TagNumber(21)
  void clearCritical() => clearField(21);

  @$pb.TagNumber(22)
  $3.StatusDetails get statusDetails => $_getN(16);
  @$pb.TagNumber(22)
  set statusDetails($3.StatusDetails v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasStatusDetails() => $_has(16);
  @$pb.TagNumber(22)
  void clearStatusDetails() => clearField(22);
  @$pb.TagNumber(22)
  $3.StatusDetails ensureStatusDetails() => $_ensure(16);

  @$pb.TagNumber(23)
  $core.String get canceledBy => $_getSZ(17);
  @$pb.TagNumber(23)
  set canceledBy($core.String v) { $_setString(17, v); }
  @$pb.TagNumber(23)
  $core.bool hasCanceledBy() => $_has(17);
  @$pb.TagNumber(23)
  void clearCanceledBy() => clearField(23);

  @$pb.TagNumber(24)
  $3.Executable get exe => $_getN(18);
  @$pb.TagNumber(24)
  set exe($3.Executable v) { setField(24, v); }
  @$pb.TagNumber(24)
  $core.bool hasExe() => $_has(18);
  @$pb.TagNumber(24)
  void clearExe() => clearField(24);
  @$pb.TagNumber(24)
  $3.Executable ensureExe() => $_ensure(18);

  @$pb.TagNumber(25)
  $core.bool get canary => $_getBF(19);
  @$pb.TagNumber(25)
  set canary($core.bool v) { $_setBool(19, v); }
  @$pb.TagNumber(25)
  $core.bool hasCanary() => $_has(19);
  @$pb.TagNumber(25)
  void clearCanary() => clearField(25);

  @$pb.TagNumber(26)
  $4.Duration get schedulingTimeout => $_getN(20);
  @$pb.TagNumber(26)
  set schedulingTimeout($4.Duration v) { setField(26, v); }
  @$pb.TagNumber(26)
  $core.bool hasSchedulingTimeout() => $_has(20);
  @$pb.TagNumber(26)
  void clearSchedulingTimeout() => clearField(26);
  @$pb.TagNumber(26)
  $4.Duration ensureSchedulingTimeout() => $_ensure(20);

  @$pb.TagNumber(27)
  $4.Duration get executionTimeout => $_getN(21);
  @$pb.TagNumber(27)
  set executionTimeout($4.Duration v) { setField(27, v); }
  @$pb.TagNumber(27)
  $core.bool hasExecutionTimeout() => $_has(21);
  @$pb.TagNumber(27)
  void clearExecutionTimeout() => clearField(27);
  @$pb.TagNumber(27)
  $4.Duration ensureExecutionTimeout() => $_ensure(21);

  @$pb.TagNumber(28)
  $core.bool get waitForCapacity => $_getBF(22);
  @$pb.TagNumber(28)
  set waitForCapacity($core.bool v) { $_setBool(22, v); }
  @$pb.TagNumber(28)
  $core.bool hasWaitForCapacity() => $_has(22);
  @$pb.TagNumber(28)
  void clearWaitForCapacity() => clearField(28);

  @$pb.TagNumber(29)
  $4.Duration get gracePeriod => $_getN(23);
  @$pb.TagNumber(29)
  set gracePeriod($4.Duration v) { setField(29, v); }
  @$pb.TagNumber(29)
  $core.bool hasGracePeriod() => $_has(23);
  @$pb.TagNumber(29)
  void clearGracePeriod() => clearField(29);
  @$pb.TagNumber(29)
  $4.Duration ensureGracePeriod() => $_ensure(23);

  @$pb.TagNumber(30)
  $core.bool get canOutliveParent => $_getBF(24);
  @$pb.TagNumber(30)
  set canOutliveParent($core.bool v) { $_setBool(24, v); }
  @$pb.TagNumber(30)
  $core.bool hasCanOutliveParent() => $_has(24);
  @$pb.TagNumber(30)
  void clearCanOutliveParent() => clearField(30);

  @$pb.TagNumber(31)
  $core.List<$fixnum.Int64> get ancestorIds => $_getList(25);

  @$pb.TagNumber(32)
  $1.Timestamp get cancelTime => $_getN(26);
  @$pb.TagNumber(32)
  set cancelTime($1.Timestamp v) { setField(32, v); }
  @$pb.TagNumber(32)
  $core.bool hasCancelTime() => $_has(26);
  @$pb.TagNumber(32)
  void clearCancelTime() => clearField(32);
  @$pb.TagNumber(32)
  $1.Timestamp ensureCancelTime() => $_ensure(26);
}

class InputDataRef_CAS_Digest extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputDataRef.CAS.Digest', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hash')
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'sizeBytes')
    ..hasRequiredFields = false
  ;

  InputDataRef_CAS_Digest._() : super();
  factory InputDataRef_CAS_Digest({
    $core.String? hash,
    $fixnum.Int64? sizeBytes,
  }) {
    final _result = create();
    if (hash != null) {
      _result.hash = hash;
    }
    if (sizeBytes != null) {
      _result.sizeBytes = sizeBytes;
    }
    return _result;
  }
  factory InputDataRef_CAS_Digest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS_Digest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputDataRef_CAS_Digest clone() => InputDataRef_CAS_Digest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputDataRef_CAS_Digest copyWith(void Function(InputDataRef_CAS_Digest) updates) => super.copyWith((message) => updates(message as InputDataRef_CAS_Digest)) as InputDataRef_CAS_Digest; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest create() => InputDataRef_CAS_Digest._();
  InputDataRef_CAS_Digest createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS_Digest> createRepeated() => $pb.PbList<InputDataRef_CAS_Digest>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS_Digest>(create);
  static InputDataRef_CAS_Digest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => clearField(2);
}

class InputDataRef_CAS extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputDataRef.CAS', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'casInstance')
    ..aOM<InputDataRef_CAS_Digest>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'digest', subBuilder: InputDataRef_CAS_Digest.create)
    ..hasRequiredFields = false
  ;

  InputDataRef_CAS._() : super();
  factory InputDataRef_CAS({
    $core.String? casInstance,
    InputDataRef_CAS_Digest? digest,
  }) {
    final _result = create();
    if (casInstance != null) {
      _result.casInstance = casInstance;
    }
    if (digest != null) {
      _result.digest = digest;
    }
    return _result;
  }
  factory InputDataRef_CAS.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputDataRef_CAS clone() => InputDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputDataRef_CAS copyWith(void Function(InputDataRef_CAS) updates) => super.copyWith((message) => updates(message as InputDataRef_CAS)) as InputDataRef_CAS; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS create() => InputDataRef_CAS._();
  InputDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS> createRepeated() => $pb.PbList<InputDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS>(create);
  static InputDataRef_CAS? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get casInstance => $_getSZ(0);
  @$pb.TagNumber(1)
  set casInstance($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearCasInstance() => clearField(1);

  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest get digest => $_getN(1);
  @$pb.TagNumber(2)
  set digest(InputDataRef_CAS_Digest v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasDigest() => $_has(1);
  @$pb.TagNumber(2)
  void clearDigest() => clearField(2);
  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest ensureDigest() => $_ensure(1);
}

class InputDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputDataRef.CIPD.PkgSpec', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'package')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..hasRequiredFields = false
  ;

  InputDataRef_CIPD_PkgSpec._() : super();
  factory InputDataRef_CIPD_PkgSpec({
    $core.String? package,
    $core.String? version,
  }) {
    final _result = create();
    if (package != null) {
      _result.package = package;
    }
    if (version != null) {
      _result.version = version;
    }
    return _result;
  }
  factory InputDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD_PkgSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec clone() => InputDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec copyWith(void Function(InputDataRef_CIPD_PkgSpec) updates) => super.copyWith((message) => updates(message as InputDataRef_CIPD_PkgSpec)) as InputDataRef_CIPD_PkgSpec; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec create() => InputDataRef_CIPD_PkgSpec._();
  InputDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<InputDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD_PkgSpec>(create);
  static InputDataRef_CIPD_PkgSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);
}

class InputDataRef_CIPD extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputDataRef.CIPD', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'server')
    ..pc<InputDataRef_CIPD_PkgSpec>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'specs', $pb.PbFieldType.PM, subBuilder: InputDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false
  ;

  InputDataRef_CIPD._() : super();
  factory InputDataRef_CIPD({
    $core.String? server,
    $core.Iterable<InputDataRef_CIPD_PkgSpec>? specs,
  }) {
    final _result = create();
    if (server != null) {
      _result.server = server;
    }
    if (specs != null) {
      _result.specs.addAll(specs);
    }
    return _result;
  }
  factory InputDataRef_CIPD.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputDataRef_CIPD clone() => InputDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputDataRef_CIPD copyWith(void Function(InputDataRef_CIPD) updates) => super.copyWith((message) => updates(message as InputDataRef_CIPD)) as InputDataRef_CIPD; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD create() => InputDataRef_CIPD._();
  InputDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD> createRepeated() => $pb.PbList<InputDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD>(create);
  static InputDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get server => $_getSZ(0);
  @$pb.TagNumber(1)
  set server($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<InputDataRef_CIPD_PkgSpec> get specs => $_getList(1);
}

enum InputDataRef_DataType {
  cas, 
  cipd, 
  notSet
}

class InputDataRef extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, InputDataRef_DataType> _InputDataRef_DataTypeByTag = {
    1 : InputDataRef_DataType.cas,
    2 : InputDataRef_DataType.cipd,
    0 : InputDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'InputDataRef', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InputDataRef_CAS>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cas', subBuilder: InputDataRef_CAS.create)
    ..aOM<InputDataRef_CIPD>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipd', subBuilder: InputDataRef_CIPD.create)
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'onPath')
    ..hasRequiredFields = false
  ;

  InputDataRef._() : super();
  factory InputDataRef({
    InputDataRef_CAS? cas,
    InputDataRef_CIPD? cipd,
    $core.Iterable<$core.String>? onPath,
  }) {
    final _result = create();
    if (cas != null) {
      _result.cas = cas;
    }
    if (cipd != null) {
      _result.cipd = cipd;
    }
    if (onPath != null) {
      _result.onPath.addAll(onPath);
    }
    return _result;
  }
  factory InputDataRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory InputDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  InputDataRef clone() => InputDataRef()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  InputDataRef copyWith(void Function(InputDataRef) updates) => super.copyWith((message) => updates(message as InputDataRef)) as InputDataRef; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static InputDataRef create() => InputDataRef._();
  InputDataRef createEmptyInstance() => create();
  static $pb.PbList<InputDataRef> createRepeated() => $pb.PbList<InputDataRef>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef>(create);
  static InputDataRef? _defaultInstance;

  InputDataRef_DataType whichDataType() => _InputDataRef_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InputDataRef_CAS get cas => $_getN(0);
  @$pb.TagNumber(1)
  set cas(InputDataRef_CAS v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  InputDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  InputDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(InputDataRef_CIPD v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCipd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipd() => clearField(2);
  @$pb.TagNumber(2)
  InputDataRef_CIPD ensureCipd() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get onPath => $_getList(2);
}

class ResolvedDataRef_Timing extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResolvedDataRef.Timing', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$4.Duration>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fetchDuration', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'installDuration', subBuilder: $4.Duration.create)
    ..hasRequiredFields = false
  ;

  ResolvedDataRef_Timing._() : super();
  factory ResolvedDataRef_Timing({
    $4.Duration? fetchDuration,
    $4.Duration? installDuration,
  }) {
    final _result = create();
    if (fetchDuration != null) {
      _result.fetchDuration = fetchDuration;
    }
    if (installDuration != null) {
      _result.installDuration = installDuration;
    }
    return _result;
  }
  factory ResolvedDataRef_Timing.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_Timing.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_Timing clone() => ResolvedDataRef_Timing()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_Timing copyWith(void Function(ResolvedDataRef_Timing) updates) => super.copyWith((message) => updates(message as ResolvedDataRef_Timing)) as ResolvedDataRef_Timing; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing create() => ResolvedDataRef_Timing._();
  ResolvedDataRef_Timing createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_Timing> createRepeated() => $pb.PbList<ResolvedDataRef_Timing>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_Timing>(create);
  static ResolvedDataRef_Timing? _defaultInstance;

  @$pb.TagNumber(1)
  $4.Duration get fetchDuration => $_getN(0);
  @$pb.TagNumber(1)
  set fetchDuration($4.Duration v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasFetchDuration() => $_has(0);
  @$pb.TagNumber(1)
  void clearFetchDuration() => clearField(1);
  @$pb.TagNumber(1)
  $4.Duration ensureFetchDuration() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.Duration get installDuration => $_getN(1);
  @$pb.TagNumber(2)
  set installDuration($4.Duration v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasInstallDuration() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstallDuration() => clearField(2);
  @$pb.TagNumber(2)
  $4.Duration ensureInstallDuration() => $_ensure(1);
}

class ResolvedDataRef_CAS extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResolvedDataRef.CAS', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<ResolvedDataRef_Timing>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false
  ;

  ResolvedDataRef_CAS._() : super();
  factory ResolvedDataRef_CAS({
    ResolvedDataRef_Timing? timing,
  }) {
    final _result = create();
    if (timing != null) {
      _result.timing = timing;
    }
    return _result;
  }
  factory ResolvedDataRef_CAS.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CAS clone() => ResolvedDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CAS copyWith(void Function(ResolvedDataRef_CAS) updates) => super.copyWith((message) => updates(message as ResolvedDataRef_CAS)) as ResolvedDataRef_CAS; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS create() => ResolvedDataRef_CAS._();
  ResolvedDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CAS> createRepeated() => $pb.PbList<ResolvedDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CAS>(create);
  static ResolvedDataRef_CAS? _defaultInstance;

  @$pb.TagNumber(1)
  ResolvedDataRef_Timing get timing => $_getN(0);
  @$pb.TagNumber(1)
  set timing(ResolvedDataRef_Timing v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTiming() => $_has(0);
  @$pb.TagNumber(1)
  void clearTiming() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(0);
}

class ResolvedDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResolvedDataRef.CIPD.PkgSpec', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'skipped')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'package')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..e<$3.Trinary>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'wasCached', $pb.PbFieldType.OE, defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<ResolvedDataRef_Timing>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false
  ;

  ResolvedDataRef_CIPD_PkgSpec._() : super();
  factory ResolvedDataRef_CIPD_PkgSpec({
    $core.bool? skipped,
    $core.String? package,
    $core.String? version,
    $3.Trinary? wasCached,
    ResolvedDataRef_Timing? timing,
  }) {
    final _result = create();
    if (skipped != null) {
      _result.skipped = skipped;
    }
    if (package != null) {
      _result.package = package;
    }
    if (version != null) {
      _result.version = version;
    }
    if (wasCached != null) {
      _result.wasCached = wasCached;
    }
    if (timing != null) {
      _result.timing = timing;
    }
    return _result;
  }
  factory ResolvedDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD_PkgSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec clone() => ResolvedDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec copyWith(void Function(ResolvedDataRef_CIPD_PkgSpec) updates) => super.copyWith((message) => updates(message as ResolvedDataRef_CIPD_PkgSpec)) as ResolvedDataRef_CIPD_PkgSpec; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec create() => ResolvedDataRef_CIPD_PkgSpec._();
  ResolvedDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD_PkgSpec>(create);
  static ResolvedDataRef_CIPD_PkgSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get skipped => $_getBF(0);
  @$pb.TagNumber(1)
  set skipped($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSkipped() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkipped() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get package => $_getSZ(1);
  @$pb.TagNumber(2)
  set package($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackage() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);

  @$pb.TagNumber(4)
  $3.Trinary get wasCached => $_getN(3);
  @$pb.TagNumber(4)
  set wasCached($3.Trinary v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasWasCached() => $_has(3);
  @$pb.TagNumber(4)
  void clearWasCached() => clearField(4);

  @$pb.TagNumber(5)
  ResolvedDataRef_Timing get timing => $_getN(4);
  @$pb.TagNumber(5)
  set timing(ResolvedDataRef_Timing v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTiming() => $_has(4);
  @$pb.TagNumber(5)
  void clearTiming() => clearField(5);
  @$pb.TagNumber(5)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(4);
}

class ResolvedDataRef_CIPD extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResolvedDataRef.CIPD', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<ResolvedDataRef_CIPD_PkgSpec>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'specs', $pb.PbFieldType.PM, subBuilder: ResolvedDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false
  ;

  ResolvedDataRef_CIPD._() : super();
  factory ResolvedDataRef_CIPD({
    $core.Iterable<ResolvedDataRef_CIPD_PkgSpec>? specs,
  }) {
    final _result = create();
    if (specs != null) {
      _result.specs.addAll(specs);
    }
    return _result;
  }
  factory ResolvedDataRef_CIPD.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CIPD clone() => ResolvedDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResolvedDataRef_CIPD copyWith(void Function(ResolvedDataRef_CIPD) updates) => super.copyWith((message) => updates(message as ResolvedDataRef_CIPD)) as ResolvedDataRef_CIPD; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD create() => ResolvedDataRef_CIPD._();
  ResolvedDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD>(create);
  static ResolvedDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<ResolvedDataRef_CIPD_PkgSpec> get specs => $_getList(0);
}

enum ResolvedDataRef_DataType {
  cas, 
  cipd, 
  notSet
}

class ResolvedDataRef extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, ResolvedDataRef_DataType> _ResolvedDataRef_DataTypeByTag = {
    1 : ResolvedDataRef_DataType.cas,
    2 : ResolvedDataRef_DataType.cipd,
    0 : ResolvedDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'ResolvedDataRef', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ResolvedDataRef_CAS>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cas', subBuilder: ResolvedDataRef_CAS.create)
    ..aOM<ResolvedDataRef_CIPD>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipd', subBuilder: ResolvedDataRef_CIPD.create)
    ..hasRequiredFields = false
  ;

  ResolvedDataRef._() : super();
  factory ResolvedDataRef({
    ResolvedDataRef_CAS? cas,
    ResolvedDataRef_CIPD? cipd,
  }) {
    final _result = create();
    if (cas != null) {
      _result.cas = cas;
    }
    if (cipd != null) {
      _result.cipd = cipd;
    }
    return _result;
  }
  factory ResolvedDataRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ResolvedDataRef clone() => ResolvedDataRef()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ResolvedDataRef copyWith(void Function(ResolvedDataRef) updates) => super.copyWith((message) => updates(message as ResolvedDataRef)) as ResolvedDataRef; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef create() => ResolvedDataRef._();
  ResolvedDataRef createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef> createRepeated() => $pb.PbList<ResolvedDataRef>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef>(create);
  static ResolvedDataRef? _defaultInstance;

  ResolvedDataRef_DataType whichDataType() => _ResolvedDataRef_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ResolvedDataRef_CAS get cas => $_getN(0);
  @$pb.TagNumber(1)
  set cas(ResolvedDataRef_CAS v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(ResolvedDataRef_CIPD v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCipd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipd() => clearField(2);
  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD ensureCipd() => $_ensure(1);
}

class BuildInfra_Buildbucket_Agent_Source_CIPD extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket.Agent.Source.CIPD', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'package')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'server')
    ..m<$core.String, $core.String>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resolvedInstances', entryClassName: 'BuildInfra.Buildbucket.Agent.Source.CIPD.ResolvedInstancesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket_Agent_Source_CIPD._() : super();
  factory BuildInfra_Buildbucket_Agent_Source_CIPD({
    $core.String? package,
    $core.String? version,
    $core.String? server,
    $core.Map<$core.String, $core.String>? resolvedInstances,
  }) {
    final _result = create();
    if (package != null) {
      _result.package = package;
    }
    if (version != null) {
      _result.version = version;
    }
    if (server != null) {
      _result.server = server;
    }
    if (resolvedInstances != null) {
      _result.resolvedInstances.addAll(resolvedInstances);
    }
    return _result;
  }
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD clone() => BuildInfra_Buildbucket_Agent_Source_CIPD()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD copyWith(void Function(BuildInfra_Buildbucket_Agent_Source_CIPD) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source_CIPD)) as BuildInfra_Buildbucket_Agent_Source_CIPD; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD create() => BuildInfra_Buildbucket_Agent_Source_CIPD._();
  BuildInfra_Buildbucket_Agent_Source_CIPD createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source_CIPD>(create);
  static BuildInfra_Buildbucket_Agent_Source_CIPD? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.String> get resolvedInstances => $_getMap(3);
}

enum BuildInfra_Buildbucket_Agent_Source_DataType {
  cipd, 
  notSet
}

class BuildInfra_Buildbucket_Agent_Source extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, BuildInfra_Buildbucket_Agent_Source_DataType> _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag = {
    1 : BuildInfra_Buildbucket_Agent_Source_DataType.cipd,
    0 : BuildInfra_Buildbucket_Agent_Source_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket.Agent.Source', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<BuildInfra_Buildbucket_Agent_Source_CIPD>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipd', subBuilder: BuildInfra_Buildbucket_Agent_Source_CIPD.create)
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket_Agent_Source._() : super();
  factory BuildInfra_Buildbucket_Agent_Source({
    BuildInfra_Buildbucket_Agent_Source_CIPD? cipd,
  }) {
    final _result = create();
    if (cipd != null) {
      _result.cipd = cipd;
    }
    return _result;
  }
  factory BuildInfra_Buildbucket_Agent_Source.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source clone() => BuildInfra_Buildbucket_Agent_Source()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source copyWith(void Function(BuildInfra_Buildbucket_Agent_Source) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source)) as BuildInfra_Buildbucket_Agent_Source; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source create() => BuildInfra_Buildbucket_Agent_Source._();
  BuildInfra_Buildbucket_Agent_Source createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent_Source>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source>(create);
  static BuildInfra_Buildbucket_Agent_Source? _defaultInstance;

  BuildInfra_Buildbucket_Agent_Source_DataType whichDataType() => _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD get cipd => $_getN(0);
  @$pb.TagNumber(1)
  set cipd(BuildInfra_Buildbucket_Agent_Source_CIPD v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCipd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipd() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD ensureCipd() => $_ensure(0);
}

class BuildInfra_Buildbucket_Agent_Input extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket.Agent.Input', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, InputDataRef>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'data', entryClassName: 'BuildInfra.Buildbucket.Agent.Input.DataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: InputDataRef.create, packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket_Agent_Input._() : super();
  factory BuildInfra_Buildbucket_Agent_Input({
    $core.Map<$core.String, InputDataRef>? data,
  }) {
    final _result = create();
    if (data != null) {
      _result.data.addAll(data);
    }
    return _result;
  }
  factory BuildInfra_Buildbucket_Agent_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input clone() => BuildInfra_Buildbucket_Agent_Input()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input copyWith(void Function(BuildInfra_Buildbucket_Agent_Input) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Input)) as BuildInfra_Buildbucket_Agent_Input; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input create() => BuildInfra_Buildbucket_Agent_Input._();
  BuildInfra_Buildbucket_Agent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Input> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Input>(create);
  static BuildInfra_Buildbucket_Agent_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, InputDataRef> get data => $_getMap(0);
}

class BuildInfra_Buildbucket_Agent_Output extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket.Agent.Output', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, ResolvedDataRef>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resolvedData', entryClassName: 'BuildInfra.Buildbucket.Agent.Output.ResolvedDataEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: ResolvedDataRef.create, packageName: const $pb.PackageName('buildbucket.v2'))
    ..e<$3.Status>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<$3.StatusDetails>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'summaryHtml')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'agentPlatform')
    ..aOM<$4.Duration>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'totalDuration', subBuilder: $4.Duration.create)
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket_Agent_Output._() : super();
  factory BuildInfra_Buildbucket_Agent_Output({
    $core.Map<$core.String, ResolvedDataRef>? resolvedData,
    $3.Status? status,
    $3.StatusDetails? statusDetails,
    $core.String? summaryHtml,
    $core.String? agentPlatform,
    $4.Duration? totalDuration,
  }) {
    final _result = create();
    if (resolvedData != null) {
      _result.resolvedData.addAll(resolvedData);
    }
    if (status != null) {
      _result.status = status;
    }
    if (statusDetails != null) {
      _result.statusDetails = statusDetails;
    }
    if (summaryHtml != null) {
      _result.summaryHtml = summaryHtml;
    }
    if (agentPlatform != null) {
      _result.agentPlatform = agentPlatform;
    }
    if (totalDuration != null) {
      _result.totalDuration = totalDuration;
    }
    return _result;
  }
  factory BuildInfra_Buildbucket_Agent_Output.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Output.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output clone() => BuildInfra_Buildbucket_Agent_Output()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output copyWith(void Function(BuildInfra_Buildbucket_Agent_Output) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Output)) as BuildInfra_Buildbucket_Agent_Output; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output create() => BuildInfra_Buildbucket_Agent_Output._();
  BuildInfra_Buildbucket_Agent_Output createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Output> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent_Output>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Output>(create);
  static BuildInfra_Buildbucket_Agent_Output? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, ResolvedDataRef> get resolvedData => $_getMap(0);

  @$pb.TagNumber(2)
  $3.Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($3.Status v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $3.StatusDetails get statusDetails => $_getN(2);
  @$pb.TagNumber(3)
  set statusDetails($3.StatusDetails v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusDetails() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusDetails() => clearField(3);
  @$pb.TagNumber(3)
  $3.StatusDetails ensureStatusDetails() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get summaryHtml => $_getSZ(3);
  @$pb.TagNumber(4)
  set summaryHtml($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSummaryHtml() => $_has(3);
  @$pb.TagNumber(4)
  void clearSummaryHtml() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get agentPlatform => $_getSZ(4);
  @$pb.TagNumber(5)
  set agentPlatform($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAgentPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearAgentPlatform() => clearField(5);

  @$pb.TagNumber(6)
  $4.Duration get totalDuration => $_getN(5);
  @$pb.TagNumber(6)
  set totalDuration($4.Duration v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasTotalDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalDuration() => clearField(6);
  @$pb.TagNumber(6)
  $4.Duration ensureTotalDuration() => $_ensure(5);
}

class BuildInfra_Buildbucket_Agent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket.Agent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket_Agent_Input>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'input', subBuilder: BuildInfra_Buildbucket_Agent_Input.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Output>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'output', subBuilder: BuildInfra_Buildbucket_Agent_Output.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Source>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'source', subBuilder: BuildInfra_Buildbucket_Agent_Source.create)
    ..m<$core.String, BuildInfra_Buildbucket_Agent_Purpose>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'purposes', entryClassName: 'BuildInfra.Buildbucket.Agent.PurposesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OE, valueOf: BuildInfra_Buildbucket_Agent_Purpose.valueOf, enumValues: BuildInfra_Buildbucket_Agent_Purpose.values, defaultEnumValue: BuildInfra_Buildbucket_Agent_Purpose.PURPOSE_UNSPECIFIED, packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket_Agent._() : super();
  factory BuildInfra_Buildbucket_Agent({
    BuildInfra_Buildbucket_Agent_Input? input,
    BuildInfra_Buildbucket_Agent_Output? output,
    BuildInfra_Buildbucket_Agent_Source? source,
    $core.Map<$core.String, BuildInfra_Buildbucket_Agent_Purpose>? purposes,
  }) {
    final _result = create();
    if (input != null) {
      _result.input = input;
    }
    if (output != null) {
      _result.output = output;
    }
    if (source != null) {
      _result.source = source;
    }
    if (purposes != null) {
      _result.purposes.addAll(purposes);
    }
    return _result;
  }
  factory BuildInfra_Buildbucket_Agent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent clone() => BuildInfra_Buildbucket_Agent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent copyWith(void Function(BuildInfra_Buildbucket_Agent) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent)) as BuildInfra_Buildbucket_Agent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent create() => BuildInfra_Buildbucket_Agent._();
  BuildInfra_Buildbucket_Agent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent>(create);
  static BuildInfra_Buildbucket_Agent? _defaultInstance;

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input get input => $_getN(0);
  @$pb.TagNumber(1)
  set input(BuildInfra_Buildbucket_Agent_Input v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasInput() => $_has(0);
  @$pb.TagNumber(1)
  void clearInput() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input ensureInput() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output get output => $_getN(1);
  @$pb.TagNumber(2)
  set output(BuildInfra_Buildbucket_Agent_Output v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output ensureOutput() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_Buildbucket_Agent_Source get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(BuildInfra_Buildbucket_Agent_Source v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => clearField(3);
  @$pb.TagNumber(3)
  BuildInfra_Buildbucket_Agent_Source ensureSource() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.Map<$core.String, BuildInfra_Buildbucket_Agent_Purpose> get purposes => $_getMap(3);
}

class BuildInfra_Buildbucket extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Buildbucket', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serviceConfigRevision')
    ..aOM<$5.Struct>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'requestedProperties', subBuilder: $5.Struct.create)
    ..pc<$3.RequestedDimension>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'requestedDimensions', $pb.PbFieldType.PM, subBuilder: $3.RequestedDimension.create)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hostname')
    ..m<$core.String, BuildInfra_Buildbucket_ExperimentReason>(8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'experimentReasons', entryClassName: 'BuildInfra.Buildbucket.ExperimentReasonsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OE, valueOf: BuildInfra_Buildbucket_ExperimentReason.valueOf, enumValues: BuildInfra_Buildbucket_ExperimentReason.values, defaultEnumValue: BuildInfra_Buildbucket_ExperimentReason.EXPERIMENT_REASON_UNSET, packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, ResolvedDataRef>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'agentExecutable', entryClassName: 'BuildInfra.Buildbucket.AgentExecutableEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: ResolvedDataRef.create, packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<BuildInfra_Buildbucket_Agent>(10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'agent', subBuilder: BuildInfra_Buildbucket_Agent.create)
    ..pPS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'knownPublicGerritHosts')
    ..hasRequiredFields = false
  ;

  BuildInfra_Buildbucket._() : super();
  factory BuildInfra_Buildbucket({
    $core.String? serviceConfigRevision,
    $5.Struct? requestedProperties,
    $core.Iterable<$3.RequestedDimension>? requestedDimensions,
    $core.String? hostname,
    $core.Map<$core.String, BuildInfra_Buildbucket_ExperimentReason>? experimentReasons,
  @$core.Deprecated('This field is deprecated.')
    $core.Map<$core.String, ResolvedDataRef>? agentExecutable,
    BuildInfra_Buildbucket_Agent? agent,
    $core.Iterable<$core.String>? knownPublicGerritHosts,
  }) {
    final _result = create();
    if (serviceConfigRevision != null) {
      _result.serviceConfigRevision = serviceConfigRevision;
    }
    if (requestedProperties != null) {
      _result.requestedProperties = requestedProperties;
    }
    if (requestedDimensions != null) {
      _result.requestedDimensions.addAll(requestedDimensions);
    }
    if (hostname != null) {
      _result.hostname = hostname;
    }
    if (experimentReasons != null) {
      _result.experimentReasons.addAll(experimentReasons);
    }
    if (agentExecutable != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.agentExecutable.addAll(agentExecutable);
    }
    if (agent != null) {
      _result.agent = agent;
    }
    if (knownPublicGerritHosts != null) {
      _result.knownPublicGerritHosts.addAll(knownPublicGerritHosts);
    }
    return _result;
  }
  factory BuildInfra_Buildbucket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket clone() => BuildInfra_Buildbucket()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Buildbucket copyWith(void Function(BuildInfra_Buildbucket) updates) => super.copyWith((message) => updates(message as BuildInfra_Buildbucket)) as BuildInfra_Buildbucket; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket create() => BuildInfra_Buildbucket._();
  BuildInfra_Buildbucket createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket> createRepeated() => $pb.PbList<BuildInfra_Buildbucket>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket>(create);
  static BuildInfra_Buildbucket? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get serviceConfigRevision => $_getSZ(0);
  @$pb.TagNumber(2)
  set serviceConfigRevision($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(2)
  $core.bool hasServiceConfigRevision() => $_has(0);
  @$pb.TagNumber(2)
  void clearServiceConfigRevision() => clearField(2);

  @$pb.TagNumber(5)
  $5.Struct get requestedProperties => $_getN(1);
  @$pb.TagNumber(5)
  set requestedProperties($5.Struct v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRequestedProperties() => $_has(1);
  @$pb.TagNumber(5)
  void clearRequestedProperties() => clearField(5);
  @$pb.TagNumber(5)
  $5.Struct ensureRequestedProperties() => $_ensure(1);

  @$pb.TagNumber(6)
  $core.List<$3.RequestedDimension> get requestedDimensions => $_getList(2);

  @$pb.TagNumber(7)
  $core.String get hostname => $_getSZ(3);
  @$pb.TagNumber(7)
  set hostname($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(7)
  $core.bool hasHostname() => $_has(3);
  @$pb.TagNumber(7)
  void clearHostname() => clearField(7);

  @$pb.TagNumber(8)
  $core.Map<$core.String, BuildInfra_Buildbucket_ExperimentReason> get experimentReasons => $_getMap(4);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.Map<$core.String, ResolvedDataRef> get agentExecutable => $_getMap(5);

  @$pb.TagNumber(10)
  BuildInfra_Buildbucket_Agent get agent => $_getN(6);
  @$pb.TagNumber(10)
  set agent(BuildInfra_Buildbucket_Agent v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasAgent() => $_has(6);
  @$pb.TagNumber(10)
  void clearAgent() => clearField(10);
  @$pb.TagNumber(10)
  BuildInfra_Buildbucket_Agent ensureAgent() => $_ensure(6);

  @$pb.TagNumber(11)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(7);
}

class BuildInfra_Swarming_CacheEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Swarming.CacheEntry', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..aOM<$4.Duration>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'waitForWarmCache', subBuilder: $4.Duration.create)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'envVar')
    ..hasRequiredFields = false
  ;

  BuildInfra_Swarming_CacheEntry._() : super();
  factory BuildInfra_Swarming_CacheEntry({
    $core.String? name,
    $core.String? path,
    $4.Duration? waitForWarmCache,
    $core.String? envVar,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (path != null) {
      _result.path = path;
    }
    if (waitForWarmCache != null) {
      _result.waitForWarmCache = waitForWarmCache;
    }
    if (envVar != null) {
      _result.envVar = envVar;
    }
    return _result;
  }
  factory BuildInfra_Swarming_CacheEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming_CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry clone() => BuildInfra_Swarming_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry copyWith(void Function(BuildInfra_Swarming_CacheEntry) updates) => super.copyWith((message) => updates(message as BuildInfra_Swarming_CacheEntry)) as BuildInfra_Swarming_CacheEntry; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry create() => BuildInfra_Swarming_CacheEntry._();
  BuildInfra_Swarming_CacheEntry createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming_CacheEntry> createRepeated() => $pb.PbList<BuildInfra_Swarming_CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming_CacheEntry>(create);
  static BuildInfra_Swarming_CacheEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  $4.Duration get waitForWarmCache => $_getN(2);
  @$pb.TagNumber(3)
  set waitForWarmCache($4.Duration v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCache() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCache() => clearField(3);
  @$pb.TagNumber(3)
  $4.Duration ensureWaitForWarmCache() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get envVar => $_getSZ(3);
  @$pb.TagNumber(4)
  set envVar($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnvVar() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnvVar() => clearField(4);
}

class BuildInfra_Swarming extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Swarming', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hostname')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taskId')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taskServiceAccount')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'priority', $pb.PbFieldType.O3)
    ..pc<$3.RequestedDimension>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taskDimensions', $pb.PbFieldType.PM, subBuilder: $3.RequestedDimension.create)
    ..pc<$3.StringPair>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'botDimensions', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..pc<BuildInfra_Swarming_CacheEntry>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'caches', $pb.PbFieldType.PM, subBuilder: BuildInfra_Swarming_CacheEntry.create)
    ..aOS(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'parentRunId')
    ..hasRequiredFields = false
  ;

  BuildInfra_Swarming._() : super();
  factory BuildInfra_Swarming({
    $core.String? hostname,
    $core.String? taskId,
    $core.String? taskServiceAccount,
    $core.int? priority,
    $core.Iterable<$3.RequestedDimension>? taskDimensions,
    $core.Iterable<$3.StringPair>? botDimensions,
    $core.Iterable<BuildInfra_Swarming_CacheEntry>? caches,
    $core.String? parentRunId,
  }) {
    final _result = create();
    if (hostname != null) {
      _result.hostname = hostname;
    }
    if (taskId != null) {
      _result.taskId = taskId;
    }
    if (taskServiceAccount != null) {
      _result.taskServiceAccount = taskServiceAccount;
    }
    if (priority != null) {
      _result.priority = priority;
    }
    if (taskDimensions != null) {
      _result.taskDimensions.addAll(taskDimensions);
    }
    if (botDimensions != null) {
      _result.botDimensions.addAll(botDimensions);
    }
    if (caches != null) {
      _result.caches.addAll(caches);
    }
    if (parentRunId != null) {
      _result.parentRunId = parentRunId;
    }
    return _result;
  }
  factory BuildInfra_Swarming.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Swarming clone() => BuildInfra_Swarming()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Swarming copyWith(void Function(BuildInfra_Swarming) updates) => super.copyWith((message) => updates(message as BuildInfra_Swarming)) as BuildInfra_Swarming; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming create() => BuildInfra_Swarming._();
  BuildInfra_Swarming createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming> createRepeated() => $pb.PbList<BuildInfra_Swarming>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming>(create);
  static BuildInfra_Swarming? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get taskServiceAccount => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskServiceAccount($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTaskServiceAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskServiceAccount() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get priority => $_getIZ(3);
  @$pb.TagNumber(4)
  set priority($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPriority() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriority() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$3.RequestedDimension> get taskDimensions => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<$3.StringPair> get botDimensions => $_getList(5);

  @$pb.TagNumber(7)
  $core.List<BuildInfra_Swarming_CacheEntry> get caches => $_getList(6);

  @$pb.TagNumber(9)
  $core.String get parentRunId => $_getSZ(7);
  @$pb.TagNumber(9)
  set parentRunId($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(9)
  $core.bool hasParentRunId() => $_has(7);
  @$pb.TagNumber(9)
  void clearParentRunId() => clearField(9);
}

class BuildInfra_LogDog extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.LogDog', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hostname')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'project')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'prefix')
    ..hasRequiredFields = false
  ;

  BuildInfra_LogDog._() : super();
  factory BuildInfra_LogDog({
    $core.String? hostname,
    $core.String? project,
    $core.String? prefix,
  }) {
    final _result = create();
    if (hostname != null) {
      _result.hostname = hostname;
    }
    if (project != null) {
      _result.project = project;
    }
    if (prefix != null) {
      _result.prefix = prefix;
    }
    return _result;
  }
  factory BuildInfra_LogDog.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_LogDog.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_LogDog clone() => BuildInfra_LogDog()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_LogDog copyWith(void Function(BuildInfra_LogDog) updates) => super.copyWith((message) => updates(message as BuildInfra_LogDog)) as BuildInfra_LogDog; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog create() => BuildInfra_LogDog._();
  BuildInfra_LogDog createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_LogDog> createRepeated() => $pb.PbList<BuildInfra_LogDog>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_LogDog>(create);
  static BuildInfra_LogDog? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get prefix => $_getSZ(2);
  @$pb.TagNumber(3)
  set prefix($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPrefix() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrefix() => clearField(3);
}

class BuildInfra_Recipe extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Recipe', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipdPackage')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..hasRequiredFields = false
  ;

  BuildInfra_Recipe._() : super();
  factory BuildInfra_Recipe({
    $core.String? cipdPackage,
    $core.String? name,
  }) {
    final _result = create();
    if (cipdPackage != null) {
      _result.cipdPackage = cipdPackage;
    }
    if (name != null) {
      _result.name = name;
    }
    return _result;
  }
  factory BuildInfra_Recipe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Recipe clone() => BuildInfra_Recipe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Recipe copyWith(void Function(BuildInfra_Recipe) updates) => super.copyWith((message) => updates(message as BuildInfra_Recipe)) as BuildInfra_Recipe; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe create() => BuildInfra_Recipe._();
  BuildInfra_Recipe createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Recipe> createRepeated() => $pb.PbList<BuildInfra_Recipe>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Recipe>(create);
  static BuildInfra_Recipe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cipdPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set cipdPackage($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCipdPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipdPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class BuildInfra_ResultDB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.ResultDB', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'hostname')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'invocation')
    ..hasRequiredFields = false
  ;

  BuildInfra_ResultDB._() : super();
  factory BuildInfra_ResultDB({
    $core.String? hostname,
    $core.String? invocation,
  }) {
    final _result = create();
    if (hostname != null) {
      _result.hostname = hostname;
    }
    if (invocation != null) {
      _result.invocation = invocation;
    }
    return _result;
  }
  factory BuildInfra_ResultDB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_ResultDB clone() => BuildInfra_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_ResultDB copyWith(void Function(BuildInfra_ResultDB) updates) => super.copyWith((message) => updates(message as BuildInfra_ResultDB)) as BuildInfra_ResultDB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB create() => BuildInfra_ResultDB._();
  BuildInfra_ResultDB createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_ResultDB> createRepeated() => $pb.PbList<BuildInfra_ResultDB>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_ResultDB>(create);
  static BuildInfra_ResultDB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get invocation => $_getSZ(1);
  @$pb.TagNumber(2)
  set invocation($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInvocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearInvocation() => clearField(2);
}

class BuildInfra_BBAgent_Input_CIPDPackage extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.BBAgent.Input.CIPDPackage', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'version')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'server')
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..hasRequiredFields = false
  ;

  BuildInfra_BBAgent_Input_CIPDPackage._() : super();
  factory BuildInfra_BBAgent_Input_CIPDPackage({
    $core.String? name,
    $core.String? version,
    $core.String? server,
    $core.String? path,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (version != null) {
      _result.version = version;
    }
    if (server != null) {
      _result.server = server;
    }
    if (path != null) {
      _result.path = path;
    }
    return _result;
  }
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage clone() => BuildInfra_BBAgent_Input_CIPDPackage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage copyWith(void Function(BuildInfra_BBAgent_Input_CIPDPackage) updates) => super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input_CIPDPackage)) as BuildInfra_BBAgent_Input_CIPDPackage; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage create() => BuildInfra_BBAgent_Input_CIPDPackage._();
  BuildInfra_BBAgent_Input_CIPDPackage createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage> createRepeated() => $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input_CIPDPackage>(create);
  static BuildInfra_BBAgent_Input_CIPDPackage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => clearField(4);
}

class BuildInfra_BBAgent_Input extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.BBAgent.Input', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<BuildInfra_BBAgent_Input_CIPDPackage>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipdPackages', $pb.PbFieldType.PM, subBuilder: BuildInfra_BBAgent_Input_CIPDPackage.create)
    ..hasRequiredFields = false
  ;

  BuildInfra_BBAgent_Input._() : super();
  factory BuildInfra_BBAgent_Input({
    $core.Iterable<BuildInfra_BBAgent_Input_CIPDPackage>? cipdPackages,
  }) {
    final _result = create();
    if (cipdPackages != null) {
      _result.cipdPackages.addAll(cipdPackages);
    }
    return _result;
  }
  factory BuildInfra_BBAgent_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent_Input clone() => BuildInfra_BBAgent_Input()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent_Input copyWith(void Function(BuildInfra_BBAgent_Input) updates) => super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input)) as BuildInfra_BBAgent_Input; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input create() => BuildInfra_BBAgent_Input._();
  BuildInfra_BBAgent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input> createRepeated() => $pb.PbList<BuildInfra_BBAgent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input>(create);
  static BuildInfra_BBAgent_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BuildInfra_BBAgent_Input_CIPDPackage> get cipdPackages => $_getList(0);
}

class BuildInfra_BBAgent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.BBAgent', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'payloadPath')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cacheDir')
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'knownPublicGerritHosts')
    ..aOM<BuildInfra_BBAgent_Input>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'input', subBuilder: BuildInfra_BBAgent_Input.create)
    ..hasRequiredFields = false
  ;

  BuildInfra_BBAgent._() : super();
  factory BuildInfra_BBAgent({
    $core.String? payloadPath,
    $core.String? cacheDir,
  @$core.Deprecated('This field is deprecated.')
    $core.Iterable<$core.String>? knownPublicGerritHosts,
  @$core.Deprecated('This field is deprecated.')
    BuildInfra_BBAgent_Input? input,
  }) {
    final _result = create();
    if (payloadPath != null) {
      _result.payloadPath = payloadPath;
    }
    if (cacheDir != null) {
      _result.cacheDir = cacheDir;
    }
    if (knownPublicGerritHosts != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.knownPublicGerritHosts.addAll(knownPublicGerritHosts);
    }
    if (input != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.input = input;
    }
    return _result;
  }
  factory BuildInfra_BBAgent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent clone() => BuildInfra_BBAgent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_BBAgent copyWith(void Function(BuildInfra_BBAgent) updates) => super.copyWith((message) => updates(message as BuildInfra_BBAgent)) as BuildInfra_BBAgent; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent create() => BuildInfra_BBAgent._();
  BuildInfra_BBAgent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent> createRepeated() => $pb.PbList<BuildInfra_BBAgent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent>(create);
  static BuildInfra_BBAgent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get payloadPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set payloadPath($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPayloadPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayloadPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get cacheDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set cacheDir($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCacheDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearCacheDir() => clearField(2);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(2);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  BuildInfra_BBAgent_Input get input => $_getN(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  set input(BuildInfra_BBAgent_Input v) { setField(4, v); }
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool hasInput() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  void clearInput() => clearField(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  BuildInfra_BBAgent_Input ensureInput() => $_ensure(3);
}

class BuildInfra_Backend extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra.Backend', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'config', subBuilder: $5.Struct.create)
    ..aOM<$6.Task>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'task', subBuilder: $6.Task.create)
    ..hasRequiredFields = false
  ;

  BuildInfra_Backend._() : super();
  factory BuildInfra_Backend({
    $5.Struct? config,
    $6.Task? task,
  }) {
    final _result = create();
    if (config != null) {
      _result.config = config;
    }
    if (task != null) {
      _result.task = task;
    }
    return _result;
  }
  factory BuildInfra_Backend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra_Backend clone() => BuildInfra_Backend()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra_Backend copyWith(void Function(BuildInfra_Backend) updates) => super.copyWith((message) => updates(message as BuildInfra_Backend)) as BuildInfra_Backend; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend create() => BuildInfra_Backend._();
  BuildInfra_Backend createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Backend> createRepeated() => $pb.PbList<BuildInfra_Backend>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Backend>(create);
  static BuildInfra_Backend? _defaultInstance;

  @$pb.TagNumber(1)
  $5.Struct get config => $_getN(0);
  @$pb.TagNumber(1)
  set config($5.Struct v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureConfig() => $_ensure(0);

  @$pb.TagNumber(2)
  $6.Task get task => $_getN(1);
  @$pb.TagNumber(2)
  set task($6.Task v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTask() => $_has(1);
  @$pb.TagNumber(2)
  void clearTask() => clearField(2);
  @$pb.TagNumber(2)
  $6.Task ensureTask() => $_ensure(1);
}

class BuildInfra extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildInfra', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'buildbucket', subBuilder: BuildInfra_Buildbucket.create)
    ..aOM<BuildInfra_Swarming>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'swarming', subBuilder: BuildInfra_Swarming.create)
    ..aOM<BuildInfra_LogDog>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logdog', subBuilder: BuildInfra_LogDog.create)
    ..aOM<BuildInfra_Recipe>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'recipe', subBuilder: BuildInfra_Recipe.create)
    ..aOM<BuildInfra_ResultDB>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resultdb', subBuilder: BuildInfra_ResultDB.create)
    ..aOM<BuildInfra_BBAgent>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bbagent', subBuilder: BuildInfra_BBAgent.create)
    ..aOM<BuildInfra_Backend>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'backend', subBuilder: BuildInfra_Backend.create)
    ..hasRequiredFields = false
  ;

  BuildInfra._() : super();
  factory BuildInfra({
    BuildInfra_Buildbucket? buildbucket,
    BuildInfra_Swarming? swarming,
    BuildInfra_LogDog? logdog,
    BuildInfra_Recipe? recipe,
    BuildInfra_ResultDB? resultdb,
    BuildInfra_BBAgent? bbagent,
    BuildInfra_Backend? backend,
  }) {
    final _result = create();
    if (buildbucket != null) {
      _result.buildbucket = buildbucket;
    }
    if (swarming != null) {
      _result.swarming = swarming;
    }
    if (logdog != null) {
      _result.logdog = logdog;
    }
    if (recipe != null) {
      _result.recipe = recipe;
    }
    if (resultdb != null) {
      _result.resultdb = resultdb;
    }
    if (bbagent != null) {
      _result.bbagent = bbagent;
    }
    if (backend != null) {
      _result.backend = backend;
    }
    return _result;
  }
  factory BuildInfra.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildInfra.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildInfra clone() => BuildInfra()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildInfra copyWith(void Function(BuildInfra) updates) => super.copyWith((message) => updates(message as BuildInfra)) as BuildInfra; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildInfra create() => BuildInfra._();
  BuildInfra createEmptyInstance() => create();
  static $pb.PbList<BuildInfra> createRepeated() => $pb.PbList<BuildInfra>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra>(create);
  static BuildInfra? _defaultInstance;

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket get buildbucket => $_getN(0);
  @$pb.TagNumber(1)
  set buildbucket(BuildInfra_Buildbucket v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasBuildbucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildbucket() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket ensureBuildbucket() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Swarming get swarming => $_getN(1);
  @$pb.TagNumber(2)
  set swarming(BuildInfra_Swarming v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSwarming() => $_has(1);
  @$pb.TagNumber(2)
  void clearSwarming() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Swarming ensureSwarming() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_LogDog get logdog => $_getN(2);
  @$pb.TagNumber(3)
  set logdog(BuildInfra_LogDog v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLogdog() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogdog() => clearField(3);
  @$pb.TagNumber(3)
  BuildInfra_LogDog ensureLogdog() => $_ensure(2);

  @$pb.TagNumber(4)
  BuildInfra_Recipe get recipe => $_getN(3);
  @$pb.TagNumber(4)
  set recipe(BuildInfra_Recipe v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasRecipe() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipe() => clearField(4);
  @$pb.TagNumber(4)
  BuildInfra_Recipe ensureRecipe() => $_ensure(3);

  @$pb.TagNumber(5)
  BuildInfra_ResultDB get resultdb => $_getN(4);
  @$pb.TagNumber(5)
  set resultdb(BuildInfra_ResultDB v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasResultdb() => $_has(4);
  @$pb.TagNumber(5)
  void clearResultdb() => clearField(5);
  @$pb.TagNumber(5)
  BuildInfra_ResultDB ensureResultdb() => $_ensure(4);

  @$pb.TagNumber(6)
  BuildInfra_BBAgent get bbagent => $_getN(5);
  @$pb.TagNumber(6)
  set bbagent(BuildInfra_BBAgent v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBbagent() => $_has(5);
  @$pb.TagNumber(6)
  void clearBbagent() => clearField(6);
  @$pb.TagNumber(6)
  BuildInfra_BBAgent ensureBbagent() => $_ensure(5);

  @$pb.TagNumber(7)
  BuildInfra_Backend get backend => $_getN(6);
  @$pb.TagNumber(7)
  set backend(BuildInfra_Backend v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasBackend() => $_has(6);
  @$pb.TagNumber(7)
  void clearBackend() => clearField(7);
  @$pb.TagNumber(7)
  BuildInfra_Backend ensureBackend() => $_ensure(6);
}

