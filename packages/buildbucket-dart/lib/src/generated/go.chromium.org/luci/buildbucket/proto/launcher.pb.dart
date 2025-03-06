//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/launcher.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'build.pb.dart' as $0;

/// A collection of build-related secrets we might pass from Buildbucket to Kitchen.
class BuildSecrets extends $pb.GeneratedMessage {
  factory BuildSecrets({
    $core.String? buildToken,
    $core.String? resultdbInvocationUpdateToken,
    $core.String? startBuildToken,
  }) {
    final $result = create();
    if (buildToken != null) {
      $result.buildToken = buildToken;
    }
    if (resultdbInvocationUpdateToken != null) {
      $result.resultdbInvocationUpdateToken = resultdbInvocationUpdateToken;
    }
    if (startBuildToken != null) {
      $result.startBuildToken = startBuildToken;
    }
    return $result;
  }
  BuildSecrets._() : super();
  factory BuildSecrets.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildSecrets.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildSecrets',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'buildToken')
    ..aOS(2, _omitFieldNames ? '' : 'resultdbInvocationUpdateToken')
    ..aOS(3, _omitFieldNames ? '' : 'startBuildToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildSecrets clone() => BuildSecrets()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildSecrets copyWith(void Function(BuildSecrets) updates) =>
      super.copyWith((message) => updates(message as BuildSecrets))
          as BuildSecrets;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildSecrets create() => BuildSecrets._();
  BuildSecrets createEmptyInstance() => create();
  static $pb.PbList<BuildSecrets> createRepeated() =>
      $pb.PbList<BuildSecrets>();
  @$core.pragma('dart2js:noInline')
  static BuildSecrets getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildSecrets>(create);
  static BuildSecrets? _defaultInstance;

  /// A BUILD token to identify UpdateBuild RPCs associated with the same build.
  @$pb.TagNumber(1)
  $core.String get buildToken => $_getSZ(0);
  @$pb.TagNumber(1)
  set buildToken($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildToken() => clearField(1);

  /// Token to allow updating this build's invocation in ResultDB.
  @$pb.TagNumber(2)
  $core.String get resultdbInvocationUpdateToken => $_getSZ(1);
  @$pb.TagNumber(2)
  set resultdbInvocationUpdateToken($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasResultdbInvocationUpdateToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultdbInvocationUpdateToken() => clearField(2);

  /// A START_BUILD token to identify StartBuild RPCs associated with
  /// the same build.
  @$pb.TagNumber(3)
  $core.String get startBuildToken => $_getSZ(2);
  @$pb.TagNumber(3)
  set startBuildToken($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStartBuildToken() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartBuildToken() => clearField(3);
}

///  Arguments for bbagent command.
///
///  All paths are relateive to bbagent's working directory, and must be delimited
///  with slashes ("/"), regardless of the host OS.
class BBAgentArgs extends $pb.GeneratedMessage {
  factory BBAgentArgs({
    $core.String? executablePath,
    $core.String? cacheDir,
    $core.Iterable<$core.String>? knownPublicGerritHosts,
    $0.Build? build,
    $core.String? payloadPath,
  }) {
    final $result = create();
    if (executablePath != null) {
      $result.executablePath = executablePath;
    }
    if (cacheDir != null) {
      $result.cacheDir = cacheDir;
    }
    if (knownPublicGerritHosts != null) {
      $result.knownPublicGerritHosts.addAll(knownPublicGerritHosts);
    }
    if (build != null) {
      $result.build = build;
    }
    if (payloadPath != null) {
      $result.payloadPath = payloadPath;
    }
    return $result;
  }
  BBAgentArgs._() : super();
  factory BBAgentArgs.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BBAgentArgs.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BBAgentArgs',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'executablePath')
    ..aOS(2, _omitFieldNames ? '' : 'cacheDir')
    ..pPS(3, _omitFieldNames ? '' : 'knownPublicGerritHosts')
    ..aOM<$0.Build>(4, _omitFieldNames ? '' : 'build',
        subBuilder: $0.Build.create)
    ..aOS(5, _omitFieldNames ? '' : 'payloadPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BBAgentArgs clone() => BBAgentArgs()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BBAgentArgs copyWith(void Function(BBAgentArgs) updates) =>
      super.copyWith((message) => updates(message as BBAgentArgs))
          as BBAgentArgs;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BBAgentArgs create() => BBAgentArgs._();
  BBAgentArgs createEmptyInstance() => create();
  static $pb.PbList<BBAgentArgs> createRepeated() => $pb.PbList<BBAgentArgs>();
  @$core.pragma('dart2js:noInline')
  static BBAgentArgs getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BBAgentArgs>(create);
  static BBAgentArgs? _defaultInstance;

  ///  Path to the user executable.
  ///
  ///  Deprecated. Superseded by payload_path and `build.exe.cmd`.
  @$pb.TagNumber(1)
  $core.String get executablePath => $_getSZ(0);
  @$pb.TagNumber(1)
  set executablePath($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasExecutablePath() => $_has(0);
  @$pb.TagNumber(1)
  void clearExecutablePath() => clearField(1);

  ///  Path to a directory where each subdirectory is a cache dir.
  ///
  ///  Required.
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

  ///  List of Gerrit hosts to force git authentication for.
  ///
  ///  By default public hosts are accessed anonymously, and the anonymous access
  ///  has very low quota. Context needs to know all such hostnames in advance to
  ///  be able to force authenticated access to them.
  @$pb.TagNumber(3)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(2);

  /// Initial state of the build, including immutable state such as id and input
  /// properties.
  @$pb.TagNumber(4)
  $0.Build get build => $_getN(3);
  @$pb.TagNumber(4)
  set build($0.Build v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasBuild() => $_has(3);
  @$pb.TagNumber(4)
  void clearBuild() => clearField(4);
  @$pb.TagNumber(4)
  $0.Build ensureBuild() => $_ensure(3);

  ///  Path to the base of the user executable package.
  ///
  ///  Required.
  @$pb.TagNumber(5)
  $core.String get payloadPath => $_getSZ(4);
  @$pb.TagNumber(5)
  set payloadPath($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPayloadPath() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayloadPath() => clearField(5);
}

class BuildbucketAgentContext extends $pb.GeneratedMessage {
  factory BuildbucketAgentContext({
    $core.String? taskId,
    BuildSecrets? secrets,
  }) {
    final $result = create();
    if (taskId != null) {
      $result.taskId = taskId;
    }
    if (secrets != null) {
      $result.secrets = secrets;
    }
    return $result;
  }
  BuildbucketAgentContext._() : super();
  factory BuildbucketAgentContext.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildbucketAgentContext.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BuildbucketAgentContext',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'taskId')
    ..aOM<BuildSecrets>(2, _omitFieldNames ? '' : 'secrets',
        subBuilder: BuildSecrets.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildbucketAgentContext clone() =>
      BuildbucketAgentContext()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildbucketAgentContext copyWith(
          void Function(BuildbucketAgentContext) updates) =>
      super.copyWith((message) => updates(message as BuildbucketAgentContext))
          as BuildbucketAgentContext;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildbucketAgentContext create() => BuildbucketAgentContext._();
  BuildbucketAgentContext createEmptyInstance() => create();
  static $pb.PbList<BuildbucketAgentContext> createRepeated() =>
      $pb.PbList<BuildbucketAgentContext>();
  @$core.pragma('dart2js:noInline')
  static BuildbucketAgentContext getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BuildbucketAgentContext>(create);
  static BuildbucketAgentContext? _defaultInstance;

  /// Should match the task_id that was sent to buildbucket in
  /// either RunTaskResposne.Task.Id.Id or in
  /// StartBuildTaskRequest.Task.Id.Id
  @$pb.TagNumber(1)
  $core.String get taskId => $_getSZ(0);
  @$pb.TagNumber(1)
  set taskId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTaskId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTaskId() => clearField(1);

  ///  The secrets that was provided to the backend from
  ///  RunTaskRequest or StartBuildTaskResponse.
  ///
  ///  During the task backend migration, the BuildToken secret
  ///  bytes sent to swarming will be populated here. Bbagent will
  ///  read LUCI_CONTEXT provided by raw swarming tasks and convert it to
  ///  BuildbucketAgentContext. All swarming tasks ran as task backend tasks
  ///  will use BuildbucketAgentContext directly.
  @$pb.TagNumber(2)
  BuildSecrets get secrets => $_getN(1);
  @$pb.TagNumber(2)
  set secrets(BuildSecrets v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSecrets() => $_has(1);
  @$pb.TagNumber(2)
  void clearSecrets() => clearField(2);
  @$pb.TagNumber(2)
  BuildSecrets ensureSecrets() => $_ensure(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
