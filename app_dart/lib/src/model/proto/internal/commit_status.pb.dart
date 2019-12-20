///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/commit_status.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $1;
import 'stage.pb.dart' as $3;

class CommitStatus extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CommitStatus',
      createEmptyInstance: create)
    ..aOM<$1.Commit>(1, 'commit', subBuilder: $1.Commit.create)
    ..pc<$3.Stage>(2, 'stages', $pb.PbFieldType.PM, subBuilder: $3.Stage.create)
    ..hasRequiredFields = false;

  CommitStatus._() : super();
  factory CommitStatus() => create();
  factory CommitStatus.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitStatus.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  CommitStatus clone() => CommitStatus()..mergeFromMessage(this);
  CommitStatus copyWith(void Function(CommitStatus) updates) =>
      super.copyWith((message) => updates(message as CommitStatus));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitStatus create() => CommitStatus._();
  CommitStatus createEmptyInstance() => create();
  static $pb.PbList<CommitStatus> createRepeated() =>
      $pb.PbList<CommitStatus>();
  @$core.pragma('dart2js:noInline')
  static CommitStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommitStatus>(create);
  static CommitStatus _defaultInstance;

  @$pb.TagNumber(1)
  $1.Commit get commit => $_getN(0);
  @$pb.TagNumber(1)
  set commit($1.Commit v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCommit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommit() => clearField(1);
  @$pb.TagNumber(1)
  $1.Commit ensureCommit() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$3.Stage> get stages => $_getList(1);
}
