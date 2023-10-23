//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $1;
import '../../../../google/protobuf/timestamp.pb.dart' as $0;

export 'common.pbenum.dart';

class Executable extends $pb.GeneratedMessage {
  factory Executable() => create();
  Executable._() : super();
  factory Executable.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Executable.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Executable',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cipdPackage')
    ..aOS(2, _omitFieldNames ? '' : 'cipdVersion')
    ..pPS(3, _omitFieldNames ? '' : 'cmd')
    ..pPS(4, _omitFieldNames ? '' : 'wrapper')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Executable clone() => Executable()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Executable copyWith(void Function(Executable) updates) =>
      super.copyWith((message) => updates(message as Executable)) as Executable;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Executable create() => Executable._();
  Executable createEmptyInstance() => create();
  static $pb.PbList<Executable> createRepeated() => $pb.PbList<Executable>();
  @$core.pragma('dart2js:noInline')
  static Executable getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Executable>(create);
  static Executable? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get cipdPackage => $_getSZ(0);
  @$pb.TagNumber(1)
  set cipdPackage($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCipdPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipdPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get cipdVersion => $_getSZ(1);
  @$pb.TagNumber(2)
  set cipdVersion($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCipdVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipdVersion() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get cmd => $_getList(2);

  @$pb.TagNumber(4)
  $core.List<$core.String> get wrapper => $_getList(3);
}

class StatusDetails_ResourceExhaustion extends $pb.GeneratedMessage {
  factory StatusDetails_ResourceExhaustion() => create();
  StatusDetails_ResourceExhaustion._() : super();
  factory StatusDetails_ResourceExhaustion.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StatusDetails_ResourceExhaustion.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails.ResourceExhaustion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StatusDetails_ResourceExhaustion clone() => StatusDetails_ResourceExhaustion()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StatusDetails_ResourceExhaustion copyWith(void Function(StatusDetails_ResourceExhaustion) updates) =>
      super.copyWith((message) => updates(message as StatusDetails_ResourceExhaustion))
          as StatusDetails_ResourceExhaustion;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails_ResourceExhaustion create() => StatusDetails_ResourceExhaustion._();
  StatusDetails_ResourceExhaustion createEmptyInstance() => create();
  static $pb.PbList<StatusDetails_ResourceExhaustion> createRepeated() =>
      $pb.PbList<StatusDetails_ResourceExhaustion>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails_ResourceExhaustion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails_ResourceExhaustion>(create);
  static StatusDetails_ResourceExhaustion? _defaultInstance;
}

class StatusDetails_Timeout extends $pb.GeneratedMessage {
  factory StatusDetails_Timeout() => create();
  StatusDetails_Timeout._() : super();
  factory StatusDetails_Timeout.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StatusDetails_Timeout.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails.Timeout',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StatusDetails_Timeout clone() => StatusDetails_Timeout()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StatusDetails_Timeout copyWith(void Function(StatusDetails_Timeout) updates) =>
      super.copyWith((message) => updates(message as StatusDetails_Timeout)) as StatusDetails_Timeout;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails_Timeout create() => StatusDetails_Timeout._();
  StatusDetails_Timeout createEmptyInstance() => create();
  static $pb.PbList<StatusDetails_Timeout> createRepeated() => $pb.PbList<StatusDetails_Timeout>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails_Timeout getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails_Timeout>(create);
  static StatusDetails_Timeout? _defaultInstance;
}

class StatusDetails extends $pb.GeneratedMessage {
  factory StatusDetails() => create();
  StatusDetails._() : super();
  factory StatusDetails.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StatusDetails.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatusDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<StatusDetails_ResourceExhaustion>(3, _omitFieldNames ? '' : 'resourceExhaustion',
        subBuilder: StatusDetails_ResourceExhaustion.create)
    ..aOM<StatusDetails_Timeout>(4, _omitFieldNames ? '' : 'timeout', subBuilder: StatusDetails_Timeout.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  StatusDetails clone() => StatusDetails()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  StatusDetails copyWith(void Function(StatusDetails) updates) =>
      super.copyWith((message) => updates(message as StatusDetails)) as StatusDetails;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatusDetails create() => StatusDetails._();
  StatusDetails createEmptyInstance() => create();
  static $pb.PbList<StatusDetails> createRepeated() => $pb.PbList<StatusDetails>();
  @$core.pragma('dart2js:noInline')
  static StatusDetails getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatusDetails>(create);
  static StatusDetails? _defaultInstance;

  @$pb.TagNumber(3)
  StatusDetails_ResourceExhaustion get resourceExhaustion => $_getN(0);
  @$pb.TagNumber(3)
  set resourceExhaustion(StatusDetails_ResourceExhaustion v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasResourceExhaustion() => $_has(0);
  @$pb.TagNumber(3)
  void clearResourceExhaustion() => clearField(3);
  @$pb.TagNumber(3)
  StatusDetails_ResourceExhaustion ensureResourceExhaustion() => $_ensure(0);

  @$pb.TagNumber(4)
  StatusDetails_Timeout get timeout => $_getN(1);
  @$pb.TagNumber(4)
  set timeout(StatusDetails_Timeout v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasTimeout() => $_has(1);
  @$pb.TagNumber(4)
  void clearTimeout() => clearField(4);
  @$pb.TagNumber(4)
  StatusDetails_Timeout ensureTimeout() => $_ensure(1);
}

class Log extends $pb.GeneratedMessage {
  factory Log() => create();
  Log._() : super();
  factory Log.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Log.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Log',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'viewUrl')
    ..aOS(3, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Log clone() => Log()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
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

  @$pb.TagNumber(2)
  $core.String get viewUrl => $_getSZ(1);
  @$pb.TagNumber(2)
  set viewUrl($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasViewUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearViewUrl() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get url => $_getSZ(2);
  @$pb.TagNumber(3)
  set url($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearUrl() => clearField(3);
}

class GerritChange extends $pb.GeneratedMessage {
  factory GerritChange() => create();
  GerritChange._() : super();
  factory GerritChange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GerritChange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GerritChange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
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
  $fixnum.Int64 get change => $_getI64(2);
  @$pb.TagNumber(3)
  set change($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasChange() => $_has(2);
  @$pb.TagNumber(3)
  void clearChange() => clearField(3);

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

class GitilesCommit extends $pb.GeneratedMessage {
  factory GitilesCommit() => create();
  GitilesCommit._() : super();
  factory GitilesCommit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory GitilesCommit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GitilesCommit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..aOS(4, _omitFieldNames ? '' : 'ref')
    ..a<$core.int>(5, _omitFieldNames ? '' : 'position', $pb.PbFieldType.OU3)
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
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get ref => $_getSZ(3);
  @$pb.TagNumber(4)
  set ref($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRef() => $_has(3);
  @$pb.TagNumber(4)
  void clearRef() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get position => $_getIZ(4);
  @$pb.TagNumber(5)
  set position($core.int v) {
    $_setUnsignedInt32(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasPosition() => $_has(4);
  @$pb.TagNumber(5)
  void clearPosition() => clearField(5);
}

class StringPair extends $pb.GeneratedMessage {
  factory StringPair() => create();
  StringPair._() : super();
  factory StringPair.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory StringPair.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StringPair',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
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

class TimeRange extends $pb.GeneratedMessage {
  factory TimeRange() => create();
  TimeRange._() : super();
  factory TimeRange.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TimeRange.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TimeRange',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$0.Timestamp>(1, _omitFieldNames ? '' : 'startTime', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'endTime', subBuilder: $0.Timestamp.create)
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

  @$pb.TagNumber(1)
  $0.Timestamp get startTime => $_getN(0);
  @$pb.TagNumber(1)
  set startTime($0.Timestamp v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasStartTime() => $_has(0);
  @$pb.TagNumber(1)
  void clearStartTime() => clearField(1);
  @$pb.TagNumber(1)
  $0.Timestamp ensureStartTime() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.Timestamp get endTime => $_getN(1);
  @$pb.TagNumber(2)
  set endTime($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasEndTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearEndTime() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureEndTime() => $_ensure(1);
}

class RequestedDimension extends $pb.GeneratedMessage {
  factory RequestedDimension() => create();
  RequestedDimension._() : super();
  factory RequestedDimension.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RequestedDimension.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RequestedDimension',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'value')
    ..aOM<$1.Duration>(3, _omitFieldNames ? '' : 'expiration', subBuilder: $1.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RequestedDimension clone() => RequestedDimension()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RequestedDimension copyWith(void Function(RequestedDimension) updates) =>
      super.copyWith((message) => updates(message as RequestedDimension)) as RequestedDimension;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RequestedDimension create() => RequestedDimension._();
  RequestedDimension createEmptyInstance() => create();
  static $pb.PbList<RequestedDimension> createRepeated() => $pb.PbList<RequestedDimension>();
  @$core.pragma('dart2js:noInline')
  static RequestedDimension getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RequestedDimension>(create);
  static RequestedDimension? _defaultInstance;

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

  @$pb.TagNumber(3)
  $1.Duration get expiration => $_getN(2);
  @$pb.TagNumber(3)
  set expiration($1.Duration v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasExpiration() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpiration() => clearField(3);
  @$pb.TagNumber(3)
  $1.Duration ensureExpiration() => $_ensure(2);
}

class CacheEntry extends $pb.GeneratedMessage {
  factory CacheEntry() => create();
  CacheEntry._() : super();
  factory CacheEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CacheEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CacheEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<$1.Duration>(3, _omitFieldNames ? '' : 'waitForWarmCache', subBuilder: $1.Duration.create)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CacheEntry clone() => CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CacheEntry copyWith(void Function(CacheEntry) updates) =>
      super.copyWith((message) => updates(message as CacheEntry)) as CacheEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CacheEntry create() => CacheEntry._();
  CacheEntry createEmptyInstance() => create();
  static $pb.PbList<CacheEntry> createRepeated() => $pb.PbList<CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static CacheEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CacheEntry>(create);
  static CacheEntry? _defaultInstance;

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

  @$pb.TagNumber(3)
  $1.Duration get waitForWarmCache => $_getN(2);
  @$pb.TagNumber(3)
  set waitForWarmCache($1.Duration v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCache() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCache() => clearField(3);
  @$pb.TagNumber(3)
  $1.Duration ensureWaitForWarmCache() => $_ensure(2);

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

class HealthStatus extends $pb.GeneratedMessage {
  factory HealthStatus() => create();
  HealthStatus._() : super();
  factory HealthStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory HealthStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HealthStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'healthScore')
    ..m<$core.String, $core.double>(2, _omitFieldNames ? '' : 'healthMetrics',
        entryClassName: 'HealthStatus.HealthMetricsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OF,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOS(3, _omitFieldNames ? '' : 'description')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'docLinks',
        entryClassName: 'HealthStatus.DocLinksEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, $core.String>(5, _omitFieldNames ? '' : 'dataLinks',
        entryClassName: 'HealthStatus.DataLinksEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOS(6, _omitFieldNames ? '' : 'reporter')
    ..aOM<$0.Timestamp>(7, _omitFieldNames ? '' : 'reportedTime', subBuilder: $0.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'contactTeamEmail')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  HealthStatus clone() => HealthStatus()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  HealthStatus copyWith(void Function(HealthStatus) updates) =>
      super.copyWith((message) => updates(message as HealthStatus)) as HealthStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthStatus create() => HealthStatus._();
  HealthStatus createEmptyInstance() => create();
  static $pb.PbList<HealthStatus> createRepeated() => $pb.PbList<HealthStatus>();
  @$core.pragma('dart2js:noInline')
  static HealthStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HealthStatus>(create);
  static HealthStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get healthScore => $_getI64(0);
  @$pb.TagNumber(1)
  set healthScore($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHealthScore() => $_has(0);
  @$pb.TagNumber(1)
  void clearHealthScore() => clearField(1);

  @$pb.TagNumber(2)
  $core.Map<$core.String, $core.double> get healthMetrics => $_getMap(1);

  @$pb.TagNumber(3)
  $core.String get description => $_getSZ(2);
  @$pb.TagNumber(3)
  set description($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasDescription() => $_has(2);
  @$pb.TagNumber(3)
  void clearDescription() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.String> get docLinks => $_getMap(3);

  @$pb.TagNumber(5)
  $core.Map<$core.String, $core.String> get dataLinks => $_getMap(4);

  @$pb.TagNumber(6)
  $core.String get reporter => $_getSZ(5);
  @$pb.TagNumber(6)
  set reporter($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasReporter() => $_has(5);
  @$pb.TagNumber(6)
  void clearReporter() => clearField(6);

  @$pb.TagNumber(7)
  $0.Timestamp get reportedTime => $_getN(6);
  @$pb.TagNumber(7)
  set reportedTime($0.Timestamp v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasReportedTime() => $_has(6);
  @$pb.TagNumber(7)
  void clearReportedTime() => clearField(7);
  @$pb.TagNumber(7)
  $0.Timestamp ensureReportedTime() => $_ensure(6);

  @$pb.TagNumber(8)
  $core.String get contactTeamEmail => $_getSZ(7);
  @$pb.TagNumber(8)
  set contactTeamEmail($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasContactTeamEmail() => $_has(7);
  @$pb.TagNumber(8)
  void clearContactTeamEmail() => clearField(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
