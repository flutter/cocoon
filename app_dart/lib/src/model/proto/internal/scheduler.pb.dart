//
//  Generated code. Do not modify.
//  source: internal/scheduler.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'scheduler.pbenum.dart';

export 'scheduler.pbenum.dart';

/// Next ID: 3
class SchedulerConfig_PlatformProperties extends $pb.GeneratedMessage {
  factory SchedulerConfig_PlatformProperties({
    $core.Map<$core.String, $core.String>? properties,
    $core.Map<$core.String, $core.String>? dimensions,
  }) {
    final $result = create();
    if (properties != null) {
      $result.properties.addAll(properties);
    }
    if (dimensions != null) {
      $result.dimensions.addAll(dimensions);
    }
    return $result;
  }
  SchedulerConfig_PlatformProperties._() : super();
  factory SchedulerConfig_PlatformProperties.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SchedulerConfig_PlatformProperties.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SchedulerConfig.PlatformProperties',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'scheduler'), createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'properties',
        entryClassName: 'SchedulerConfig.PlatformProperties.PropertiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('scheduler'))
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'dimensions',
        entryClassName: 'SchedulerConfig.PlatformProperties.DimensionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('scheduler'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SchedulerConfig_PlatformProperties clone() => SchedulerConfig_PlatformProperties()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SchedulerConfig_PlatformProperties copyWith(void Function(SchedulerConfig_PlatformProperties) updates) =>
      super.copyWith((message) => updates(message as SchedulerConfig_PlatformProperties))
          as SchedulerConfig_PlatformProperties;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchedulerConfig_PlatformProperties create() => SchedulerConfig_PlatformProperties._();
  SchedulerConfig_PlatformProperties createEmptyInstance() => create();
  static $pb.PbList<SchedulerConfig_PlatformProperties> createRepeated() =>
      $pb.PbList<SchedulerConfig_PlatformProperties>();
  @$core.pragma('dart2js:noInline')
  static SchedulerConfig_PlatformProperties getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SchedulerConfig_PlatformProperties>(create);
  static SchedulerConfig_PlatformProperties? _defaultInstance;

  /// Generic key, value pairs to set platform-wide properties
  @$pb.TagNumber(1)
  $core.Map<$core.String, $core.String> get properties => $_getMap(0);

  /// Generic key, value pairs to set platform-wide dimensions
  /// Doc for dimension and properties: https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/appengine/swarming/doc/User-Guide.md
  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get dimensions => $_getMap(1);
}

/// Model of .ci.yaml.
/// Next ID: 4
class SchedulerConfig extends $pb.GeneratedMessage {
  factory SchedulerConfig({
    $core.Iterable<Target>? targets,
    $core.Iterable<$core.String>? enabledBranches,
    $core.Map<$core.String, SchedulerConfig_PlatformProperties>? platformProperties,
  }) {
    final $result = create();
    if (targets != null) {
      $result.targets.addAll(targets);
    }
    if (enabledBranches != null) {
      $result.enabledBranches.addAll(enabledBranches);
    }
    if (platformProperties != null) {
      $result.platformProperties.addAll(platformProperties);
    }
    return $result;
  }
  SchedulerConfig._() : super();
  factory SchedulerConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SchedulerConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SchedulerConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'scheduler'), createEmptyInstance: create)
    ..pc<Target>(1, _omitFieldNames ? '' : 'targets', $pb.PbFieldType.PM, subBuilder: Target.create)
    ..pPS(2, _omitFieldNames ? '' : 'enabledBranches')
    ..m<$core.String, SchedulerConfig_PlatformProperties>(3, _omitFieldNames ? '' : 'platformProperties',
        entryClassName: 'SchedulerConfig.PlatformPropertiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: SchedulerConfig_PlatformProperties.create,
        valueDefaultOrMaker: SchedulerConfig_PlatformProperties.getDefault,
        packageName: const $pb.PackageName('scheduler'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SchedulerConfig clone() => SchedulerConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SchedulerConfig copyWith(void Function(SchedulerConfig) updates) =>
      super.copyWith((message) => updates(message as SchedulerConfig)) as SchedulerConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SchedulerConfig create() => SchedulerConfig._();
  SchedulerConfig createEmptyInstance() => create();
  static $pb.PbList<SchedulerConfig> createRepeated() => $pb.PbList<SchedulerConfig>();
  @$core.pragma('dart2js:noInline')
  static SchedulerConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SchedulerConfig>(create);
  static SchedulerConfig? _defaultInstance;

  /// Targets to run from this config.
  @$pb.TagNumber(1)
  $core.List<Target> get targets => $_getList(0);

  /// Git branches to run these targets against.
  @$pb.TagNumber(2)
  $core.List<$core.String> get enabledBranches => $_getList(1);

  /// Universal platform args passed to LUCI builders.
  /// Keys are the platforms and values are the PlatformProperties (properties, dimensions etc.).
  @$pb.TagNumber(3)
  $core.Map<$core.String, SchedulerConfig_PlatformProperties> get platformProperties => $_getMap(2);
}

/// A unit of work for infrastructure to run.
/// Next ID: 17
class Target extends $pb.GeneratedMessage {
  factory Target({
    $core.String? name,
    $core.Iterable<$core.String>? dependencies,
    $core.bool? bringup,
    $core.int? timeout,
    $core.String? testbed,
    $core.Map<$core.String, $core.String>? properties,
    @$core.Deprecated('This field is deprecated.') $core.String? builder,
    SchedulerSystem? scheduler,
    $core.bool? presubmit,
    $core.bool? postsubmit,
    $core.Iterable<$core.String>? runIf,
    $core.Iterable<$core.String>? enabledBranches,
    $core.String? recipe,
    $core.Map<$core.String, $core.String>? postsubmitProperties,
    $core.Map<$core.String, $core.String>? dimensions,
    $core.Iterable<$core.String>? droneDimensions,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (dependencies != null) {
      $result.dependencies.addAll(dependencies);
    }
    if (bringup != null) {
      $result.bringup = bringup;
    }
    if (timeout != null) {
      $result.timeout = timeout;
    }
    if (testbed != null) {
      $result.testbed = testbed;
    }
    if (properties != null) {
      $result.properties.addAll(properties);
    }
    if (builder != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.builder = builder;
    }
    if (scheduler != null) {
      $result.scheduler = scheduler;
    }
    if (presubmit != null) {
      $result.presubmit = presubmit;
    }
    if (postsubmit != null) {
      $result.postsubmit = postsubmit;
    }
    if (runIf != null) {
      $result.runIf.addAll(runIf);
    }
    if (enabledBranches != null) {
      $result.enabledBranches.addAll(enabledBranches);
    }
    if (recipe != null) {
      $result.recipe = recipe;
    }
    if (postsubmitProperties != null) {
      $result.postsubmitProperties.addAll(postsubmitProperties);
    }
    if (dimensions != null) {
      $result.dimensions.addAll(dimensions);
    }
    if (droneDimensions != null) {
      $result.droneDimensions.addAll(droneDimensions);
    }
    return $result;
  }
  Target._() : super();
  factory Target.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Target.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Target',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'scheduler'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'dependencies')
    ..aOB(3, _omitFieldNames ? '' : 'bringup')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'timeout', $pb.PbFieldType.O3, defaultOrMaker: 30)
    ..a<$core.String>(5, _omitFieldNames ? '' : 'testbed', $pb.PbFieldType.OS, defaultOrMaker: 'linux-vm')
    ..m<$core.String, $core.String>(6, _omitFieldNames ? '' : 'properties',
        entryClassName: 'Target.PropertiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('scheduler'))
    ..aOS(7, _omitFieldNames ? '' : 'builder')
    ..e<SchedulerSystem>(8, _omitFieldNames ? '' : 'scheduler', $pb.PbFieldType.OE,
        defaultOrMaker: SchedulerSystem.cocoon, valueOf: SchedulerSystem.valueOf, enumValues: SchedulerSystem.values)
    ..a<$core.bool>(9, _omitFieldNames ? '' : 'presubmit', $pb.PbFieldType.OB, defaultOrMaker: true)
    ..a<$core.bool>(10, _omitFieldNames ? '' : 'postsubmit', $pb.PbFieldType.OB, defaultOrMaker: true)
    ..pPS(11, _omitFieldNames ? '' : 'runIf')
    ..pPS(12, _omitFieldNames ? '' : 'enabledBranches')
    ..aOS(13, _omitFieldNames ? '' : 'recipe')
    ..m<$core.String, $core.String>(15, _omitFieldNames ? '' : 'postsubmitProperties',
        entryClassName: 'Target.PostsubmitPropertiesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('scheduler'))
    ..m<$core.String, $core.String>(16, _omitFieldNames ? '' : 'dimensions',
        entryClassName: 'Target.DimensionsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('scheduler'))
    ..pPS(17, _omitFieldNames ? '' : 'droneDimensions')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Target clone() => Target()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Target copyWith(void Function(Target) updates) => super.copyWith((message) => updates(message as Target)) as Target;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Target create() => Target._();
  Target createEmptyInstance() => create();
  static $pb.PbList<Target> createRepeated() => $pb.PbList<Target>();
  @$core.pragma('dart2js:noInline')
  static Target getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Target>(create);
  static Target? _defaultInstance;

  /// Unique, human readable identifier.
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

  /// Names of other targets required to succeed before triggering this target.
  @$pb.TagNumber(2)
  $core.List<$core.String> get dependencies => $_getList(1);

  /// Whether this target is stable and can be used to gate commits.
  /// Defaults to false which blocks builds and does not run in presubmit.
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

  /// Number of minutes this target is allowed to run before being marked as failed.
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

  /// Name of the testbed this target will run on.
  /// Defaults to a linux vm.
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

  /// Properties to configure infrastructure tooling.
  @$pb.TagNumber(6)
  $core.Map<$core.String, $core.String> get properties => $_getMap(5);

  /// Name of the LUCI builder to trigger.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(7)
  $core.String get builder => $_getSZ(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(7)
  set builder($core.String v) {
    $_setString(6, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(7)
  $core.bool hasBuilder() => $_has(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(7)
  void clearBuilder() => clearField(7);

  /// Name of the scheduler to trigger this target.
  /// Defaults to being triggered by cocoon.
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

  /// Whether target should run pre-submit. Defaults to true, will run in presubmit.
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

  /// Whether target should run post-submit. Defaults to true, will run in postsubmit.
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

  /// List of paths that trigger this target in presubmit when there is a diff.
  /// If no paths are given, it will always run.
  @$pb.TagNumber(11)
  $core.List<$core.String> get runIf => $_getList(10);

  /// Override of enabled_branches for this target (for release targets).
  @$pb.TagNumber(12)
  $core.List<$core.String> get enabledBranches => $_getList(11);

  /// Name of the LUCI recipe to use for the builder.
  @$pb.TagNumber(13)
  $core.String get recipe => $_getSZ(12);
  @$pb.TagNumber(13)
  set recipe($core.String v) {
    $_setString(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasRecipe() => $_has(12);
  @$pb.TagNumber(13)
  void clearRecipe() => clearField(13);

  /// Properties to configure infrastructure tooling for only postsubmit runs.
  @$pb.TagNumber(15)
  $core.Map<$core.String, $core.String> get postsubmitProperties => $_getMap(13);

  /// Dimensions to configure swarming dimensions of LUCI builds.
  @$pb.TagNumber(16)
  $core.Map<$core.String, $core.String> get dimensions => $_getMap(14);

  /// Dimensions used when this build runs within a drone.
  @$pb.TagNumber(17)
  $core.List<$core.String> get droneDimensions => $_getList(15);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
