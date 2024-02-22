//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../../google/protobuf/timestamp.pb.dart' as $0;

///  A key-value map describing one variant of a test case.
///
///  The same test case can be executed in different ways, for example on
///  different OS, GPUs, with different compile options or runtime flags.
///  A variant definition captures one variant.
///  A test case with a specific variant definition is called test variant.
///
///  Guidelines for variant definition design:
///  - This rule guides what keys MUST be present in the definition.
///    A single expected result of a given test variant is enough to consider it
///    passing (potentially flakily). If it is important to differentiate across
///    a certain dimension (e.g. whether web tests are executed with or without
///    site per process isolation), then there MUST be a key that captures the
///    dimension (e.g. a name from test_suites.pyl).
///    Otherwise, a pass in one variant will hide a failure of another one.
///
///  - This rule guides what keys MUST NOT be present in the definition.
///    A change in the key-value set essentially resets the test result history.
///    For example, if GN args are among variant key-value pairs, then adding a
///    new GN arg changes the identity of the test variant and resets its history.
///
///  In Chromium, variant keys are:
///  - bucket: the LUCI bucket, e.g. "ci"
///  - builder: the LUCI builder, e.g. "linux-rel"
///  - test_suite: a name from
///    https://cs.chromium.org/chromium/src/testing/buildbot/test_suites.pyl
class Variant extends $pb.GeneratedMessage {
  factory Variant({
    $core.Map<$core.String, $core.String>? def,
  }) {
    final $result = create();
    if (def != null) {
      $result.def.addAll(def);
    }
    return $result;
  }
  Variant._() : super();
  factory Variant.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Variant.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Variant',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..m<$core.String, $core.String>(1, _omitFieldNames ? '' : 'def',
        entryClassName: 'Variant.DefEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('luci.resultdb.v1'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Variant clone() => Variant()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Variant copyWith(void Function(Variant) updates) =>
      super.copyWith((message) => updates(message as Variant)) as Variant;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Variant create() => Variant._();
  Variant createEmptyInstance() => create();
  static $pb.PbList<Variant> createRepeated() => $pb.PbList<Variant>();
  @$core.pragma('dart2js:noInline')
  static Variant getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Variant>(create);
  static Variant? _defaultInstance;

  /// The definition of the variant.
  /// Key and values must be valid StringPair keys and values, see their
  /// constraints.
  @$pb.TagNumber(1)
  $core.Map<$core.String, $core.String> get def => $_getMap(0);
}

/// A string key-value pair. Typically used for tagging, see Invocation.tags
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
  factory StringPair.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StringPair.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StringPair',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StringPair clone() => StringPair()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StringPair copyWith(void Function(StringPair) updates) =>
      super.copyWith((message) => updates(message as StringPair)) as StringPair;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringPair create() => StringPair._();
  StringPair createEmptyInstance() => create();
  static $pb.PbList<StringPair> createRepeated() => $pb.PbList<StringPair>();
  @$core.pragma('dart2js:noInline')
  static StringPair getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StringPair>(create);
  static StringPair? _defaultInstance;

  /// Regex: ^[a-z][a-z0-9_]*(/[a-z][a-z0-9_]*)*$
  /// Max length: 64.
  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);

  /// Max length: 256.
  @$pb.TagNumber(2)
  $core.String get value => $_getSZ(1);
  @$pb.TagNumber(2)
  set value($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasValue() => $_has(1);
  @$pb.TagNumber(2)
  void clearValue() => clearField(2);
}

///  GitilesCommit specifies the position of the gitiles commit an invocation
///  ran against, in a repository's commit log. More specifically, a ref's commit
///  log.
///
///  It also specifies the host/project/ref combination that the commit
///  exists in, to provide context.
class GitilesCommit extends $pb.GeneratedMessage {
  factory GitilesCommit({
    $core.String? host,
    $core.String? project,
    $core.String? ref,
    $core.String? commitHash,
    $fixnum.Int64? position,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (project != null) {
      $result.project = project;
    }
    if (ref != null) {
      $result.ref = ref;
    }
    if (commitHash != null) {
      $result.commitHash = commitHash;
    }
    if (position != null) {
      $result.position = position;
    }
    return $result;
  }
  GitilesCommit._() : super();
  factory GitilesCommit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GitilesCommit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GitilesCommit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'ref')
    ..aOS(4, _omitFieldNames ? '' : 'commitHash')
    ..aInt64(5, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GitilesCommit clone() => GitilesCommit()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GitilesCommit copyWith(void Function(GitilesCommit) updates) =>
      super.copyWith((message) => updates(message as GitilesCommit)) as GitilesCommit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitilesCommit create() => GitilesCommit._();
  GitilesCommit createEmptyInstance() => create();
  static $pb.PbList<GitilesCommit> createRepeated() => $pb.PbList<GitilesCommit>();
  @$core.pragma('dart2js:noInline')
  static GitilesCommit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitilesCommit>(create);
  static GitilesCommit? _defaultInstance;

  /// The identity of the gitiles host, e.g. "chromium.googlesource.com".
  /// Mandatory.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// Repository name on the host, e.g. "chromium/src". Mandatory.
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// Commit ref, e.g. "refs/heads/main" from which the commit was fetched.
  /// Not the branch name, use "refs/heads/branch"
  /// Mandatory.
  @$pb.TagNumber(3)
  $core.String get ref => $_getSZ(2);
  @$pb.TagNumber(3)
  set ref($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRef() => $_has(2);
  @$pb.TagNumber(3)
  void clearRef() => clearField(3);

  /// Commit HEX SHA1. All lowercase. Mandatory.
  @$pb.TagNumber(4)
  $core.String get commitHash => $_getSZ(3);
  @$pb.TagNumber(4)
  set commitHash($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCommitHash() => $_has(3);
  @$pb.TagNumber(4)
  void clearCommitHash() => clearField(4);

  /// Defines a total order of commits on the ref.
  /// A positive, monotonically increasing integer. The recommended
  /// way of obtaining this is by using the goto.google.com/git-numberer
  /// Gerrit plugin. Other solutions can be used as well, so long
  /// as the same scheme is used consistently for a ref.
  /// Mandatory.
  @$pb.TagNumber(5)
  $fixnum.Int64 get position => $_getI64(4);
  @$pb.TagNumber(5)
  set position($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);
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
  factory GerritChange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GerritChange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GerritChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aInt64(3, _omitFieldNames ? '' : 'change')
    ..aInt64(4, _omitFieldNames ? '' : 'patchset')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GerritChange clone() => GerritChange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GerritChange copyWith(void Function(GerritChange) updates) =>
      super.copyWith((message) => updates(message as GerritChange)) as GerritChange;

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
  set host($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// Gerrit project, e.g. "chromium/src".
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// Change number, e.g. 12345.
  @$pb.TagNumber(3)
  $fixnum.Int64 get change => $_getI64(2);
  @$pb.TagNumber(3)
  set change($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasChange() => $_has(2);
  @$pb.TagNumber(3)
  void clearChange() => clearField(3);

  /// Patch set number, e.g. 1.
  @$pb.TagNumber(4)
  $fixnum.Int64 get patchset => $_getI64(3);
  @$pb.TagNumber(4)
  set patchset($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPatchset() => $_has(3);
  @$pb.TagNumber(4)
  void clearPatchset() => clearField(4);
}

/// Deprecated: Use GitilesCommit instead.
class CommitPosition extends $pb.GeneratedMessage {
  factory CommitPosition({
    $core.String? host,
    $core.String? project,
    $core.String? ref,
    $fixnum.Int64? position,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (project != null) {
      $result.project = project;
    }
    if (ref != null) {
      $result.ref = ref;
    }
    if (position != null) {
      $result.position = position;
    }
    return $result;
  }
  CommitPosition._() : super();
  factory CommitPosition.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitPosition.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommitPosition',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'ref')
    ..aInt64(4, _omitFieldNames ? '' : 'position')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitPosition clone() => CommitPosition()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitPosition copyWith(void Function(CommitPosition) updates) =>
      super.copyWith((message) => updates(message as CommitPosition)) as CommitPosition;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitPosition create() => CommitPosition._();
  CommitPosition createEmptyInstance() => create();
  static $pb.PbList<CommitPosition> createRepeated() => $pb.PbList<CommitPosition>();
  @$core.pragma('dart2js:noInline')
  static CommitPosition getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitPosition>(create);
  static CommitPosition? _defaultInstance;

  /// The following fields identify a git repository and a ref within which the
  /// numerical position below identifies a single commit.
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ref => $_getSZ(2);
  @$pb.TagNumber(3)
  set ref($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRef() => $_has(2);
  @$pb.TagNumber(3)
  void clearRef() => clearField(3);

  /// The numerical position of the commit in the log for the host/project/ref
  /// above.
  @$pb.TagNumber(4)
  $fixnum.Int64 get position => $_getI64(3);
  @$pb.TagNumber(4)
  set position($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPosition() => $_has(3);
  @$pb.TagNumber(4)
  void clearPosition() => clearField(4);
}

/// Deprecated: Do not use.
class CommitPositionRange extends $pb.GeneratedMessage {
  factory CommitPositionRange({
    CommitPosition? earliest,
    CommitPosition? latest,
  }) {
    final $result = create();
    if (earliest != null) {
      $result.earliest = earliest;
    }
    if (latest != null) {
      $result.latest = latest;
    }
    return $result;
  }
  CommitPositionRange._() : super();
  factory CommitPositionRange.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitPositionRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommitPositionRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<CommitPosition>(1, _omitFieldNames ? '' : 'earliest', subBuilder: CommitPosition.create)
    ..aOM<CommitPosition>(2, _omitFieldNames ? '' : 'latest', subBuilder: CommitPosition.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitPositionRange clone() => CommitPositionRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitPositionRange copyWith(void Function(CommitPositionRange) updates) =>
      super.copyWith((message) => updates(message as CommitPositionRange)) as CommitPositionRange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitPositionRange create() => CommitPositionRange._();
  CommitPositionRange createEmptyInstance() => create();
  static $pb.PbList<CommitPositionRange> createRepeated() => $pb.PbList<CommitPositionRange>();
  @$core.pragma('dart2js:noInline')
  static CommitPositionRange getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitPositionRange>(create);
  static CommitPositionRange? _defaultInstance;

  /// The lowest commit position to include in the range.
  @$pb.TagNumber(1)
  CommitPosition get earliest => $_getN(0);
  @$pb.TagNumber(1)
  set earliest(CommitPosition v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEarliest() => $_has(0);
  @$pb.TagNumber(1)
  void clearEarliest() => clearField(1);
  @$pb.TagNumber(1)
  CommitPosition ensureEarliest() => $_ensure(0);

  /// Include only commit positions that that are strictly lower than this.
  @$pb.TagNumber(2)
  CommitPosition get latest => $_getN(1);
  @$pb.TagNumber(2)
  set latest(CommitPosition v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLatest() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatest() => clearField(2);
  @$pb.TagNumber(2)
  CommitPosition ensureLatest() => $_ensure(1);
}

///  A range of timestamps.
///
///  Currently unused.
class TimeRange extends $pb.GeneratedMessage {
  factory TimeRange({
    $0.Timestamp? earliest,
    $0.Timestamp? latest,
  }) {
    final $result = create();
    if (earliest != null) {
      $result.earliest = earliest;
    }
    if (latest != null) {
      $result.latest = latest;
    }
    return $result;
  }
  TimeRange._() : super();
  factory TimeRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TimeRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TimeRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'earliest', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'latest', subBuilder: $0.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TimeRange clone() => TimeRange()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TimeRange copyWith(void Function(TimeRange) updates) =>
      super.copyWith((message) => updates(message as TimeRange)) as TimeRange;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TimeRange create() => TimeRange._();
  TimeRange createEmptyInstance() => create();
  static $pb.PbList<TimeRange> createRepeated() => $pb.PbList<TimeRange>();
  @$core.pragma('dart2js:noInline')
  static TimeRange getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TimeRange>(create);
  static TimeRange? _defaultInstance;

  /// The oldest timestamp to include in the range.
  @$pb.TagNumber(1)
  $0.Timestamp get earliest => $_getN(0);
  @$pb.TagNumber(1)
  set earliest($0.Timestamp v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasEarliest() => $_has(0);
  @$pb.TagNumber(1)
  void clearEarliest() => clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureEarliest() => $_ensure(0);

  /// Include only timestamps that are strictly older than this.
  @$pb.TagNumber(2)
  $0.Timestamp get latest => $_getN(1);
  @$pb.TagNumber(2)
  set latest($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLatest() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatest() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureLatest() => $_ensure(1);
}

enum SourceRef_System { gitiles, notSet }

/// Represents a reference in a source control system.
class SourceRef extends $pb.GeneratedMessage {
  factory SourceRef({
    GitilesRef? gitiles,
  }) {
    final $result = create();
    if (gitiles != null) {
      $result.gitiles = gitiles;
    }
    return $result;
  }
  SourceRef._() : super();
  factory SourceRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory SourceRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, SourceRef_System> _SourceRef_SystemByTag = {
    1: SourceRef_System.gitiles,
    0: SourceRef_System.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SourceRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<GitilesRef>(1, _omitFieldNames ? '' : 'gitiles', subBuilder: GitilesRef.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  SourceRef clone() => SourceRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  SourceRef copyWith(void Function(SourceRef) updates) =>
      super.copyWith((message) => updates(message as SourceRef)) as SourceRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SourceRef create() => SourceRef._();
  SourceRef createEmptyInstance() => create();
  static $pb.PbList<SourceRef> createRepeated() => $pb.PbList<SourceRef>();
  @$core.pragma('dart2js:noInline')
  static SourceRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SourceRef>(create);
  static SourceRef? _defaultInstance;

  SourceRef_System whichSystem() => _SourceRef_SystemByTag[$_whichOneof(0)]!;
  void clearSystem() => clearField($_whichOneof(0));

  /// A branch in gitiles repository.
  @$pb.TagNumber(1)
  GitilesRef get gitiles => $_getN(0);
  @$pb.TagNumber(1)
  set gitiles(GitilesRef v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasGitiles() => $_has(0);
  @$pb.TagNumber(1)
  void clearGitiles() => clearField(1);
  @$pb.TagNumber(1)
  GitilesRef ensureGitiles() => $_ensure(0);
}

/// Represents a branch in a gitiles repository.
class GitilesRef extends $pb.GeneratedMessage {
  factory GitilesRef({
    $core.String? host,
    $core.String? project,
    $core.String? ref,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (project != null) {
      $result.project = project;
    }
    if (ref != null) {
      $result.ref = ref;
    }
    return $result;
  }
  GitilesRef._() : super();
  factory GitilesRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GitilesRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GitilesRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'ref')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  GitilesRef clone() => GitilesRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  GitilesRef copyWith(void Function(GitilesRef) updates) =>
      super.copyWith((message) => updates(message as GitilesRef)) as GitilesRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GitilesRef create() => GitilesRef._();
  GitilesRef createEmptyInstance() => create();
  static $pb.PbList<GitilesRef> createRepeated() => $pb.PbList<GitilesRef>();
  @$core.pragma('dart2js:noInline')
  static GitilesRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GitilesRef>(create);
  static GitilesRef? _defaultInstance;

  /// The gitiles host, e.g. "chromium.googlesource.com".
  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  /// The project on the gitiles host, e.g. "chromium/src".
  @$pb.TagNumber(2)
  $core.String get project => $_getSZ(1);
  @$pb.TagNumber(2)
  set project($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasProject() => $_has(1);
  @$pb.TagNumber(2)
  void clearProject() => clearField(2);

  /// Commit ref, e.g. "refs/heads/main" from which the commit was fetched.
  /// Not the branch name, use "refs/heads/branch"
  @$pb.TagNumber(3)
  $core.String get ref => $_getSZ(2);
  @$pb.TagNumber(3)
  set ref($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasRef() => $_has(2);
  @$pb.TagNumber(3)
  void clearRef() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
