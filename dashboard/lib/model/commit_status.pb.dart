//
//  Generated code. Do not modify.
//  source: lib/model/commit_status.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit.pb.dart' as $1;
import 'task.pb.dart' as $2;

class CommitStatus extends $pb.GeneratedMessage {
  factory CommitStatus({
    $1.Commit? commit,
    $core.Iterable<$2.Task>? tasks,
    $core.String? branch,
  }) {
    final $result = create();
    if (commit != null) {
      $result.commit = commit;
    }
    if (tasks != null) {
      $result.tasks.addAll(tasks);
    }
    if (branch != null) {
      $result.branch = branch;
    }
    return $result;
  }
  CommitStatus._() : super();
  factory CommitStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommitStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'), createEmptyInstance: create)
    ..aOM<$1.Commit>(1, _omitFieldNames ? '' : 'commit', subBuilder: $1.Commit.create)
    ..pc<$2.Task>(2, _omitFieldNames ? '' : 'tasks', $pb.PbFieldType.PM, subBuilder: $2.Task.create)
    ..aOS(3, _omitFieldNames ? '' : 'branch')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitStatus clone() => CommitStatus()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitStatus copyWith(void Function(CommitStatus) updates) =>
      super.copyWith((message) => updates(message as CommitStatus)) as CommitStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitStatus create() => CommitStatus._();
  CommitStatus createEmptyInstance() => create();
  static $pb.PbList<CommitStatus> createRepeated() => $pb.PbList<CommitStatus>();
  @$core.pragma('dart2js:noInline')
  static CommitStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitStatus>(create);
  static CommitStatus? _defaultInstance;

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
  $core.List<$2.Task> get tasks => $_getList(1);

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

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
