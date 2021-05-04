///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/scheduler.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'scheduler.pbenum.dart';

export 'scheduler.pbenum.dart';

class SchedulerConfig extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'SchedulerConfig',
      createEmptyInstance: create)
    ..pc<Target>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'targets', $pb.PbFieldType.PM,
        subBuilder: Target.create)
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enabledBranches')
    ..hasRequiredFields = false;

  SchedulerConfig._() : super();
  factory SchedulerConfig({
    $core.Iterable<Target> targets,
    $core.Iterable<$core.String> enabledBranches,
  }) {
    final _result = create();
    if (targets != null) {
      _result.targets.addAll(targets);
    }
    if (enabledBranches != null) {
      _result.enabledBranches.addAll(enabledBranches);
    }
    return _result;
  }
  factory SchedulerConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SchedulerConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SchedulerConfig clone() => SchedulerConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SchedulerConfig copyWith(void Function(SchedulerConfig) updates) =>
      super.copyWith((message) => updates(message as SchedulerConfig)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static SchedulerConfig create() => SchedulerConfig._();
  SchedulerConfig createEmptyInstance() => create();
  static $pb.PbList<SchedulerConfig> createRepeated() => $pb.PbList<SchedulerConfig>();
  @$core.pragma('dart2js:noInline')
  static SchedulerConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SchedulerConfig>(create);
  static SchedulerConfig _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Target> get targets => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get enabledBranches => $_getList(1);
}

class Target extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Target',
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dependencies')
    ..aOB(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bringup')
    ..a<$core.int>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'timeout', $pb.PbFieldType.O3,
        defaultOrMaker: 30)
    ..a<$core.String>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'testbed', $pb.PbFieldType.OS,
        defaultOrMaker: 'linux-vm')
    ..m<$core.String, $core.String>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'properties',
        entryClassName: 'Target.PropertiesEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'builder')
    ..e<SchedulerSystem>(
        8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'scheduler', $pb.PbFieldType.OE,
        defaultOrMaker: SchedulerSystem.cocoon, valueOf: SchedulerSystem.valueOf, enumValues: SchedulerSystem.values)
    ..a<$core.bool>(
        9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'presubmit', $pb.PbFieldType.OB,
        defaultOrMaker: true)
    ..a<$core.bool>(
        10, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'postsubmit', $pb.PbFieldType.OB,
        defaultOrMaker: true)
    ..pPS(11, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'runIf')
    ..hasRequiredFields = false;

  Target._() : super();
  factory Target({
    $core.String name,
    $core.Iterable<$core.String> dependencies,
    $core.bool bringup,
    $core.int timeout,
    $core.String testbed,
    $core.Map<$core.String, $core.String> properties,
    $core.String builder,
    SchedulerSystem scheduler,
    $core.bool presubmit,
    $core.bool postsubmit,
    $core.Iterable<$core.String> runIf,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (dependencies != null) {
      _result.dependencies.addAll(dependencies);
    }
    if (bringup != null) {
      _result.bringup = bringup;
    }
    if (timeout != null) {
      _result.timeout = timeout;
    }
    if (testbed != null) {
      _result.testbed = testbed;
    }
    if (properties != null) {
      _result.properties.addAll(properties);
    }
    if (builder != null) {
      _result.builder = builder;
    }
    if (scheduler != null) {
      _result.scheduler = scheduler;
    }
    if (presubmit != null) {
      _result.presubmit = presubmit;
    }
    if (postsubmit != null) {
      _result.postsubmit = postsubmit;
    }
    if (runIf != null) {
      _result.runIf.addAll(runIf);
    }
    return _result;
  }
  factory Target.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Target.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Target clone() => Target()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Target copyWith(void Function(Target) updates) =>
      super.copyWith((message) => updates(message as Target)); // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Target create() => Target._();
  Target createEmptyInstance() => create();
  static $pb.PbList<Target> createRepeated() => $pb.PbList<Target>();
  @$core.pragma('dart2js:noInline')
  static Target getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Target>(create);
  static Target _defaultInstance;

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
  $core.List<$core.String> get dependencies => $_getList(1);

  @$pb.TagNumber(3)
  $core.bool get bringup => $_getBF(2);
  @$pb.TagNumber(3)
  set bringup($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBringup() => $_has(2);
  @$pb.TagNumber(3)
  void clearBringup() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get timeout => $_getI(3, 30);
  @$pb.TagNumber(4)
  set timeout($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTimeout() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimeout() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get testbed => $_getS(4, 'linux-vm');
  @$pb.TagNumber(5)
  set testbed($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTestbed() => $_has(4);
  @$pb.TagNumber(5)
  void clearTestbed() => clearField(5);

  @$pb.TagNumber(6)
  $core.Map<$core.String, $core.String> get properties => $_getMap(5);

  @$pb.TagNumber(7)
  $core.String get builder => $_getSZ(6);
  @$pb.TagNumber(7)
  set builder($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBuilder() => $_has(6);
  @$pb.TagNumber(7)
  void clearBuilder() => clearField(7);

  @$pb.TagNumber(8)
  SchedulerSystem get scheduler => $_getN(7);
  @$pb.TagNumber(8)
  set scheduler(SchedulerSystem v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasScheduler() => $_has(7);
  @$pb.TagNumber(8)
  void clearScheduler() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get presubmit => $_getB(8, true);
  @$pb.TagNumber(9)
  set presubmit($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasPresubmit() => $_has(8);
  @$pb.TagNumber(9)
  void clearPresubmit() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get postsubmit => $_getB(9, true);
  @$pb.TagNumber(10)
  set postsubmit($core.bool v) {
    $_setBool(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasPostsubmit() => $_has(9);
  @$pb.TagNumber(10)
  void clearPostsubmit() => clearField(10);

  @$pb.TagNumber(11)
  $core.List<$core.String> get runIf => $_getList(10);
}
