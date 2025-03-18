//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/notification.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'build.pb.dart' as $0;
import 'common.pbenum.dart' as $1;

/// Configuration for per-build notification. It's usually set by the caller on
/// each ScheduleBuild request.
class NotificationConfig extends $pb.GeneratedMessage {
  factory NotificationConfig({
    $core.String? pubsubTopic,
    $core.List<$core.int>? userData,
  }) {
    final $result = create();
    if (pubsubTopic != null) {
      $result.pubsubTopic = pubsubTopic;
    }
    if (userData != null) {
      $result.userData = userData;
    }
    return $result;
  }
  NotificationConfig._() : super();
  factory NotificationConfig.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory NotificationConfig.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotificationConfig',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pubsubTopic')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'userData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  NotificationConfig clone() => NotificationConfig()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  NotificationConfig copyWith(void Function(NotificationConfig) updates) =>
      super.copyWith((message) => updates(message as NotificationConfig))
          as NotificationConfig;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotificationConfig create() => NotificationConfig._();
  NotificationConfig createEmptyInstance() => create();
  static $pb.PbList<NotificationConfig> createRepeated() =>
      $pb.PbList<NotificationConfig>();
  @$core.pragma('dart2js:noInline')
  static NotificationConfig getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotificationConfig>(create);
  static NotificationConfig? _defaultInstance;

  ///  Target Cloud PubSub topic.
  ///  Usually has format "projects/{cloud project}/topics/{topic name}".
  ///
  ///  The PubSub message data schema is defined in `PubSubCallBack` in this file.
  ///
  ///  The legacy schema is:
  ///      {
  ///       'build': ${BuildMessage},
  ///       'user_data': ${NotificationConfig.user_data}
  ///       'hostname': 'cr-buildbucket.appspot.com',
  ///     }
  ///  where the BuildMessage is
  ///  https://chromium.googlesource.com/infra/infra.git/+/b3204748243a9e4bf815a7024e921be46e3e1747/appengine/cr-buildbucket/legacy/api_common.py#94
  ///
  ///  Note: The legacy data schema is deprecated. Only a few old users are using
  ///  it and will be migrated soon.
  ///
  ///  <buildbucket-app-id>@appspot.gserviceaccount.com must have
  ///  "pubsub.topics.publish" and "pubsub.topics.get" permissions on the topic,
  ///  where <buildbucket-app-id> is usually "cr-buildbucket."
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

  /// Will be available in PubSubCallBack.user_data.
  /// Max length: 4096.
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

/// BuildsV2PubSub is the "builds_v2" pubsub topic message data schema.
/// Attributes of this pubsub message:
/// - "project"
/// - "bucket"
/// - "builder"
/// - "is_completed" (The value is either "true" or "false" in string.)
/// - "version" (The value is "v2". To help distinguish messages from the old `builds` topic)
class BuildsV2PubSub extends $pb.GeneratedMessage {
  factory BuildsV2PubSub({
    $0.Build? build,
    $core.List<$core.int>? buildLargeFields,
    $1.Compression? compression,
  }) {
    final $result = create();
    if (build != null) {
      $result.build = build;
    }
    if (buildLargeFields != null) {
      $result.buildLargeFields = buildLargeFields;
    }
    if (compression != null) {
      $result.compression = compression;
    }
    return $result;
  }
  BuildsV2PubSub._() : super();
  factory BuildsV2PubSub.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildsV2PubSub.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildsV2PubSub',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<$0.Build>(1, _omitFieldNames ? '' : 'build',
        subBuilder: $0.Build.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'buildLargeFields', $pb.PbFieldType.OY)
    ..e<$1.Compression>(
        3, _omitFieldNames ? '' : 'compression', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Compression.ZLIB,
        valueOf: $1.Compression.valueOf,
        enumValues: $1.Compression.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildsV2PubSub clone() => BuildsV2PubSub()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildsV2PubSub copyWith(void Function(BuildsV2PubSub) updates) =>
      super.copyWith((message) => updates(message as BuildsV2PubSub))
          as BuildsV2PubSub;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildsV2PubSub create() => BuildsV2PubSub._();
  BuildsV2PubSub createEmptyInstance() => create();
  static $pb.PbList<BuildsV2PubSub> createRepeated() =>
      $pb.PbList<BuildsV2PubSub>();
  @$core.pragma('dart2js:noInline')
  static BuildsV2PubSub getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildsV2PubSub>(create);
  static BuildsV2PubSub? _defaultInstance;

  /// Contains all field except large fields
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

  /// A Compressed bytes in proto binary format of buildbucket.v2.Build where
  /// it only contains the large build fields - build.input.properties,
  /// build.output.properties and build.steps.
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

  /// The compression method the above `build_large_fields` uses. By default, it
  /// is ZLIB as this is the most common one and is the built-in lib in many
  /// programming languages.
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

/// PubSubCallBack is the message data schema for the ad-hoc pubsub notification
/// specified per ScheduleBuild request level.
/// Attributes of this pubsub message:
/// - "project"
/// - "bucket"
/// - "builder"
/// - "is_completed" (The value is either "true" or "false" in string.)
/// - "version" (The value is "v2". To help distinguish messages from the old `builds` topic)
class PubSubCallBack extends $pb.GeneratedMessage {
  factory PubSubCallBack({
    BuildsV2PubSub? buildPubsub,
    $core.List<$core.int>? userData,
  }) {
    final $result = create();
    if (buildPubsub != null) {
      $result.buildPubsub = buildPubsub;
    }
    if (userData != null) {
      $result.userData = userData;
    }
    return $result;
  }
  PubSubCallBack._() : super();
  factory PubSubCallBack.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory PubSubCallBack.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PubSubCallBack',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOM<BuildsV2PubSub>(1, _omitFieldNames ? '' : 'buildPubsub',
        subBuilder: BuildsV2PubSub.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'userData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  PubSubCallBack clone() => PubSubCallBack()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  PubSubCallBack copyWith(void Function(PubSubCallBack) updates) =>
      super.copyWith((message) => updates(message as PubSubCallBack))
          as PubSubCallBack;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PubSubCallBack create() => PubSubCallBack._();
  PubSubCallBack createEmptyInstance() => create();
  static $pb.PbList<PubSubCallBack> createRepeated() =>
      $pb.PbList<PubSubCallBack>();
  @$core.pragma('dart2js:noInline')
  static PubSubCallBack getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PubSubCallBack>(create);
  static PubSubCallBack? _defaultInstance;

  /// Buildbucket build
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

  /// User-defined opaque blob specified in NotificationConfig.user_data.
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
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
