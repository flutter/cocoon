//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'common.pb.dart' as $0;
import 'project_config.pb.dart' as $1;

/// Identifies a builder.
/// Canonical string representation: "{project}/{bucket}/{builder}".
class BuilderID extends $pb.GeneratedMessage {
  factory BuilderID({
    $core.String? project,
    $core.String? bucket,
    $core.String? builder,
  }) {
    final $result = create();
    if (project != null) {
      $result.project = project;
    }
    if (bucket != null) {
      $result.bucket = bucket;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    return $result;
  }
  BuilderID._() : super();
  factory BuilderID.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderID.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderID',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'project')
    ..aOS(2, _omitFieldNames ? '' : 'bucket')
    ..aOS(3, _omitFieldNames ? '' : 'builder')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderID clone() => BuilderID()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderID copyWith(void Function(BuilderID) updates) =>
      super.copyWith((message) => updates(message as BuilderID)) as BuilderID;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderID create() => BuilderID._();
  BuilderID createEmptyInstance() => create();
  static $pb.PbList<BuilderID> createRepeated() => $pb.PbList<BuilderID>();
  @$core.pragma('dart2js:noInline')
  static BuilderID getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderID>(create);
  static BuilderID? _defaultInstance;

  /// Project ID, e.g. "chromium". Unique within a LUCI deployment.
  /// Regex: ^[a-z0-9\-_]+$
  @$pb.TagNumber(1)
  $core.String get project => $_getSZ(0);
  @$pb.TagNumber(1)
  set project($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProject() => $_has(0);
  @$pb.TagNumber(1)
  void clearProject() => clearField(1);

  /// Bucket name, e.g. "try". Unique within the project.
  /// Regex: ^[a-z0-9\-_.]{1,100}$
  /// Together with project, defines an ACL.
  @$pb.TagNumber(2)
  $core.String get bucket => $_getSZ(1);
  @$pb.TagNumber(2)
  set bucket($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBucket() => $_has(1);
  @$pb.TagNumber(2)
  void clearBucket() => clearField(2);

  /// Builder name, e.g. "linux-rel". Unique within the bucket.
  /// Regex: ^[a-zA-Z0-9\-_.\(\) ]{1,128}$
  @$pb.TagNumber(3)
  $core.String get builder => $_getSZ(2);
  @$pb.TagNumber(3)
  set builder($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBuilder() => $_has(2);
  @$pb.TagNumber(3)
  void clearBuilder() => clearField(3);
}

class BuilderMetadata extends $pb.GeneratedMessage {
  factory BuilderMetadata({
    $core.String? owner,
    $0.HealthStatus? health,
  }) {
    final $result = create();
    if (owner != null) {
      $result.owner = owner;
    }
    if (health != null) {
      $result.health = health;
    }
    return $result;
  }
  BuilderMetadata._() : super();
  factory BuilderMetadata.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderMetadata.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'owner')
    ..aOM<$0.HealthStatus>(2, _omitFieldNames ? '' : 'health', subBuilder: $0.HealthStatus.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderMetadata clone() => BuilderMetadata()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderMetadata copyWith(void Function(BuilderMetadata) updates) =>
      super.copyWith((message) => updates(message as BuilderMetadata)) as BuilderMetadata;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderMetadata create() => BuilderMetadata._();
  BuilderMetadata createEmptyInstance() => create();
  static $pb.PbList<BuilderMetadata> createRepeated() => $pb.PbList<BuilderMetadata>();
  @$core.pragma('dart2js:noInline')
  static BuilderMetadata getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderMetadata>(create);
  static BuilderMetadata? _defaultInstance;

  /// Team that owns the builder
  @$pb.TagNumber(1)
  $core.String get owner => $_getSZ(0);
  @$pb.TagNumber(1)
  set owner($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasOwner() => $_has(0);
  @$pb.TagNumber(1)
  void clearOwner() => clearField(1);

  /// Builders current health status
  @$pb.TagNumber(2)
  $0.HealthStatus get health => $_getN(1);
  @$pb.TagNumber(2)
  set health($0.HealthStatus v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasHealth() => $_has(1);
  @$pb.TagNumber(2)
  void clearHealth() => clearField(2);
  @$pb.TagNumber(2)
  $0.HealthStatus ensureHealth() => $_ensure(1);
}

///  A configured builder.
///
///  It is called BuilderItem and not Builder because
///  1) Builder already exists
///  2) Name "Builder" is incompatible with proto->Java compiler.
class BuilderItem extends $pb.GeneratedMessage {
  factory BuilderItem({
    BuilderID? id,
    $1.BuilderConfig? config,
    BuilderMetadata? metadata,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (config != null) {
      $result.config = config;
    }
    if (metadata != null) {
      $result.metadata = metadata;
    }
    return $result;
  }
  BuilderItem._() : super();
  factory BuilderItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuilderItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuilderID>(1, _omitFieldNames ? '' : 'id', subBuilder: BuilderID.create)
    ..aOM<$1.BuilderConfig>(2, _omitFieldNames ? '' : 'config', subBuilder: $1.BuilderConfig.create)
    ..aOM<BuilderMetadata>(3, _omitFieldNames ? '' : 'metadata', subBuilder: BuilderMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderItem clone() => BuilderItem()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderItem copyWith(void Function(BuilderItem) updates) =>
      super.copyWith((message) => updates(message as BuilderItem)) as BuilderItem;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuilderItem create() => BuilderItem._();
  BuilderItem createEmptyInstance() => create();
  static $pb.PbList<BuilderItem> createRepeated() => $pb.PbList<BuilderItem>();
  @$core.pragma('dart2js:noInline')
  static BuilderItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderItem>(create);
  static BuilderItem? _defaultInstance;

  /// Uniquely identifies the builder in a given Buildbucket instance.
  @$pb.TagNumber(1)
  BuilderID get id => $_getN(0);
  @$pb.TagNumber(1)
  set id(BuilderID v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
  @$pb.TagNumber(1)
  BuilderID ensureId() => $_ensure(0);

  /// User-supplied configuration after normalization.
  /// Does not refer to mixins and has defaults inlined.
  @$pb.TagNumber(2)
  $1.BuilderConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config($1.BuilderConfig v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => clearField(2);
  @$pb.TagNumber(2)
  $1.BuilderConfig ensureConfig() => $_ensure(1);

  /// Metadata surrounding the builder.
  @$pb.TagNumber(3)
  BuilderMetadata get metadata => $_getN(2);
  @$pb.TagNumber(3)
  set metadata(BuilderMetadata v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasMetadata() => $_has(2);
  @$pb.TagNumber(3)
  void clearMetadata() => clearField(3);
  @$pb.TagNumber(3)
  BuilderMetadata ensureMetadata() => $_ensure(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
