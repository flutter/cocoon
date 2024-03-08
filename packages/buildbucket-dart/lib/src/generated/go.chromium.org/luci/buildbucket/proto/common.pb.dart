//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $1;
import '../../../../google/protobuf/timestamp.pb.dart' as $0;

export 'common.pbenum.dart';

///  An executable to run when the build is ready to start.
///
///  Please refer to go.chromium.org/luci/luciexe for the protocol this executable
///  is expected to implement.
///
///  In addition to the "Host Application" responsibilities listed there,
///  buildbucket will also ensure that $CWD points to an empty directory when it
///  starts the build.
class Executable extends $pb.GeneratedMessage {
  factory Executable({
    $core.String? cipdPackage,
    $core.String? cipdVersion,
    $core.Iterable<$core.String>? cmd,
    $core.Iterable<$core.String>? wrapper,
  }) {
    final $result = create();
    if (cipdPackage != null) {
      $result.cipdPackage = cipdPackage;
    }
    if (cipdVersion != null) {
      $result.cipdVersion = cipdVersion;
    }
    if (cmd != null) {
      $result.cmd.addAll(cmd);
    }
    if (wrapper != null) {
      $result.wrapper.addAll(wrapper);
    }
    return $result;
  }
  Executable._() : super();
  factory Executable.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Executable.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Executable', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cipdPackage')
    ..aOS(2, _omitFieldNames ? '' : 'cipdVersion')
    ..pPS(3, _omitFieldNames ? '' : 'cmd')
    ..pPS(4, _omitFieldNames ? '' : 'wrapper')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Executable clone() => Executable()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Executable copyWith(void Function(Executable) updates) => super.copyWith((message) => updates(message as Executable)) as Executable;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Executable create() => Executable._();
  Executable createEmptyInstance() => create();
  static $pb.PbList<Executable> createRepeated() => $pb.PbList<Executable>();
  @$core.pragma('dart2js:noInline')
  static Executable getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Executable>(create);
  static Executable? _defaultInstance;

  ///  The CIPD package containing the executable.
  ///
  ///  See the `cmd` field below for how the executable will be located within the
  ///  package.
  @$pb.TagNumber(1)
  $core.String get cipdPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set cipdPackage($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCipdPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipdPackage() => clearField(1);

  ///  The CIPD version to fetch.
  ///
  ///  Optional. If omitted, this defaults to `latest`.
  @$pb.TagNumber(2)
  $core.String get cipdVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set cipdVersion($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCipdVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipdVersion() => clearField(2);

  ///  The command to invoke within the package.
  ///
  ///  The 0th argument is taken as relative to the cipd_package root (a.k.a.
  ///  BBAgentArgs.payload_path), so "foo" would invoke the binary called "foo" in
  ///  the root of the package. On Windows, this will automatically look
  ///  first for ".exe" and ".bat" variants. Similarly, "subdir/foo" would
  ///  look for "foo" in "subdir" of the CIPD package.
  ///
  ///  The other arguments are passed verbatim to the executable.
  ///
  ///  The 'build.proto' binary message will always be passed to stdin, even when
  ///  this command has arguments (see go.chromium.org/luci/luciexe).
  ///
  ///  RECOMMENDATION: It's advised to rely on the build.proto's Input.Properties
  ///  field for passing task-specific data. Properties are JSON-typed and can be
  ///  modeled with a protobuf (using JSONPB). However, supplying additional args
  ///  can be useful to, e.g., increase logging verbosity, or similar
  ///  'system level' settings within the binary.
  ///
  ///  Optional. If omitted, defaults to `['luciexe']`.
  @$pb.TagNumber(3)
  $core.List<$core.String> get cmd => $_getList(2);

  ///  Wrapper is a command and its args which will be used to 'wrap' the
  ///  execution of `cmd`.
  ///  Given:
  ///   wrapper = ['/some/exe', '--arg']
  ///   cmd = ['my_exe', '--other-arg']
  ///  Buildbucket's agent will invoke
  ///   /some/exe --arg -- /path/to/task/root/dir/my_exe --other-arg
  ///  Note that '--' is always inserted between the wrapper and the target
  ///  cmd
  ///
  ///  The wrapper program MUST maintain all the invariants specified in
  ///  go.chromium.org/luci/luciexe (likely by passing-through
  ///  most of this responsibility to `cmd`).
  ///
  ///  wrapper[0] MAY be an absolute path. If https://pkg.go.dev/path/filepath#IsAbs
  ///  returns `true` for wrapper[0], it will be interpreted as an absolute
  ///  path. In this case, it is your responsibility to ensure that the target
  ///  binary is correctly deployed an any machine where the Build might run
  ///  (by whatever means you use to prepare/adjust your system image). Failure to do
  ///  so will cause the build to terminate with INFRA_FAILURE.
  ///
  ///  If wrapper[0] is non-absolute, but does not contain a path separator,
  ///  it will be looked for in $PATH (and the same rules apply for
  ///  pre-distribution as in the absolute path case).
  ///
  ///  If wrapper[0] begins with a "./" (or ".\") or contains a path separator
  ///  anywhere, it will be considered relative to the task root.
  ///
  ///  Example wrapper[0]:
  ///
  ///  Absolute path (*nix): /some/prog
  ///  Absolute path (Windows): C:\some\prog.exe
  ///  $PATH or %PATH% lookup: prog
  ///  task-relative (*nix): ./prog ($taskRoot/prog)
  ///  task-relative (*nix): dir/prog ($taskRoot/dir/prog)
  ///  task-relative (Windows): .\prog.exe ($taskRoot\\prog.exe)
  ///  task-relative (Windows): dir\prog.exe ($taskRoot\\dir\\prog.exe)
  @$pb.TagNumber(4)
  $core.List<$core.String> get wrapper => $_getList(3);
}

class StatusDetails_ResourceExhaustion extends $pb.GeneratedMessage {
  factory StatusDetails_ResourceExhaustion() => create();
  StatusDetails_ResourceExhaustion._() : super();
  factory StatusDetails_ResourceExhaustion.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatusDetails_ResourceExhaustion.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails.ResourceExhaustion', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatusDetails_ResourceExhaustion clone() => StatusDetails_ResourceExhaustion()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatusDetails_ResourceExhaustion copyWith(void Function(StatusDetails_ResourceExhaustion) updates) => super.copyWith((message) => updates(message as StatusDetails_ResourceExhaustion)) as StatusDetails_ResourceExhaustion;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails_ResourceExhaustion create() => StatusDetails_ResourceExhaustion._();
  StatusDetails_ResourceExhaustion createEmptyInstance() => create();
  static $pb.PbList<StatusDetails_ResourceExhaustion> createRepeated() => $pb.PbList<StatusDetails_ResourceExhaustion>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails_ResourceExhaustion getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails_ResourceExhaustion>(create);
  static StatusDetails_ResourceExhaustion? _defaultInstance;
}

class StatusDetails_Timeout extends $pb.GeneratedMessage {
  factory StatusDetails_Timeout() => create();
  StatusDetails_Timeout._() : super();
  factory StatusDetails_Timeout.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatusDetails_Timeout.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails.Timeout', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatusDetails_Timeout clone() => StatusDetails_Timeout()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatusDetails_Timeout copyWith(void Function(StatusDetails_Timeout) updates) => super.copyWith((message) => updates(message as StatusDetails_Timeout)) as StatusDetails_Timeout;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails_Timeout create() => StatusDetails_Timeout._();
  StatusDetails_Timeout createEmptyInstance() => create();
  static $pb.PbList<StatusDetails_Timeout> createRepeated() => $pb.PbList<StatusDetails_Timeout>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails_Timeout getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails_Timeout>(create);
  static StatusDetails_Timeout? _defaultInstance;
}

/// Machine-readable details of a status.
/// Human-readble details are present in a sibling summary_markdown field.
class StatusDetails extends $pb.GeneratedMessage {
  factory StatusDetails({
    StatusDetails_ResourceExhaustion? resourceExhaustion,
    StatusDetails_Timeout? timeout,
  }) {
    final $result = create();
    if (resourceExhaustion != null) {
      $result.resourceExhaustion = resourceExhaustion;
    }
    if (timeout != null) {
      $result.timeout = timeout;
    }
    return $result;
  }
  StatusDetails._() : super();
  factory StatusDetails.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatusDetails.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<StatusDetails_ResourceExhaustion>(3, _omitFieldNames ? '' : 'resourceExhaustion', subBuilder: StatusDetails_ResourceExhaustion.create)
    ..aOM<StatusDetails_Timeout>(4, _omitFieldNames ? '' : 'timeout', subBuilder: StatusDetails_Timeout.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatusDetails clone() => StatusDetails()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatusDetails copyWith(void Function(StatusDetails) updates) => super.copyWith((message) => updates(message as StatusDetails)) as StatusDetails;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails create() => StatusDetails._();
  StatusDetails createEmptyInstance() => create();
  static $pb.PbList<StatusDetails> createRepeated() => $pb.PbList<StatusDetails>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails>(create);
  static StatusDetails? _defaultInstance;

  /// If set, indicates that the failure was due to a resource exhaustion / quota
  /// denial.
  /// Applicable in FAILURE and INFRA_FAILURE statuses.
  @$pb.TagNumber(3)
  StatusDetails_ResourceExhaustion get resourceExhaustion => $_getN(0);
  @$pb.TagNumber(3)
  set resourceExhaustion(StatusDetails_ResourceExhaustion v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasResourceExhaustion() => $_has(0);
  @$pb.TagNumber(3)
  void clearResourceExhaustion() => clearField(3);
  @$pb.TagNumber(3)
  StatusDetails_ResourceExhaustion ensureResourceExhaustion() => $_ensure(0);

  ///  If set, indicates that the build ended due to the expiration_timeout or
  ///  scheduling_timeout set for the build.
  ///
  ///  Applicable in all final statuses.
  ///
  ///  SUCCESS+timeout would indicate a successful recovery from a timeout signal
  ///  during the build's grace_period.
  @$pb.TagNumber(4)
  StatusDetails_Timeout get timeout => $_getN(1);
  @$pb.TagNumber(4)
  set timeout(StatusDetails_Timeout v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasTimeout() => $_has(1);
  @$pb.TagNumber(4)
  void clearTimeout() => clearField(4);
  @$pb.TagNumber(4)
  StatusDetails_Timeout ensureTimeout() => $_ensure(1);
}

/// A named log of a step or build.
class Log extends $pb.GeneratedMessage {
  factory Log({
    $core.String? name,
    $core.String? viewUrl,
    $core.String? url,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (viewUrl != null) {
      $result.viewUrl = viewUrl;
    }
    if (url != null) {
      $result.url = url;
    }
    return $result;
  }
  Log._() : super();
  factory Log.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Log.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Log', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'viewUrl')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Log clone() => Log()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Log copyWith(void Function(Log) updates) => super.copyWith((message) => updates(message as Log)) as Log;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Log create() => Log._();
  Log createEmptyInstance() => create();
  static $pb.PbList<Log> createRepeated() => $pb.PbList<Log>();
  @$core.pragma('dart2js:noInline')
  static Log getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Log>(create);
  static Log? _defaultInstance;

  /// Log name, standard ("stdout", "stderr") or custom (e.g. "json.output").
  /// Unique within the containing message (step or build).
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  /// URL of a Human-readable page that displays log contents.
  @$pb.TagNumber(2)
  $core.String get viewUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set viewUrl($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasViewUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearViewUrl() => clearField(2);

  /// URL of the log content.
  /// As of 2018-09-06, the only supported scheme is "logdog".
  /// Typically it has form
  /// "logdog://<host>/<project>/<prefix>/+/<stream_name>".
  /// See also
  /// https://godoc.org/go.chromium.org/luci/logdog/common/types#ParseURL
  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => clearField(3);
}

/// A Gerrit patchset.
class GerritChange extends $pb.GeneratedMessage {
  factory GerritChange({
    $core.String? host,
    $core.String? project,
    $fixnum.Int64? change,
    $fixnum.Int64? patchset,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (project != null) {
      $result.project = project;
    }
    if (change != null) {
      $result.change = change;
    }
    if (patchset != null) {
      $result.patchset = patchset;
    }
    return $result;
  }
  GerritChange._() : super();
  factory GerritChange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GerritChange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GerritChange', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aInt64(3, _omitFieldNames ? '' : 'change')
    ..aInt64(4, _omitFieldNames ? '' : 'patchset')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GerritChange clone() => GerritChange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GerritChange copyWith(void Function(GerritChange) updates) => super.copyWith((message) => updates(message as GerritChange)) as GerritChange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GerritChange create() => GerritChange._();
  GerritChange createEmptyInstance() => create();
  static $pb.PbList<GerritChange> createRepeated() => $pb.PbList<GerritChange>();
  @$core.pragma('dart2js:noInline')
  static GerritChange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GerritChange>(create);
  static GerritChange? _defaultInstance;

  /// Gerrit hostname, e.g. "chromium-review.googlesource.com".
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// Gerrit project, e.g. "chromium/src".
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// Change number, e.g. 12345.
  @$pb.TagNumber(3)
  $fixnum.Int64 get change => $_getI64(2);
  @$pb.TagNumber(3)
  set change($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasChange() => $_has(2);
  @$pb.TagNumber(3)
  void clearChange() => clearField(3);

  /// Patch set number, e.g. 1.
  @$pb.TagNumber(4)
  $fixnum.Int64 get patchset => $_getI64(3);
  @$pb.TagNumber(4)
  set patchset($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPatchset() => $_has(3);
  @$pb.TagNumber(4)
  void clearPatchset() => clearField(4);
}

/// A landed Git commit hosted on Gitiles.
class GitilesCommit extends $pb.GeneratedMessage {
  factory GitilesCommit({
    $core.String? host,
    $core.String? project,
    $core.String? id,
    $core.String? ref,
    $core.int? position,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (project != null) {
      $result.project = project;
    }
    if (id != null) {
      $result.id = id;
    }
    if (ref != null) {
      $result.ref = ref;
    }
    if (position != null) {
      $result.position = position;
    }
    return $result;
  }
  GitilesCommit._() : super();
  factory GitilesCommit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GitilesCommit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GitilesCommit', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..aOS(4, _omitFieldNames ? '' : 'ref')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'position', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GitilesCommit clone() => GitilesCommit()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GitilesCommit copyWith(void Function(GitilesCommit) updates) => super.copyWith((message) => updates(message as GitilesCommit)) as GitilesCommit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitilesCommit create() => GitilesCommit._();
  GitilesCommit createEmptyInstance() => create();
  static $pb.PbList<GitilesCommit> createRepeated() => $pb.PbList<GitilesCommit>();
  @$core.pragma('dart2js:noInline')
  static GitilesCommit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitilesCommit>(create);
  static GitilesCommit? _defaultInstance;

  /// Gitiles hostname, e.g. "chromium.googlesource.com".
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// Repository name on the host, e.g. "chromium/src".
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// Commit HEX SHA1.
  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  /// Commit ref, e.g. "refs/heads/master".
  /// NOT a branch name: if specified, must start with "refs/".
  /// If id is set, ref SHOULD also be set, so that git clients can
  /// know how to obtain the commit by id.
  @$pb.TagNumber(4)
  $core.String get ref => $_getSZ(3);
  @$pb.TagNumber(4)
  set ref($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearRef() => clearField(4);

  /// Defines a total order of commits on the ref. Requires ref field.
  /// Typically 1-based, monotonically increasing, contiguous integer
  /// defined by a Gerrit plugin, goto.google.com/git-numberer.
  /// TODO(tandrii): make it a public doc.
  @$pb.TagNumber(5)
  $core.int get position => $_getIZ(4);
  @$pb.TagNumber(5)
  set position($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);
}

/// A key-value pair of strings.
class StringPair extends $pb.GeneratedMessage {
  factory StringPair({
    $core.String? key,
    $core.String? value,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (value != null) {
      $result.value = value;
    }
    return $result;
  }
  StringPair._() : super();
  factory StringPair.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StringPair.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StringPair', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StringPair clone() => StringPair()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StringPair copyWith(void Function(StringPair) updates) => super.copyWith((message) => updates(message as StringPair)) as StringPair;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringPair create() => StringPair._();
  StringPair createEmptyInstance() => create();
  static $pb.PbList<StringPair> createRepeated() => $pb.PbList<StringPair>();
  @$core.pragma('dart2js:noInline')
  static StringPair getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StringPair>(create);
  static StringPair? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

/// Half-open time range.
class TimeRange extends $pb.GeneratedMessage {
  factory TimeRange({
    $0.Timestamp? startTime,
    $0.Timestamp? endTime,
  }) {
    final $result = create();
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    return $result;
  }
  TimeRange._() : super();
  factory TimeRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TimeRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TimeRange', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'startTime', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'endTime', subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TimeRange clone() => TimeRange()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TimeRange copyWith(void Function(TimeRange) updates) => super.copyWith((message) => updates(message as TimeRange)) as TimeRange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeRange create() => TimeRange._();
  TimeRange createEmptyInstance() => create();
  static $pb.PbList<TimeRange> createRepeated() => $pb.PbList<TimeRange>();
  @$core.pragma('dart2js:noInline')
  static TimeRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeRange>(create);
  static TimeRange? _defaultInstance;

  /// Inclusive lower boundary. Optional.
  @$pb.TagNumber(1)
  $0.Timestamp get startTime => $_getN(0);
  @$pb.TagNumber(1)
  set startTime($0.Timestamp v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStartTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTime() => clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureStartTime() => $_ensure(0);

  /// Exclusive upper boundary. Optional.
  @$pb.TagNumber(2)
  $0.Timestamp get endTime => $_getN(1);
  @$pb.TagNumber(2)
  set endTime($0.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasEndTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndTime() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureEndTime() => $_ensure(1);
}

/// A requested dimension. Looks like StringPair, but also has an expiration.
class RequestedDimension extends $pb.GeneratedMessage {
  factory RequestedDimension({
    $core.String? key,
    $core.String? value,
    $1.Duration? expiration,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (value != null) {
      $result.value = value;
    }
    if (expiration != null) {
      $result.expiration = expiration;
    }
    return $result;
  }
  RequestedDimension._() : super();
  factory RequestedDimension.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RequestedDimension.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RequestedDimension', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOM<$1.Duration>(3, _omitFieldNames ? '' : 'expiration', subBuilder: $1.Duration.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RequestedDimension clone() => RequestedDimension()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RequestedDimension copyWith(void Function(RequestedDimension) updates) => super.copyWith((message) => updates(message as RequestedDimension)) as RequestedDimension;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestedDimension create() => RequestedDimension._();
  RequestedDimension createEmptyInstance() => create();
  static $pb.PbList<RequestedDimension> createRepeated() => $pb.PbList<RequestedDimension>();
  @$core.pragma('dart2js:noInline')
  static RequestedDimension getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RequestedDimension>(create);
  static RequestedDimension? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);

  /// If set, ignore this dimension after this duration.
  @$pb.TagNumber(3)
  $1.Duration get expiration => $_getN(2);
  @$pb.TagNumber(3)
  set expiration($1.Duration v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasExpiration() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiration() => clearField(3);
  @$pb.TagNumber(3)
  $1.Duration ensureExpiration() => $_ensure(2);
}

///  This message is a duplicate of Build.Infra.Swarming.CacheEntry,
///  however we will be moving from hardcoded swarming -> task backends.
///  This message will remain as the desired CacheEntry and eventually
///  Build.Infra.Swarming will be deprecated, so this will remain.
///
///  Describes a cache directory persisted on a bot.
///
///  If a build requested a cache, the cache directory is available on build
///  startup. If the cache was present on the bot, the directory contains
///  files from the previous run on that bot.
///  The build can read/write to the cache directory while it runs.
///  After build completes, the cache directory is persisted.
///  The next time another build requests the same cache and runs on the same
///  bot, the files will still be there (unless the cache was evicted,
///  perhaps due to disk space reasons).
///
///  One bot can keep multiple caches at the same time and one build can request
///  multiple different caches.
///  A cache is identified by its name and mapped to a path.
///
///  If the bot is running out of space, caches are evicted in LRU manner
///  before the next build on this bot starts.
///
///  Buildbucket implicitly declares cache
///    {"name": "<hash(project/bucket/builder)>", "path": "builder"}.
///  This means that any LUCI builder has a "personal disk space" on the bot.
///  Builder cache is often a good start before customizing caching.
///  In recipes, it is available at api.buildbucket.builder_cache_path.
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
class CacheEntry extends $pb.GeneratedMessage {
  factory CacheEntry({
    $core.String? name,
    $core.String? path,
    $1.Duration? waitForWarmCache,
    $core.String? envVar,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (path != null) {
      $result.path = path;
    }
    if (waitForWarmCache != null) {
      $result.waitForWarmCache = waitForWarmCache;
    }
    if (envVar != null) {
      $result.envVar = envVar;
    }
    return $result;
  }
  CacheEntry._() : super();
  factory CacheEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CacheEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<$1.Duration>(3, _omitFieldNames ? '' : 'waitForWarmCache', subBuilder: $1.Duration.create)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CacheEntry clone() => CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CacheEntry copyWith(void Function(CacheEntry) updates) => super.copyWith((message) => updates(message as CacheEntry)) as CacheEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheEntry create() => CacheEntry._();
  CacheEntry createEmptyInstance() => create();
  static $pb.PbList<CacheEntry> createRepeated() => $pb.PbList<CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static CacheEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheEntry>(create);
  static CacheEntry? _defaultInstance;

  ///  Identifier of the cache. Required. Length is limited to 128.
  ///  Must be unique in the build.
  ///
  ///  If the pool of swarming bots is shared among multiple LUCI projects and
  ///  projects use same cache name, the cache will be shared across projects.
  ///  To avoid affecting and being affected by other projects, prefix the
  ///  cache name with something project-specific, e.g. "v8-".
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  ///  Relative path where the cache in mapped into. Required.
  ///
  ///  Must use POSIX format (forward slashes).
  ///  In most cases, it does not need slashes at all.
  ///
  ///  In recipes, use api.path['cache'].join(path) to get absolute path.
  ///
  ///  Must be unique in the build.
  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => clearField(2);

  ///  Duration to wait for a bot with a warm cache to pick up the
  ///  task, before falling back to a bot with a cold (non-existent) cache.
  ///
  ///  The default is 0, which means that no preference will be chosen for a
  ///  bot with this or without this cache, and a bot without this cache may
  ///  be chosen instead.
  ///
  ///  If no bot has this cache warm, the task will skip this wait and will
  ///  immediately fallback to a cold cache request.
  ///
  ///  The value must be multiples of 60 seconds.
  @$pb.TagNumber(3)
  $1.Duration get waitForWarmCache => $_getN(2);
  @$pb.TagNumber(3)
  set waitForWarmCache($1.Duration v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCache() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCache() => clearField(3);
  @$pb.TagNumber(3)
  $1.Duration ensureWaitForWarmCache() => $_ensure(2);

  /// Environment variable with this name will be set to the path to the cache
  /// directory.
  @$pb.TagNumber(4)
  $core.String get envVar => $_getSZ(3);
  @$pb.TagNumber(4)
  set envVar($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnvVar() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnvVar() => clearField(4);
}

class HealthStatus extends $pb.GeneratedMessage {
  factory HealthStatus({
    $fixnum.Int64? healthScore,
    $core.Map<$core.String, $core.double>? healthMetrics,
    $core.String? description,
    $core.Map<$core.String, $core.String>? docLinks,
    $core.Map<$core.String, $core.String>? dataLinks,
    $core.String? reporter,
    $0.Timestamp? reportedTime,
    $core.String? contactTeamEmail,
  }) {
    final $result = create();
    if (healthScore != null) {
      $result.healthScore = healthScore;
    }
    if (healthMetrics != null) {
      $result.healthMetrics.addAll(healthMetrics);
    }
    if (description != null) {
      $result.description = description;
    }
    if (docLinks != null) {
      $result.docLinks.addAll(docLinks);
    }
    if (dataLinks != null) {
      $result.dataLinks.addAll(dataLinks);
    }
    if (reporter != null) {
      $result.reporter = reporter;
    }
    if (reportedTime != null) {
      $result.reportedTime = reportedTime;
    }
    if (contactTeamEmail != null) {
      $result.contactTeamEmail = contactTeamEmail;
    }
    return $result;
  }
  HealthStatus._() : super();
  factory HealthStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HealthStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HealthStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'healthScore')
    ..m<$core.String, $core.double>(2, _omitFieldNames ? '' : 'healthMetrics', entryClassName: 'HealthStatus.HealthMetricsEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OF, packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'docLinks', entryClassName: 'HealthStatus.DocLinksEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'dataLinks', entryClassName: 'HealthStatus.DataLinksEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OS, packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOS(6, _omitFieldNames ? '' : 'reporter')
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'reportedTime', subBuilder: $0.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'contactTeamEmail')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HealthStatus clone() => HealthStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HealthStatus copyWith(void Function(HealthStatus) updates) => super.copyWith((message) => updates(message as HealthStatus)) as HealthStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthStatus create() => HealthStatus._();
  HealthStatus createEmptyInstance() => create();
  static $pb.PbList<HealthStatus> createRepeated() => $pb.PbList<HealthStatus>();
  @$core.pragma('dart2js:noInline')
  static HealthStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HealthStatus>(create);
  static HealthStatus? _defaultInstance;

  ///  A numeric score for a builder's health.
  ///  The scores must respect the following:
  ///    - 0: Unknown status
  ///    - 1: The worst possible health
  ///          e.g.
  ///            - all bots are dead.
  ///            - every single build has ended in INFRA_FAILURE in the configured
  ///              time period.
  ///    - 10: Completely healthy.
  ///            e.g. Every single build has ended in SUCCESS or CANCELLED in the
  ///                 configured time period.
  ///
  ///  Reasoning for scores from 2 to 9 are to be configured by the builder owner.
  ///  Since each set of metrics used to calculate the health score can vary, the
  ///  builder owners must provide the score and reasoning (using the description
  ///  field). This allows for complicated metric calculation while preserving a
  ///  binary solution for less complex forms of metric calculation.
  @$pb.TagNumber(1)
  $fixnum.Int64 get healthScore => $_getI64(0);
  @$pb.TagNumber(1)
  set healthScore($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHealthScore() => $_has(0);
  @$pb.TagNumber(1)
  void clearHealthScore() => clearField(1);

  ///  A map of metric label to value. This will allow milo to display the metrics
  ///  used to construct the health score. There is no generic set of metrics for
  ///  this since each set of metrics can vary from team to team.
  ///
  ///  Buildbucket will not use this information to calculate the health score.
  ///  These metrics are for display only.
  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.double> get healthMetrics => $_getMap(1);

  ///  A human readable summary of why the health is the way it is, without
  ///  the user having to go to the dashboard to find it themselves.
  ///
  ///  E.g.
  ///    "the p90 pending time has been greater than 50 minutes for at least 3
  ///     of the last 7 days"
  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  ///  Mapping of username domain to clickable link for documentation on the health
  ///  metrics and how they were calculated.
  ///
  ///  The empty domain value will be used as a fallback for anonymous users, or
  ///  if the user identity domain doesn't have a matching entry in this map.
  ///
  ///  If linking an internal google link (say g3doc), use a go-link instead of a
  ///  raw url.
  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.String> get docLinks => $_getMap(3);

  ///  Mapping of username domain to clickable link for data visualization or
  ///  dashboards for the health metrics.
  ///
  ///  Similar to doc_links, the empty domain value will be used as a fallback for
  ///  anonymous users, or if the user identity domain doesn't have a matching
  ///  entry in this map.
  ///
  ///  If linking an internal google link (say g3doc), use a go-link instead of a
  ///  raw url.
  @$pb.TagNumber(5)
  $core.Map<$core.String, $core.String> get dataLinks => $_getMap(4);

  ///  Entity that reported the health status, A luci-auth identity.
  ///  E.g.
  ///     anonymous:anonymous, user:someuser@example.com, project:chromeos
  ///
  ///  Set by Buildbucket. Output only.
  @$pb.TagNumber(6)
  $core.String get reporter => $_getSZ(5);
  @$pb.TagNumber(6)
  set reporter($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasReporter() => $_has(5);
  @$pb.TagNumber(6)
  void clearReporter() => clearField(6);

  /// Set by Buildbucket. Output only.
  @$pb.TagNumber(7)
  $0.Timestamp get reportedTime => $_getN(6);
  @$pb.TagNumber(7)
  set reportedTime($0.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasReportedTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearReportedTime() => clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureReportedTime() => $_ensure(6);

  /// A contact email for the builder's owning team, for the purpose of fixing builder health issues
  /// See contact_team_email field in project_config.BuilderConfig
  @$pb.TagNumber(8)
  $core.String get contactTeamEmail => $_getSZ(7);
  @$pb.TagNumber(8)
  set contactTeamEmail($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasContactTeamEmail() => $_has(7);
  @$pb.TagNumber(8)
  void clearContactTeamEmail() => clearField(8);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
