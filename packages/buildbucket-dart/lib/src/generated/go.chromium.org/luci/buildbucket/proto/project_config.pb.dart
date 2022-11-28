///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/wrappers.pb.dart' as $0;
import 'common.pb.dart' as $1;
import '../../../../google/protobuf/duration.pb.dart' as $2;
import '../../resultdb/proto/v1/invocation.pb.dart' as $3;

import 'project_config.pbenum.dart';
import 'common.pbenum.dart' as $1;

export 'project_config.pbenum.dart';

class Acl extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Acl', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..e<Acl_Role>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: Acl_Role.READER, valueOf: Acl_Role.valueOf, enumValues: Acl_Role.values)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'group')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'identity')
    ..hasRequiredFields = false
  ;

  Acl._() : super();
  factory Acl({
  @$core.Deprecated('This field is deprecated.')
    Acl_Role? role,
  @$core.Deprecated('This field is deprecated.')
    $core.String? group,
  @$core.Deprecated('This field is deprecated.')
    $core.String? identity,
  }) {
    final _result = create();
    if (role != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.role = role;
    }
    if (group != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.group = group;
    }
    if (identity != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.identity = identity;
    }
    return _result;
  }
  factory Acl.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Acl.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Acl clone() => Acl()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Acl copyWith(void Function(Acl) updates) => super.copyWith((message) => updates(message as Acl)) as Acl; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Acl create() => Acl._();
  Acl createEmptyInstance() => create();
  static $pb.PbList<Acl> createRepeated() => $pb.PbList<Acl>();
  @$core.pragma('dart2js:noInline')
  static Acl getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Acl>(create);
  static Acl? _defaultInstance;

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  Acl_Role get role => $_getN(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  set role(Acl_Role v) { setField(1, v); }
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  $core.bool hasRole() => $_has(0);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(1)
  void clearRole() => clearField(1);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.String get group => $_getSZ(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  set group($core.String v) { $_setString(1, v); }
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.bool hasGroup() => $_has(1);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  void clearGroup() => clearField(2);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.String get identity => $_getSZ(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  set identity($core.String v) { $_setString(2, v); }
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool hasIdentity() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  void clearIdentity() => clearField(3);
}

class BuilderConfig_CacheEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderConfig.CacheEntry', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'path')
    ..a<$core.int>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'waitForWarmCacheSecs', $pb.PbFieldType.O3)
    ..aOS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'envVar')
    ..hasRequiredFields = false
  ;

  BuilderConfig_CacheEntry._() : super();
  factory BuilderConfig_CacheEntry({
    $core.String? name,
    $core.String? path,
    $core.int? waitForWarmCacheSecs,
    $core.String? envVar,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (path != null) {
      _result.path = path;
    }
    if (waitForWarmCacheSecs != null) {
      _result.waitForWarmCacheSecs = waitForWarmCacheSecs;
    }
    if (envVar != null) {
      _result.envVar = envVar;
    }
    return _result;
  }
  factory BuilderConfig_CacheEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_CacheEntry clone() => BuilderConfig_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_CacheEntry copyWith(void Function(BuilderConfig_CacheEntry) updates) => super.copyWith((message) => updates(message as BuilderConfig_CacheEntry)) as BuilderConfig_CacheEntry; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_CacheEntry create() => BuilderConfig_CacheEntry._();
  BuilderConfig_CacheEntry createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_CacheEntry> createRepeated() => $pb.PbList<BuilderConfig_CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_CacheEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_CacheEntry>(create);
  static BuilderConfig_CacheEntry? _defaultInstance;

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
  $core.int get waitForWarmCacheSecs => $_getIZ(2);
  @$pb.TagNumber(3)
  set waitForWarmCacheSecs($core.int v) { $_setSignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCacheSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCacheSecs() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get envVar => $_getSZ(3);
  @$pb.TagNumber(4)
  set envVar($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnvVar() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnvVar() => clearField(4);
}

class BuilderConfig_Recipe extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderConfig.Recipe', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'properties')
    ..pPS(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'propertiesJ')
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipdVersion')
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'cipdPackage')
    ..hasRequiredFields = false
  ;

  BuilderConfig_Recipe._() : super();
  factory BuilderConfig_Recipe({
    $core.String? name,
    $core.Iterable<$core.String>? properties,
    $core.Iterable<$core.String>? propertiesJ,
    $core.String? cipdVersion,
    $core.String? cipdPackage,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (properties != null) {
      _result.properties.addAll(properties);
    }
    if (propertiesJ != null) {
      _result.propertiesJ.addAll(propertiesJ);
    }
    if (cipdVersion != null) {
      _result.cipdVersion = cipdVersion;
    }
    if (cipdPackage != null) {
      _result.cipdPackage = cipdPackage;
    }
    return _result;
  }
  factory BuilderConfig_Recipe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_Recipe clone() => BuilderConfig_Recipe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_Recipe copyWith(void Function(BuilderConfig_Recipe) updates) => super.copyWith((message) => updates(message as BuilderConfig_Recipe)) as BuilderConfig_Recipe; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Recipe create() => BuilderConfig_Recipe._();
  BuilderConfig_Recipe createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_Recipe> createRepeated() => $pb.PbList<BuilderConfig_Recipe>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Recipe getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_Recipe>(create);
  static BuilderConfig_Recipe? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(2)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get properties => $_getList(1);

  @$pb.TagNumber(4)
  $core.List<$core.String> get propertiesJ => $_getList(2);

  @$pb.TagNumber(5)
  $core.String get cipdVersion => $_getSZ(3);
  @$pb.TagNumber(5)
  set cipdVersion($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasCipdVersion() => $_has(3);
  @$pb.TagNumber(5)
  void clearCipdVersion() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get cipdPackage => $_getSZ(4);
  @$pb.TagNumber(6)
  set cipdPackage($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasCipdPackage() => $_has(4);
  @$pb.TagNumber(6)
  void clearCipdPackage() => clearField(6);
}

class BuilderConfig_ResultDB extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderConfig.ResultDB', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOB(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'enable')
    ..pc<$3.BigQueryExport>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bqExports', $pb.PbFieldType.PM, subBuilder: $3.BigQueryExport.create)
    ..aOM<$3.HistoryOptions>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'historyOptions', subBuilder: $3.HistoryOptions.create)
    ..hasRequiredFields = false
  ;

  BuilderConfig_ResultDB._() : super();
  factory BuilderConfig_ResultDB({
    $core.bool? enable,
    $core.Iterable<$3.BigQueryExport>? bqExports,
    $3.HistoryOptions? historyOptions,
  }) {
    final _result = create();
    if (enable != null) {
      _result.enable = enable;
    }
    if (bqExports != null) {
      _result.bqExports.addAll(bqExports);
    }
    if (historyOptions != null) {
      _result.historyOptions = historyOptions;
    }
    return _result;
  }
  factory BuilderConfig_ResultDB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_ResultDB clone() => BuilderConfig_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_ResultDB copyWith(void Function(BuilderConfig_ResultDB) updates) => super.copyWith((message) => updates(message as BuilderConfig_ResultDB)) as BuilderConfig_ResultDB; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ResultDB create() => BuilderConfig_ResultDB._();
  BuilderConfig_ResultDB createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_ResultDB> createRepeated() => $pb.PbList<BuilderConfig_ResultDB>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ResultDB getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_ResultDB>(create);
  static BuilderConfig_ResultDB? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enable => $_getBF(0);
  @$pb.TagNumber(1)
  set enable($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnable() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnable() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$3.BigQueryExport> get bqExports => $_getList(1);

  @$pb.TagNumber(3)
  $3.HistoryOptions get historyOptions => $_getN(2);
  @$pb.TagNumber(3)
  set historyOptions($3.HistoryOptions v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasHistoryOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearHistoryOptions() => clearField(3);
  @$pb.TagNumber(3)
  $3.HistoryOptions ensureHistoryOptions() => $_ensure(2);
}

class BuilderConfig_Backend extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderConfig.Backend', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'target')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'configJson')
    ..hasRequiredFields = false
  ;

  BuilderConfig_Backend._() : super();
  factory BuilderConfig_Backend({
    $core.String? target,
    $core.String? configJson,
  }) {
    final _result = create();
    if (target != null) {
      _result.target = target;
    }
    if (configJson != null) {
      _result.configJson = configJson;
    }
    return _result;
  }
  factory BuilderConfig_Backend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_Backend clone() => BuilderConfig_Backend()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_Backend copyWith(void Function(BuilderConfig_Backend) updates) => super.copyWith((message) => updates(message as BuilderConfig_Backend)) as BuilderConfig_Backend; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Backend create() => BuilderConfig_Backend._();
  BuilderConfig_Backend createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_Backend> createRepeated() => $pb.PbList<BuilderConfig_Backend>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Backend getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_Backend>(create);
  static BuilderConfig_Backend? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get target => $_getSZ(0);
  @$pb.TagNumber(1)
  set target($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get configJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set configJson($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasConfigJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigJson() => clearField(2);
}

class BuilderConfig extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderConfig', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'swarmingTags')
    ..pPS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dimensions')
    ..aOM<BuilderConfig_Recipe>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'recipe', subBuilder: BuilderConfig_Recipe.create)
    ..a<$core.int>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'priority', $pb.PbFieldType.OU3)
    ..aOS(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'category')
    ..a<$core.int>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'executionTimeoutSecs', $pb.PbFieldType.OU3)
    ..pc<BuilderConfig_CacheEntry>(9, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'caches', $pb.PbFieldType.PM, subBuilder: BuilderConfig_CacheEntry.create)
    ..aOS(12, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serviceAccount')
    ..e<Toggle>(16, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'buildNumbers', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(17, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'autoBuilderDimension', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(18, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'experimental', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..a<$core.int>(20, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'expirationSecs', $pb.PbFieldType.OU3)
    ..aOS(21, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'swarmingHost')
    ..aOM<$0.UInt32Value>(22, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..aOM<$1.Executable>(23, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'exe', subBuilder: $1.Executable.create)
    ..aOS(24, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'properties')
    ..e<$1.Trinary>(25, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'critical', $pb.PbFieldType.OE, defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOM<BuilderConfig_ResultDB>(26, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'resultdb', subBuilder: BuilderConfig_ResultDB.create)
    ..m<$core.String, $core.int>(28, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'experiments', entryClassName: 'BuilderConfig.ExperimentsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.O3, packageName: const $pb.PackageName('buildbucket'))
    ..e<$1.Trinary>(29, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'waitForCapacity', $pb.PbFieldType.OE, defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOS(30, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'descriptionHtml')
    ..aOM<$2.Duration>(31, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'gracePeriod', subBuilder: $2.Duration.create)
    ..aOM<BuilderConfig_Backend>(32, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'backend', subBuilder: BuilderConfig_Backend.create)
    ..aOM<BuilderConfig_Backend>(33, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'backendAlt', subBuilder: BuilderConfig_Backend.create)
    ..pPS(34, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'allowedPropertyOverrides')
    ..hasRequiredFields = false
  ;

  BuilderConfig._() : super();
  factory BuilderConfig({
    $core.String? name,
    $core.Iterable<$core.String>? swarmingTags,
    $core.Iterable<$core.String>? dimensions,
    BuilderConfig_Recipe? recipe,
    $core.int? priority,
    $core.String? category,
    $core.int? executionTimeoutSecs,
    $core.Iterable<BuilderConfig_CacheEntry>? caches,
    $core.String? serviceAccount,
    Toggle? buildNumbers,
    Toggle? autoBuilderDimension,
    Toggle? experimental,
    $core.int? expirationSecs,
    $core.String? swarmingHost,
    $0.UInt32Value? taskTemplateCanaryPercentage,
    $1.Executable? exe,
    $core.String? properties,
    $1.Trinary? critical,
    BuilderConfig_ResultDB? resultdb,
    $core.Map<$core.String, $core.int>? experiments,
    $1.Trinary? waitForCapacity,
    $core.String? descriptionHtml,
    $2.Duration? gracePeriod,
    BuilderConfig_Backend? backend,
    BuilderConfig_Backend? backendAlt,
    $core.Iterable<$core.String>? allowedPropertyOverrides,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (swarmingTags != null) {
      _result.swarmingTags.addAll(swarmingTags);
    }
    if (dimensions != null) {
      _result.dimensions.addAll(dimensions);
    }
    if (recipe != null) {
      _result.recipe = recipe;
    }
    if (priority != null) {
      _result.priority = priority;
    }
    if (category != null) {
      _result.category = category;
    }
    if (executionTimeoutSecs != null) {
      _result.executionTimeoutSecs = executionTimeoutSecs;
    }
    if (caches != null) {
      _result.caches.addAll(caches);
    }
    if (serviceAccount != null) {
      _result.serviceAccount = serviceAccount;
    }
    if (buildNumbers != null) {
      _result.buildNumbers = buildNumbers;
    }
    if (autoBuilderDimension != null) {
      _result.autoBuilderDimension = autoBuilderDimension;
    }
    if (experimental != null) {
      _result.experimental = experimental;
    }
    if (expirationSecs != null) {
      _result.expirationSecs = expirationSecs;
    }
    if (swarmingHost != null) {
      _result.swarmingHost = swarmingHost;
    }
    if (taskTemplateCanaryPercentage != null) {
      _result.taskTemplateCanaryPercentage = taskTemplateCanaryPercentage;
    }
    if (exe != null) {
      _result.exe = exe;
    }
    if (properties != null) {
      _result.properties = properties;
    }
    if (critical != null) {
      _result.critical = critical;
    }
    if (resultdb != null) {
      _result.resultdb = resultdb;
    }
    if (experiments != null) {
      _result.experiments.addAll(experiments);
    }
    if (waitForCapacity != null) {
      _result.waitForCapacity = waitForCapacity;
    }
    if (descriptionHtml != null) {
      _result.descriptionHtml = descriptionHtml;
    }
    if (gracePeriod != null) {
      _result.gracePeriod = gracePeriod;
    }
    if (backend != null) {
      _result.backend = backend;
    }
    if (backendAlt != null) {
      _result.backendAlt = backendAlt;
    }
    if (allowedPropertyOverrides != null) {
      _result.allowedPropertyOverrides.addAll(allowedPropertyOverrides);
    }
    return _result;
  }
  factory BuilderConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig clone() => BuilderConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig copyWith(void Function(BuilderConfig) updates) => super.copyWith((message) => updates(message as BuilderConfig)) as BuilderConfig; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderConfig create() => BuilderConfig._();
  BuilderConfig createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig> createRepeated() => $pb.PbList<BuilderConfig>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig>(create);
  static BuilderConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get swarmingTags => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<$core.String> get dimensions => $_getList(2);

  @$pb.TagNumber(4)
  BuilderConfig_Recipe get recipe => $_getN(3);
  @$pb.TagNumber(4)
  set recipe(BuilderConfig_Recipe v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasRecipe() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipe() => clearField(4);
  @$pb.TagNumber(4)
  BuilderConfig_Recipe ensureRecipe() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.int get priority => $_getIZ(4);
  @$pb.TagNumber(5)
  set priority($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get category => $_getSZ(5);
  @$pb.TagNumber(6)
  set category($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategory() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get executionTimeoutSecs => $_getIZ(6);
  @$pb.TagNumber(7)
  set executionTimeoutSecs($core.int v) { $_setUnsignedInt32(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasExecutionTimeoutSecs() => $_has(6);
  @$pb.TagNumber(7)
  void clearExecutionTimeoutSecs() => clearField(7);

  @$pb.TagNumber(9)
  $core.List<BuilderConfig_CacheEntry> get caches => $_getList(7);

  @$pb.TagNumber(12)
  $core.String get serviceAccount => $_getSZ(8);
  @$pb.TagNumber(12)
  set serviceAccount($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(12)
  $core.bool hasServiceAccount() => $_has(8);
  @$pb.TagNumber(12)
  void clearServiceAccount() => clearField(12);

  @$pb.TagNumber(16)
  Toggle get buildNumbers => $_getN(9);
  @$pb.TagNumber(16)
  set buildNumbers(Toggle v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasBuildNumbers() => $_has(9);
  @$pb.TagNumber(16)
  void clearBuildNumbers() => clearField(16);

  @$pb.TagNumber(17)
  Toggle get autoBuilderDimension => $_getN(10);
  @$pb.TagNumber(17)
  set autoBuilderDimension(Toggle v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasAutoBuilderDimension() => $_has(10);
  @$pb.TagNumber(17)
  void clearAutoBuilderDimension() => clearField(17);

  @$pb.TagNumber(18)
  Toggle get experimental => $_getN(11);
  @$pb.TagNumber(18)
  set experimental(Toggle v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasExperimental() => $_has(11);
  @$pb.TagNumber(18)
  void clearExperimental() => clearField(18);

  @$pb.TagNumber(20)
  $core.int get expirationSecs => $_getIZ(12);
  @$pb.TagNumber(20)
  set expirationSecs($core.int v) { $_setUnsignedInt32(12, v); }
  @$pb.TagNumber(20)
  $core.bool hasExpirationSecs() => $_has(12);
  @$pb.TagNumber(20)
  void clearExpirationSecs() => clearField(20);

  @$pb.TagNumber(21)
  $core.String get swarmingHost => $_getSZ(13);
  @$pb.TagNumber(21)
  set swarmingHost($core.String v) { $_setString(13, v); }
  @$pb.TagNumber(21)
  $core.bool hasSwarmingHost() => $_has(13);
  @$pb.TagNumber(21)
  void clearSwarmingHost() => clearField(21);

  @$pb.TagNumber(22)
  $0.UInt32Value get taskTemplateCanaryPercentage => $_getN(14);
  @$pb.TagNumber(22)
  set taskTemplateCanaryPercentage($0.UInt32Value v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasTaskTemplateCanaryPercentage() => $_has(14);
  @$pb.TagNumber(22)
  void clearTaskTemplateCanaryPercentage() => clearField(22);
  @$pb.TagNumber(22)
  $0.UInt32Value ensureTaskTemplateCanaryPercentage() => $_ensure(14);

  @$pb.TagNumber(23)
  $1.Executable get exe => $_getN(15);
  @$pb.TagNumber(23)
  set exe($1.Executable v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasExe() => $_has(15);
  @$pb.TagNumber(23)
  void clearExe() => clearField(23);
  @$pb.TagNumber(23)
  $1.Executable ensureExe() => $_ensure(15);

  @$pb.TagNumber(24)
  $core.String get properties => $_getSZ(16);
  @$pb.TagNumber(24)
  set properties($core.String v) { $_setString(16, v); }
  @$pb.TagNumber(24)
  $core.bool hasProperties() => $_has(16);
  @$pb.TagNumber(24)
  void clearProperties() => clearField(24);

  @$pb.TagNumber(25)
  $1.Trinary get critical => $_getN(17);
  @$pb.TagNumber(25)
  set critical($1.Trinary v) { setField(25, v); }
  @$pb.TagNumber(25)
  $core.bool hasCritical() => $_has(17);
  @$pb.TagNumber(25)
  void clearCritical() => clearField(25);

  @$pb.TagNumber(26)
  BuilderConfig_ResultDB get resultdb => $_getN(18);
  @$pb.TagNumber(26)
  set resultdb(BuilderConfig_ResultDB v) { setField(26, v); }
  @$pb.TagNumber(26)
  $core.bool hasResultdb() => $_has(18);
  @$pb.TagNumber(26)
  void clearResultdb() => clearField(26);
  @$pb.TagNumber(26)
  BuilderConfig_ResultDB ensureResultdb() => $_ensure(18);

  @$pb.TagNumber(28)
  $core.Map<$core.String, $core.int> get experiments => $_getMap(19);

  @$pb.TagNumber(29)
  $1.Trinary get waitForCapacity => $_getN(20);
  @$pb.TagNumber(29)
  set waitForCapacity($1.Trinary v) { setField(29, v); }
  @$pb.TagNumber(29)
  $core.bool hasWaitForCapacity() => $_has(20);
  @$pb.TagNumber(29)
  void clearWaitForCapacity() => clearField(29);

  @$pb.TagNumber(30)
  $core.String get descriptionHtml => $_getSZ(21);
  @$pb.TagNumber(30)
  set descriptionHtml($core.String v) { $_setString(21, v); }
  @$pb.TagNumber(30)
  $core.bool hasDescriptionHtml() => $_has(21);
  @$pb.TagNumber(30)
  void clearDescriptionHtml() => clearField(30);

  @$pb.TagNumber(31)
  $2.Duration get gracePeriod => $_getN(22);
  @$pb.TagNumber(31)
  set gracePeriod($2.Duration v) { setField(31, v); }
  @$pb.TagNumber(31)
  $core.bool hasGracePeriod() => $_has(22);
  @$pb.TagNumber(31)
  void clearGracePeriod() => clearField(31);
  @$pb.TagNumber(31)
  $2.Duration ensureGracePeriod() => $_ensure(22);

  @$pb.TagNumber(32)
  BuilderConfig_Backend get backend => $_getN(23);
  @$pb.TagNumber(32)
  set backend(BuilderConfig_Backend v) { setField(32, v); }
  @$pb.TagNumber(32)
  $core.bool hasBackend() => $_has(23);
  @$pb.TagNumber(32)
  void clearBackend() => clearField(32);
  @$pb.TagNumber(32)
  BuilderConfig_Backend ensureBackend() => $_ensure(23);

  @$pb.TagNumber(33)
  BuilderConfig_Backend get backendAlt => $_getN(24);
  @$pb.TagNumber(33)
  set backendAlt(BuilderConfig_Backend v) { setField(33, v); }
  @$pb.TagNumber(33)
  $core.bool hasBackendAlt() => $_has(24);
  @$pb.TagNumber(33)
  void clearBackendAlt() => clearField(33);
  @$pb.TagNumber(33)
  BuilderConfig_Backend ensureBackendAlt() => $_ensure(24);

  @$pb.TagNumber(34)
  $core.List<$core.String> get allowedPropertyOverrides => $_getList(25);
}

class Swarming extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Swarming', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<BuilderConfig>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'builders', $pb.PbFieldType.PM, subBuilder: BuilderConfig.create)
    ..aOM<$0.UInt32Value>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..hasRequiredFields = false
  ;

  Swarming._() : super();
  factory Swarming({
    $core.Iterable<BuilderConfig>? builders,
    $0.UInt32Value? taskTemplateCanaryPercentage,
  }) {
    final _result = create();
    if (builders != null) {
      _result.builders.addAll(builders);
    }
    if (taskTemplateCanaryPercentage != null) {
      _result.taskTemplateCanaryPercentage = taskTemplateCanaryPercentage;
    }
    return _result;
  }
  factory Swarming.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Swarming clone() => Swarming()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Swarming copyWith(void Function(Swarming) updates) => super.copyWith((message) => updates(message as Swarming)) as Swarming; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Swarming create() => Swarming._();
  Swarming createEmptyInstance() => create();
  static $pb.PbList<Swarming> createRepeated() => $pb.PbList<Swarming>();
  @$core.pragma('dart2js:noInline')
  static Swarming getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Swarming>(create);
  static Swarming? _defaultInstance;

  @$pb.TagNumber(4)
  $core.List<BuilderConfig> get builders => $_getList(0);

  @$pb.TagNumber(5)
  $0.UInt32Value get taskTemplateCanaryPercentage => $_getN(1);
  @$pb.TagNumber(5)
  set taskTemplateCanaryPercentage($0.UInt32Value v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTaskTemplateCanaryPercentage() => $_has(1);
  @$pb.TagNumber(5)
  void clearTaskTemplateCanaryPercentage() => clearField(5);
  @$pb.TagNumber(5)
  $0.UInt32Value ensureTaskTemplateCanaryPercentage() => $_ensure(1);
}

class Bucket_Constraints extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Bucket.Constraints', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pPS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'pools')
    ..pPS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'serviceAccounts')
    ..hasRequiredFields = false
  ;

  Bucket_Constraints._() : super();
  factory Bucket_Constraints({
    $core.Iterable<$core.String>? pools,
    $core.Iterable<$core.String>? serviceAccounts,
  }) {
    final _result = create();
    if (pools != null) {
      _result.pools.addAll(pools);
    }
    if (serviceAccounts != null) {
      _result.serviceAccounts.addAll(serviceAccounts);
    }
    return _result;
  }
  factory Bucket_Constraints.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket_Constraints.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket_Constraints clone() => Bucket_Constraints()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket_Constraints copyWith(void Function(Bucket_Constraints) updates) => super.copyWith((message) => updates(message as Bucket_Constraints)) as Bucket_Constraints; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Bucket_Constraints create() => Bucket_Constraints._();
  Bucket_Constraints createEmptyInstance() => create();
  static $pb.PbList<Bucket_Constraints> createRepeated() => $pb.PbList<Bucket_Constraints>();
  @$core.pragma('dart2js:noInline')
  static Bucket_Constraints getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bucket_Constraints>(create);
  static Bucket_Constraints? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get pools => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$core.String> get serviceAccounts => $_getList(1);
}

class Bucket_DynamicBuilderTemplate extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Bucket.DynamicBuilderTemplate', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  Bucket_DynamicBuilderTemplate._() : super();
  factory Bucket_DynamicBuilderTemplate() => create();
  factory Bucket_DynamicBuilderTemplate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket_DynamicBuilderTemplate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate clone() => Bucket_DynamicBuilderTemplate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate copyWith(void Function(Bucket_DynamicBuilderTemplate) updates) => super.copyWith((message) => updates(message as Bucket_DynamicBuilderTemplate)) as Bucket_DynamicBuilderTemplate; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Bucket_DynamicBuilderTemplate create() => Bucket_DynamicBuilderTemplate._();
  Bucket_DynamicBuilderTemplate createEmptyInstance() => create();
  static $pb.PbList<Bucket_DynamicBuilderTemplate> createRepeated() => $pb.PbList<Bucket_DynamicBuilderTemplate>();
  @$core.pragma('dart2js:noInline')
  static Bucket_DynamicBuilderTemplate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bucket_DynamicBuilderTemplate>(create);
  static Bucket_DynamicBuilderTemplate? _defaultInstance;
}

class Bucket extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Bucket', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..pc<Acl>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'acls', $pb.PbFieldType.PM, subBuilder: Acl.create)
    ..aOM<Swarming>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'swarming', subBuilder: Swarming.create)
    ..aOS(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'shadow')
    ..aOM<Bucket_Constraints>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'constraints', subBuilder: Bucket_Constraints.create)
    ..aOM<Bucket_DynamicBuilderTemplate>(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'dynamicBuilderTemplate', subBuilder: Bucket_DynamicBuilderTemplate.create)
    ..hasRequiredFields = false
  ;

  Bucket._() : super();
  factory Bucket({
    $core.String? name,
  @$core.Deprecated('This field is deprecated.')
    $core.Iterable<Acl>? acls,
    Swarming? swarming,
    $core.String? shadow,
    Bucket_Constraints? constraints,
    Bucket_DynamicBuilderTemplate? dynamicBuilderTemplate,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (acls != null) {
      // ignore: deprecated_member_use_from_same_package
      _result.acls.addAll(acls);
    }
    if (swarming != null) {
      _result.swarming = swarming;
    }
    if (shadow != null) {
      _result.shadow = shadow;
    }
    if (constraints != null) {
      _result.constraints = constraints;
    }
    if (dynamicBuilderTemplate != null) {
      _result.dynamicBuilderTemplate = dynamicBuilderTemplate;
    }
    return _result;
  }
  factory Bucket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket clone() => Bucket()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket copyWith(void Function(Bucket) updates) => super.copyWith((message) => updates(message as Bucket)) as Bucket; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Bucket create() => Bucket._();
  Bucket createEmptyInstance() => create();
  static $pb.PbList<Bucket> createRepeated() => $pb.PbList<Bucket>();
  @$core.pragma('dart2js:noInline')
  static Bucket getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bucket>(create);
  static Bucket? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.List<Acl> get acls => $_getList(1);

  @$pb.TagNumber(3)
  Swarming get swarming => $_getN(2);
  @$pb.TagNumber(3)
  set swarming(Swarming v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSwarming() => $_has(2);
  @$pb.TagNumber(3)
  void clearSwarming() => clearField(3);
  @$pb.TagNumber(3)
  Swarming ensureSwarming() => $_ensure(2);

  @$pb.TagNumber(5)
  $core.String get shadow => $_getSZ(3);
  @$pb.TagNumber(5)
  set shadow($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasShadow() => $_has(3);
  @$pb.TagNumber(5)
  void clearShadow() => clearField(5);

  @$pb.TagNumber(6)
  Bucket_Constraints get constraints => $_getN(4);
  @$pb.TagNumber(6)
  set constraints(Bucket_Constraints v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasConstraints() => $_has(4);
  @$pb.TagNumber(6)
  void clearConstraints() => clearField(6);
  @$pb.TagNumber(6)
  Bucket_Constraints ensureConstraints() => $_ensure(4);

  @$pb.TagNumber(7)
  Bucket_DynamicBuilderTemplate get dynamicBuilderTemplate => $_getN(5);
  @$pb.TagNumber(7)
  set dynamicBuilderTemplate(Bucket_DynamicBuilderTemplate v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasDynamicBuilderTemplate() => $_has(5);
  @$pb.TagNumber(7)
  void clearDynamicBuilderTemplate() => clearField(7);
  @$pb.TagNumber(7)
  Bucket_DynamicBuilderTemplate ensureDynamicBuilderTemplate() => $_ensure(5);
}

class BuildbucketCfg_topic extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildbucketCfg.topic', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..e<$1.Compression>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'compression', $pb.PbFieldType.OE, defaultOrMaker: $1.Compression.ZLIB, valueOf: $1.Compression.valueOf, enumValues: $1.Compression.values)
    ..hasRequiredFields = false
  ;

  BuildbucketCfg_topic._() : super();
  factory BuildbucketCfg_topic({
    $core.String? name,
    $1.Compression? compression,
  }) {
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (compression != null) {
      _result.compression = compression;
    }
    return _result;
  }
  factory BuildbucketCfg_topic.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg_topic.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_topic clone() => BuildbucketCfg_topic()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_topic copyWith(void Function(BuildbucketCfg_topic) updates) => super.copyWith((message) => updates(message as BuildbucketCfg_topic)) as BuildbucketCfg_topic; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_topic create() => BuildbucketCfg_topic._();
  BuildbucketCfg_topic createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg_topic> createRepeated() => $pb.PbList<BuildbucketCfg_topic>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_topic getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg_topic>(create);
  static BuildbucketCfg_topic? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $1.Compression get compression => $_getN(1);
  @$pb.TagNumber(2)
  set compression($1.Compression v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasCompression() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompression() => clearField(2);
}

class BuildbucketCfg extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuildbucketCfg', package: const $pb.PackageName(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<Bucket>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'buckets', $pb.PbFieldType.PM, subBuilder: Bucket.create)
    ..pc<BuildbucketCfg_topic>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'buildsNotificationTopics', $pb.PbFieldType.PM, subBuilder: BuildbucketCfg_topic.create)
    ..hasRequiredFields = false
  ;

  BuildbucketCfg._() : super();
  factory BuildbucketCfg({
    $core.Iterable<Bucket>? buckets,
    $core.Iterable<BuildbucketCfg_topic>? buildsNotificationTopics,
  }) {
    final _result = create();
    if (buckets != null) {
      _result.buckets.addAll(buckets);
    }
    if (buildsNotificationTopics != null) {
      _result.buildsNotificationTopics.addAll(buildsNotificationTopics);
    }
    return _result;
  }
  factory BuildbucketCfg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildbucketCfg clone() => BuildbucketCfg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildbucketCfg copyWith(void Function(BuildbucketCfg) updates) => super.copyWith((message) => updates(message as BuildbucketCfg)) as BuildbucketCfg; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg create() => BuildbucketCfg._();
  BuildbucketCfg createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg> createRepeated() => $pb.PbList<BuildbucketCfg>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg>(create);
  static BuildbucketCfg? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Bucket> get buckets => $_getList(0);

  @$pb.TagNumber(4)
  $core.List<BuildbucketCfg_topic> get buildsNotificationTopics => $_getList(1);
}

