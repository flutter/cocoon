//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $2;
import '../../../../google/protobuf/wrappers.pb.dart' as $0;
import '../../resultdb/proto/v1/invocation.pb.dart' as $3;
import 'common.pb.dart' as $1;
import 'common.pbenum.dart' as $1;
import 'project_config.pbenum.dart';

export 'project_config.pbenum.dart';

class Acl extends $pb.GeneratedMessage {
  factory Acl() => create();
  Acl._() : super();
  factory Acl.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Acl.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Acl', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..e<Acl_Role>(1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE, defaultOrMaker: Acl_Role.READER, valueOf: Acl_Role.valueOf, enumValues: Acl_Role.values)
    ..aOS(2, _omitFieldNames ? '' : 'group')
    ..aOS(3, _omitFieldNames ? '' : 'identity')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Acl clone() => Acl()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Acl copyWith(void Function(Acl) updates) => super.copyWith((message) => updates(message as Acl)) as Acl;

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
  factory BuilderConfig_CacheEntry() => create();
  BuilderConfig_CacheEntry._() : super();
  factory BuilderConfig_CacheEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.CacheEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'waitForWarmCacheSecs', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_CacheEntry clone() => BuilderConfig_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_CacheEntry copyWith(void Function(BuilderConfig_CacheEntry) updates) => super.copyWith((message) => updates(message as BuilderConfig_CacheEntry)) as BuilderConfig_CacheEntry;

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
  factory BuilderConfig_Recipe() => create();
  BuilderConfig_Recipe._() : super();
  factory BuilderConfig_Recipe.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.Recipe', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPS(3, _omitFieldNames ? '' : 'properties')
    ..pPS(4, _omitFieldNames ? '' : 'propertiesJ')
    ..aOS(5, _omitFieldNames ? '' : 'cipdVersion')
    ..aOS(6, _omitFieldNames ? '' : 'cipdPackage')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_Recipe clone() => BuilderConfig_Recipe()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_Recipe copyWith(void Function(BuilderConfig_Recipe) updates) => super.copyWith((message) => updates(message as BuilderConfig_Recipe)) as BuilderConfig_Recipe;

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
  factory BuilderConfig_ResultDB() => create();
  BuilderConfig_ResultDB._() : super();
  factory BuilderConfig_ResultDB.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.ResultDB', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enable')
    ..pc<$3.BigQueryExport>(2, _omitFieldNames ? '' : 'bqExports', $pb.PbFieldType.PM, subBuilder: $3.BigQueryExport.create)
    ..aOM<$3.HistoryOptions>(3, _omitFieldNames ? '' : 'historyOptions', subBuilder: $3.HistoryOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_ResultDB clone() => BuilderConfig_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_ResultDB copyWith(void Function(BuilderConfig_ResultDB) updates) => super.copyWith((message) => updates(message as BuilderConfig_ResultDB)) as BuilderConfig_ResultDB;

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
  factory BuilderConfig_Backend() => create();
  BuilderConfig_Backend._() : super();
  factory BuilderConfig_Backend.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.Backend', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'target')
    ..aOS(2, _omitFieldNames ? '' : 'configJson')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_Backend clone() => BuilderConfig_Backend()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_Backend copyWith(void Function(BuilderConfig_Backend) updates) => super.copyWith((message) => updates(message as BuilderConfig_Backend)) as BuilderConfig_Backend;

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

class BuilderConfig_ShadowBuilderAdjustments extends $pb.GeneratedMessage {
  factory BuilderConfig_ShadowBuilderAdjustments() => create();
  BuilderConfig_ShadowBuilderAdjustments._() : super();
  factory BuilderConfig_ShadowBuilderAdjustments.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_ShadowBuilderAdjustments.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.ShadowBuilderAdjustments', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceAccount')
    ..aOS(2, _omitFieldNames ? '' : 'pool')
    ..aOS(3, _omitFieldNames ? '' : 'properties')
    ..pPS(4, _omitFieldNames ? '' : 'dimensions')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_ShadowBuilderAdjustments clone() => BuilderConfig_ShadowBuilderAdjustments()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_ShadowBuilderAdjustments copyWith(void Function(BuilderConfig_ShadowBuilderAdjustments) updates) => super.copyWith((message) => updates(message as BuilderConfig_ShadowBuilderAdjustments)) as BuilderConfig_ShadowBuilderAdjustments;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ShadowBuilderAdjustments create() => BuilderConfig_ShadowBuilderAdjustments._();
  BuilderConfig_ShadowBuilderAdjustments createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_ShadowBuilderAdjustments> createRepeated() => $pb.PbList<BuilderConfig_ShadowBuilderAdjustments>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ShadowBuilderAdjustments getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_ShadowBuilderAdjustments>(create);
  static BuilderConfig_ShadowBuilderAdjustments? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceAccount => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceAccount($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServiceAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceAccount() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get pool => $_getSZ(1);
  @$pb.TagNumber(2)
  set pool($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPool() => $_has(1);
  @$pb.TagNumber(2)
  void clearPool() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get properties => $_getSZ(2);
  @$pb.TagNumber(3)
  set properties($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasProperties() => $_has(2);
  @$pb.TagNumber(3)
  void clearProperties() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.String> get dimensions => $_getList(3);
}

class BuilderConfig_BuilderHealthLinks extends $pb.GeneratedMessage {
  factory BuilderConfig_BuilderHealthLinks() => create();
  BuilderConfig_BuilderHealthLinks._() : super();
  factory BuilderConfig_BuilderHealthLinks.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig_BuilderHealthLinks.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.BuilderHealthLinks', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'docLinks', entryClassName: 'BuilderConfig.BuilderHealthLinks.DocLinksEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('buildbucket'))
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'dataLinks', entryClassName: 'BuilderConfig.BuilderHealthLinks.DataLinksEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('buildbucket'))
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig_BuilderHealthLinks clone() => BuilderConfig_BuilderHealthLinks()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig_BuilderHealthLinks copyWith(void Function(BuilderConfig_BuilderHealthLinks) updates) => super.copyWith((message) => updates(message as BuilderConfig_BuilderHealthLinks)) as BuilderConfig_BuilderHealthLinks;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_BuilderHealthLinks create() => BuilderConfig_BuilderHealthLinks._();
  BuilderConfig_BuilderHealthLinks createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_BuilderHealthLinks> createRepeated() => $pb.PbList<BuilderConfig_BuilderHealthLinks>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_BuilderHealthLinks getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_BuilderHealthLinks>(create);
  static BuilderConfig_BuilderHealthLinks? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, $core.String> get docLinks => $_getMap(0);

  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get dataLinks => $_getMap(1);
}

class BuilderConfig extends $pb.GeneratedMessage {
  factory BuilderConfig() => create();
  BuilderConfig._() : super();
  factory BuilderConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuilderConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'swarmingTags')
    ..pPS(3, _omitFieldNames ? '' : 'dimensions')
    ..aOM<BuilderConfig_Recipe>(4, _omitFieldNames ? '' : 'recipe', subBuilder: BuilderConfig_Recipe.create)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'category')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'executionTimeoutSecs', $pb.PbFieldType.OU3)
    ..pc<BuilderConfig_CacheEntry>(9, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM, subBuilder: BuilderConfig_CacheEntry.create)
    ..aOS(12, _omitFieldNames ? '' : 'serviceAccount')
    ..e<Toggle>(16, _omitFieldNames ? '' : 'buildNumbers', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(17, _omitFieldNames ? '' : 'autoBuilderDimension', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(18, _omitFieldNames ? '' : 'experimental', $pb.PbFieldType.OE, defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..a<$core.int>(20, _omitFieldNames ? '' : 'expirationSecs', $pb.PbFieldType.OU3)
    ..aOS(21, _omitFieldNames ? '' : 'swarmingHost')
    ..aOM<$0.UInt32Value>(22, _omitFieldNames ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..aOM<$1.Executable>(23, _omitFieldNames ? '' : 'exe', subBuilder: $1.Executable.create)
    ..aOS(24, _omitFieldNames ? '' : 'properties')
    ..e<$1.Trinary>(25, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE, defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOM<BuilderConfig_ResultDB>(26, _omitFieldNames ? '' : 'resultdb', subBuilder: BuilderConfig_ResultDB.create)
    ..m<$core.String, $core.int>(28, _omitFieldNames ? '' : 'experiments', entryClassName: 'BuilderConfig.ExperimentsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.O3, packageName: const $pb.PackageName('buildbucket'))
    ..e<$1.Trinary>(29, _omitFieldNames ? '' : 'waitForCapacity', $pb.PbFieldType.OE, defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOS(30, _omitFieldNames ? '' : 'descriptionHtml')
    ..aOM<$2.Duration>(31, _omitFieldNames ? '' : 'gracePeriod', subBuilder: $2.Duration.create)
    ..aOM<BuilderConfig_Backend>(32, _omitFieldNames ? '' : 'backend', subBuilder: BuilderConfig_Backend.create)
    ..aOM<BuilderConfig_Backend>(33, _omitFieldNames ? '' : 'backendAlt', subBuilder: BuilderConfig_Backend.create)
    ..pPS(34, _omitFieldNames ? '' : 'allowedPropertyOverrides')
    ..aOM<BuilderConfig_ShadowBuilderAdjustments>(35, _omitFieldNames ? '' : 'shadowBuilderAdjustments', subBuilder: BuilderConfig_ShadowBuilderAdjustments.create)
    ..e<$1.Trinary>(36, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE, defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOM<BuilderConfig_BuilderHealthLinks>(37, _omitFieldNames ? '' : 'builderHealthMetricsLinks', subBuilder: BuilderConfig_BuilderHealthLinks.create)
    ..aOS(38, _omitFieldNames ? '' : 'contactTeamEmail')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuilderConfig clone() => BuilderConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuilderConfig copyWith(void Function(BuilderConfig) updates) => super.copyWith((message) => updates(message as BuilderConfig)) as BuilderConfig;

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

  @$pb.TagNumber(35)
  BuilderConfig_ShadowBuilderAdjustments get shadowBuilderAdjustments => $_getN(26);
  @$pb.TagNumber(35)
  set shadowBuilderAdjustments(BuilderConfig_ShadowBuilderAdjustments v) { setField(35, v); }
  @$pb.TagNumber(35)
  $core.bool hasShadowBuilderAdjustments() => $_has(26);
  @$pb.TagNumber(35)
  void clearShadowBuilderAdjustments() => clearField(35);
  @$pb.TagNumber(35)
  BuilderConfig_ShadowBuilderAdjustments ensureShadowBuilderAdjustments() => $_ensure(26);

  @$pb.TagNumber(36)
  $1.Trinary get retriable => $_getN(27);
  @$pb.TagNumber(36)
  set retriable($1.Trinary v) { setField(36, v); }
  @$pb.TagNumber(36)
  $core.bool hasRetriable() => $_has(27);
  @$pb.TagNumber(36)
  void clearRetriable() => clearField(36);

  @$pb.TagNumber(37)
  BuilderConfig_BuilderHealthLinks get builderHealthMetricsLinks => $_getN(28);
  @$pb.TagNumber(37)
  set builderHealthMetricsLinks(BuilderConfig_BuilderHealthLinks v) { setField(37, v); }
  @$pb.TagNumber(37)
  $core.bool hasBuilderHealthMetricsLinks() => $_has(28);
  @$pb.TagNumber(37)
  void clearBuilderHealthMetricsLinks() => clearField(37);
  @$pb.TagNumber(37)
  BuilderConfig_BuilderHealthLinks ensureBuilderHealthMetricsLinks() => $_ensure(28);

  @$pb.TagNumber(38)
  $core.String get contactTeamEmail => $_getSZ(29);
  @$pb.TagNumber(38)
  set contactTeamEmail($core.String v) { $_setString(29, v); }
  @$pb.TagNumber(38)
  $core.bool hasContactTeamEmail() => $_has(29);
  @$pb.TagNumber(38)
  void clearContactTeamEmail() => clearField(38);
}

class Swarming extends $pb.GeneratedMessage {
  factory Swarming() => create();
  Swarming._() : super();
  factory Swarming.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Swarming', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<BuilderConfig>(4, _omitFieldNames ? '' : 'builders', $pb.PbFieldType.PM, subBuilder: BuilderConfig.create)
    ..aOM<$0.UInt32Value>(5, _omitFieldNames ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Swarming clone() => Swarming()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Swarming copyWith(void Function(Swarming) updates) => super.copyWith((message) => updates(message as Swarming)) as Swarming;

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
  factory Bucket_Constraints() => create();
  Bucket_Constraints._() : super();
  factory Bucket_Constraints.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket_Constraints.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket.Constraints', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'pools')
    ..pPS(2, _omitFieldNames ? '' : 'serviceAccounts')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket_Constraints clone() => Bucket_Constraints()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket_Constraints copyWith(void Function(Bucket_Constraints) updates) => super.copyWith((message) => updates(message as Bucket_Constraints)) as Bucket_Constraints;

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
  factory Bucket_DynamicBuilderTemplate() => create();
  Bucket_DynamicBuilderTemplate._() : super();
  factory Bucket_DynamicBuilderTemplate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket_DynamicBuilderTemplate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket.DynamicBuilderTemplate', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate clone() => Bucket_DynamicBuilderTemplate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate copyWith(void Function(Bucket_DynamicBuilderTemplate) updates) => super.copyWith((message) => updates(message as Bucket_DynamicBuilderTemplate)) as Bucket_DynamicBuilderTemplate;

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
  factory Bucket() => create();
  Bucket._() : super();
  factory Bucket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Bucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pc<Acl>(2, _omitFieldNames ? '' : 'acls', $pb.PbFieldType.PM, subBuilder: Acl.create)
    ..aOM<Swarming>(3, _omitFieldNames ? '' : 'swarming', subBuilder: Swarming.create)
    ..aOS(5, _omitFieldNames ? '' : 'shadow')
    ..aOM<Bucket_Constraints>(6, _omitFieldNames ? '' : 'constraints', subBuilder: Bucket_Constraints.create)
    ..aOM<Bucket_DynamicBuilderTemplate>(7, _omitFieldNames ? '' : 'dynamicBuilderTemplate', subBuilder: Bucket_DynamicBuilderTemplate.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Bucket clone() => Bucket()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Bucket copyWith(void Function(Bucket) updates) => super.copyWith((message) => updates(message as Bucket)) as Bucket;

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

class BuildbucketCfg_Topic extends $pb.GeneratedMessage {
  factory BuildbucketCfg_Topic() => create();
  BuildbucketCfg_Topic._() : super();
  factory BuildbucketCfg_Topic.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg_Topic.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg.Topic', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<$1.Compression>(2, _omitFieldNames ? '' : 'compression', $pb.PbFieldType.OE, defaultOrMaker: $1.Compression.ZLIB, valueOf: $1.Compression.valueOf, enumValues: $1.Compression.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_Topic clone() => BuildbucketCfg_Topic()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_Topic copyWith(void Function(BuildbucketCfg_Topic) updates) => super.copyWith((message) => updates(message as BuildbucketCfg_Topic)) as BuildbucketCfg_Topic;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_Topic create() => BuildbucketCfg_Topic._();
  BuildbucketCfg_Topic createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg_Topic> createRepeated() => $pb.PbList<BuildbucketCfg_Topic>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_Topic getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg_Topic>(create);
  static BuildbucketCfg_Topic? _defaultInstance;

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

class BuildbucketCfg_CommonConfig extends $pb.GeneratedMessage {
  factory BuildbucketCfg_CommonConfig() => create();
  BuildbucketCfg_CommonConfig._() : super();
  factory BuildbucketCfg_CommonConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg_CommonConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg.CommonConfig', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<BuildbucketCfg_Topic>(1, _omitFieldNames ? '' : 'buildsNotificationTopics', $pb.PbFieldType.PM, subBuilder: BuildbucketCfg_Topic.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_CommonConfig clone() => BuildbucketCfg_CommonConfig()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildbucketCfg_CommonConfig copyWith(void Function(BuildbucketCfg_CommonConfig) updates) => super.copyWith((message) => updates(message as BuildbucketCfg_CommonConfig)) as BuildbucketCfg_CommonConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_CommonConfig create() => BuildbucketCfg_CommonConfig._();
  BuildbucketCfg_CommonConfig createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg_CommonConfig> createRepeated() => $pb.PbList<BuildbucketCfg_CommonConfig>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_CommonConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg_CommonConfig>(create);
  static BuildbucketCfg_CommonConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BuildbucketCfg_Topic> get buildsNotificationTopics => $_getList(0);
}

class BuildbucketCfg extends $pb.GeneratedMessage {
  factory BuildbucketCfg() => create();
  BuildbucketCfg._() : super();
  factory BuildbucketCfg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<Bucket>(1, _omitFieldNames ? '' : 'buckets', $pb.PbFieldType.PM, subBuilder: Bucket.create)
    ..aOM<BuildbucketCfg_CommonConfig>(5, _omitFieldNames ? '' : 'commonConfig', subBuilder: BuildbucketCfg_CommonConfig.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BuildbucketCfg clone() => BuildbucketCfg()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BuildbucketCfg copyWith(void Function(BuildbucketCfg) updates) => super.copyWith((message) => updates(message as BuildbucketCfg)) as BuildbucketCfg;

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

  @$pb.TagNumber(5)
  BuildbucketCfg_CommonConfig get commonConfig => $_getN(1);
  @$pb.TagNumber(5)
  set commonConfig(BuildbucketCfg_CommonConfig v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasCommonConfig() => $_has(1);
  @$pb.TagNumber(5)
  void clearCommonConfig() => clearField(5);
  @$pb.TagNumber(5)
  BuildbucketCfg_CommonConfig ensureCommonConfig() => $_ensure(1);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
