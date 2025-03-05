//
//  Generated code. Do not modify.
//  source: lib/model/commit_tasks_status.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'commit_firestore.pb.dart' as $0;
import 'task_firestore.pb.dart' as $1;

class CommitTasksStatus extends $pb.GeneratedMessage {
  factory CommitTasksStatus({
    $0.CommitDocument? commit,
    $core.Iterable<$1.TaskDocument>? tasks,
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
  CommitTasksStatus._() : super();
  factory CommitTasksStatus.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitTasksStatus.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CommitTasksStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'),
      createEmptyInstance: create)
    ..aOM<$0.CommitDocument>(1, _omitFieldNames ? '' : 'commit',
        subBuilder: $0.CommitDocument.create)
    ..pc<$1.TaskDocument>(2, _omitFieldNames ? '' : 'tasks', $pb.PbFieldType.PM,
        subBuilder: $1.TaskDocument.create)
    ..aOS(3, _omitFieldNames ? '' : 'branch')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitTasksStatus clone() => CommitTasksStatus()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitTasksStatus copyWith(void Function(CommitTasksStatus) updates) =>
      super.copyWith((message) => updates(message as CommitTasksStatus))
          as CommitTasksStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitTasksStatus create() => CommitTasksStatus._();
  CommitTasksStatus createEmptyInstance() => create();
  static $pb.PbList<CommitTasksStatus> createRepeated() =>
      $pb.PbList<CommitTasksStatus>();
  @$core.pragma('dart2js:noInline')
  static CommitTasksStatus getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CommitTasksStatus>(create);
  static CommitTasksStatus? _defaultInstance;

  @$pb.TagNumber(1)
  $0.CommitDocument get commit => $_getN(0);
  @$pb.TagNumber(1)
  set commit($0.CommitDocument v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCommit() => $_has(0);
  @$pb.TagNumber(1)
  void clearCommit() => clearField(1);
  @$pb.TagNumber(1)
  $0.CommitDocument ensureCommit() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$1.TaskDocument> get tasks => $_getList(1);

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
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
