///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/commit_status.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $0;
import 'stage.pb.dart' as $1;

class CommitStatus extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('CommitStatus')
    ..a<$0.Commit>(1, 'commit', $pb.PbFieldType.OM, $0.Commit.getDefault, $0.Commit.create)
    ..pc<$1.Stage>(2, 'stages', $pb.PbFieldType.PM,$1.Stage.create)
    ..hasRequiredFields = false
  ;

  CommitStatus._() : super();
  factory CommitStatus() => create();
  factory CommitStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CommitStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  CommitStatus clone() => CommitStatus()..mergeFromMessage(this);
  CommitStatus copyWith(void Function(CommitStatus) updates) => super.copyWith((message) => updates(message as CommitStatus));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitStatus create() => CommitStatus._();
  CommitStatus createEmptyInstance() => create();
  static $pb.PbList<CommitStatus> createRepeated() => $pb.PbList<CommitStatus>();
  static CommitStatus getDefault() => _defaultInstance ??= create()..freeze();
  static CommitStatus _defaultInstance;

  $0.Commit get commit => $_getN(0);
  set commit($0.Commit v) { setField(1, v); }
  $core.bool hasCommit() => $_has(0);
  void clearCommit() => clearField(1);

  $core.List<$1.Stage> get stages => $_getList(1);
}

