//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
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

/// Deprecated in favor of LUCI Realms. This proto is totally unused now, exists
/// only to not break older configs that still may have deprecated fields
/// populated.
class Acl extends $pb.GeneratedMessage {
  factory Acl({
    @$core.Deprecated('This field is deprecated.') Acl_Role? role,
    @$core.Deprecated('This field is deprecated.') $core.String? group,
    @$core.Deprecated('This field is deprecated.') $core.String? identity,
  }) {
    final $result = create();
    if (role != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.role = role;
    }
    if (group != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.group = group;
    }
    if (identity != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.identity = identity;
    }
    return $result;
  }
  Acl._() : super();
  factory Acl.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Acl.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Acl',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..e<Acl_Role>(1, _omitFieldNames ? '' : 'role', $pb.PbFieldType.OE,
        defaultOrMaker: Acl_Role.READER, valueOf: Acl_Role.valueOf, enumValues: Acl_Role.values)
    ..aOS(2, _omitFieldNames ? '' : 'group')
    ..aOS(3, _omitFieldNames ? '' : 'identity')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Acl clone() => Acl()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
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
  set role(Acl_Role v) {
    setField(1, v);
  }

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
  set group($core.String v) {
    $_setString(1, v);
  }

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
  set identity($core.String v) {
    $_setString(2, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.bool hasIdentity() => $_has(2);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  void clearIdentity() => clearField(3);
}

///  Describes a cache directory persisted on a bot.
///  Prerequisite reading in BuildInfra.Swarming.CacheEntry message in
///  build.proto.
///
///  To share a builder cache among multiple builders, it can be overridden:
///
///    builders {
///      name: "a"
///      caches {
///        path: "builder"
///        name: "my_shared_cache"
///      }
///    }
///    builders {
///      name: "b"
///      caches {
///        path: "builder"
///        name: "my_shared_cache"
///      }
///    }
///
///  Builders "a" and "b" share their builder cache. If an "a" build ran on a
///  bot and left some files in the builder cache and then a "b" build runs on
///  the same bot, the same files will be available in the builder cache.
class BuilderConfig_CacheEntry extends $pb.GeneratedMessage {
  factory BuilderConfig_CacheEntry({
    $core.String? name,
    $core.String? path,
    $core.int? waitForWarmCacheSecs,
    $core.String? envVar,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (path != null) {
      $result.path = path;
    }
    if (waitForWarmCacheSecs != null) {
      $result.waitForWarmCacheSecs = waitForWarmCacheSecs;
    }
    if (envVar != null) {
      $result.envVar = envVar;
    }
    return $result;
  }
  BuilderConfig_CacheEntry._() : super();
  factory BuilderConfig_CacheEntry.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.CacheEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'waitForWarmCacheSecs', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_CacheEntry clone() => BuilderConfig_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_CacheEntry copyWith(void Function(BuilderConfig_CacheEntry) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_CacheEntry)) as BuilderConfig_CacheEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_CacheEntry create() => BuilderConfig_CacheEntry._();
  BuilderConfig_CacheEntry createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_CacheEntry> createRepeated() => $pb.PbList<BuilderConfig_CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_CacheEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_CacheEntry>(create);
  static BuilderConfig_CacheEntry? _defaultInstance;

  /// Identifier of the cache. Length is limited to 128.
  /// Defaults to path.
  /// See also BuildInfra.Swarming.CacheEntry.name in build.proto.
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

  /// Relative path where the cache in mapped into. Required.
  /// See also BuildInfra.Swarming.CacheEntry.path in build.proto.
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

  /// Number of seconds to wait for a bot with a warm cache to pick up the
  /// task, before falling back to a bot with a cold (non-existent) cache.
  /// See also BuildInfra.Swarming.CacheEntry.wait_for_warm_cache in build.proto.
  /// The value must be multiples of 60 seconds.
  @$pb.TagNumber(3)
  $core.int get waitForWarmCacheSecs => $_getIZ(2);
  @$pb.TagNumber(3)
  set waitForWarmCacheSecs($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCacheSecs() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCacheSecs() => clearField(3);

  /// Environment variable with this name will be set to the path to the cache
  /// directory.
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

///  DEPRECATED. See BuilderConfig.executable and BuilderConfig.properties
///
///  To specify a recipe name, pass "$recipe_engine" property which is a JSON
///  object having "recipe" property.
class BuilderConfig_Recipe extends $pb.GeneratedMessage {
  factory BuilderConfig_Recipe({
    $core.String? name,
    $core.Iterable<$core.String>? properties,
    $core.Iterable<$core.String>? propertiesJ,
    $core.String? cipdVersion,
    $core.String? cipdPackage,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (properties != null) {
      $result.properties.addAll(properties);
    }
    if (propertiesJ != null) {
      $result.propertiesJ.addAll(propertiesJ);
    }
    if (cipdVersion != null) {
      $result.cipdVersion = cipdVersion;
    }
    if (cipdPackage != null) {
      $result.cipdPackage = cipdPackage;
    }
    return $result;
  }
  BuilderConfig_Recipe._() : super();
  factory BuilderConfig_Recipe.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.Recipe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..pPS(3, _omitFieldNames ? '' : 'properties')
    ..pPS(4, _omitFieldNames ? '' : 'propertiesJ')
    ..aOS(5, _omitFieldNames ? '' : 'cipdVersion')
    ..aOS(6, _omitFieldNames ? '' : 'cipdPackage')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_Recipe clone() => BuilderConfig_Recipe()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_Recipe copyWith(void Function(BuilderConfig_Recipe) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_Recipe)) as BuilderConfig_Recipe;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Recipe create() => BuilderConfig_Recipe._();
  BuilderConfig_Recipe createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_Recipe> createRepeated() => $pb.PbList<BuilderConfig_Recipe>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Recipe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_Recipe>(create);
  static BuilderConfig_Recipe? _defaultInstance;

  /// Name of the recipe to run.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);

  ///  Colon-separated build properties to set.
  ///  Ignored if BuilderConfig.properties is set.
  ///
  ///  Use this field for string properties and use properties_j for other
  ///  types.
  @$pb.TagNumber(3)
  $core.List<$core.String> get properties => $_getList(1);

  ///  Same as properties, but the value must valid JSON. For example
  ///    properties_j: "a:1"
  ///  means property a is a number 1, not string "1".
  ///
  ///  If null, it means no property must be defined. In particular, it removes
  ///  a default value for the property, if any.
  ///
  ///  Fields properties and properties_j can be used together, but cannot both
  ///  specify values for same property.
  @$pb.TagNumber(4)
  $core.List<$core.String> get propertiesJ => $_getList(2);

  ///  The CIPD version to fetch. This can be a lower-cased git ref (like
  ///  `refs/heads/main` or `head`), or it can be a cipd tag (like
  ///  `git_revision:dead...beef`).
  ///
  ///  The default is `head`, which corresponds to the git repo's HEAD ref. This
  ///  is typically (but not always) a symbolic ref for `refs/heads/master`.
  @$pb.TagNumber(5)
  $core.String get cipdVersion => $_getSZ(3);
  @$pb.TagNumber(5)
  set cipdVersion($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCipdVersion() => $_has(3);
  @$pb.TagNumber(5)
  void clearCipdVersion() => clearField(5);

  ///  The CIPD package to fetch the recipes from.
  ///
  ///  Typically the package will look like:
  ///
  ///    infra/recipe_bundles/chromium.googlesource.com/chromium/tools/build
  ///
  ///  Recipes bundled from internal repositories are typically under
  ///  `infra_internal/recipe_bundles/...`.
  ///
  ///  But if you're building your own recipe bundles, they could be located
  ///  elsewhere.
  @$pb.TagNumber(6)
  $core.String get cipdPackage => $_getSZ(4);
  @$pb.TagNumber(6)
  set cipdPackage($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCipdPackage() => $_has(4);
  @$pb.TagNumber(6)
  void clearCipdPackage() => clearField(6);
}

/// ResultDB-specific information for a builder.
class BuilderConfig_ResultDB extends $pb.GeneratedMessage {
  factory BuilderConfig_ResultDB({
    $core.bool? enable,
    $core.Iterable<$3.BigQueryExport>? bqExports,
    $3.HistoryOptions? historyOptions,
  }) {
    final $result = create();
    if (enable != null) {
      $result.enable = enable;
    }
    if (bqExports != null) {
      $result.bqExports.addAll(bqExports);
    }
    if (historyOptions != null) {
      $result.historyOptions = historyOptions;
    }
    return $result;
  }
  BuilderConfig_ResultDB._() : super();
  factory BuilderConfig_ResultDB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.ResultDB',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enable')
    ..pc<$3.BigQueryExport>(2, _omitFieldNames ? '' : 'bqExports', $pb.PbFieldType.PM,
        subBuilder: $3.BigQueryExport.create)
    ..aOM<$3.HistoryOptions>(3, _omitFieldNames ? '' : 'historyOptions', subBuilder: $3.HistoryOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_ResultDB clone() => BuilderConfig_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_ResultDB copyWith(void Function(BuilderConfig_ResultDB) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_ResultDB)) as BuilderConfig_ResultDB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ResultDB create() => BuilderConfig_ResultDB._();
  BuilderConfig_ResultDB createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_ResultDB> createRepeated() => $pb.PbList<BuilderConfig_ResultDB>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ResultDB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_ResultDB>(create);
  static BuilderConfig_ResultDB? _defaultInstance;

  /// Whether to enable ResultDB:Buildbucket integration.
  @$pb.TagNumber(1)
  $core.bool get enable => $_getBF(0);
  @$pb.TagNumber(1)
  set enable($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEnable() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnable() => clearField(1);

  /// Configuration for exporting test results to BigQuery.
  /// This can have multiple values to export results to multiple BigQuery
  /// tables, or to support multiple test result predicates.
  @$pb.TagNumber(2)
  $core.List<$3.BigQueryExport> get bqExports => $_getList(1);

  /// Deprecated. Any values specified here are ignored.
  @$pb.TagNumber(3)
  $3.HistoryOptions get historyOptions => $_getN(2);
  @$pb.TagNumber(3)
  set historyOptions($3.HistoryOptions v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasHistoryOptions() => $_has(2);
  @$pb.TagNumber(3)
  void clearHistoryOptions() => clearField(3);
  @$pb.TagNumber(3)
  $3.HistoryOptions ensureHistoryOptions() => $_ensure(2);
}

/// Buildbucket backend-specific information for a builder.
class BuilderConfig_Backend extends $pb.GeneratedMessage {
  factory BuilderConfig_Backend({
    $core.String? target,
    $core.String? configJson,
  }) {
    final $result = create();
    if (target != null) {
      $result.target = target;
    }
    if (configJson != null) {
      $result.configJson = configJson;
    }
    return $result;
  }
  BuilderConfig_Backend._() : super();
  factory BuilderConfig_Backend.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.Backend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'target')
    ..aOS(2, _omitFieldNames ? '' : 'configJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_Backend clone() => BuilderConfig_Backend()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_Backend copyWith(void Function(BuilderConfig_Backend) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_Backend)) as BuilderConfig_Backend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Backend create() => BuilderConfig_Backend._();
  BuilderConfig_Backend createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_Backend> createRepeated() => $pb.PbList<BuilderConfig_Backend>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_Backend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_Backend>(create);
  static BuilderConfig_Backend? _defaultInstance;

  /// URI for this backend, e.g. "swarming://chromium-swarm".
  @$pb.TagNumber(1)
  $core.String get target => $_getSZ(0);
  @$pb.TagNumber(1)
  set target($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => clearField(1);

  /// A string interpreted as JSON encapsulating configuration for this
  /// backend.
  /// TODO(crbug.com/1042991): Move priority, wait_for_capacity, etc. here.
  @$pb.TagNumber(2)
  $core.String get configJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set configJson($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasConfigJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfigJson() => clearField(2);
}

///  Configurations that need to be replaced when running a led build for this
///  Builder.
///
///  Note: Builders in a dynamic bucket cannot have ShadowBuilderAdjustments.
class BuilderConfig_ShadowBuilderAdjustments extends $pb.GeneratedMessage {
  factory BuilderConfig_ShadowBuilderAdjustments({
    $core.String? serviceAccount,
    $core.String? pool,
    $core.String? properties,
    $core.Iterable<$core.String>? dimensions,
  }) {
    final $result = create();
    if (serviceAccount != null) {
      $result.serviceAccount = serviceAccount;
    }
    if (pool != null) {
      $result.pool = pool;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    if (dimensions != null) {
      $result.dimensions.addAll(dimensions);
    }
    return $result;
  }
  BuilderConfig_ShadowBuilderAdjustments._() : super();
  factory BuilderConfig_ShadowBuilderAdjustments.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_ShadowBuilderAdjustments.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.ShadowBuilderAdjustments',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serviceAccount')
    ..aOS(2, _omitFieldNames ? '' : 'pool')
    ..aOS(3, _omitFieldNames ? '' : 'properties')
    ..pPS(4, _omitFieldNames ? '' : 'dimensions')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_ShadowBuilderAdjustments clone() => BuilderConfig_ShadowBuilderAdjustments()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_ShadowBuilderAdjustments copyWith(void Function(BuilderConfig_ShadowBuilderAdjustments) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_ShadowBuilderAdjustments))
          as BuilderConfig_ShadowBuilderAdjustments;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ShadowBuilderAdjustments create() => BuilderConfig_ShadowBuilderAdjustments._();
  BuilderConfig_ShadowBuilderAdjustments createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_ShadowBuilderAdjustments> createRepeated() =>
      $pb.PbList<BuilderConfig_ShadowBuilderAdjustments>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_ShadowBuilderAdjustments getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_ShadowBuilderAdjustments>(create);
  static BuilderConfig_ShadowBuilderAdjustments? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serviceAccount => $_getSZ(0);
  @$pb.TagNumber(1)
  set serviceAccount($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasServiceAccount() => $_has(0);
  @$pb.TagNumber(1)
  void clearServiceAccount() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get pool => $_getSZ(1);
  @$pb.TagNumber(2)
  set pool($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPool() => $_has(1);
  @$pb.TagNumber(2)
  void clearPool() => clearField(2);

  /// A JSON object contains properties to override Build.input.properties
  /// when creating the led build.
  /// Same as ScheduleBuild, the top-level properties here will override the
  /// ones in builder config, instead of deep merge.
  @$pb.TagNumber(3)
  $core.String get properties => $_getSZ(2);
  @$pb.TagNumber(3)
  set properties($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasProperties() => $_has(2);
  @$pb.TagNumber(3)
  void clearProperties() => clearField(3);

  ///  Overrides default dimensions defined by builder config.
  ///  Same as ScheduleBuild,
  ///  * dimensions with empty value will be excluded.
  ///  * same key dimensions with both empty and non-empty values are disallowed.
  ///
  ///  Note: for historical reason, pool can be adjusted individually.
  ///  If pool is adjusted individually, the same change should be reflected in
  ///  dimensions, and vice versa.
  @$pb.TagNumber(4)
  $core.List<$core.String> get dimensions => $_getList(3);
}

class BuilderConfig_BuilderHealthLinks extends $pb.GeneratedMessage {
  factory BuilderConfig_BuilderHealthLinks({
    $core.Map<$core.String, $core.String>? docLinks,
    $core.Map<$core.String, $core.String>? dataLinks,
  }) {
    final $result = create();
    if (docLinks != null) {
      $result.docLinks.addAll(docLinks);
    }
    if (dataLinks != null) {
      $result.dataLinks.addAll(dataLinks);
    }
    return $result;
  }
  BuilderConfig_BuilderHealthLinks._() : super();
  factory BuilderConfig_BuilderHealthLinks.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig_BuilderHealthLinks.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig.BuilderHealthLinks',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'docLinks',
        entryClassName: 'BuilderConfig.BuilderHealthLinks.DocLinksEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket'))
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'dataLinks',
        entryClassName: 'BuilderConfig.BuilderHealthLinks.DataLinksEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig_BuilderHealthLinks clone() => BuilderConfig_BuilderHealthLinks()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig_BuilderHealthLinks copyWith(void Function(BuilderConfig_BuilderHealthLinks) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig_BuilderHealthLinks))
          as BuilderConfig_BuilderHealthLinks;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig_BuilderHealthLinks create() => BuilderConfig_BuilderHealthLinks._();
  BuilderConfig_BuilderHealthLinks createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig_BuilderHealthLinks> createRepeated() =>
      $pb.PbList<BuilderConfig_BuilderHealthLinks>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig_BuilderHealthLinks getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig_BuilderHealthLinks>(create);
  static BuilderConfig_BuilderHealthLinks? _defaultInstance;

  ///  Mapping of username domain to clickable link for documentation on the health
  ///  metrics and how they were calculated.
  ///
  ///  The empty domain value will be used as a fallback for anonymous users, or
  ///  if the user identity domain doesn't have a matching entry in this map.
  ///
  ///  If linking an internal google link (say g3doc), use a go-link instead of a
  ///  raw url.
  @$pb.TagNumber(1)
  $core.Map<$core.String, $core.String> get docLinks => $_getMap(0);

  ///  Mapping of username domain to clickable link for data visualization or
  ///  dashboards for the health metrics.
  ///
  ///  Similar to doc_links, the empty domain value will be used as a fallback for
  ///  anonymous users, or if the user identity domain doesn't have a matching
  ///  entry in this map.
  ///
  ///  If linking an internal google link (say g3doc), use a go-link instead of a
  ///  raw url.
  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.String> get dataLinks => $_getMap(1);
}

///  Defines a swarmbucket builder. A builder has a name, a category and specifies
///  what should happen if a build is scheduled to that builder.
///
///  SECURITY WARNING: if adding more fields to this message, keep in mind that
///  a user that has permissions to schedule a build to the bucket, can override
///  this config.
///
///  Next tag: 40.
class BuilderConfig extends $pb.GeneratedMessage {
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
    BuilderConfig_ShadowBuilderAdjustments? shadowBuilderAdjustments,
    $1.Trinary? retriable,
    BuilderConfig_BuilderHealthLinks? builderHealthMetricsLinks,
    $core.String? contactTeamEmail,
    $core.int? heartbeatTimeoutSecs,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (swarmingTags != null) {
      $result.swarmingTags.addAll(swarmingTags);
    }
    if (dimensions != null) {
      $result.dimensions.addAll(dimensions);
    }
    if (recipe != null) {
      $result.recipe = recipe;
    }
    if (priority != null) {
      $result.priority = priority;
    }
    if (category != null) {
      $result.category = category;
    }
    if (executionTimeoutSecs != null) {
      $result.executionTimeoutSecs = executionTimeoutSecs;
    }
    if (caches != null) {
      $result.caches.addAll(caches);
    }
    if (serviceAccount != null) {
      $result.serviceAccount = serviceAccount;
    }
    if (buildNumbers != null) {
      $result.buildNumbers = buildNumbers;
    }
    if (autoBuilderDimension != null) {
      $result.autoBuilderDimension = autoBuilderDimension;
    }
    if (experimental != null) {
      $result.experimental = experimental;
    }
    if (expirationSecs != null) {
      $result.expirationSecs = expirationSecs;
    }
    if (swarmingHost != null) {
      $result.swarmingHost = swarmingHost;
    }
    if (taskTemplateCanaryPercentage != null) {
      $result.taskTemplateCanaryPercentage = taskTemplateCanaryPercentage;
    }
    if (exe != null) {
      $result.exe = exe;
    }
    if (properties != null) {
      $result.properties = properties;
    }
    if (critical != null) {
      $result.critical = critical;
    }
    if (resultdb != null) {
      $result.resultdb = resultdb;
    }
    if (experiments != null) {
      $result.experiments.addAll(experiments);
    }
    if (waitForCapacity != null) {
      $result.waitForCapacity = waitForCapacity;
    }
    if (descriptionHtml != null) {
      $result.descriptionHtml = descriptionHtml;
    }
    if (gracePeriod != null) {
      $result.gracePeriod = gracePeriod;
    }
    if (backend != null) {
      $result.backend = backend;
    }
    if (backendAlt != null) {
      $result.backendAlt = backendAlt;
    }
    if (allowedPropertyOverrides != null) {
      $result.allowedPropertyOverrides.addAll(allowedPropertyOverrides);
    }
    if (shadowBuilderAdjustments != null) {
      $result.shadowBuilderAdjustments = shadowBuilderAdjustments;
    }
    if (retriable != null) {
      $result.retriable = retriable;
    }
    if (builderHealthMetricsLinks != null) {
      $result.builderHealthMetricsLinks = builderHealthMetricsLinks;
    }
    if (contactTeamEmail != null) {
      $result.contactTeamEmail = contactTeamEmail;
    }
    if (heartbeatTimeoutSecs != null) {
      $result.heartbeatTimeoutSecs = heartbeatTimeoutSecs;
    }
    return $result;
  }
  BuilderConfig._() : super();
  factory BuilderConfig.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pPS(2, _omitFieldNames ? '' : 'swarmingTags')
    ..pPS(3, _omitFieldNames ? '' : 'dimensions')
    ..aOM<BuilderConfig_Recipe>(4, _omitFieldNames ? '' : 'recipe', subBuilder: BuilderConfig_Recipe.create)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'category')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'executionTimeoutSecs', $pb.PbFieldType.OU3)
    ..pc<BuilderConfig_CacheEntry>(9, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM,
        subBuilder: BuilderConfig_CacheEntry.create)
    ..aOS(12, _omitFieldNames ? '' : 'serviceAccount')
    ..e<Toggle>(16, _omitFieldNames ? '' : 'buildNumbers', $pb.PbFieldType.OE,
        defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(17, _omitFieldNames ? '' : 'autoBuilderDimension', $pb.PbFieldType.OE,
        defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..e<Toggle>(18, _omitFieldNames ? '' : 'experimental', $pb.PbFieldType.OE,
        defaultOrMaker: Toggle.UNSET, valueOf: Toggle.valueOf, enumValues: Toggle.values)
    ..a<$core.int>(20, _omitFieldNames ? '' : 'expirationSecs', $pb.PbFieldType.OU3)
    ..aOS(21, _omitFieldNames ? '' : 'swarmingHost')
    ..aOM<$0.UInt32Value>(22, _omitFieldNames ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..aOM<$1.Executable>(23, _omitFieldNames ? '' : 'exe', subBuilder: $1.Executable.create)
    ..aOS(24, _omitFieldNames ? '' : 'properties')
    ..e<$1.Trinary>(25, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOM<BuilderConfig_ResultDB>(26, _omitFieldNames ? '' : 'resultdb', subBuilder: BuilderConfig_ResultDB.create)
    ..m<$core.String, $core.int>(28, _omitFieldNames ? '' : 'experiments',
        entryClassName: 'BuilderConfig.ExperimentsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.O3,
        packageName: const $pb.PackageName('buildbucket'))
    ..e<$1.Trinary>(29, _omitFieldNames ? '' : 'waitForCapacity', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOS(30, _omitFieldNames ? '' : 'descriptionHtml')
    ..aOM<$2.Duration>(31, _omitFieldNames ? '' : 'gracePeriod', subBuilder: $2.Duration.create)
    ..aOM<BuilderConfig_Backend>(32, _omitFieldNames ? '' : 'backend', subBuilder: BuilderConfig_Backend.create)
    ..aOM<BuilderConfig_Backend>(33, _omitFieldNames ? '' : 'backendAlt', subBuilder: BuilderConfig_Backend.create)
    ..pPS(34, _omitFieldNames ? '' : 'allowedPropertyOverrides')
    ..aOM<BuilderConfig_ShadowBuilderAdjustments>(35, _omitFieldNames ? '' : 'shadowBuilderAdjustments',
        subBuilder: BuilderConfig_ShadowBuilderAdjustments.create)
    ..e<$1.Trinary>(36, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Trinary.UNSET, valueOf: $1.Trinary.valueOf, enumValues: $1.Trinary.values)
    ..aOM<BuilderConfig_BuilderHealthLinks>(37, _omitFieldNames ? '' : 'builderHealthMetricsLinks',
        subBuilder: BuilderConfig_BuilderHealthLinks.create)
    ..aOS(38, _omitFieldNames ? '' : 'contactTeamEmail')
    ..a<$core.int>(39, _omitFieldNames ? '' : 'heartbeatTimeoutSecs', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderConfig clone() => BuilderConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderConfig copyWith(void Function(BuilderConfig) updates) =>
      super.copyWith((message) => updates(message as BuilderConfig)) as BuilderConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderConfig create() => BuilderConfig._();
  BuilderConfig createEmptyInstance() => create();
  static $pb.PbList<BuilderConfig> createRepeated() => $pb.PbList<BuilderConfig>();
  @$core.pragma('dart2js:noInline')
  static BuilderConfig getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderConfig>(create);
  static BuilderConfig? _defaultInstance;

  ///  Name of the builder.
  ///
  ///  If a builder name, will be propagated to "builder" build tag and
  ///  "buildername" recipe property.
  ///
  ///  A builder name must be unique within the bucket, and match regex
  ///  ^[a-zA-Z0-9\-_.\(\) ]{1,128}$.
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

  /// DEPRECATED.
  /// Used only to enable "vpython:native-python-wrapper"
  /// Does NOT actually propagate to swarming.
  @$pb.TagNumber(2)
  $core.List<$core.String> get swarmingTags => $_getList(1);

  ///  A requirement for a bot to execute the build.
  ///
  ///  Supports 2 forms:
  ///  - "<key>:<value>" - require a bot with this dimension.
  ///    This is a shortcut for "0:<key>:<value>", see below.
  ///  - "<expiration_secs>:<key>:<value>" - wait for up to expiration_secs.
  ///    for a bot with the dimension.
  ///    Supports multiple values for different keys and expiration_secs.
  ///    expiration_secs must be a multiple of 60.
  ///
  ///  If this builder is defined in a bucket, dimension "pool" is defaulted
  ///  to the name of the bucket. See Bucket message below.
  @$pb.TagNumber(3)
  $core.List<$core.String> get dimensions => $_getList(2);

  /// Specifies that a recipe to run.
  /// DEPRECATED: use exe.
  @$pb.TagNumber(4)
  BuilderConfig_Recipe get recipe => $_getN(3);
  @$pb.TagNumber(4)
  set recipe(BuilderConfig_Recipe v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRecipe() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipe() => clearField(4);
  @$pb.TagNumber(4)
  BuilderConfig_Recipe ensureRecipe() => $_ensure(3);

  ///  Swarming task priority.
  ///  A value between 20 and 255, inclusive.
  ///  Lower means more important.
  ///
  ///  The default value is configured in
  ///  https://chrome-internal.googlesource.com/infradata/config/+/89dede6f6a67eb06946a6009a6a88d377e957d25/configs/cr-buildbucket/swarming_task_template.json
  ///
  ///  See also https://chromium.googlesource.com/infra/luci/luci-py.git/+/main/appengine/swarming/doc/User-Guide.md#request
  @$pb.TagNumber(5)
  $core.int get priority => $_getIZ(4);
  @$pb.TagNumber(5)
  set priority($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPriority() => $_has(4);
  @$pb.TagNumber(5)
  void clearPriority() => clearField(5);

  /// Builder category. Will be used for visual grouping, for example in Code Review.
  @$pb.TagNumber(6)
  $core.String get category => $_getSZ(5);
  @$pb.TagNumber(6)
  set category($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCategory() => $_has(5);
  @$pb.TagNumber(6)
  void clearCategory() => clearField(6);

  ///  Maximum build execution time.
  ///
  ///  Not to be confused with pending time.
  ///
  ///  If the timeout is reached, the task will be signaled according to the
  ///  `deadline` section of
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/client/LUCI_CONTEXT.md
  ///  and status_details.timeout is set.
  ///
  ///  The task will have `grace_period` amount of time to handle cleanup
  ///  before being forcefully terminated.
  ///
  ///  NOTE: This corresponds with Build.execution_timeout and
  ///  ScheduleBuildRequest.execution_timeout; The name `execution_timeout_secs` and
  ///  uint32 type are relics of the past.
  @$pb.TagNumber(7)
  $core.int get executionTimeoutSecs => $_getIZ(6);
  @$pb.TagNumber(7)
  set executionTimeoutSecs($core.int v) {
    $_setUnsignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasExecutionTimeoutSecs() => $_has(6);
  @$pb.TagNumber(7)
  void clearExecutionTimeoutSecs() => clearField(7);

  /// Caches that should be present on the bot.
  @$pb.TagNumber(9)
  $core.List<BuilderConfig_CacheEntry> get caches => $_getList(7);

  /// Email of a service account to run the build as or literal 'bot' string to
  /// use Swarming bot's account (if available). Passed directly to Swarming.
  /// Subject to Swarming's ACLs.
  @$pb.TagNumber(12)
  $core.String get serviceAccount => $_getSZ(8);
  @$pb.TagNumber(12)
  set serviceAccount($core.String v) {
    $_setString(8, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasServiceAccount() => $_has(8);
  @$pb.TagNumber(12)
  void clearServiceAccount() => clearField(12);

  /// If YES, generate monotonically increasing contiguous numbers for each
  /// build, unique within the builder.
  /// Note: this limits the build creation rate in this builder to 5 per second.
  @$pb.TagNumber(16)
  Toggle get buildNumbers => $_getN(9);
  @$pb.TagNumber(16)
  set buildNumbers(Toggle v) {
    setField(16, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasBuildNumbers() => $_has(9);
  @$pb.TagNumber(16)
  void clearBuildNumbers() => clearField(16);

  ///  If YES, each builder will get extra dimension "builder:<builder name>"
  ///  added. Default is UNSET.
  ///
  ///  For example, this config
  ///
  ///    builder {
  ///      name: "linux-compiler"
  ///      dimension: "builder:linux-compiler"
  ///    }
  ///
  ///  is equivalent to this:
  ///
  ///    builders {
  ///      name: "linux-compiler"
  ///      auto_builder_dimension: YES
  ///    }
  ///
  ///  (see also http://docs.buildbot.net/0.8.9/manual/cfg-properties.html#interpolate)
  ///  but are currently against complicating config with this.
  @$pb.TagNumber(17)
  Toggle get autoBuilderDimension => $_getN(10);
  @$pb.TagNumber(17)
  set autoBuilderDimension(Toggle v) {
    setField(17, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasAutoBuilderDimension() => $_has(10);
  @$pb.TagNumber(17)
  void clearAutoBuilderDimension() => clearField(17);

  ///  DEPRECATED
  ///
  ///  Set the "luci.non_production" experiment in the 'experiments' field below,
  ///  instead.
  ///
  ///  If YES, sets the "luci.non_production" experiment to 100% for
  ///  builds on this builder.
  ///
  ///  See the documentation on `experiments` for more details about the
  ///  "luci.non_production" experiment.
  @$pb.TagNumber(18)
  Toggle get experimental => $_getN(11);
  @$pb.TagNumber(18)
  set experimental(Toggle v) {
    setField(18, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasExperimental() => $_has(11);
  @$pb.TagNumber(18)
  void clearExperimental() => clearField(18);

  ///  Maximum build pending time.
  ///
  ///  If the timeout is reached, the build is marked as INFRA_FAILURE status
  ///  and both status_details.{timeout, resource_exhaustion} are set.
  ///
  ///  NOTE: This corresponds with Build.scheduling_timeout and
  ///  ScheduleBuildRequest.scheduling_timeout; The name `expiration_secs` and
  ///  uint32 type are relics of the past.
  @$pb.TagNumber(20)
  $core.int get expirationSecs => $_getIZ(12);
  @$pb.TagNumber(20)
  set expirationSecs($core.int v) {
    $_setUnsignedInt32(12, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasExpirationSecs() => $_has(12);
  @$pb.TagNumber(20)
  void clearExpirationSecs() => clearField(20);

  /// Hostname of the swarming instance, e.g. "chromium-swarm.appspot.com".
  /// Required, but defaults to deprecated Swarming.hostname.
  @$pb.TagNumber(21)
  $core.String get swarmingHost => $_getSZ(13);
  @$pb.TagNumber(21)
  set swarmingHost($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(21)
  $core.bool hasSwarmingHost() => $_has(13);
  @$pb.TagNumber(21)
  void clearSwarmingHost() => clearField(21);

  ///  DEPRECATED
  ///
  ///  Set the "luci.buildbucket.canary_software" experiment in the 'experiments'
  ///  field below, instead.
  ///
  ///  Percentage of builds that should use a canary swarming task template.
  ///  A value from 0 to 100.
  ///  If omitted, a global server-defined default percentage is used.
  @$pb.TagNumber(22)
  $0.UInt32Value get taskTemplateCanaryPercentage => $_getN(14);
  @$pb.TagNumber(22)
  set taskTemplateCanaryPercentage($0.UInt32Value v) {
    setField(22, v);
  }

  @$pb.TagNumber(22)
  $core.bool hasTaskTemplateCanaryPercentage() => $_has(14);
  @$pb.TagNumber(22)
  void clearTaskTemplateCanaryPercentage() => clearField(22);
  @$pb.TagNumber(22)
  $0.UInt32Value ensureTaskTemplateCanaryPercentage() => $_ensure(14);

  /// What to run when a build is ready to start.
  @$pb.TagNumber(23)
  $1.Executable get exe => $_getN(15);
  @$pb.TagNumber(23)
  set exe($1.Executable v) {
    setField(23, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasExe() => $_has(15);
  @$pb.TagNumber(23)
  void clearExe() => clearField(23);
  @$pb.TagNumber(23)
  $1.Executable ensureExe() => $_ensure(15);

  /// A JSON object representing Build.input.properties.
  /// Individual object properties can be overridden with
  /// ScheduleBuildRequest.properties.
  @$pb.TagNumber(24)
  $core.String get properties => $_getSZ(16);
  @$pb.TagNumber(24)
  set properties($core.String v) {
    $_setString(16, v);
  }

  @$pb.TagNumber(24)
  $core.bool hasProperties() => $_has(16);
  @$pb.TagNumber(24)
  void clearProperties() => clearField(24);

  ///  This field will set the default value of the "critical" field of
  ///  all the builds of this builder. Please refer to build.proto for
  ///  the meaning of this field.
  ///
  ///  This value can be overridden by ScheduleBuildRequest.critical
  @$pb.TagNumber(25)
  $1.Trinary get critical => $_getN(17);
  @$pb.TagNumber(25)
  set critical($1.Trinary v) {
    setField(25, v);
  }

  @$pb.TagNumber(25)
  $core.bool hasCritical() => $_has(17);
  @$pb.TagNumber(25)
  void clearCritical() => clearField(25);

  /// Used to enable and configure ResultDB integration.
  @$pb.TagNumber(26)
  BuilderConfig_ResultDB get resultdb => $_getN(18);
  @$pb.TagNumber(26)
  set resultdb(BuilderConfig_ResultDB v) {
    setField(26, v);
  }

  @$pb.TagNumber(26)
  $core.bool hasResultdb() => $_has(18);
  @$pb.TagNumber(26)
  void clearResultdb() => clearField(26);
  @$pb.TagNumber(26)
  BuilderConfig_ResultDB ensureResultdb() => $_ensure(18);

  ///  A mapping of experiment name to the percentage chance (0-100) that it will
  ///  apply to builds generated from this builder. Experiments are simply strings
  ///  which various parts of the stack (from LUCI services down to your build
  ///  scripts) may react to in order to enable certain functionality.
  ///
  ///  You may set any experiments you like, but experiments beginning with
  ///  "luci." are reserved. Experiment names must conform to
  ///
  ///     [a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*
  ///
  ///  Any experiments which are selected for a build show up in
  ///  `Build.input.experiments`.
  ///
  ///  Its recommended that you confine your experiments to smaller, more explicit
  ///  targets. For example, prefer the experiment named
  ///  "my_project.use_mysoftware_v2_crbug_999999" rather than "use_next_gen".
  ///
  ///  It is NOT recommended to 'piggy-back' on top of existing experiment names
  ///  for a different purpose. However if you want to, you can have your build
  ///  treat the presence of ANY experiment as equivalent to "luci.non_production"
  ///  being set for your build (i.e. "if any experiment is set, don't affect
  ///  production"). This is ulimately up to you, however.
  ///
  ///  Well-known experiments
  ///
  ///  Buildbucket has a number of 'global' experiments which are in various
  ///  states of deployment at any given time. For the current state, see
  ///  go/buildbucket-settings.cfg.
  @$pb.TagNumber(28)
  $core.Map<$core.String, $core.int> get experiments => $_getMap(19);

  ///  If YES, will request that swarming wait until it sees at least one bot
  ///  report a superset of the requested dimensions.
  ///
  ///  If UNSET/NO (the default), swarming will immediately reject a build which
  ///  specifies a dimension set that it's never seen before.
  ///
  ///  Usually you want this to be UNSET/NO, unless you know that some external
  ///  system is working to add bots to swarming which will match the requested
  ///  dimensions within expiration_secs. Otherwise you'll have to wait for all of
  ///  `expiration_secs` until swarming tells you "Sorry, nothing has dimension
  ///  `os:MadeUpOS`".
  @$pb.TagNumber(29)
  $1.Trinary get waitForCapacity => $_getN(20);
  @$pb.TagNumber(29)
  set waitForCapacity($1.Trinary v) {
    setField(29, v);
  }

  @$pb.TagNumber(29)
  $core.bool hasWaitForCapacity() => $_has(20);
  @$pb.TagNumber(29)
  void clearWaitForCapacity() => clearField(29);

  /// Description that helps users understand the purpose of the builder, in
  /// HTML.
  @$pb.TagNumber(30)
  $core.String get descriptionHtml => $_getSZ(21);
  @$pb.TagNumber(30)
  set descriptionHtml($core.String v) {
    $_setString(21, v);
  }

  @$pb.TagNumber(30)
  $core.bool hasDescriptionHtml() => $_has(21);
  @$pb.TagNumber(30)
  void clearDescriptionHtml() => clearField(30);

  ///  Amount of cleanup time after execution_timeout_secs.
  ///
  ///  After being signaled according to execution_timeout_secs, the task will
  ///  have this many seconds to clean up before being forcefully terminated.
  ///
  ///  The signalling process is explained in the `deadline` section of
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/client/LUCI_CONTEXT.md.
  ///
  ///  Defaults to 30s if unspecified or 0.
  @$pb.TagNumber(31)
  $2.Duration get gracePeriod => $_getN(22);
  @$pb.TagNumber(31)
  set gracePeriod($2.Duration v) {
    setField(31, v);
  }

  @$pb.TagNumber(31)
  $core.bool hasGracePeriod() => $_has(22);
  @$pb.TagNumber(31)
  void clearGracePeriod() => clearField(31);
  @$pb.TagNumber(31)
  $2.Duration ensureGracePeriod() => $_ensure(22);

  /// Backend for this builder.
  /// If unset, builds are scheduled using the legacy pipeline.
  @$pb.TagNumber(32)
  BuilderConfig_Backend get backend => $_getN(23);
  @$pb.TagNumber(32)
  set backend(BuilderConfig_Backend v) {
    setField(32, v);
  }

  @$pb.TagNumber(32)
  $core.bool hasBackend() => $_has(23);
  @$pb.TagNumber(32)
  void clearBackend() => clearField(32);
  @$pb.TagNumber(32)
  BuilderConfig_Backend ensureBackend() => $_ensure(23);

  /// Alternate backend to use for this builder when the
  /// "luci.buildbucket.backend_alt" experiment is enabled. Works even when
  /// `backend` is empty. Useful for migrations to new backends.
  @$pb.TagNumber(33)
  BuilderConfig_Backend get backendAlt => $_getN(24);
  @$pb.TagNumber(33)
  set backendAlt(BuilderConfig_Backend v) {
    setField(33, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasBackendAlt() => $_has(24);
  @$pb.TagNumber(33)
  void clearBackendAlt() => clearField(33);
  @$pb.TagNumber(33)
  BuilderConfig_Backend ensureBackendAlt() => $_ensure(24);

  ///  A list of top-level property names which can be overridden in
  ///  ScheduleBuildRequest.
  ///
  ///  If this field is the EXACT value `["*"]` then all properties are permitted
  ///  to be overridden.
  ///
  ///  NOTE: Some executables (such as the recipe engine) can have drastic
  ///  behavior differences based on some properties (for example, the "recipe"
  ///  property). If you allow the "recipe" property to be overridden, then anyone
  ///  with the 'buildbucket.builds.add' permission could create a Build for this
  ///  Builder running a different recipe (from the same recipe repo).
  @$pb.TagNumber(34)
  $core.List<$core.String> get allowedPropertyOverrides => $_getList(25);

  @$pb.TagNumber(35)
  BuilderConfig_ShadowBuilderAdjustments get shadowBuilderAdjustments => $_getN(26);
  @$pb.TagNumber(35)
  set shadowBuilderAdjustments(BuilderConfig_ShadowBuilderAdjustments v) {
    setField(35, v);
  }

  @$pb.TagNumber(35)
  $core.bool hasShadowBuilderAdjustments() => $_has(26);
  @$pb.TagNumber(35)
  void clearShadowBuilderAdjustments() => clearField(35);
  @$pb.TagNumber(35)
  BuilderConfig_ShadowBuilderAdjustments ensureShadowBuilderAdjustments() => $_ensure(26);

  ///  This field will set the default value of the "retriable" field of
  ///  all the builds of this builder. Please refer to build.proto for
  ///  the meaning of this field.
  ///
  ///  This value can be overridden by ScheduleBuildRequest.retriable
  @$pb.TagNumber(36)
  $1.Trinary get retriable => $_getN(27);
  @$pb.TagNumber(36)
  set retriable($1.Trinary v) {
    setField(36, v);
  }

  @$pb.TagNumber(36)
  $core.bool hasRetriable() => $_has(27);
  @$pb.TagNumber(36)
  void clearRetriable() => clearField(36);

  @$pb.TagNumber(37)
  BuilderConfig_BuilderHealthLinks get builderHealthMetricsLinks => $_getN(28);
  @$pb.TagNumber(37)
  set builderHealthMetricsLinks(BuilderConfig_BuilderHealthLinks v) {
    setField(37, v);
  }

  @$pb.TagNumber(37)
  $core.bool hasBuilderHealthMetricsLinks() => $_has(28);
  @$pb.TagNumber(37)
  void clearBuilderHealthMetricsLinks() => clearField(37);
  @$pb.TagNumber(37)
  BuilderConfig_BuilderHealthLinks ensureBuilderHealthMetricsLinks() => $_ensure(28);

  /// The owning team's contact email. This team is responsible for fixing
  /// any builder health issues (see Builder.Metadata.HealthSpec).
  /// Will be validated as an email address, but nothing else.
  /// It will display on milo and could be public facing, so please don't put anything sensitive.
  @$pb.TagNumber(38)
  $core.String get contactTeamEmail => $_getSZ(29);
  @$pb.TagNumber(38)
  set contactTeamEmail($core.String v) {
    $_setString(29, v);
  }

  @$pb.TagNumber(38)
  $core.bool hasContactTeamEmail() => $_has(29);
  @$pb.TagNumber(38)
  void clearContactTeamEmail() => clearField(38);

  ///  Maximum amount of time to wait for the next heartbeat(i.e UpdateBuild).
  ///
  ///  After a build is started, the client can send heartbeat requests
  ///  periodically. Buildbucket will mark the build as INFRA_FAILURE, if the
  ///  timeout threshold reaches. It’s to fail a build more quickly, rather than
  ///  waiting for `execution_timeout_secs` to expire. Some V1 users, which don't
  ///  have real task backends, can utilize this feature.
  ///
  ///  By default, the value is 0, which means no timeout threshold is applied.
  ///
  ///  Note: this field only takes effect for TaskBackendLite builds. For builds
  ///  with full-featured TaskBackend Implementation, `sync_backend_tasks` cron
  ///  job fulfills the similar functionality.
  @$pb.TagNumber(39)
  $core.int get heartbeatTimeoutSecs => $_getIZ(30);
  @$pb.TagNumber(39)
  set heartbeatTimeoutSecs($core.int v) {
    $_setUnsignedInt32(30, v);
  }

  @$pb.TagNumber(39)
  $core.bool hasHeartbeatTimeoutSecs() => $_has(30);
  @$pb.TagNumber(39)
  void clearHeartbeatTimeoutSecs() => clearField(39);
}

/// Configuration of buildbucket-swarming integration for one bucket.
class Swarming extends $pb.GeneratedMessage {
  factory Swarming({
    $core.Iterable<BuilderConfig>? builders,
    $0.UInt32Value? taskTemplateCanaryPercentage,
  }) {
    final $result = create();
    if (builders != null) {
      $result.builders.addAll(builders);
    }
    if (taskTemplateCanaryPercentage != null) {
      $result.taskTemplateCanaryPercentage = taskTemplateCanaryPercentage;
    }
    return $result;
  }
  Swarming._() : super();
  factory Swarming.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Swarming',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<BuilderConfig>(4, _omitFieldNames ? '' : 'builders', $pb.PbFieldType.PM, subBuilder: BuilderConfig.create)
    ..aOM<$0.UInt32Value>(5, _omitFieldNames ? '' : 'taskTemplateCanaryPercentage', subBuilder: $0.UInt32Value.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Swarming clone() => Swarming()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Swarming copyWith(void Function(Swarming) updates) =>
      super.copyWith((message) => updates(message as Swarming)) as Swarming;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Swarming create() => Swarming._();
  Swarming createEmptyInstance() => create();
  static $pb.PbList<Swarming> createRepeated() => $pb.PbList<Swarming>();
  @$core.pragma('dart2js:noInline')
  static Swarming getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Swarming>(create);
  static Swarming? _defaultInstance;

  /// Configuration for each builder.
  /// Swarming tasks are created only for builds for builders that are not
  /// explicitly specified.
  @$pb.TagNumber(4)
  $core.List<BuilderConfig> get builders => $_getList(0);

  /// DEPRECATED. Use builder_defaults.task_template_canary_percentage instead.
  /// Setting this field sets builder_defaults.task_template_canary_percentage.
  @$pb.TagNumber(5)
  $0.UInt32Value get taskTemplateCanaryPercentage => $_getN(1);
  @$pb.TagNumber(5)
  set taskTemplateCanaryPercentage($0.UInt32Value v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTaskTemplateCanaryPercentage() => $_has(1);
  @$pb.TagNumber(5)
  void clearTaskTemplateCanaryPercentage() => clearField(5);
  @$pb.TagNumber(5)
  $0.UInt32Value ensureTaskTemplateCanaryPercentage() => $_ensure(1);
}

///  Constraints for a bucket.
///
///  Buildbucket.CreateBuild will validate the incoming requests to make sure
///  they meet these constraints.
class Bucket_Constraints extends $pb.GeneratedMessage {
  factory Bucket_Constraints({
    $core.Iterable<$core.String>? pools,
    $core.Iterable<$core.String>? serviceAccounts,
  }) {
    final $result = create();
    if (pools != null) {
      $result.pools.addAll(pools);
    }
    if (serviceAccounts != null) {
      $result.serviceAccounts.addAll(serviceAccounts);
    }
    return $result;
  }
  Bucket_Constraints._() : super();
  factory Bucket_Constraints.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Bucket_Constraints.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket.Constraints',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'pools')
    ..pPS(2, _omitFieldNames ? '' : 'serviceAccounts')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Bucket_Constraints clone() => Bucket_Constraints()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Bucket_Constraints copyWith(void Function(Bucket_Constraints) updates) =>
      super.copyWith((message) => updates(message as Bucket_Constraints)) as Bucket_Constraints;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Bucket_Constraints create() => Bucket_Constraints._();
  Bucket_Constraints createEmptyInstance() => create();
  static $pb.PbList<Bucket_Constraints> createRepeated() => $pb.PbList<Bucket_Constraints>();
  @$core.pragma('dart2js:noInline')
  static Bucket_Constraints getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bucket_Constraints>(create);
  static Bucket_Constraints? _defaultInstance;

  /// Constraints allowed pools.
  /// Builds in this bucket must have a "pool" dimension which matches an entry in this list.
  @$pb.TagNumber(1)
  $core.List<$core.String> get pools => $_getList(0);

  /// Only service accounts in this list are allowed.
  @$pb.TagNumber(2)
  $core.List<$core.String> get serviceAccounts => $_getList(1);
}

/// Template of builders in a dynamic bucket.
class Bucket_DynamicBuilderTemplate extends $pb.GeneratedMessage {
  factory Bucket_DynamicBuilderTemplate({
    BuilderConfig? template,
  }) {
    final $result = create();
    if (template != null) {
      $result.template = template;
    }
    return $result;
  }
  Bucket_DynamicBuilderTemplate._() : super();
  factory Bucket_DynamicBuilderTemplate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Bucket_DynamicBuilderTemplate.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket.DynamicBuilderTemplate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOM<BuilderConfig>(1, _omitFieldNames ? '' : 'template', subBuilder: BuilderConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate clone() => Bucket_DynamicBuilderTemplate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Bucket_DynamicBuilderTemplate copyWith(void Function(Bucket_DynamicBuilderTemplate) updates) =>
      super.copyWith((message) => updates(message as Bucket_DynamicBuilderTemplate)) as Bucket_DynamicBuilderTemplate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Bucket_DynamicBuilderTemplate create() => Bucket_DynamicBuilderTemplate._();
  Bucket_DynamicBuilderTemplate createEmptyInstance() => create();
  static $pb.PbList<Bucket_DynamicBuilderTemplate> createRepeated() => $pb.PbList<Bucket_DynamicBuilderTemplate>();
  @$core.pragma('dart2js:noInline')
  static Bucket_DynamicBuilderTemplate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Bucket_DynamicBuilderTemplate>(create);
  static Bucket_DynamicBuilderTemplate? _defaultInstance;

  /// The Builder template which is shared among all builders in this dynamic
  /// bucket.
  @$pb.TagNumber(1)
  BuilderConfig get template => $_getN(0);
  @$pb.TagNumber(1)
  set template(BuilderConfig v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTemplate() => $_has(0);
  @$pb.TagNumber(1)
  void clearTemplate() => clearField(1);
  @$pb.TagNumber(1)
  BuilderConfig ensureTemplate() => $_ensure(0);
}

/// Defines one bucket in buildbucket.cfg
class Bucket extends $pb.GeneratedMessage {
  factory Bucket({
    $core.String? name,
    @$core.Deprecated('This field is deprecated.') $core.Iterable<Acl>? acls,
    Swarming? swarming,
    $core.String? shadow,
    Bucket_Constraints? constraints,
    Bucket_DynamicBuilderTemplate? dynamicBuilderTemplate,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (acls != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.acls.addAll(acls);
    }
    if (swarming != null) {
      $result.swarming = swarming;
    }
    if (shadow != null) {
      $result.shadow = shadow;
    }
    if (constraints != null) {
      $result.constraints = constraints;
    }
    if (dynamicBuilderTemplate != null) {
      $result.dynamicBuilderTemplate = dynamicBuilderTemplate;
    }
    return $result;
  }
  Bucket._() : super();
  factory Bucket.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Bucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Bucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..pc<Acl>(2, _omitFieldNames ? '' : 'acls', $pb.PbFieldType.PM, subBuilder: Acl.create)
    ..aOM<Swarming>(3, _omitFieldNames ? '' : 'swarming', subBuilder: Swarming.create)
    ..aOS(5, _omitFieldNames ? '' : 'shadow')
    ..aOM<Bucket_Constraints>(6, _omitFieldNames ? '' : 'constraints', subBuilder: Bucket_Constraints.create)
    ..aOM<Bucket_DynamicBuilderTemplate>(7, _omitFieldNames ? '' : 'dynamicBuilderTemplate',
        subBuilder: Bucket_DynamicBuilderTemplate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Bucket clone() => Bucket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
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

  /// Name of the bucket. Names are unique within one instance of buildbucket.
  /// If another project already uses this name, a config will be rejected.
  /// Name reservation is first-come first-serve.
  /// Regex: ^[a-z0-9\-_.]{1,100}$
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

  /// Deprecated and ignored. Use Realms ACLs instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(2)
  $core.List<Acl> get acls => $_getList(1);

  /// Buildbucket-swarming integration.
  /// Mutually exclusive with builder_template.
  @$pb.TagNumber(3)
  Swarming get swarming => $_getN(2);
  @$pb.TagNumber(3)
  set swarming(Swarming v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSwarming() => $_has(2);
  @$pb.TagNumber(3)
  void clearSwarming() => clearField(3);
  @$pb.TagNumber(3)
  Swarming ensureSwarming() => $_ensure(2);

  ///  Name of this bucket's shadow bucket for the led builds to use.
  ///
  ///  If omitted, it implies that led builds of this bucket reuse this bucket.
  ///  This is allowed, but note that it means the led builds will be in
  ///  the same bucket/builder with the real builds, which means Any users with
  ///  led access will be able to do ANYTHING that this bucket's bots and
  ///  service_accounts can do.
  ///
  ///  It could also be noisy, such as:
  ///  * On the LUCI UI, led builds will show under the same builder as the real builds,
  ///  * Led builds will share the same ResultDB config as the real builds, so
  ///    their test results will be exported to the same BigQuery tables.
  ///  * Subscribers of Buildbucket PubSub need to filter them out.
  ///
  ///  Note: Don't set it if it's a dynamic bucket. Currently, a dynamic bucket is
  ///  not allowed to have a shadow bucket.
  @$pb.TagNumber(5)
  $core.String get shadow => $_getSZ(3);
  @$pb.TagNumber(5)
  set shadow($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasShadow() => $_has(3);
  @$pb.TagNumber(5)
  void clearShadow() => clearField(5);

  ///  Security constraints of the bucket.
  ///
  ///  This field is used by CreateBuild on this bucket to constrain proposed
  ///  Builds. If a build doesn't meet the constraints, it will be rejected.
  ///  For shadow buckets, this is what prevents the bucket from allowing
  ///  totally arbitrary Builds.
  ///
  ///  `lucicfg` will automatically populate this for the "primary" bucket
  ///  when using `luci.builder`.
  ///
  ///  Buildbuceket.CreateBuild will validate the incoming requests to make sure
  ///  they meet these constraints.
  @$pb.TagNumber(6)
  Bucket_Constraints get constraints => $_getN(4);
  @$pb.TagNumber(6)
  set constraints(Bucket_Constraints v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasConstraints() => $_has(4);
  @$pb.TagNumber(6)
  void clearConstraints() => clearField(6);
  @$pb.TagNumber(6)
  Bucket_Constraints ensureConstraints() => $_ensure(4);

  ///  Template of builders in a dynamic bucket.
  ///  Mutually exclusive with swarming.
  ///
  ///  If is not nil, the bucket is a dynamic LUCI bucket.
  ///  If a bucket has both swarming and dynamic_builder_template as nil,
  ///  the bucket is a legacy one.
  @$pb.TagNumber(7)
  Bucket_DynamicBuilderTemplate get dynamicBuilderTemplate => $_getN(5);
  @$pb.TagNumber(7)
  set dynamicBuilderTemplate(Bucket_DynamicBuilderTemplate v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasDynamicBuilderTemplate() => $_has(5);
  @$pb.TagNumber(7)
  void clearDynamicBuilderTemplate() => clearField(7);
  @$pb.TagNumber(7)
  Bucket_DynamicBuilderTemplate ensureDynamicBuilderTemplate() => $_ensure(5);
}

class BuildbucketCfg_Topic extends $pb.GeneratedMessage {
  factory BuildbucketCfg_Topic({
    $core.String? name,
    $1.Compression? compression,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (compression != null) {
      $result.compression = compression;
    }
    return $result;
  }
  BuildbucketCfg_Topic._() : super();
  factory BuildbucketCfg_Topic.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg_Topic.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg.Topic',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<$1.Compression>(2, _omitFieldNames ? '' : 'compression', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Compression.ZLIB, valueOf: $1.Compression.valueOf, enumValues: $1.Compression.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildbucketCfg_Topic clone() => BuildbucketCfg_Topic()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildbucketCfg_Topic copyWith(void Function(BuildbucketCfg_Topic) updates) =>
      super.copyWith((message) => updates(message as BuildbucketCfg_Topic)) as BuildbucketCfg_Topic;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_Topic create() => BuildbucketCfg_Topic._();
  BuildbucketCfg_Topic createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg_Topic> createRepeated() => $pb.PbList<BuildbucketCfg_Topic>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_Topic getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg_Topic>(create);
  static BuildbucketCfg_Topic? _defaultInstance;

  /// Topic name format should be like
  /// "projects/<projid>/topics/<topicid>" and conforms to the guideline:
  /// https://cloud.google.com/pubsub/docs/admin#resource_names.
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

  /// The compression method that  `build_large_fields` uses in pubsub message
  /// data. By default, it's ZLIB as this is the most common one and is the
  /// built-in lib in many programming languages.
  @$pb.TagNumber(2)
  $1.Compression get compression => $_getN(1);
  @$pb.TagNumber(2)
  set compression($1.Compression v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCompression() => $_has(1);
  @$pb.TagNumber(2)
  void clearCompression() => clearField(2);
}

class BuildbucketCfg_CommonConfig extends $pb.GeneratedMessage {
  factory BuildbucketCfg_CommonConfig({
    $core.Iterable<BuildbucketCfg_Topic>? buildsNotificationTopics,
  }) {
    final $result = create();
    if (buildsNotificationTopics != null) {
      $result.buildsNotificationTopics.addAll(buildsNotificationTopics);
    }
    return $result;
  }
  BuildbucketCfg_CommonConfig._() : super();
  factory BuildbucketCfg_CommonConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg_CommonConfig.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg.CommonConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<BuildbucketCfg_Topic>(1, _omitFieldNames ? '' : 'buildsNotificationTopics', $pb.PbFieldType.PM,
        subBuilder: BuildbucketCfg_Topic.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildbucketCfg_CommonConfig clone() => BuildbucketCfg_CommonConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildbucketCfg_CommonConfig copyWith(void Function(BuildbucketCfg_CommonConfig) updates) =>
      super.copyWith((message) => updates(message as BuildbucketCfg_CommonConfig)) as BuildbucketCfg_CommonConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_CommonConfig create() => BuildbucketCfg_CommonConfig._();
  BuildbucketCfg_CommonConfig createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg_CommonConfig> createRepeated() => $pb.PbList<BuildbucketCfg_CommonConfig>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg_CommonConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg_CommonConfig>(create);
  static BuildbucketCfg_CommonConfig? _defaultInstance;

  ///  A list of PubSub topics that Buildbucket will publish notifications for
  ///  build status changes in this project.
  ///  The message data schema can be found in message `BuildsV2PubSub` in
  ///  https://chromium.googlesource.com/infra/luci/luci-go/+/main/buildbucket/proto/notification.proto
  ///  Attributes on the pubsub messages:
  ///  - "project"
  ///  - "bucket"
  ///  - "builder"
  ///  - "is_completed" (The value is either "true" or "false" in string.)
  ///
  ///  Note: `pubsub.topics.publish` permission must be granted to the
  ///  corresponding luci-project-scoped accounts in the cloud project(s) hosting
  ///  the topics.
  @$pb.TagNumber(1)
  $core.List<BuildbucketCfg_Topic> get buildsNotificationTopics => $_getList(0);
}

/// Schema of buildbucket.cfg file, a project config.
class BuildbucketCfg extends $pb.GeneratedMessage {
  factory BuildbucketCfg({
    $core.Iterable<Bucket>? buckets,
    BuildbucketCfg_CommonConfig? commonConfig,
  }) {
    final $result = create();
    if (buckets != null) {
      $result.buckets.addAll(buckets);
    }
    if (commonConfig != null) {
      $result.commonConfig = commonConfig;
    }
    return $result;
  }
  BuildbucketCfg._() : super();
  factory BuildbucketCfg.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildbucketCfg.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildbucketCfg',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket'), createEmptyInstance: create)
    ..pc<Bucket>(1, _omitFieldNames ? '' : 'buckets', $pb.PbFieldType.PM, subBuilder: Bucket.create)
    ..aOM<BuildbucketCfg_CommonConfig>(5, _omitFieldNames ? '' : 'commonConfig',
        subBuilder: BuildbucketCfg_CommonConfig.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildbucketCfg clone() => BuildbucketCfg()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildbucketCfg copyWith(void Function(BuildbucketCfg) updates) =>
      super.copyWith((message) => updates(message as BuildbucketCfg)) as BuildbucketCfg;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg create() => BuildbucketCfg._();
  BuildbucketCfg createEmptyInstance() => create();
  static $pb.PbList<BuildbucketCfg> createRepeated() => $pb.PbList<BuildbucketCfg>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketCfg getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildbucketCfg>(create);
  static BuildbucketCfg? _defaultInstance;

  /// All buckets defined for this project.
  @$pb.TagNumber(1)
  $core.List<Bucket> get buckets => $_getList(0);

  /// Global configs are shared among all buckets and builders defined inside
  /// this project.
  @$pb.TagNumber(5)
  BuildbucketCfg_CommonConfig get commonConfig => $_getN(1);
  @$pb.TagNumber(5)
  set commonConfig(BuildbucketCfg_CommonConfig v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCommonConfig() => $_has(1);
  @$pb.TagNumber(5)
  void clearCommonConfig() => clearField(5);
  @$pb.TagNumber(5)
  BuildbucketCfg_CommonConfig ensureCommonConfig() => $_ensure(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
