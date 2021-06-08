///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/commit_status.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $0;
import 'stage.pb.dart' as $1;

class CommitStatus extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CommitStatus', createEmptyInstance: create)
    ..aOM<$0.Commit>(1, 'commit', subBuilder: $0.Commit.create)
    ..pc<$1.Stage>(2, 'stages', $pb.PbFieldType.PM, subBuilder: $1.Stage.create)
    ..aOS(3, 'branch')
    ..hasRequiredFields = false;

  CommitStatus._() : super();
  factory CommitStatus() => create();
  factory CommitStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  CommitStatus clone() => CommitStatus()..mergeFromMessage(this);
  CommitStatus copyWith(void Function(CommitStatus) updates) =>
      super.copyWith((message) => updates(message as CommitStatus));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitStatus create() => CommitStatus._();
  CommitStatus createEmptyInstance() => create();
  static $pb.PbList<CommitStatus> createRepeated() => $pb.PbList<CommitStatus>();
  @$core.pragma('dart2js:noInline')
  static CommitStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitStatus>(create);
  static CommitStatus _defaultInstance;

  @$pb.TagNumber(1)
  $0.Commit get commit => $_getN(0);
  @$pb.TagNumber(1)
  set commit($0.Commit v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCommit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommit() => clearField(1);
  @$pb.TagNumber(1)
  $0.Commit ensureCommit() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$1.Stage> get stages => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get branch => $_getSZ(2);
  @$pb.TagNumber(3)
  set branch($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasBranch() => $_has(2);
  @$pb.TagNumber(3)
  void clearBranch() => clearField(3);
}
