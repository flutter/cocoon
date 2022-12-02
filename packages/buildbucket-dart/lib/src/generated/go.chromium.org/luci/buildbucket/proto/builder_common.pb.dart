///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'project_config.pb.dart' as $0;

class BuilderID extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderID',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'project')
    ..aOS(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'bucket')
    ..aOS(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'builder')
    ..hasRequiredFields = false;

  BuilderID._() : super();
  factory BuilderID({
    $core.String? project,
    $core.String? bucket,
    $core.String? builder,
  }) {
    final _result = create();
    if (project != null) {
      _result.project = project;
    }
    if (bucket != null) {
      _result.bucket = bucket;
    }
    if (builder != null) {
      _result.builder = builder;
    }
    return _result;
  }
  factory BuilderID.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderID.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderID clone() => BuilderID()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderID copyWith(void Function(BuilderID) updates) =>
      super.copyWith((message) => updates(message as BuilderID)) as BuilderID; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderID create() => BuilderID._();
  BuilderID createEmptyInstance() => create();
  static $pb.PbList<BuilderID> createRepeated() => $pb.PbList<BuilderID>();
  @$core.pragma('dart2js:noInline')
  static BuilderID getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderID>(create);
  static BuilderID? _defaultInstance;

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

class BuilderItem extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'BuilderItem',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<BuilderID>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'id',
        subBuilder: BuilderID.create)
    ..aOM<$0.BuilderConfig>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'config',
        subBuilder: $0.BuilderConfig.create)
    ..hasRequiredFields = false;

  BuilderItem._() : super();
  factory BuilderItem({
    BuilderID? id,
    $0.BuilderConfig? config,
  }) {
    final _result = create();
    if (id != null) {
      _result.id = id;
    }
    if (config != null) {
      _result.config = config;
    }
    return _result;
  }
  factory BuilderItem.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuilderItem.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuilderItem clone() => BuilderItem()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuilderItem copyWith(void Function(BuilderItem) updates) =>
      super.copyWith((message) => updates(message as BuilderItem)) as BuilderItem; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static BuilderItem create() => BuilderItem._();
  BuilderItem createEmptyInstance() => create();
  static $pb.PbList<BuilderItem> createRepeated() => $pb.PbList<BuilderItem>();
  @$core.pragma('dart2js:noInline')
  static BuilderItem getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuilderItem>(create);
  static BuilderItem? _defaultInstance;

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

  @$pb.TagNumber(2)
  $0.BuilderConfig get config => $_getN(1);
  @$pb.TagNumber(2)
  set config($0.BuilderConfig v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasConfig() => $_has(1);
  @$pb.TagNumber(2)
  void clearConfig() => clearField(2);
  @$pb.TagNumber(2)
  $0.BuilderConfig ensureConfig() => $_ensure(1);
}
