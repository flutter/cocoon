//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/struct.pb.dart' as $1;
import 'common.pb.dart' as $0;
import 'common.pbenum.dart' as $0;

/// A backend task.
/// Next id: 9.
class Task extends $pb.GeneratedMessage {
  factory Task({
    TaskID? id,
    $core.String? link,
    $0.Status? status,
    $0.StatusDetails? statusDetails,
    $core.String? summaryHtml,
    $1.Struct? details,
    $fixnum.Int64? updateId,
    $core.String? summaryMarkdown,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (link != null) {
      $result.link = link;
    }
    if (status != null) {
      $result.status = status;
    }
    if (statusDetails != null) {
      $result.statusDetails = statusDetails;
    }
    if (summaryHtml != null) {
      $result.summaryHtml = summaryHtml;
    }
    if (details != null) {
      $result.details = details;
    }
    if (updateId != null) {
      $result.updateId = updateId;
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    return $result;
  }
  Task._() : super();
  factory Task.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Task.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Task',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<TaskID>(1, _omitFieldNames ? '' : 'id', subBuilder: TaskID.create)
    ..aOS(2, _omitFieldNames ? '' : 'link')
    ..e<$0.Status>(3, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $0.Status.STATUS_UNSPECIFIED, valueOf: $0.Status.valueOf, enumValues: $0.Status.values)
    ..aOM<$0.StatusDetails>(4, _omitFieldNames ? '' : 'statusDetails', subBuilder: $0.StatusDetails.create)
    ..aOS(5, _omitFieldNames ? '' : 'summaryHtml')
    ..aOM<$1.Struct>(6, _omitFieldNames ? '' : 'details', subBuilder: $1.Struct.create)
    ..aInt64(7, _omitFieldNames ? '' : 'updateId')
    ..aOS(8, _omitFieldNames ? '' : 'summaryMarkdown')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Task clone() => Task()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Task copyWith(void Function(Task) updates) => super.copyWith((message) => updates(message as Task)) as Task;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Task create() => Task._();
  Task createEmptyInstance() => create();
  static $pb.PbList<Task> createRepeated() => $pb.PbList<Task>();
  @$core.pragma('dart2js:noInline')
  static Task getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Task>(create);
  static Task? _defaultInstance;

  @$pb.TagNumber(1)
  TaskID get id => $_getN(0);
  @$pb.TagNumber(1)
  set id(TaskID v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);
  @$pb.TagNumber(1)
  TaskID ensureId() => $_ensure(0);

  /// (optional) Human-clickable link to the status page for this task.
  /// This should be populated as part of the Task response in RunTaskResponse.
  /// Any update to this via the Task field in BuildTaskUpdate will override the
  /// existing link that was provided in RunTaskResponse.
  @$pb.TagNumber(2)
  $core.String get link => $_getSZ(1);
  @$pb.TagNumber(2)
  set link($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLink() => $_has(1);
  @$pb.TagNumber(2)
  void clearLink() => clearField(2);

  /// The backend's status for handling this task.
  @$pb.TagNumber(3)
  $0.Status get status => $_getN(2);
  @$pb.TagNumber(3)
  set status($0.Status v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatus() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatus() => clearField(3);

  /// The 'status_details' around handling this task.
  @$pb.TagNumber(4)
  $0.StatusDetails get statusDetails => $_getN(3);
  @$pb.TagNumber(4)
  set statusDetails($0.StatusDetails v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasStatusDetails() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatusDetails() => clearField(4);
  @$pb.TagNumber(4)
  $0.StatusDetails ensureStatusDetails() => $_ensure(3);

  /// Deprecated. Use summary_markdown instead.
  @$pb.TagNumber(5)
  $core.String get summaryHtml => $_getSZ(4);
  @$pb.TagNumber(5)
  set summaryHtml($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasSummaryHtml() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummaryHtml() => clearField(5);

  ///  Additional backend-specific details about the task.
  ///
  ///  This could be used to indicate things like named-cache status, task
  ///  startup/end time, etc.
  ///
  ///  This is limited to 10KB (binary PB + gzip(5))
  ///
  ///  This should be populated as part of the Task response in RunTaskResponse.
  ///  Any update to this via the Task field in BuildTaskUpdate will override the
  ///  existing details that were provided in RunTaskResponse.
  @$pb.TagNumber(6)
  $1.Struct get details => $_getN(5);
  @$pb.TagNumber(6)
  set details($1.Struct v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasDetails() => $_has(5);
  @$pb.TagNumber(6)
  void clearDetails() => clearField(6);
  @$pb.TagNumber(6)
  $1.Struct ensureDetails() => $_ensure(5);

  /// A monotonically increasing integer set by the backend to track
  /// which task is the most up to date when calling UpdateBuildTask.
  /// When the build is first created, this will be set to 0.
  /// When RunTask is called and returns a task, this should not be 0 or nil.
  /// Each UpdateBuildTask call will check this to ensure the latest task is
  /// being stored in datastore.
  @$pb.TagNumber(7)
  $fixnum.Int64 get updateId => $_getI64(6);
  @$pb.TagNumber(7)
  set updateId($fixnum.Int64 v) {
    $_setInt64(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasUpdateId() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdateId() => clearField(7);

  /// Human-readable commentary around the handling of this task.
  @$pb.TagNumber(8)
  $core.String get summaryMarkdown => $_getSZ(7);
  @$pb.TagNumber(8)
  set summaryMarkdown($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasSummaryMarkdown() => $_has(7);
  @$pb.TagNumber(8)
  void clearSummaryMarkdown() => clearField(8);
}

/// A unique identifier for tasks.
class TaskID extends $pb.GeneratedMessage {
  factory TaskID({
    $core.String? target,
    $core.String? id,
  }) {
    final $result = create();
    if (target != null) {
      $result.target = target;
    }
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  TaskID._() : super();
  factory TaskID.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TaskID.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TaskID',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'target')
    ..aOS(2, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TaskID clone() => TaskID()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TaskID copyWith(void Function(TaskID) updates) => super.copyWith((message) => updates(message as TaskID)) as TaskID;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskID create() => TaskID._();
  TaskID createEmptyInstance() => create();
  static $pb.PbList<TaskID> createRepeated() => $pb.PbList<TaskID>();
  @$core.pragma('dart2js:noInline')
  static TaskID getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TaskID>(create);
  static TaskID? _defaultInstance;

  /// Target backend. e.g. "swarming://chromium-swarm".
  @$pb.TagNumber(1)
  $core.String get target => $_getSZ(0);
  @$pb.TagNumber(1)
  set target($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTarget() => $_has(0);
  @$pb.TagNumber(1)
  void clearTarget() => clearField(1);

  /// An ID unique to the target used to identify this task. e.g. Swarming task
  /// ID.
  @$pb.TagNumber(2)
  $core.String get id => $_getSZ(1);
  @$pb.TagNumber(2)
  set id($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasId() => $_has(1);
  @$pb.TagNumber(2)
  void clearId() => clearField(2);
}

///  A message sent by task backends as part of the payload to a
///  pubsub topic corresponding with that backend. Buildbucket handles these
///  pubsub messages with the UpdateBuildTask cloud task.
///  Backends must use this proto when sending pubsub updates to buildbucket.
///
///  NOTE: If the task has not been registered with buildbucket yet (by means of
///  RunTask returning or StartBuild doing an initial associaton of the task to
///  the build), then the message will be dropped and lost forever.
///  Use with caution.
class BuildTaskUpdate extends $pb.GeneratedMessage {
  factory BuildTaskUpdate({
    $core.String? buildId,
    Task? task,
  }) {
    final $result = create();
    if (buildId != null) {
      $result.buildId = buildId;
    }
    if (task != null) {
      $result.task = task;
    }
    return $result;
  }
  BuildTaskUpdate._() : super();
  factory BuildTaskUpdate.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildTaskUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildTaskUpdate',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'buildId')
    ..aOM<Task>(2, _omitFieldNames ? '' : 'task', subBuilder: Task.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildTaskUpdate clone() => BuildTaskUpdate()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildTaskUpdate copyWith(void Function(BuildTaskUpdate) updates) =>
      super.copyWith((message) => updates(message as BuildTaskUpdate)) as BuildTaskUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildTaskUpdate create() => BuildTaskUpdate._();
  BuildTaskUpdate createEmptyInstance() => create();
  static $pb.PbList<BuildTaskUpdate> createRepeated() => $pb.PbList<BuildTaskUpdate>();
  @$core.pragma('dart2js:noInline')
  static BuildTaskUpdate getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildTaskUpdate>(create);
  static BuildTaskUpdate? _defaultInstance;

  /// A build ID.
  @$pb.TagNumber(1)
  $core.String get buildId => $_getSZ(0);
  @$pb.TagNumber(1)
  set buildId($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildId() => clearField(1);

  /// Task
  @$pb.TagNumber(2)
  Task get task => $_getN(1);
  @$pb.TagNumber(2)
  set task(Task v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTask() => $_has(1);
  @$pb.TagNumber(2)
  void clearTask() => clearField(2);
  @$pb.TagNumber(2)
  Task ensureTask() => $_ensure(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
