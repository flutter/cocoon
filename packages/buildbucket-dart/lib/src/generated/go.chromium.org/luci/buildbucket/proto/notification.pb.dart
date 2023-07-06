//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/notification.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'build.pb.dart' as $0;
import 'common.pbenum.dart' as $1;

class NotificationConfig extends $pb.GeneratedMessage {
  factory NotificationConfig() => create();
  NotificationConfig._() : super();
  factory NotificationConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory NotificationConfig.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotificationConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pubsubTopic')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'userData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  NotificationConfig clone() => NotificationConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  NotificationConfig copyWith(void Function(NotificationConfig) updates) =>
      super.copyWith((message) => updates(message as NotificationConfig)) as NotificationConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotificationConfig create() => NotificationConfig._();
  NotificationConfig createEmptyInstance() => create();
  static $pb.PbList<NotificationConfig> createRepeated() => $pb.PbList<NotificationConfig>();
  @$core.pragma('dart2js:noInline')
  static NotificationConfig getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotificationConfig>(create);
  static NotificationConfig? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pubsubTopic => $_getSZ(0);
  @$pb.TagNumber(1)
  set pubsubTopic($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPubsubTopic() => $_has(0);
  @$pb.TagNumber(1)
  void clearPubsubTopic() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get userData => $_getN(1);
  @$pb.TagNumber(2)
  set userData($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUserData() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserData() => clearField(2);
}

class BuildsV2PubSub extends $pb.GeneratedMessage {
  factory BuildsV2PubSub() => create();
  BuildsV2PubSub._() : super();
  factory BuildsV2PubSub.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildsV2PubSub.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildsV2PubSub',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$0.Build>(1, _omitFieldNames ? '' : 'build', subBuilder: $0.Build.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'buildLargeFields', $pb.PbFieldType.OY)
    ..e<$1.Compression>(3, _omitFieldNames ? '' : 'compression', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Compression.ZLIB, valueOf: $1.Compression.valueOf, enumValues: $1.Compression.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildsV2PubSub clone() => BuildsV2PubSub()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildsV2PubSub copyWith(void Function(BuildsV2PubSub) updates) =>
      super.copyWith((message) => updates(message as BuildsV2PubSub)) as BuildsV2PubSub;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildsV2PubSub create() => BuildsV2PubSub._();
  BuildsV2PubSub createEmptyInstance() => create();
  static $pb.PbList<BuildsV2PubSub> createRepeated() => $pb.PbList<BuildsV2PubSub>();
  @$core.pragma('dart2js:noInline')
  static BuildsV2PubSub getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildsV2PubSub>(create);
  static BuildsV2PubSub? _defaultInstance;

  @$pb.TagNumber(1)
  $0.Build get build => $_getN(0);
  @$pb.TagNumber(1)
  set build($0.Build v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuild() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuild() => clearField(1);
  @$pb.TagNumber(1)
  $0.Build ensureBuild() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get buildLargeFields => $_getN(1);
  @$pb.TagNumber(2)
  set buildLargeFields($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuildLargeFields() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuildLargeFields() => clearField(2);

  @$pb.TagNumber(3)
  $1.Compression get compression => $_getN(2);
  @$pb.TagNumber(3)
  set compression($1.Compression v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCompression() => $_has(2);
  @$pb.TagNumber(3)
  void clearCompression() => clearField(3);
}

class PubSubCallBack extends $pb.GeneratedMessage {
  factory PubSubCallBack() => create();
  PubSubCallBack._() : super();
  factory PubSubCallBack.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PubSubCallBack.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PubSubCallBack',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildsV2PubSub>(1, _omitFieldNames ? '' : 'buildPubsub', subBuilder: BuildsV2PubSub.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'userData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PubSubCallBack clone() => PubSubCallBack()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PubSubCallBack copyWith(void Function(PubSubCallBack) updates) =>
      super.copyWith((message) => updates(message as PubSubCallBack)) as PubSubCallBack;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PubSubCallBack create() => PubSubCallBack._();
  PubSubCallBack createEmptyInstance() => create();
  static $pb.PbList<PubSubCallBack> createRepeated() => $pb.PbList<PubSubCallBack>();
  @$core.pragma('dart2js:noInline')
  static PubSubCallBack getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PubSubCallBack>(create);
  static PubSubCallBack? _defaultInstance;

  @$pb.TagNumber(1)
  BuildsV2PubSub get buildPubsub => $_getN(0);
  @$pb.TagNumber(1)
  set buildPubsub(BuildsV2PubSub v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildPubsub() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildPubsub() => clearField(1);
  @$pb.TagNumber(1)
  BuildsV2PubSub ensureBuildPubsub() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get userData => $_getN(1);
  @$pb.TagNumber(2)
  set userData($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUserData() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserData() => clearField(2);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
