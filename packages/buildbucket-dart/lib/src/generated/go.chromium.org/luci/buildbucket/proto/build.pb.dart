//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $4;
import '../../../../google/protobuf/struct.pb.dart' as $5;
import '../../../../google/protobuf/timestamp.pb.dart' as $1;
import '../../resultdb/proto/v1/invocation.pb.dart' as $6;
import 'build.pbenum.dart';
import 'builder_common.pb.dart' as $0;
import 'common.pb.dart' as $3;
import 'common.pbenum.dart' as $3;
import 'step.pb.dart' as $2;
import 'task.pb.dart' as $7;

export 'build.pbenum.dart';

class Build_Input extends $pb.GeneratedMessage {
  factory Build_Input() => create();
  Build_Input._() : super();
  factory Build_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOM<$3.GitilesCommit>(2, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.GerritChange>(3, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $3.GerritChange.create)
    ..aOB(5, _omitFieldNames ? '' : 'experimental')
    ..pPS(6, _omitFieldNames ? '' : 'experiments')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_Input clone() => Build_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_Input copyWith(void Function(Build_Input) updates) =>
      super.copyWith((message) => updates(message as Build_Input)) as Build_Input;

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
  set properties($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  @$pb.TagNumber(2)
  $3.GitilesCommit get gitilesCommit => $_getN(1);
  @$pb.TagNumber(2)
  set gitilesCommit($3.GitilesCommit v) {
    setField(2, v);
  }

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
  set experimental($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasExperimental() => $_has(3);
  @$pb.TagNumber(5)
  void clearExperimental() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.String> get experiments => $_getList(4);
}

class Build_Output extends $pb.GeneratedMessage {
  factory Build_Output() => create();
  Build_Output._() : super();
  factory Build_Output.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_Output.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.Output',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOS(2, _omitFieldNames ? '' : 'summaryMarkdown')
    ..aOM<$3.GitilesCommit>(3, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.Log>(5, _omitFieldNames ? '' : 'logs', $pb.PbFieldType.PM, subBuilder: $3.Log.create)
    ..e<$3.Status>(6, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<$3.StatusDetails>(7, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(8, _omitFieldNames ? '' : 'summaryHtml')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_Output clone() => Build_Output()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_Output copyWith(void Function(Build_Output) updates) =>
      super.copyWith((message) => updates(message as Build_Output)) as Build_Output;

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
  set properties($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get summaryMarkdown => $_getSZ(1);
  @$pb.TagNumber(2)
  set summaryMarkdown($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSummaryMarkdown() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummaryMarkdown() => clearField(2);

  @$pb.TagNumber(3)
  $3.GitilesCommit get gitilesCommit => $_getN(2);
  @$pb.TagNumber(3)
  set gitilesCommit($3.GitilesCommit v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasGitilesCommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearGitilesCommit() => clearField(3);
  @$pb.TagNumber(3)
  $3.GitilesCommit ensureGitilesCommit() => $_ensure(2);

  @$pb.TagNumber(5)
  $core.List<$3.Log> get logs => $_getList(3);

  @$pb.TagNumber(6)
  $3.Status get status => $_getN(4);
  @$pb.TagNumber(6)
  set status($3.Status v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(6)
  void clearStatus() => clearField(6);

  @$pb.TagNumber(7)
  $3.StatusDetails get statusDetails => $_getN(5);
  @$pb.TagNumber(7)
  set statusDetails($3.StatusDetails v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStatusDetails() => $_has(5);
  @$pb.TagNumber(7)
  void clearStatusDetails() => clearField(7);
  @$pb.TagNumber(7)
  $3.StatusDetails ensureStatusDetails() => $_ensure(5);

  @$pb.TagNumber(8)
  $core.String get summaryHtml => $_getSZ(6);
  @$pb.TagNumber(8)
  set summaryHtml($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasSummaryHtml() => $_has(6);
  @$pb.TagNumber(8)
  void clearSummaryHtml() => clearField(8);
}

class Build_BuilderInfo extends $pb.GeneratedMessage {
  factory Build_BuilderInfo() => create();
  Build_BuilderInfo._() : super();
  factory Build_BuilderInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_BuilderInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.BuilderInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_BuilderInfo clone() => Build_BuilderInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_BuilderInfo copyWith(void Function(Build_BuilderInfo) updates) =>
      super.copyWith((message) => updates(message as Build_BuilderInfo)) as Build_BuilderInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Build_BuilderInfo create() => Build_BuilderInfo._();
  Build_BuilderInfo createEmptyInstance() => create();
  static $pb.PbList<Build_BuilderInfo> createRepeated() => $pb.PbList<Build_BuilderInfo>();
  @$core.pragma('dart2js:noInline')
  static Build_BuilderInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_BuilderInfo>(create);
  static Build_BuilderInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => clearField(1);
}

class Build extends $pb.GeneratedMessage {
  factory Build() => create();
  Build._() : super();
  factory Build.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$0.BuilderID>(2, _omitFieldNames ? '' : 'builder', subBuilder: $0.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'number', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'createdBy')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'createTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(7, _omitFieldNames ? '' : 'startTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'endTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'updateTime', subBuilder: $1.Timestamp.create)
    ..e<$3.Status>(12, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<Build_Input>(15, _omitFieldNames ? '' : 'input', subBuilder: Build_Input.create)
    ..aOM<Build_Output>(16, _omitFieldNames ? '' : 'output', subBuilder: Build_Output.create)
    ..pc<$2.Step>(17, _omitFieldNames ? '' : 'steps', $pb.PbFieldType.PM, subBuilder: $2.Step.create)
    ..aOM<BuildInfra>(18, _omitFieldNames ? '' : 'infra', subBuilder: BuildInfra.create)
    ..pc<$3.StringPair>(19, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..aOS(20, _omitFieldNames ? '' : 'summaryMarkdown')
    ..e<$3.Trinary>(21, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<$3.StatusDetails>(22, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(23, _omitFieldNames ? '' : 'canceledBy')
    ..aOM<$3.Executable>(24, _omitFieldNames ? '' : 'exe', subBuilder: $3.Executable.create)
    ..aOB(25, _omitFieldNames ? '' : 'canary')
    ..aOM<$4.Duration>(26, _omitFieldNames ? '' : 'schedulingTimeout', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(27, _omitFieldNames ? '' : 'executionTimeout', subBuilder: $4.Duration.create)
    ..aOB(28, _omitFieldNames ? '' : 'waitForCapacity')
    ..aOM<$4.Duration>(29, _omitFieldNames ? '' : 'gracePeriod', subBuilder: $4.Duration.create)
    ..aOB(30, _omitFieldNames ? '' : 'canOutliveParent')
    ..p<$fixnum.Int64>(31, _omitFieldNames ? '' : 'ancestorIds', $pb.PbFieldType.K6)
    ..aOM<$1.Timestamp>(32, _omitFieldNames ? '' : 'cancelTime', subBuilder: $1.Timestamp.create)
    ..aOS(33, _omitFieldNames ? '' : 'cancellationMarkdown')
    ..aOM<Build_BuilderInfo>(34, _omitFieldNames ? '' : 'builderInfo', subBuilder: Build_BuilderInfo.create)
    ..e<$3.Trinary>(35, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build clone() => Build()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build copyWith(void Function(Build) updates) => super.copyWith((message) => updates(message as Build)) as Build;

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
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $0.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($0.BuilderID v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $0.BuilderID ensureBuilder() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.int get number => $_getIZ(2);
  @$pb.TagNumber(3)
  set number($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get createdBy => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdBy($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCreatedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedBy() => clearField(4);

  @$pb.TagNumber(6)
  $1.Timestamp get createTime => $_getN(4);
  @$pb.TagNumber(6)
  set createTime($1.Timestamp v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(4);
  @$pb.TagNumber(6)
  void clearCreateTime() => clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreateTime() => $_ensure(4);

  @$pb.TagNumber(7)
  $1.Timestamp get startTime => $_getN(5);
  @$pb.TagNumber(7)
  set startTime($1.Timestamp v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStartTime() => $_has(5);
  @$pb.TagNumber(7)
  void clearStartTime() => clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureStartTime() => $_ensure(5);

  @$pb.TagNumber(8)
  $1.Timestamp get endTime => $_getN(6);
  @$pb.TagNumber(8)
  set endTime($1.Timestamp v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasEndTime() => $_has(6);
  @$pb.TagNumber(8)
  void clearEndTime() => clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureEndTime() => $_ensure(6);

  @$pb.TagNumber(9)
  $1.Timestamp get updateTime => $_getN(7);
  @$pb.TagNumber(9)
  set updateTime($1.Timestamp v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasUpdateTime() => $_has(7);
  @$pb.TagNumber(9)
  void clearUpdateTime() => clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureUpdateTime() => $_ensure(7);

  @$pb.TagNumber(12)
  $3.Status get status => $_getN(8);
  @$pb.TagNumber(12)
  set status($3.Status v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(12)
  void clearStatus() => clearField(12);

  @$pb.TagNumber(15)
  Build_Input get input => $_getN(9);
  @$pb.TagNumber(15)
  set input(Build_Input v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasInput() => $_has(9);
  @$pb.TagNumber(15)
  void clearInput() => clearField(15);
  @$pb.TagNumber(15)
  Build_Input ensureInput() => $_ensure(9);

  @$pb.TagNumber(16)
  Build_Output get output => $_getN(10);
  @$pb.TagNumber(16)
  set output(Build_Output v) {
    setField(16, v);
  }

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
  set infra(BuildInfra v) {
    setField(18, v);
  }

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
  set summaryMarkdown($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasSummaryMarkdown() => $_has(14);
  @$pb.TagNumber(20)
  void clearSummaryMarkdown() => clearField(20);

  @$pb.TagNumber(21)
  $3.Trinary get critical => $_getN(15);
  @$pb.TagNumber(21)
  set critical($3.Trinary v) {
    setField(21, v);
  }

  @$pb.TagNumber(21)
  $core.bool hasCritical() => $_has(15);
  @$pb.TagNumber(21)
  void clearCritical() => clearField(21);

  @$pb.TagNumber(22)
  $3.StatusDetails get statusDetails => $_getN(16);
  @$pb.TagNumber(22)
  set statusDetails($3.StatusDetails v) {
    setField(22, v);
  }

  @$pb.TagNumber(22)
  $core.bool hasStatusDetails() => $_has(16);
  @$pb.TagNumber(22)
  void clearStatusDetails() => clearField(22);
  @$pb.TagNumber(22)
  $3.StatusDetails ensureStatusDetails() => $_ensure(16);

  @$pb.TagNumber(23)
  $core.String get canceledBy => $_getSZ(17);
  @$pb.TagNumber(23)
  set canceledBy($core.String v) {
    $_setString(17, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasCanceledBy() => $_has(17);
  @$pb.TagNumber(23)
  void clearCanceledBy() => clearField(23);

  @$pb.TagNumber(24)
  $3.Executable get exe => $_getN(18);
  @$pb.TagNumber(24)
  set exe($3.Executable v) {
    setField(24, v);
  }

  @$pb.TagNumber(24)
  $core.bool hasExe() => $_has(18);
  @$pb.TagNumber(24)
  void clearExe() => clearField(24);
  @$pb.TagNumber(24)
  $3.Executable ensureExe() => $_ensure(18);

  @$pb.TagNumber(25)
  $core.bool get canary => $_getBF(19);
  @$pb.TagNumber(25)
  set canary($core.bool v) {
    $_setBool(19, v);
  }

  @$pb.TagNumber(25)
  $core.bool hasCanary() => $_has(19);
  @$pb.TagNumber(25)
  void clearCanary() => clearField(25);

  @$pb.TagNumber(26)
  $4.Duration get schedulingTimeout => $_getN(20);
  @$pb.TagNumber(26)
  set schedulingTimeout($4.Duration v) {
    setField(26, v);
  }

  @$pb.TagNumber(26)
  $core.bool hasSchedulingTimeout() => $_has(20);
  @$pb.TagNumber(26)
  void clearSchedulingTimeout() => clearField(26);
  @$pb.TagNumber(26)
  $4.Duration ensureSchedulingTimeout() => $_ensure(20);

  @$pb.TagNumber(27)
  $4.Duration get executionTimeout => $_getN(21);
  @$pb.TagNumber(27)
  set executionTimeout($4.Duration v) {
    setField(27, v);
  }

  @$pb.TagNumber(27)
  $core.bool hasExecutionTimeout() => $_has(21);
  @$pb.TagNumber(27)
  void clearExecutionTimeout() => clearField(27);
  @$pb.TagNumber(27)
  $4.Duration ensureExecutionTimeout() => $_ensure(21);

  @$pb.TagNumber(28)
  $core.bool get waitForCapacity => $_getBF(22);
  @$pb.TagNumber(28)
  set waitForCapacity($core.bool v) {
    $_setBool(22, v);
  }

  @$pb.TagNumber(28)
  $core.bool hasWaitForCapacity() => $_has(22);
  @$pb.TagNumber(28)
  void clearWaitForCapacity() => clearField(28);

  @$pb.TagNumber(29)
  $4.Duration get gracePeriod => $_getN(23);
  @$pb.TagNumber(29)
  set gracePeriod($4.Duration v) {
    setField(29, v);
  }

  @$pb.TagNumber(29)
  $core.bool hasGracePeriod() => $_has(23);
  @$pb.TagNumber(29)
  void clearGracePeriod() => clearField(29);
  @$pb.TagNumber(29)
  $4.Duration ensureGracePeriod() => $_ensure(23);

  @$pb.TagNumber(30)
  $core.bool get canOutliveParent => $_getBF(24);
  @$pb.TagNumber(30)
  set canOutliveParent($core.bool v) {
    $_setBool(24, v);
  }

  @$pb.TagNumber(30)
  $core.bool hasCanOutliveParent() => $_has(24);
  @$pb.TagNumber(30)
  void clearCanOutliveParent() => clearField(30);

  @$pb.TagNumber(31)
  $core.List<$fixnum.Int64> get ancestorIds => $_getList(25);

  @$pb.TagNumber(32)
  $1.Timestamp get cancelTime => $_getN(26);
  @$pb.TagNumber(32)
  set cancelTime($1.Timestamp v) {
    setField(32, v);
  }

  @$pb.TagNumber(32)
  $core.bool hasCancelTime() => $_has(26);
  @$pb.TagNumber(32)
  void clearCancelTime() => clearField(32);
  @$pb.TagNumber(32)
  $1.Timestamp ensureCancelTime() => $_ensure(26);

  @$pb.TagNumber(33)
  $core.String get cancellationMarkdown => $_getSZ(27);
  @$pb.TagNumber(33)
  set cancellationMarkdown($core.String v) {
    $_setString(27, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasCancellationMarkdown() => $_has(27);
  @$pb.TagNumber(33)
  void clearCancellationMarkdown() => clearField(33);

  @$pb.TagNumber(34)
  Build_BuilderInfo get builderInfo => $_getN(28);
  @$pb.TagNumber(34)
  set builderInfo(Build_BuilderInfo v) {
    setField(34, v);
  }

  @$pb.TagNumber(34)
  $core.bool hasBuilderInfo() => $_has(28);
  @$pb.TagNumber(34)
  void clearBuilderInfo() => clearField(34);
  @$pb.TagNumber(34)
  Build_BuilderInfo ensureBuilderInfo() => $_ensure(28);

  @$pb.TagNumber(35)
  $3.Trinary get retriable => $_getN(29);
  @$pb.TagNumber(35)
  set retriable($3.Trinary v) {
    setField(35, v);
  }

  @$pb.TagNumber(35)
  $core.bool hasRetriable() => $_has(29);
  @$pb.TagNumber(35)
  void clearRetriable() => clearField(35);
}

class InputDataRef_CAS_Digest extends $pb.GeneratedMessage {
  factory InputDataRef_CAS_Digest() => create();
  InputDataRef_CAS_Digest._() : super();
  factory InputDataRef_CAS_Digest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS_Digest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CAS.Digest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..aInt64(2, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS_Digest clone() => InputDataRef_CAS_Digest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS_Digest copyWith(void Function(InputDataRef_CAS_Digest) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CAS_Digest)) as InputDataRef_CAS_Digest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest create() => InputDataRef_CAS_Digest._();
  InputDataRef_CAS_Digest createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS_Digest> createRepeated() => $pb.PbList<InputDataRef_CAS_Digest>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS_Digest>(create);
  static InputDataRef_CAS_Digest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => clearField(2);
}

class InputDataRef_CAS extends $pb.GeneratedMessage {
  factory InputDataRef_CAS() => create();
  InputDataRef_CAS._() : super();
  factory InputDataRef_CAS.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CAS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'casInstance')
    ..aOM<InputDataRef_CAS_Digest>(2, _omitFieldNames ? '' : 'digest', subBuilder: InputDataRef_CAS_Digest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS clone() => InputDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS copyWith(void Function(InputDataRef_CAS) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CAS)) as InputDataRef_CAS;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS create() => InputDataRef_CAS._();
  InputDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS> createRepeated() => $pb.PbList<InputDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS>(create);
  static InputDataRef_CAS? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get casInstance => $_getSZ(0);
  @$pb.TagNumber(1)
  set casInstance($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearCasInstance() => clearField(1);

  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest get digest => $_getN(1);
  @$pb.TagNumber(2)
  set digest(InputDataRef_CAS_Digest v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDigest() => $_has(1);
  @$pb.TagNumber(2)
  void clearDigest() => clearField(2);
  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest ensureDigest() => $_ensure(1);
}

class InputDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  factory InputDataRef_CIPD_PkgSpec() => create();
  InputDataRef_CIPD_PkgSpec._() : super();
  factory InputDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD_PkgSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CIPD.PkgSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec clone() => InputDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec copyWith(void Function(InputDataRef_CIPD_PkgSpec) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CIPD_PkgSpec)) as InputDataRef_CIPD_PkgSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec create() => InputDataRef_CIPD_PkgSpec._();
  InputDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<InputDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD_PkgSpec>(create);
  static InputDataRef_CIPD_PkgSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);
}

class InputDataRef_CIPD extends $pb.GeneratedMessage {
  factory InputDataRef_CIPD() => create();
  InputDataRef_CIPD._() : super();
  factory InputDataRef_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'server')
    ..pc<InputDataRef_CIPD_PkgSpec>(2, _omitFieldNames ? '' : 'specs', $pb.PbFieldType.PM,
        subBuilder: InputDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD clone() => InputDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD copyWith(void Function(InputDataRef_CIPD) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CIPD)) as InputDataRef_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD create() => InputDataRef_CIPD._();
  InputDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD> createRepeated() => $pb.PbList<InputDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD>(create);
  static InputDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get server => $_getSZ(0);
  @$pb.TagNumber(1)
  set server($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<InputDataRef_CIPD_PkgSpec> get specs => $_getList(1);
}

enum InputDataRef_DataType { cas, cipd, notSet }

class InputDataRef extends $pb.GeneratedMessage {
  factory InputDataRef() => create();
  InputDataRef._() : super();
  factory InputDataRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, InputDataRef_DataType> _InputDataRef_DataTypeByTag = {
    1: InputDataRef_DataType.cas,
    2: InputDataRef_DataType.cipd,
    0: InputDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InputDataRef_CAS>(1, _omitFieldNames ? '' : 'cas', subBuilder: InputDataRef_CAS.create)
    ..aOM<InputDataRef_CIPD>(2, _omitFieldNames ? '' : 'cipd', subBuilder: InputDataRef_CIPD.create)
    ..pPS(3, _omitFieldNames ? '' : 'onPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef clone() => InputDataRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef copyWith(void Function(InputDataRef) updates) =>
      super.copyWith((message) => updates(message as InputDataRef)) as InputDataRef;

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
  set cas(InputDataRef_CAS v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  InputDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  InputDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(InputDataRef_CIPD v) {
    setField(2, v);
  }

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
  factory ResolvedDataRef_Timing() => create();
  ResolvedDataRef_Timing._() : super();
  factory ResolvedDataRef_Timing.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_Timing.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.Timing',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$4.Duration>(1, _omitFieldNames ? '' : 'fetchDuration', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(2, _omitFieldNames ? '' : 'installDuration', subBuilder: $4.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_Timing clone() => ResolvedDataRef_Timing()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_Timing copyWith(void Function(ResolvedDataRef_Timing) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_Timing)) as ResolvedDataRef_Timing;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing create() => ResolvedDataRef_Timing._();
  ResolvedDataRef_Timing createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_Timing> createRepeated() => $pb.PbList<ResolvedDataRef_Timing>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_Timing>(create);
  static ResolvedDataRef_Timing? _defaultInstance;

  @$pb.TagNumber(1)
  $4.Duration get fetchDuration => $_getN(0);
  @$pb.TagNumber(1)
  set fetchDuration($4.Duration v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFetchDuration() => $_has(0);
  @$pb.TagNumber(1)
  void clearFetchDuration() => clearField(1);
  @$pb.TagNumber(1)
  $4.Duration ensureFetchDuration() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.Duration get installDuration => $_getN(1);
  @$pb.TagNumber(2)
  set installDuration($4.Duration v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInstallDuration() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstallDuration() => clearField(2);
  @$pb.TagNumber(2)
  $4.Duration ensureInstallDuration() => $_ensure(1);
}

class ResolvedDataRef_CAS extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CAS() => create();
  ResolvedDataRef_CAS._() : super();
  factory ResolvedDataRef_CAS.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CAS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<ResolvedDataRef_Timing>(1, _omitFieldNames ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CAS clone() => ResolvedDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CAS copyWith(void Function(ResolvedDataRef_CAS) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CAS)) as ResolvedDataRef_CAS;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS create() => ResolvedDataRef_CAS._();
  ResolvedDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CAS> createRepeated() => $pb.PbList<ResolvedDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CAS>(create);
  static ResolvedDataRef_CAS? _defaultInstance;

  @$pb.TagNumber(1)
  ResolvedDataRef_Timing get timing => $_getN(0);
  @$pb.TagNumber(1)
  set timing(ResolvedDataRef_Timing v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTiming() => $_has(0);
  @$pb.TagNumber(1)
  void clearTiming() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(0);
}

class ResolvedDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CIPD_PkgSpec() => create();
  ResolvedDataRef_CIPD_PkgSpec._() : super();
  factory ResolvedDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD_PkgSpec.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CIPD.PkgSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'skipped')
    ..aOS(2, _omitFieldNames ? '' : 'package')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..e<$3.Trinary>(4, _omitFieldNames ? '' : 'wasCached', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<ResolvedDataRef_Timing>(5, _omitFieldNames ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec clone() => ResolvedDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec copyWith(void Function(ResolvedDataRef_CIPD_PkgSpec) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CIPD_PkgSpec)) as ResolvedDataRef_CIPD_PkgSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec create() => ResolvedDataRef_CIPD_PkgSpec._();
  ResolvedDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD_PkgSpec>(create);
  static ResolvedDataRef_CIPD_PkgSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get skipped => $_getBF(0);
  @$pb.TagNumber(1)
  set skipped($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSkipped() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkipped() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get package => $_getSZ(1);
  @$pb.TagNumber(2)
  set package($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackage() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);

  @$pb.TagNumber(4)
  $3.Trinary get wasCached => $_getN(3);
  @$pb.TagNumber(4)
  set wasCached($3.Trinary v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWasCached() => $_has(3);
  @$pb.TagNumber(4)
  void clearWasCached() => clearField(4);

  @$pb.TagNumber(5)
  ResolvedDataRef_Timing get timing => $_getN(4);
  @$pb.TagNumber(5)
  set timing(ResolvedDataRef_Timing v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTiming() => $_has(4);
  @$pb.TagNumber(5)
  void clearTiming() => clearField(5);
  @$pb.TagNumber(5)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(4);
}

class ResolvedDataRef_CIPD extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CIPD() => create();
  ResolvedDataRef_CIPD._() : super();
  factory ResolvedDataRef_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<ResolvedDataRef_CIPD_PkgSpec>(2, _omitFieldNames ? '' : 'specs', $pb.PbFieldType.PM,
        subBuilder: ResolvedDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD clone() => ResolvedDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD copyWith(void Function(ResolvedDataRef_CIPD) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CIPD)) as ResolvedDataRef_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD create() => ResolvedDataRef_CIPD._();
  ResolvedDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD>(create);
  static ResolvedDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<ResolvedDataRef_CIPD_PkgSpec> get specs => $_getList(0);
}

enum ResolvedDataRef_DataType { cas, cipd, notSet }

class ResolvedDataRef extends $pb.GeneratedMessage {
  factory ResolvedDataRef() => create();
  ResolvedDataRef._() : super();
  factory ResolvedDataRef.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ResolvedDataRef_DataType> _ResolvedDataRef_DataTypeByTag = {
    1: ResolvedDataRef_DataType.cas,
    2: ResolvedDataRef_DataType.cipd,
    0: ResolvedDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ResolvedDataRef_CAS>(1, _omitFieldNames ? '' : 'cas', subBuilder: ResolvedDataRef_CAS.create)
    ..aOM<ResolvedDataRef_CIPD>(2, _omitFieldNames ? '' : 'cipd', subBuilder: ResolvedDataRef_CIPD.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef clone() => ResolvedDataRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef copyWith(void Function(ResolvedDataRef) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef)) as ResolvedDataRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef create() => ResolvedDataRef._();
  ResolvedDataRef createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef> createRepeated() => $pb.PbList<ResolvedDataRef>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef>(create);
  static ResolvedDataRef? _defaultInstance;

  ResolvedDataRef_DataType whichDataType() => _ResolvedDataRef_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ResolvedDataRef_CAS get cas => $_getN(0);
  @$pb.TagNumber(1)
  set cas(ResolvedDataRef_CAS v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(ResolvedDataRef_CIPD v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCipd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipd() => clearField(2);
  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD ensureCipd() => $_ensure(1);
}

class BuildInfra_Buildbucket_Agent_Source_CIPD extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Source_CIPD() => create();
  BuildInfra_Buildbucket_Agent_Source_CIPD._() : super();
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Source.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'server')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'resolvedInstances',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Source.CIPD.ResolvedInstancesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD clone() =>
      BuildInfra_Buildbucket_Agent_Source_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD copyWith(void Function(BuildInfra_Buildbucket_Agent_Source_CIPD) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source_CIPD))
          as BuildInfra_Buildbucket_Agent_Source_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD create() => BuildInfra_Buildbucket_Agent_Source_CIPD._();
  BuildInfra_Buildbucket_Agent_Source_CIPD createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source_CIPD>(create);
  static BuildInfra_Buildbucket_Agent_Source_CIPD? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.String> get resolvedInstances => $_getMap(3);
}

enum BuildInfra_Buildbucket_Agent_Source_DataType { cipd, notSet }

class BuildInfra_Buildbucket_Agent_Source extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Source() => create();
  BuildInfra_Buildbucket_Agent_Source._() : super();
  factory BuildInfra_Buildbucket_Agent_Source.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BuildInfra_Buildbucket_Agent_Source_DataType>
      _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag = {
    1: BuildInfra_Buildbucket_Agent_Source_DataType.cipd,
    0: BuildInfra_Buildbucket_Agent_Source_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Source',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<BuildInfra_Buildbucket_Agent_Source_CIPD>(1, _omitFieldNames ? '' : 'cipd',
        subBuilder: BuildInfra_Buildbucket_Agent_Source_CIPD.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source clone() => BuildInfra_Buildbucket_Agent_Source()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source copyWith(void Function(BuildInfra_Buildbucket_Agent_Source) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source))
          as BuildInfra_Buildbucket_Agent_Source;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source create() => BuildInfra_Buildbucket_Agent_Source._();
  BuildInfra_Buildbucket_Agent_Source createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Source>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source>(create);
  static BuildInfra_Buildbucket_Agent_Source? _defaultInstance;

  BuildInfra_Buildbucket_Agent_Source_DataType whichDataType() =>
      _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD get cipd => $_getN(0);
  @$pb.TagNumber(1)
  set cipd(BuildInfra_Buildbucket_Agent_Source_CIPD v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCipd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipd() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD ensureCipd() => $_ensure(0);
}

class BuildInfra_Buildbucket_Agent_Input extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Input() => create();
  BuildInfra_Buildbucket_Agent_Input._() : super();
  factory BuildInfra_Buildbucket_Agent_Input.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Input.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, InputDataRef>(1, _omitFieldNames ? '' : 'data',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Input.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: InputDataRef.create,
        valueDefaultOrMaker: InputDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input clone() => BuildInfra_Buildbucket_Agent_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input copyWith(void Function(BuildInfra_Buildbucket_Agent_Input) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Input))
          as BuildInfra_Buildbucket_Agent_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input create() => BuildInfra_Buildbucket_Agent_Input._();
  BuildInfra_Buildbucket_Agent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Input> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Input>(create);
  static BuildInfra_Buildbucket_Agent_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, InputDataRef> get data => $_getMap(0);
}

class BuildInfra_Buildbucket_Agent_Output extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Output() => create();
  BuildInfra_Buildbucket_Agent_Output._() : super();
  factory BuildInfra_Buildbucket_Agent_Output.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Output.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Output',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, ResolvedDataRef>(1, _omitFieldNames ? '' : 'resolvedData',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Output.ResolvedDataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ResolvedDataRef.create,
        valueDefaultOrMaker: ResolvedDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..e<$3.Status>(2, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<$3.StatusDetails>(3, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(4, _omitFieldNames ? '' : 'summaryHtml')
    ..aOS(5, _omitFieldNames ? '' : 'agentPlatform')
    ..aOM<$4.Duration>(6, _omitFieldNames ? '' : 'totalDuration', subBuilder: $4.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output clone() => BuildInfra_Buildbucket_Agent_Output()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output copyWith(void Function(BuildInfra_Buildbucket_Agent_Output) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Output))
          as BuildInfra_Buildbucket_Agent_Output;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output create() => BuildInfra_Buildbucket_Agent_Output._();
  BuildInfra_Buildbucket_Agent_Output createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Output> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Output>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Output>(create);
  static BuildInfra_Buildbucket_Agent_Output? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, ResolvedDataRef> get resolvedData => $_getMap(0);

  @$pb.TagNumber(2)
  $3.Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($3.Status v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $3.StatusDetails get statusDetails => $_getN(2);
  @$pb.TagNumber(3)
  set statusDetails($3.StatusDetails v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusDetails() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusDetails() => clearField(3);
  @$pb.TagNumber(3)
  $3.StatusDetails ensureStatusDetails() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get summaryHtml => $_getSZ(3);
  @$pb.TagNumber(4)
  set summaryHtml($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasSummaryHtml() => $_has(3);
  @$pb.TagNumber(4)
  void clearSummaryHtml() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get agentPlatform => $_getSZ(4);
  @$pb.TagNumber(5)
  set agentPlatform($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAgentPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearAgentPlatform() => clearField(5);

  @$pb.TagNumber(6)
  $4.Duration get totalDuration => $_getN(5);
  @$pb.TagNumber(6)
  set totalDuration($4.Duration v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTotalDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalDuration() => clearField(6);
  @$pb.TagNumber(6)
  $4.Duration ensureTotalDuration() => $_ensure(5);
}

class BuildInfra_Buildbucket_Agent extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent() => create();
  BuildInfra_Buildbucket_Agent._() : super();
  factory BuildInfra_Buildbucket_Agent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket_Agent_Input>(1, _omitFieldNames ? '' : 'input',
        subBuilder: BuildInfra_Buildbucket_Agent_Input.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Output>(2, _omitFieldNames ? '' : 'output',
        subBuilder: BuildInfra_Buildbucket_Agent_Output.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Source>(3, _omitFieldNames ? '' : 'source',
        subBuilder: BuildInfra_Buildbucket_Agent_Source.create)
    ..m<$core.String, BuildInfra_Buildbucket_Agent_Purpose>(4, _omitFieldNames ? '' : 'purposes',
        entryClassName: 'BuildInfra.Buildbucket.Agent.PurposesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OE,
        valueOf: BuildInfra_Buildbucket_Agent_Purpose.valueOf,
        enumValues: BuildInfra_Buildbucket_Agent_Purpose.values,
        valueDefaultOrMaker: BuildInfra_Buildbucket_Agent_Purpose.PURPOSE_UNSPECIFIED,
        defaultEnumValue: BuildInfra_Buildbucket_Agent_Purpose.PURPOSE_UNSPECIFIED,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent clone() => BuildInfra_Buildbucket_Agent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent copyWith(void Function(BuildInfra_Buildbucket_Agent) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent)) as BuildInfra_Buildbucket_Agent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent create() => BuildInfra_Buildbucket_Agent._();
  BuildInfra_Buildbucket_Agent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent>(create);
  static BuildInfra_Buildbucket_Agent? _defaultInstance;

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input get input => $_getN(0);
  @$pb.TagNumber(1)
  set input(BuildInfra_Buildbucket_Agent_Input v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInput() => $_has(0);
  @$pb.TagNumber(1)
  void clearInput() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input ensureInput() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output get output => $_getN(1);
  @$pb.TagNumber(2)
  set output(BuildInfra_Buildbucket_Agent_Output v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output ensureOutput() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_Buildbucket_Agent_Source get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(BuildInfra_Buildbucket_Agent_Source v) {
    setField(3, v);
  }

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
  factory BuildInfra_Buildbucket() => create();
  BuildInfra_Buildbucket._() : super();
  factory BuildInfra_Buildbucket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'serviceConfigRevision')
    ..aOM<$5.Struct>(5, _omitFieldNames ? '' : 'requestedProperties', subBuilder: $5.Struct.create)
    ..pc<$3.RequestedDimension>(6, _omitFieldNames ? '' : 'requestedDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..aOS(7, _omitFieldNames ? '' : 'hostname')
    ..m<$core.String, BuildInfra_Buildbucket_ExperimentReason>(8, _omitFieldNames ? '' : 'experimentReasons',
        entryClassName: 'BuildInfra.Buildbucket.ExperimentReasonsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OE,
        valueOf: BuildInfra_Buildbucket_ExperimentReason.valueOf,
        enumValues: BuildInfra_Buildbucket_ExperimentReason.values,
        valueDefaultOrMaker: BuildInfra_Buildbucket_ExperimentReason.EXPERIMENT_REASON_UNSET,
        defaultEnumValue: BuildInfra_Buildbucket_ExperimentReason.EXPERIMENT_REASON_UNSET,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, ResolvedDataRef>(9, _omitFieldNames ? '' : 'agentExecutable',
        entryClassName: 'BuildInfra.Buildbucket.AgentExecutableEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ResolvedDataRef.create,
        valueDefaultOrMaker: ResolvedDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<BuildInfra_Buildbucket_Agent>(10, _omitFieldNames ? '' : 'agent',
        subBuilder: BuildInfra_Buildbucket_Agent.create)
    ..pPS(11, _omitFieldNames ? '' : 'knownPublicGerritHosts')
    ..aOB(12, _omitFieldNames ? '' : 'buildNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket clone() => BuildInfra_Buildbucket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket copyWith(void Function(BuildInfra_Buildbucket) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket)) as BuildInfra_Buildbucket;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket create() => BuildInfra_Buildbucket._();
  BuildInfra_Buildbucket createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket> createRepeated() => $pb.PbList<BuildInfra_Buildbucket>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket>(create);
  static BuildInfra_Buildbucket? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get serviceConfigRevision => $_getSZ(0);
  @$pb.TagNumber(2)
  set serviceConfigRevision($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasServiceConfigRevision() => $_has(0);
  @$pb.TagNumber(2)
  void clearServiceConfigRevision() => clearField(2);

  @$pb.TagNumber(5)
  $5.Struct get requestedProperties => $_getN(1);
  @$pb.TagNumber(5)
  set requestedProperties($5.Struct v) {
    setField(5, v);
  }

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
  set hostname($core.String v) {
    $_setString(3, v);
  }

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
  set agent(BuildInfra_Buildbucket_Agent v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasAgent() => $_has(6);
  @$pb.TagNumber(10)
  void clearAgent() => clearField(10);
  @$pb.TagNumber(10)
  BuildInfra_Buildbucket_Agent ensureAgent() => $_ensure(6);

  @$pb.TagNumber(11)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(7);

  @$pb.TagNumber(12)
  $core.bool get buildNumber => $_getBF(8);
  @$pb.TagNumber(12)
  set buildNumber($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasBuildNumber() => $_has(8);
  @$pb.TagNumber(12)
  void clearBuildNumber() => clearField(12);
}

class BuildInfra_Swarming_CacheEntry extends $pb.GeneratedMessage {
  factory BuildInfra_Swarming_CacheEntry() => create();
  BuildInfra_Swarming_CacheEntry._() : super();
  factory BuildInfra_Swarming_CacheEntry.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming_CacheEntry.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Swarming.CacheEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<$4.Duration>(3, _omitFieldNames ? '' : 'waitForWarmCache', subBuilder: $4.Duration.create)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry clone() => BuildInfra_Swarming_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry copyWith(void Function(BuildInfra_Swarming_CacheEntry) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Swarming_CacheEntry)) as BuildInfra_Swarming_CacheEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry create() => BuildInfra_Swarming_CacheEntry._();
  BuildInfra_Swarming_CacheEntry createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming_CacheEntry> createRepeated() => $pb.PbList<BuildInfra_Swarming_CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming_CacheEntry>(create);
  static BuildInfra_Swarming_CacheEntry? _defaultInstance;

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
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  @$pb.TagNumber(3)
  $4.Duration get waitForWarmCache => $_getN(2);
  @$pb.TagNumber(3)
  set waitForWarmCache($4.Duration v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCache() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCache() => clearField(3);
  @$pb.TagNumber(3)
  $4.Duration ensureWaitForWarmCache() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.String get envVar => $_getSZ(3);
  @$pb.TagNumber(4)
  set envVar($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEnvVar() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnvVar() => clearField(4);
}

class BuildInfra_Swarming extends $pb.GeneratedMessage {
  factory BuildInfra_Swarming() => create();
  BuildInfra_Swarming._() : super();
  factory BuildInfra_Swarming.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Swarming',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'taskServiceAccount')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.O3)
    ..pc<$3.RequestedDimension>(5, _omitFieldNames ? '' : 'taskDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..pc<$3.StringPair>(6, _omitFieldNames ? '' : 'botDimensions', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..pc<BuildInfra_Swarming_CacheEntry>(7, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM,
        subBuilder: BuildInfra_Swarming_CacheEntry.create)
    ..aOS(9, _omitFieldNames ? '' : 'parentRunId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming clone() => BuildInfra_Swarming()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming copyWith(void Function(BuildInfra_Swarming) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Swarming)) as BuildInfra_Swarming;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming create() => BuildInfra_Swarming._();
  BuildInfra_Swarming createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming> createRepeated() => $pb.PbList<BuildInfra_Swarming>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming>(create);
  static BuildInfra_Swarming? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get taskServiceAccount => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskServiceAccount($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTaskServiceAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskServiceAccount() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get priority => $_getIZ(3);
  @$pb.TagNumber(4)
  set priority($core.int v) {
    $_setSignedInt32(3, v);
  }

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
  set parentRunId($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasParentRunId() => $_has(7);
  @$pb.TagNumber(9)
  void clearParentRunId() => clearField(9);
}

class BuildInfra_LogDog extends $pb.GeneratedMessage {
  factory BuildInfra_LogDog() => create();
  BuildInfra_LogDog._() : super();
  factory BuildInfra_LogDog.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_LogDog.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.LogDog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'prefix')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_LogDog clone() => BuildInfra_LogDog()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_LogDog copyWith(void Function(BuildInfra_LogDog) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_LogDog)) as BuildInfra_LogDog;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog create() => BuildInfra_LogDog._();
  BuildInfra_LogDog createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_LogDog> createRepeated() => $pb.PbList<BuildInfra_LogDog>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_LogDog>(create);
  static BuildInfra_LogDog? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get prefix => $_getSZ(2);
  @$pb.TagNumber(3)
  set prefix($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPrefix() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrefix() => clearField(3);
}

class BuildInfra_Recipe extends $pb.GeneratedMessage {
  factory BuildInfra_Recipe() => create();
  BuildInfra_Recipe._() : super();
  factory BuildInfra_Recipe.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Recipe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cipdPackage')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Recipe clone() => BuildInfra_Recipe()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Recipe copyWith(void Function(BuildInfra_Recipe) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Recipe)) as BuildInfra_Recipe;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe create() => BuildInfra_Recipe._();
  BuildInfra_Recipe createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Recipe> createRepeated() => $pb.PbList<BuildInfra_Recipe>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Recipe>(create);
  static BuildInfra_Recipe? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cipdPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set cipdPackage($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCipdPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipdPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

class BuildInfra_ResultDB extends $pb.GeneratedMessage {
  factory BuildInfra_ResultDB() => create();
  BuildInfra_ResultDB._() : super();
  factory BuildInfra_ResultDB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.ResultDB',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'invocation')
    ..aOB(3, _omitFieldNames ? '' : 'enable')
    ..pc<$6.BigQueryExport>(4, _omitFieldNames ? '' : 'bqExports', $pb.PbFieldType.PM,
        subBuilder: $6.BigQueryExport.create)
    ..aOM<$6.HistoryOptions>(5, _omitFieldNames ? '' : 'historyOptions', subBuilder: $6.HistoryOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_ResultDB clone() => BuildInfra_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_ResultDB copyWith(void Function(BuildInfra_ResultDB) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_ResultDB)) as BuildInfra_ResultDB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB create() => BuildInfra_ResultDB._();
  BuildInfra_ResultDB createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_ResultDB> createRepeated() => $pb.PbList<BuildInfra_ResultDB>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_ResultDB>(create);
  static BuildInfra_ResultDB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get invocation => $_getSZ(1);
  @$pb.TagNumber(2)
  set invocation($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInvocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearInvocation() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get enable => $_getBF(2);
  @$pb.TagNumber(3)
  set enable($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEnable() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnable() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$6.BigQueryExport> get bqExports => $_getList(3);

  @$pb.TagNumber(5)
  $6.HistoryOptions get historyOptions => $_getN(4);
  @$pb.TagNumber(5)
  set historyOptions($6.HistoryOptions v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasHistoryOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearHistoryOptions() => clearField(5);
  @$pb.TagNumber(5)
  $6.HistoryOptions ensureHistoryOptions() => $_ensure(4);
}

class BuildInfra_BBAgent_Input_CIPDPackage extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent_Input_CIPDPackage() => create();
  BuildInfra_BBAgent_Input_CIPDPackage._() : super();
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent.Input.CIPDPackage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'server')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage clone() => BuildInfra_BBAgent_Input_CIPDPackage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage copyWith(void Function(BuildInfra_BBAgent_Input_CIPDPackage) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input_CIPDPackage))
          as BuildInfra_BBAgent_Input_CIPDPackage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage create() => BuildInfra_BBAgent_Input_CIPDPackage._();
  BuildInfra_BBAgent_Input_CIPDPackage createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage> createRepeated() =>
      $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input_CIPDPackage>(create);
  static BuildInfra_BBAgent_Input_CIPDPackage? _defaultInstance;

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
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => clearField(4);
}

class BuildInfra_BBAgent_Input extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent_Input() => create();
  BuildInfra_BBAgent_Input._() : super();
  factory BuildInfra_BBAgent_Input.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<BuildInfra_BBAgent_Input_CIPDPackage>(1, _omitFieldNames ? '' : 'cipdPackages', $pb.PbFieldType.PM,
        subBuilder: BuildInfra_BBAgent_Input_CIPDPackage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input clone() => BuildInfra_BBAgent_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input copyWith(void Function(BuildInfra_BBAgent_Input) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input)) as BuildInfra_BBAgent_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input create() => BuildInfra_BBAgent_Input._();
  BuildInfra_BBAgent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input> createRepeated() => $pb.PbList<BuildInfra_BBAgent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input>(create);
  static BuildInfra_BBAgent_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BuildInfra_BBAgent_Input_CIPDPackage> get cipdPackages => $_getList(0);
}

class BuildInfra_BBAgent extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent() => create();
  BuildInfra_BBAgent._() : super();
  factory BuildInfra_BBAgent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'payloadPath')
    ..aOS(2, _omitFieldNames ? '' : 'cacheDir')
    ..pPS(3, _omitFieldNames ? '' : 'knownPublicGerritHosts')
    ..aOM<BuildInfra_BBAgent_Input>(4, _omitFieldNames ? '' : 'input', subBuilder: BuildInfra_BBAgent_Input.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent clone() => BuildInfra_BBAgent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent copyWith(void Function(BuildInfra_BBAgent) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent)) as BuildInfra_BBAgent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent create() => BuildInfra_BBAgent._();
  BuildInfra_BBAgent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent> createRepeated() => $pb.PbList<BuildInfra_BBAgent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent>(create);
  static BuildInfra_BBAgent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get payloadPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set payloadPath($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPayloadPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayloadPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get cacheDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set cacheDir($core.String v) {
    $_setString(1, v);
  }

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
  set input(BuildInfra_BBAgent_Input v) {
    setField(4, v);
  }

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
  factory BuildInfra_Backend() => create();
  BuildInfra_Backend._() : super();
  factory BuildInfra_Backend.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Backend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'config', subBuilder: $5.Struct.create)
    ..aOM<$7.Task>(2, _omitFieldNames ? '' : 'task', subBuilder: $7.Task.create)
    ..pc<$3.CacheEntry>(3, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM, subBuilder: $3.CacheEntry.create)
    ..pc<$3.RequestedDimension>(5, _omitFieldNames ? '' : 'taskDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Backend clone() => BuildInfra_Backend()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Backend copyWith(void Function(BuildInfra_Backend) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Backend)) as BuildInfra_Backend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend create() => BuildInfra_Backend._();
  BuildInfra_Backend createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Backend> createRepeated() => $pb.PbList<BuildInfra_Backend>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Backend>(create);
  static BuildInfra_Backend? _defaultInstance;

  @$pb.TagNumber(1)
  $5.Struct get config => $_getN(0);
  @$pb.TagNumber(1)
  set config($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureConfig() => $_ensure(0);

  @$pb.TagNumber(2)
  $7.Task get task => $_getN(1);
  @$pb.TagNumber(2)
  set task($7.Task v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTask() => $_has(1);
  @$pb.TagNumber(2)
  void clearTask() => clearField(2);
  @$pb.TagNumber(2)
  $7.Task ensureTask() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<$3.CacheEntry> get caches => $_getList(2);

  @$pb.TagNumber(5)
  $core.List<$3.RequestedDimension> get taskDimensions => $_getList(3);
}

class BuildInfra extends $pb.GeneratedMessage {
  factory BuildInfra() => create();
  BuildInfra._() : super();
  factory BuildInfra.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket>(1, _omitFieldNames ? '' : 'buildbucket', subBuilder: BuildInfra_Buildbucket.create)
    ..aOM<BuildInfra_Swarming>(2, _omitFieldNames ? '' : 'swarming', subBuilder: BuildInfra_Swarming.create)
    ..aOM<BuildInfra_LogDog>(3, _omitFieldNames ? '' : 'logdog', subBuilder: BuildInfra_LogDog.create)
    ..aOM<BuildInfra_Recipe>(4, _omitFieldNames ? '' : 'recipe', subBuilder: BuildInfra_Recipe.create)
    ..aOM<BuildInfra_ResultDB>(5, _omitFieldNames ? '' : 'resultdb', subBuilder: BuildInfra_ResultDB.create)
    ..aOM<BuildInfra_BBAgent>(6, _omitFieldNames ? '' : 'bbagent', subBuilder: BuildInfra_BBAgent.create)
    ..aOM<BuildInfra_Backend>(7, _omitFieldNames ? '' : 'backend', subBuilder: BuildInfra_Backend.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra clone() => BuildInfra()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra copyWith(void Function(BuildInfra) updates) =>
      super.copyWith((message) => updates(message as BuildInfra)) as BuildInfra;

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
  set buildbucket(BuildInfra_Buildbucket v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildbucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildbucket() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket ensureBuildbucket() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Swarming get swarming => $_getN(1);
  @$pb.TagNumber(2)
  set swarming(BuildInfra_Swarming v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSwarming() => $_has(1);
  @$pb.TagNumber(2)
  void clearSwarming() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Swarming ensureSwarming() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_LogDog get logdog => $_getN(2);
  @$pb.TagNumber(3)
  set logdog(BuildInfra_LogDog v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLogdog() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogdog() => clearField(3);
  @$pb.TagNumber(3)
  BuildInfra_LogDog ensureLogdog() => $_ensure(2);

  @$pb.TagNumber(4)
  BuildInfra_Recipe get recipe => $_getN(3);
  @$pb.TagNumber(4)
  set recipe(BuildInfra_Recipe v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRecipe() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipe() => clearField(4);
  @$pb.TagNumber(4)
  BuildInfra_Recipe ensureRecipe() => $_ensure(3);

  @$pb.TagNumber(5)
  BuildInfra_ResultDB get resultdb => $_getN(4);
  @$pb.TagNumber(5)
  set resultdb(BuildInfra_ResultDB v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasResultdb() => $_has(4);
  @$pb.TagNumber(5)
  void clearResultdb() => clearField(5);
  @$pb.TagNumber(5)
  BuildInfra_ResultDB ensureResultdb() => $_ensure(4);

  @$pb.TagNumber(6)
  BuildInfra_BBAgent get bbagent => $_getN(5);
  @$pb.TagNumber(6)
  set bbagent(BuildInfra_BBAgent v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasBbagent() => $_has(5);
  @$pb.TagNumber(6)
  void clearBbagent() => clearField(6);
  @$pb.TagNumber(6)
  BuildInfra_BBAgent ensureBbagent() => $_ensure(5);

  @$pb.TagNumber(7)
  BuildInfra_Backend get backend => $_getN(6);
  @$pb.TagNumber(7)
  set backend(BuildInfra_Backend v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBackend() => $_has(6);
  @$pb.TagNumber(7)
  void clearBackend() => clearField(7);
  @$pb.TagNumber(7)
  BuildInfra_Backend ensureBackend() => $_ensure(6);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
