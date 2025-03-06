///
//  Generated code. Do not modify.
//  source: lib/model/commit_status.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $0;
import 'task.pb.dart' as $1;

class CommitStatus extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'CommitStatus',
      createEmptyInstance: create)
    ..aOM<$0.Commit>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'commit',
        subBuilder: $0.Commit.create)
    ..pc<$1.Task>(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'tasks',
        $pb.PbFieldType.PM,
        subBuilder: $1.Task.create)
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'branch')
    ..hasRequiredFields = false;

  CommitStatus._() : super();
  factory CommitStatus({
    $0.Commit? commit,
    $core.Iterable<$1.Task>? tasks,
    $core.String? branch,
  }) {
    final _result = create();
    if (commit != null) {
      _result.commit = commit;
    }
    if (tasks != null) {
      _result.tasks.addAll(tasks);
    }
    if (branch != null) {
      _result.branch = branch;
    }
    return _result;
  }
  factory CommitStatus.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitStatus.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitStatus clone() => CommitStatus()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitStatus copyWith(void Function(CommitStatus) updates) =>
      super.copyWith((message) => updates(message as CommitStatus))
          as CommitStatus; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static CommitStatus create() => CommitStatus._();
  CommitStatus createEmptyInstance() => create();
  static $pb.PbList<CommitStatus> createRepeated() =>
      $pb.PbList<CommitStatus>();
  @$core.pragma('dart2js:noInline')
  static CommitStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommitStatus>(create);
  static CommitStatus? _defaultInstance;

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
  $core.List<$1.Task> get tasks => $_getList(1);

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
