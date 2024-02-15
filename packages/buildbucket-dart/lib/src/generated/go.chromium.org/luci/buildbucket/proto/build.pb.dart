//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/duration.pb.dart' as $4;
import '../../../../google/protobuf/struct.pb.dart' as $5;
import '../../../../google/protobuf/timestamp.pb.dart' as $1;
import '../../resultdb/proto/v1/invocation.pb.dart' as $6;
import 'build.pbenum.dart';
import 'builder_common.pb.dart' as $0;
import 'common.pb.dart' as $3;
import 'common.pbenum.dart' as $3;
import 'step.pb.dart' as $2;
import 'task.pb.dart' as $7;

export 'build.pbenum.dart';

///  Defines what to build/test.
///
///  Behavior of a build executable MAY depend on Input.
///  It MAY NOT modify its behavior based on anything outside of Input.
///  It MAY read non-Input fields to display for debugging or to pass-through to
///  triggered builds. For example the "tags" field may be passed to triggered
///  builds, or the "infra" field may be printed for debugging purposes.
class Build_Input extends $pb.GeneratedMessage {
  factory Build_Input({
    $5.Struct? properties,
    $3.GitilesCommit? gitilesCommit,
    $core.Iterable<$3.GerritChange>? gerritChanges,
    $core.bool? experimental,
    $core.Iterable<$core.String>? experiments,
  }) {
    final $result = create();
    if (properties != null) {
      $result.properties = properties;
    }
    if (gitilesCommit != null) {
      $result.gitilesCommit = gitilesCommit;
    }
    if (gerritChanges != null) {
      $result.gerritChanges.addAll(gerritChanges);
    }
    if (experimental != null) {
      $result.experimental = experimental;
    }
    if (experiments != null) {
      $result.experiments.addAll(experiments);
    }
    return $result;
  }
  Build_Input._() : super();
  factory Build_Input.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOM<$3.GitilesCommit>(2, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.GerritChange>(3, _omitFieldNames ? '' : 'gerritChanges', $pb.PbFieldType.PM,
        subBuilder: $3.GerritChange.create)
    ..aOB(5, _omitFieldNames ? '' : 'experimental')
    ..pPS(6, _omitFieldNames ? '' : 'experiments')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_Input clone() => Build_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_Input copyWith(void Function(Build_Input) updates) =>
      super.copyWith((message) => updates(message as Build_Input)) as Build_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Build_Input create() => Build_Input._();
  Build_Input createEmptyInstance() => create();
  static $pb.PbList<Build_Input> createRepeated() => $pb.PbList<Build_Input>();
  @$core.pragma('dart2js:noInline')
  static Build_Input getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_Input>(create);
  static Build_Input? _defaultInstance;

  ///  Arbitrary JSON object. Available at build run time.
  ///
  ///  RPC: By default, this field is excluded from responses.
  ///
  ///  V1 equivalent: corresponds to "properties" key in "parameters_json".
  @$pb.TagNumber(1)
  $5.Struct get properties => $_getN(0);
  @$pb.TagNumber(1)
  set properties($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  ///  The Gitiles commit to run against.
  ///  Usually present in CI builds, set by LUCI Scheduler.
  ///  If not present, the build may checkout "refs/heads/master".
  ///  NOT a blamelist.
  ///
  ///  V1 equivalent: supersedes "revision" property and "buildset"
  ///  tag that starts with "commit/gitiles/".
  @$pb.TagNumber(2)
  $3.GitilesCommit get gitilesCommit => $_getN(1);
  @$pb.TagNumber(2)
  set gitilesCommit($3.GitilesCommit v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasGitilesCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearGitilesCommit() => clearField(2);
  @$pb.TagNumber(2)
  $3.GitilesCommit ensureGitilesCommit() => $_ensure(1);

  ///  Gerrit patchsets to run against.
  ///  Usually present in tryjobs, set by CQ, Gerrit, git-cl-try.
  ///  Applied on top of gitiles_commit if specified, otherwise tip of the tree.
  ///
  ///  V1 equivalent: supersedes patch_* properties and "buildset"
  ///  tag that starts with "patch/gerrit/".
  @$pb.TagNumber(3)
  $core.List<$3.GerritChange> get gerritChanges => $_getList(2);

  ///  DEPRECATED
  ///
  ///  Equivalent to `"luci.non_production" in experiments`.
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(5)
  $core.bool get experimental => $_getBF(3);
  @$pb.TagNumber(5)
  set experimental($core.bool v) {
    $_setBool(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasExperimental() => $_has(3);
  @$pb.TagNumber(5)
  void clearExperimental() => clearField(5);

  ///  The sorted list of experiments enabled on this build.
  ///
  ///  See `Builder.experiments` for a detailed breakdown on how experiments
  ///  work, and go/buildbucket-settings.cfg for the current state of global
  ///  experiments.
  @$pb.TagNumber(6)
  $core.List<$core.String> get experiments => $_getList(4);
}

/// Result of the build executable.
class Build_Output extends $pb.GeneratedMessage {
  factory Build_Output({
    $5.Struct? properties,
    $core.String? summaryMarkdown,
    $3.GitilesCommit? gitilesCommit,
    $core.Iterable<$3.Log>? logs,
    $3.Status? status,
    $3.StatusDetails? statusDetails,
    @$core.Deprecated('This field is deprecated.') $core.String? summaryHtml,
  }) {
    final $result = create();
    if (properties != null) {
      $result.properties = properties;
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    if (gitilesCommit != null) {
      $result.gitilesCommit = gitilesCommit;
    }
    if (logs != null) {
      $result.logs.addAll(logs);
    }
    if (status != null) {
      $result.status = status;
    }
    if (statusDetails != null) {
      $result.statusDetails = statusDetails;
    }
    if (summaryHtml != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.summaryHtml = summaryHtml;
    }
    return $result;
  }
  Build_Output._() : super();
  factory Build_Output.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_Output.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.Output',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'properties', subBuilder: $5.Struct.create)
    ..aOS(2, _omitFieldNames ? '' : 'summaryMarkdown')
    ..aOM<$3.GitilesCommit>(3, _omitFieldNames ? '' : 'gitilesCommit', subBuilder: $3.GitilesCommit.create)
    ..pc<$3.Log>(5, _omitFieldNames ? '' : 'logs', $pb.PbFieldType.PM, subBuilder: $3.Log.create)
    ..e<$3.Status>(6, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<$3.StatusDetails>(7, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(8, _omitFieldNames ? '' : 'summaryHtml')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_Output clone() => Build_Output()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_Output copyWith(void Function(Build_Output) updates) =>
      super.copyWith((message) => updates(message as Build_Output)) as Build_Output;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Build_Output create() => Build_Output._();
  Build_Output createEmptyInstance() => create();
  static $pb.PbList<Build_Output> createRepeated() => $pb.PbList<Build_Output>();
  @$core.pragma('dart2js:noInline')
  static Build_Output getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_Output>(create);
  static Build_Output? _defaultInstance;

  ///  Arbitrary JSON object produced by the build.
  ///
  ///  In recipes, use step_result.presentation.properties to set these,
  ///  for example
  ///
  ///    step_result = api.step(['echo'])
  ///    step_result.presentation.properties['foo'] = 'bar'
  ///
  ///  More docs: https://chromium.googlesource.com/infra/luci/recipes-py/+/HEAD/doc/old_user_guide.md#Setting-properties
  ///
  ///  V1 equivalent: corresponds to "properties" key in
  ///  "result_details_json".
  ///  In V1 output properties are not populated until build ends.
  @$pb.TagNumber(1)
  $5.Struct get properties => $_getN(0);
  @$pb.TagNumber(1)
  set properties($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasProperties() => $_has(0);
  @$pb.TagNumber(1)
  void clearProperties() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureProperties() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get summaryMarkdown => $_getSZ(1);
  @$pb.TagNumber(2)
  set summaryMarkdown($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSummaryMarkdown() => $_has(1);
  @$pb.TagNumber(2)
  void clearSummaryMarkdown() => clearField(2);

  ///  Build checked out and executed on this commit.
  ///
  ///  Should correspond to Build.Input.gitiles_commit.
  ///  May be present even if Build.Input.gitiles_commit is not set, for example
  ///  in cron builders.
  ///
  ///  V1 equivalent: this supersedes all got_revision output property.
  @$pb.TagNumber(3)
  $3.GitilesCommit get gitilesCommit => $_getN(2);
  @$pb.TagNumber(3)
  set gitilesCommit($3.GitilesCommit v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasGitilesCommit() => $_has(2);
  @$pb.TagNumber(3)
  void clearGitilesCommit() => clearField(3);
  @$pb.TagNumber(3)
  $3.GitilesCommit ensureGitilesCommit() => $_ensure(2);

  /// Logs produced by the build script, typically "stdout" and "stderr".
  @$pb.TagNumber(5)
  $core.List<$3.Log> get logs => $_getList(3);

  /// Build status which is reported by the client via StartBuild or UpdateBuild.
  @$pb.TagNumber(6)
  $3.Status get status => $_getN(4);
  @$pb.TagNumber(6)
  set status($3.Status v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(6)
  void clearStatus() => clearField(6);

  @$pb.TagNumber(7)
  $3.StatusDetails get statusDetails => $_getN(5);
  @$pb.TagNumber(7)
  set statusDetails($3.StatusDetails v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStatusDetails() => $_has(5);
  @$pb.TagNumber(7)
  void clearStatusDetails() => clearField(7);
  @$pb.TagNumber(7)
  $3.StatusDetails ensureStatusDetails() => $_ensure(5);

  /// Deprecated. Use summary_markdown instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  $core.String get summaryHtml => $_getSZ(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  set summaryHtml($core.String v) {
    $_setString(6, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  $core.bool hasSummaryHtml() => $_has(6);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(8)
  void clearSummaryHtml() => clearField(8);
}

///  Information of the builder, propagated from builder config.
///
///  The info captures the state of the builder at creation time.
///  If any information is updated, all future builds will have the new
///  information, while the historical builds persist the old information.
class Build_BuilderInfo extends $pb.GeneratedMessage {
  factory Build_BuilderInfo({
    $core.String? description,
  }) {
    final $result = create();
    if (description != null) {
      $result.description = description;
    }
    return $result;
  }
  Build_BuilderInfo._() : super();
  factory Build_BuilderInfo.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build_BuilderInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build.BuilderInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'description')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build_BuilderInfo clone() => Build_BuilderInfo()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build_BuilderInfo copyWith(void Function(Build_BuilderInfo) updates) =>
      super.copyWith((message) => updates(message as Build_BuilderInfo)) as Build_BuilderInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Build_BuilderInfo create() => Build_BuilderInfo._();
  Build_BuilderInfo createEmptyInstance() => create();
  static $pb.PbList<Build_BuilderInfo> createRepeated() => $pb.PbList<Build_BuilderInfo>();
  @$core.pragma('dart2js:noInline')
  static Build_BuilderInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build_BuilderInfo>(create);
  static Build_BuilderInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get description => $_getSZ(0);
  @$pb.TagNumber(1)
  set description($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDescription() => $_has(0);
  @$pb.TagNumber(1)
  void clearDescription() => clearField(1);
}

///  A single build, identified by an int64 ID.
///  Belongs to a builder.
///
///  RPC: see Builds service for build creation and retrieval.
///  Some Build fields are marked as excluded from responses by default.
///  Use "mask" request field to specify that a field must be included.
///
///  BigQuery: this message also defines schema of a BigQuery table of completed
///  builds. A BigQuery row is inserted soon after build ends, i.e. a row
///  represents a state of a build at completion time and does not change after
///  that. All fields are included.
///
///  Next id: 36.
class Build extends $pb.GeneratedMessage {
  factory Build({
    $fixnum.Int64? id,
    $0.BuilderID? builder,
    $core.int? number,
    $core.String? createdBy,
    $1.Timestamp? createTime,
    $1.Timestamp? startTime,
    $1.Timestamp? endTime,
    $1.Timestamp? updateTime,
    $3.Status? status,
    Build_Input? input,
    Build_Output? output,
    $core.Iterable<$2.Step>? steps,
    BuildInfra? infra,
    $core.Iterable<$3.StringPair>? tags,
    $core.String? summaryMarkdown,
    $3.Trinary? critical,
    $3.StatusDetails? statusDetails,
    $core.String? canceledBy,
    $3.Executable? exe,
    $core.bool? canary,
    $4.Duration? schedulingTimeout,
    $4.Duration? executionTimeout,
    $core.bool? waitForCapacity,
    $4.Duration? gracePeriod,
    $core.bool? canOutliveParent,
    $core.Iterable<$fixnum.Int64>? ancestorIds,
    $1.Timestamp? cancelTime,
    $core.String? cancellationMarkdown,
    Build_BuilderInfo? builderInfo,
    $3.Trinary? retriable,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (builder != null) {
      $result.builder = builder;
    }
    if (number != null) {
      $result.number = number;
    }
    if (createdBy != null) {
      $result.createdBy = createdBy;
    }
    if (createTime != null) {
      $result.createTime = createTime;
    }
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    if (updateTime != null) {
      $result.updateTime = updateTime;
    }
    if (status != null) {
      $result.status = status;
    }
    if (input != null) {
      $result.input = input;
    }
    if (output != null) {
      $result.output = output;
    }
    if (steps != null) {
      $result.steps.addAll(steps);
    }
    if (infra != null) {
      $result.infra = infra;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    if (critical != null) {
      $result.critical = critical;
    }
    if (statusDetails != null) {
      $result.statusDetails = statusDetails;
    }
    if (canceledBy != null) {
      $result.canceledBy = canceledBy;
    }
    if (exe != null) {
      $result.exe = exe;
    }
    if (canary != null) {
      $result.canary = canary;
    }
    if (schedulingTimeout != null) {
      $result.schedulingTimeout = schedulingTimeout;
    }
    if (executionTimeout != null) {
      $result.executionTimeout = executionTimeout;
    }
    if (waitForCapacity != null) {
      $result.waitForCapacity = waitForCapacity;
    }
    if (gracePeriod != null) {
      $result.gracePeriod = gracePeriod;
    }
    if (canOutliveParent != null) {
      $result.canOutliveParent = canOutliveParent;
    }
    if (ancestorIds != null) {
      $result.ancestorIds.addAll(ancestorIds);
    }
    if (cancelTime != null) {
      $result.cancelTime = cancelTime;
    }
    if (cancellationMarkdown != null) {
      $result.cancellationMarkdown = cancellationMarkdown;
    }
    if (builderInfo != null) {
      $result.builderInfo = builderInfo;
    }
    if (retriable != null) {
      $result.retriable = retriable;
    }
    return $result;
  }
  Build._() : super();
  factory Build.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Build.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Build',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..aOM<$0.BuilderID>(2, _omitFieldNames ? '' : 'builder', subBuilder: $0.BuilderID.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'number', $pb.PbFieldType.O3)
    ..aOS(4, _omitFieldNames ? '' : 'createdBy')
    ..aOM<$1.Timestamp>(6, _omitFieldNames ? '' : 'createTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(7, _omitFieldNames ? '' : 'startTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(8, _omitFieldNames ? '' : 'endTime', subBuilder: $1.Timestamp.create)
    ..aOM<$1.Timestamp>(9, _omitFieldNames ? '' : 'updateTime', subBuilder: $1.Timestamp.create)
    ..e<$3.Status>(12, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<Build_Input>(15, _omitFieldNames ? '' : 'input', subBuilder: Build_Input.create)
    ..aOM<Build_Output>(16, _omitFieldNames ? '' : 'output', subBuilder: Build_Output.create)
    ..pc<$2.Step>(17, _omitFieldNames ? '' : 'steps', $pb.PbFieldType.PM, subBuilder: $2.Step.create)
    ..aOM<BuildInfra>(18, _omitFieldNames ? '' : 'infra', subBuilder: BuildInfra.create)
    ..pc<$3.StringPair>(19, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..aOS(20, _omitFieldNames ? '' : 'summaryMarkdown')
    ..e<$3.Trinary>(21, _omitFieldNames ? '' : 'critical', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<$3.StatusDetails>(22, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(23, _omitFieldNames ? '' : 'canceledBy')
    ..aOM<$3.Executable>(24, _omitFieldNames ? '' : 'exe', subBuilder: $3.Executable.create)
    ..aOB(25, _omitFieldNames ? '' : 'canary')
    ..aOM<$4.Duration>(26, _omitFieldNames ? '' : 'schedulingTimeout', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(27, _omitFieldNames ? '' : 'executionTimeout', subBuilder: $4.Duration.create)
    ..aOB(28, _omitFieldNames ? '' : 'waitForCapacity')
    ..aOM<$4.Duration>(29, _omitFieldNames ? '' : 'gracePeriod', subBuilder: $4.Duration.create)
    ..aOB(30, _omitFieldNames ? '' : 'canOutliveParent')
    ..p<$fixnum.Int64>(31, _omitFieldNames ? '' : 'ancestorIds', $pb.PbFieldType.K6)
    ..aOM<$1.Timestamp>(32, _omitFieldNames ? '' : 'cancelTime', subBuilder: $1.Timestamp.create)
    ..aOS(33, _omitFieldNames ? '' : 'cancellationMarkdown')
    ..aOM<Build_BuilderInfo>(34, _omitFieldNames ? '' : 'builderInfo', subBuilder: Build_BuilderInfo.create)
    ..e<$3.Trinary>(35, _omitFieldNames ? '' : 'retriable', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Build clone() => Build()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Build copyWith(void Function(Build) updates) => super.copyWith((message) => updates(message as Build)) as Build;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Build create() => Build._();
  Build createEmptyInstance() => create();
  static $pb.PbList<Build> createRepeated() => $pb.PbList<Build>();
  @$core.pragma('dart2js:noInline')
  static Build getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Build>(create);
  static Build? _defaultInstance;

  /// Identifier of the build, unique per LUCI deployment.
  /// IDs are monotonically decreasing.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  ///  Required. The builder this build belongs to.
  ///
  ///  Tuple (builder.project, builder.bucket) defines build ACL
  ///  which may change after build has ended.
  @$pb.TagNumber(2)
  $0.BuilderID get builder => $_getN(1);
  @$pb.TagNumber(2)
  set builder($0.BuilderID v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasBuilder() => $_has(1);
  @$pb.TagNumber(2)
  void clearBuilder() => clearField(2);
  @$pb.TagNumber(2)
  $0.BuilderID ensureBuilder() => $_ensure(1);

  ///  Human-readable identifier of the build with the following properties:
  ///  - unique within the builder
  ///  - a monotonically increasing number
  ///  - mostly contiguous
  ///  - much shorter than id
  ///
  ///  Caution: populated (positive number) iff build numbers were enabled
  ///  in the builder configuration at the time of build creation.
  ///
  ///  Caution: Build numbers are not guaranteed to be contiguous.
  ///  There may be gaps during outages.
  ///
  ///  Caution: Build numbers, while monotonically increasing, do not
  ///  necessarily reflect source-code order. For example, force builds
  ///  or rebuilds can allocate new, higher, numbers, but build an older-
  ///  than-HEAD version of the source.
  @$pb.TagNumber(3)
  $core.int get number => $_getIZ(2);
  @$pb.TagNumber(3)
  set number($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasNumber() => $_has(2);
  @$pb.TagNumber(3)
  void clearNumber() => clearField(3);

  /// Verified LUCI identity that created this build.
  @$pb.TagNumber(4)
  $core.String get createdBy => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdBy($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasCreatedBy() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedBy() => clearField(4);

  /// When the build was created.
  @$pb.TagNumber(6)
  $1.Timestamp get createTime => $_getN(4);
  @$pb.TagNumber(6)
  set createTime($1.Timestamp v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCreateTime() => $_has(4);
  @$pb.TagNumber(6)
  void clearCreateTime() => clearField(6);
  @$pb.TagNumber(6)
  $1.Timestamp ensureCreateTime() => $_ensure(4);

  /// When the build started.
  /// Required iff status is STARTED, SUCCESS or FAILURE.
  @$pb.TagNumber(7)
  $1.Timestamp get startTime => $_getN(5);
  @$pb.TagNumber(7)
  set startTime($1.Timestamp v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasStartTime() => $_has(5);
  @$pb.TagNumber(7)
  void clearStartTime() => clearField(7);
  @$pb.TagNumber(7)
  $1.Timestamp ensureStartTime() => $_ensure(5);

  /// When the build ended.
  /// Present iff status is terminal.
  /// MUST NOT be before start_time.
  @$pb.TagNumber(8)
  $1.Timestamp get endTime => $_getN(6);
  @$pb.TagNumber(8)
  set endTime($1.Timestamp v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasEndTime() => $_has(6);
  @$pb.TagNumber(8)
  void clearEndTime() => clearField(8);
  @$pb.TagNumber(8)
  $1.Timestamp ensureEndTime() => $_ensure(6);

  ///  When the build was most recently updated.
  ///
  ///  RPC: can be > end_time if, e.g. new tags were attached to a completed
  ///  build.
  @$pb.TagNumber(9)
  $1.Timestamp get updateTime => $_getN(7);
  @$pb.TagNumber(9)
  set updateTime($1.Timestamp v) {
    setField(9, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasUpdateTime() => $_has(7);
  @$pb.TagNumber(9)
  void clearUpdateTime() => clearField(9);
  @$pb.TagNumber(9)
  $1.Timestamp ensureUpdateTime() => $_ensure(7);

  ///  Status of the build.
  ///  Must be specified, i.e. not STATUS_UNSPECIFIED.
  ///
  ///  RPC: Responses have most current status.
  ///
  ///  BigQuery: Final status of the build. Cannot be SCHEDULED or STARTED.
  @$pb.TagNumber(12)
  $3.Status get status => $_getN(8);
  @$pb.TagNumber(12)
  set status($3.Status v) {
    setField(12, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasStatus() => $_has(8);
  @$pb.TagNumber(12)
  void clearStatus() => clearField(12);

  /// Input to the build executable.
  @$pb.TagNumber(15)
  Build_Input get input => $_getN(9);
  @$pb.TagNumber(15)
  set input(Build_Input v) {
    setField(15, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasInput() => $_has(9);
  @$pb.TagNumber(15)
  void clearInput() => clearField(15);
  @$pb.TagNumber(15)
  Build_Input ensureInput() => $_ensure(9);

  ///  Output of the build executable.
  ///  SHOULD depend only on input field and NOT other fields.
  ///  MUST be unset if build status is SCHEDULED.
  ///
  ///  RPC: By default, this field is excluded from responses.
  ///  Updated while the build is running and finalized when the build ends.
  @$pb.TagNumber(16)
  Build_Output get output => $_getN(10);
  @$pb.TagNumber(16)
  set output(Build_Output v) {
    setField(16, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasOutput() => $_has(10);
  @$pb.TagNumber(16)
  void clearOutput() => clearField(16);
  @$pb.TagNumber(16)
  Build_Output ensureOutput() => $_ensure(10);

  ///  Current list of build steps.
  ///  Updated as build runs.
  ///
  ///  May take up to 1MB after zlib compression.
  ///  MUST be unset if build status is SCHEDULED.
  ///
  ///  RPC: By default, this field is excluded from responses.
  @$pb.TagNumber(17)
  $core.List<$2.Step> get steps => $_getList(11);

  ///  Build infrastructure used by the build.
  ///
  ///  RPC: By default, this field is excluded from responses.
  @$pb.TagNumber(18)
  BuildInfra get infra => $_getN(12);
  @$pb.TagNumber(18)
  set infra(BuildInfra v) {
    setField(18, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasInfra() => $_has(12);
  @$pb.TagNumber(18)
  void clearInfra() => clearField(18);
  @$pb.TagNumber(18)
  BuildInfra ensureInfra() => $_ensure(12);

  /// Arbitrary annotations for the build.
  /// One key may have multiple values, which is why this is not a map<string,string>.
  /// Indexed by the server, see also BuildPredicate.tags.
  @$pb.TagNumber(19)
  $core.List<$3.StringPair> get tags => $_getList(13);

  /// Human-readable summary of the build in Markdown format
  /// (https://spec.commonmark.org/0.28/).
  /// Explains status.
  /// Up to 4 KB.
  @$pb.TagNumber(20)
  $core.String get summaryMarkdown => $_getSZ(14);
  @$pb.TagNumber(20)
  set summaryMarkdown($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(20)
  $core.bool hasSummaryMarkdown() => $_has(14);
  @$pb.TagNumber(20)
  void clearSummaryMarkdown() => clearField(20);

  /// If NO, then the build status SHOULD NOT be used to assess correctness of
  /// the input gitiles_commit or gerrit_changes.
  /// For example, if a pre-submit build has failed, CQ MAY still land the CL.
  /// For example, if a post-submit build has failed, CLs MAY continue landing.
  @$pb.TagNumber(21)
  $3.Trinary get critical => $_getN(15);
  @$pb.TagNumber(21)
  set critical($3.Trinary v) {
    setField(21, v);
  }

  @$pb.TagNumber(21)
  $core.bool hasCritical() => $_has(15);
  @$pb.TagNumber(21)
  void clearCritical() => clearField(21);

  /// Machine-readable details of the current status.
  /// Human-readable status reason is available in summary_markdown.
  @$pb.TagNumber(22)
  $3.StatusDetails get statusDetails => $_getN(16);
  @$pb.TagNumber(22)
  set statusDetails($3.StatusDetails v) {
    setField(22, v);
  }

  @$pb.TagNumber(22)
  $core.bool hasStatusDetails() => $_has(16);
  @$pb.TagNumber(22)
  void clearStatusDetails() => clearField(22);
  @$pb.TagNumber(22)
  $3.StatusDetails ensureStatusDetails() => $_ensure(16);

  ///  Verified LUCI identity that canceled this build.
  ///
  ///  Special values:
  ///  * buildbucket: The build is canceled by buildbucket. This can happen if the
  ///  build's parent has ended, and the build cannot outlive its parent.
  ///  * backend: The build's backend task is canceled. For example the build's
  ///  Swarming task is killed.
  @$pb.TagNumber(23)
  $core.String get canceledBy => $_getSZ(17);
  @$pb.TagNumber(23)
  set canceledBy($core.String v) {
    $_setString(17, v);
  }

  @$pb.TagNumber(23)
  $core.bool hasCanceledBy() => $_has(17);
  @$pb.TagNumber(23)
  void clearCanceledBy() => clearField(23);

  /// What to run when the build is ready to start.
  @$pb.TagNumber(24)
  $3.Executable get exe => $_getN(18);
  @$pb.TagNumber(24)
  set exe($3.Executable v) {
    setField(24, v);
  }

  @$pb.TagNumber(24)
  $core.bool hasExe() => $_has(18);
  @$pb.TagNumber(24)
  void clearExe() => clearField(24);
  @$pb.TagNumber(24)
  $3.Executable ensureExe() => $_ensure(18);

  ///  DEPRECATED
  ///
  ///  Equivalent to `"luci.buildbucket.canary_software" in input.experiments`.
  ///
  ///  See `Builder.experiments` for well-known experiments.
  @$pb.TagNumber(25)
  $core.bool get canary => $_getBF(19);
  @$pb.TagNumber(25)
  set canary($core.bool v) {
    $_setBool(19, v);
  }

  @$pb.TagNumber(25)
  $core.bool hasCanary() => $_has(19);
  @$pb.TagNumber(25)
  void clearCanary() => clearField(25);

  /// Maximum build pending time.
  /// If the timeout is reached, the build is marked as INFRA_FAILURE status
  /// and both status_details.{timeout, resource_exhaustion} are set.
  @$pb.TagNumber(26)
  $4.Duration get schedulingTimeout => $_getN(20);
  @$pb.TagNumber(26)
  set schedulingTimeout($4.Duration v) {
    setField(26, v);
  }

  @$pb.TagNumber(26)
  $core.bool hasSchedulingTimeout() => $_has(20);
  @$pb.TagNumber(26)
  void clearSchedulingTimeout() => clearField(26);
  @$pb.TagNumber(26)
  $4.Duration ensureSchedulingTimeout() => $_ensure(20);

  ///  Maximum build execution time.
  ///
  ///  Not to be confused with scheduling_timeout.
  ///
  ///  If the timeout is reached, the task will be signaled according to the
  ///  `deadline` section of
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/client/LUCI_CONTEXT.md
  ///  and status_details.timeout is set.
  ///
  ///  The task will have `grace_period` amount of time to handle cleanup
  ///  before being forcefully terminated.
  @$pb.TagNumber(27)
  $4.Duration get executionTimeout => $_getN(21);
  @$pb.TagNumber(27)
  set executionTimeout($4.Duration v) {
    setField(27, v);
  }

  @$pb.TagNumber(27)
  $core.bool hasExecutionTimeout() => $_has(21);
  @$pb.TagNumber(27)
  void clearExecutionTimeout() => clearField(27);
  @$pb.TagNumber(27)
  $4.Duration ensureExecutionTimeout() => $_ensure(21);

  /// If set, swarming was requested to wait until it sees at least one bot
  /// report a superset of the build's requested dimensions.
  @$pb.TagNumber(28)
  $core.bool get waitForCapacity => $_getBF(22);
  @$pb.TagNumber(28)
  set waitForCapacity($core.bool v) {
    $_setBool(22, v);
  }

  @$pb.TagNumber(28)
  $core.bool hasWaitForCapacity() => $_has(22);
  @$pb.TagNumber(28)
  void clearWaitForCapacity() => clearField(28);

  ///  Amount of cleanup time after execution_timeout.
  ///
  ///  After being signaled according to execution_timeout, the task will
  ///  have this duration to clean up before being forcefully terminated.
  ///
  ///  The signalling process is explained in the `deadline` section of
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/client/LUCI_CONTEXT.md.
  @$pb.TagNumber(29)
  $4.Duration get gracePeriod => $_getN(23);
  @$pb.TagNumber(29)
  set gracePeriod($4.Duration v) {
    setField(29, v);
  }

  @$pb.TagNumber(29)
  $core.bool hasGracePeriod() => $_has(23);
  @$pb.TagNumber(29)
  void clearGracePeriod() => clearField(29);
  @$pb.TagNumber(29)
  $4.Duration ensureGracePeriod() => $_ensure(23);

  ///  Flag to control if the build can outlive its parent.
  ///
  ///  This field is only meaningful if the build has ancestors.
  ///  If the build has ancestors and the value is false, it means that the build
  ///  SHOULD reach a terminal status (SUCCESS, FAILURE, INFRA_FAILURE or
  ///  CANCELED) before its parent. If the child fails to do so, Buildbucket will
  ///  cancel it some time after the parent build reaches a terminal status.
  ///
  ///  A build that can outlive its parent can also outlive its parent's ancestors.
  @$pb.TagNumber(30)
  $core.bool get canOutliveParent => $_getBF(24);
  @$pb.TagNumber(30)
  set canOutliveParent($core.bool v) {
    $_setBool(24, v);
  }

  @$pb.TagNumber(30)
  $core.bool hasCanOutliveParent() => $_has(24);
  @$pb.TagNumber(30)
  void clearCanOutliveParent() => clearField(30);

  /// IDs of the build's ancestors. This includes all parents/grandparents/etc.
  /// This is ordered from top-to-bottom so `ancestor_ids[0]` is the root of
  /// the builds tree, and `ancestor_ids[-1]` is this build's immediate parent.
  /// This does not include any "siblings" at higher levels of the tree, just
  /// the direct chain of ancestors from root to this build.
  @$pb.TagNumber(31)
  $core.List<$fixnum.Int64> get ancestorIds => $_getList(25);

  ///  When the cancel process of the build started.
  ///  Note it's not the time that the cancellation completed, which would be
  ///  tracked by end_time.
  ///
  ///  During the cancel process, the build still accepts updates.
  ///
  ///  bbagent checks this field at the frequency of
  ///  buildbucket.MinUpdateBuildInterval. When bbagent sees the build is in
  ///  cancel process, there are two states:
  ///   * it has NOT yet started the exe payload,
  ///   * it HAS started the exe payload.
  ///
  ///  In the first state, bbagent will immediately terminate the build without
  ///  invoking the exe payload at all.
  ///
  ///  In the second state, bbagent will send SIGTERM/CTRL-BREAK to the exe
  ///  (according to the deadline protocol described in
  ///  https://chromium.googlesource.com/infra/luci/luci-py/+/HEAD/client/LUCI_CONTEXT.md).
  ///  After grace_period it will then try to kill the exe.
  ///
  ///  NOTE: There is a race condition here; If bbagent starts the luciexe and
  ///  then immediately notices that the build is canceled, it's possible that
  ///  bbagent can send SIGTERM/CTRL-BREAK to the exe before that exe sets up
  ///  interrupt handlers. There is a bug on file (crbug.com/1311821)
  ///  which we plan to implement at some point as a mitigation for this.
  ///
  ///  Additionally, the Buildbucket service itself will launch an asynchronous
  ///  task to terminate the build via the backend API (e.g. Swarming cancellation)
  ///  if bbagent cannot successfully terminate the exe in time.
  @$pb.TagNumber(32)
  $1.Timestamp get cancelTime => $_getN(26);
  @$pb.TagNumber(32)
  set cancelTime($1.Timestamp v) {
    setField(32, v);
  }

  @$pb.TagNumber(32)
  $core.bool hasCancelTime() => $_has(26);
  @$pb.TagNumber(32)
  void clearCancelTime() => clearField(32);
  @$pb.TagNumber(32)
  $1.Timestamp ensureCancelTime() => $_ensure(26);

  /// Markdown reasoning for cancelling the build.
  /// Human readable and should be following https://spec.commonmark.org/0.28/.
  @$pb.TagNumber(33)
  $core.String get cancellationMarkdown => $_getSZ(27);
  @$pb.TagNumber(33)
  set cancellationMarkdown($core.String v) {
    $_setString(27, v);
  }

  @$pb.TagNumber(33)
  $core.bool hasCancellationMarkdown() => $_has(27);
  @$pb.TagNumber(33)
  void clearCancellationMarkdown() => clearField(33);

  @$pb.TagNumber(34)
  Build_BuilderInfo get builderInfo => $_getN(28);
  @$pb.TagNumber(34)
  set builderInfo(Build_BuilderInfo v) {
    setField(34, v);
  }

  @$pb.TagNumber(34)
  $core.bool hasBuilderInfo() => $_has(28);
  @$pb.TagNumber(34)
  void clearBuilderInfo() => clearField(34);
  @$pb.TagNumber(34)
  Build_BuilderInfo ensureBuilderInfo() => $_ensure(28);

  /// If UNSET, retrying the build is implicitly allowed;
  /// If YES, retrying the build is explicitly allowed;
  /// If NO, retrying the build is explicitly disallowed,
  ///   * any UI displaying the build should remove "retry" button(s),
  ///   * ScheduleBuild using the build as template should fail,
  ///   * but the build can still be synthesized by SynthesizeBuild.
  @$pb.TagNumber(35)
  $3.Trinary get retriable => $_getN(29);
  @$pb.TagNumber(35)
  set retriable($3.Trinary v) {
    setField(35, v);
  }

  @$pb.TagNumber(35)
  $core.bool hasRetriable() => $_has(29);
  @$pb.TagNumber(35)
  void clearRetriable() => clearField(35);
}

/// This is a [Digest][build.bazel.remote.execution.v2.Digest] of a blob on
/// RBE-CAS. See the explanations at the original definition.
/// https://github.com/bazelbuild/remote-apis/blob/77cfb44a88577a7ade5dd2400425f6d50469ec6d/build/bazel/remote/execution/v2/remote_execution.proto#L753-L791
class InputDataRef_CAS_Digest extends $pb.GeneratedMessage {
  factory InputDataRef_CAS_Digest({
    $core.String? hash,
    $fixnum.Int64? sizeBytes,
  }) {
    final $result = create();
    if (hash != null) {
      $result.hash = hash;
    }
    if (sizeBytes != null) {
      $result.sizeBytes = sizeBytes;
    }
    return $result;
  }
  InputDataRef_CAS_Digest._() : super();
  factory InputDataRef_CAS_Digest.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS_Digest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CAS.Digest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hash')
    ..aInt64(2, _omitFieldNames ? '' : 'sizeBytes')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS_Digest clone() => InputDataRef_CAS_Digest()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS_Digest copyWith(void Function(InputDataRef_CAS_Digest) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CAS_Digest)) as InputDataRef_CAS_Digest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest create() => InputDataRef_CAS_Digest._();
  InputDataRef_CAS_Digest createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS_Digest> createRepeated() => $pb.PbList<InputDataRef_CAS_Digest>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS_Digest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS_Digest>(create);
  static InputDataRef_CAS_Digest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get hash => $_getSZ(0);
  @$pb.TagNumber(1)
  set hash($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHash() => $_has(0);
  @$pb.TagNumber(1)
  void clearHash() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get sizeBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set sizeBytes($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSizeBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearSizeBytes() => clearField(2);
}

class InputDataRef_CAS extends $pb.GeneratedMessage {
  factory InputDataRef_CAS({
    $core.String? casInstance,
    InputDataRef_CAS_Digest? digest,
  }) {
    final $result = create();
    if (casInstance != null) {
      $result.casInstance = casInstance;
    }
    if (digest != null) {
      $result.digest = digest;
    }
    return $result;
  }
  InputDataRef_CAS._() : super();
  factory InputDataRef_CAS.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CAS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'casInstance')
    ..aOM<InputDataRef_CAS_Digest>(2, _omitFieldNames ? '' : 'digest', subBuilder: InputDataRef_CAS_Digest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS clone() => InputDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CAS copyWith(void Function(InputDataRef_CAS) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CAS)) as InputDataRef_CAS;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS create() => InputDataRef_CAS._();
  InputDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CAS> createRepeated() => $pb.PbList<InputDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CAS getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CAS>(create);
  static InputDataRef_CAS? _defaultInstance;

  /// Full name of RBE-CAS instance. `projects/{project_id}/instances/{instance}`.
  /// e.g. projects/chromium-swarm/instances/default_instance
  @$pb.TagNumber(1)
  $core.String get casInstance => $_getSZ(0);
  @$pb.TagNumber(1)
  set casInstance($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCasInstance() => $_has(0);
  @$pb.TagNumber(1)
  void clearCasInstance() => clearField(1);

  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest get digest => $_getN(1);
  @$pb.TagNumber(2)
  set digest(InputDataRef_CAS_Digest v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasDigest() => $_has(1);
  @$pb.TagNumber(2)
  void clearDigest() => clearField(2);
  @$pb.TagNumber(2)
  InputDataRef_CAS_Digest ensureDigest() => $_ensure(1);
}

class InputDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  factory InputDataRef_CIPD_PkgSpec({
    $core.String? package,
    $core.String? version,
  }) {
    final $result = create();
    if (package != null) {
      $result.package = package;
    }
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  InputDataRef_CIPD_PkgSpec._() : super();
  factory InputDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD_PkgSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CIPD.PkgSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec clone() => InputDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD_PkgSpec copyWith(void Function(InputDataRef_CIPD_PkgSpec) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CIPD_PkgSpec)) as InputDataRef_CIPD_PkgSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec create() => InputDataRef_CIPD_PkgSpec._();
  InputDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<InputDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD_PkgSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD_PkgSpec>(create);
  static InputDataRef_CIPD_PkgSpec? _defaultInstance;

  /// Package MAY include CIPD variables, including conditional variables like
  /// `${os=windows}`. Additionally, version may be a ref or a tag.
  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);
}

class InputDataRef_CIPD extends $pb.GeneratedMessage {
  factory InputDataRef_CIPD({
    $core.String? server,
    $core.Iterable<InputDataRef_CIPD_PkgSpec>? specs,
  }) {
    final $result = create();
    if (server != null) {
      $result.server = server;
    }
    if (specs != null) {
      $result.specs.addAll(specs);
    }
    return $result;
  }
  InputDataRef_CIPD._() : super();
  factory InputDataRef_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'server')
    ..pc<InputDataRef_CIPD_PkgSpec>(2, _omitFieldNames ? '' : 'specs', $pb.PbFieldType.PM,
        subBuilder: InputDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD clone() => InputDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef_CIPD copyWith(void Function(InputDataRef_CIPD) updates) =>
      super.copyWith((message) => updates(message as InputDataRef_CIPD)) as InputDataRef_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD create() => InputDataRef_CIPD._();
  InputDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<InputDataRef_CIPD> createRepeated() => $pb.PbList<InputDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef_CIPD>(create);
  static InputDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get server => $_getSZ(0);
  @$pb.TagNumber(1)
  set server($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<InputDataRef_CIPD_PkgSpec> get specs => $_getList(1);
}

enum InputDataRef_DataType { cas, cipd, notSet }

class InputDataRef extends $pb.GeneratedMessage {
  factory InputDataRef({
    InputDataRef_CAS? cas,
    InputDataRef_CIPD? cipd,
    $core.Iterable<$core.String>? onPath,
  }) {
    final $result = create();
    if (cas != null) {
      $result.cas = cas;
    }
    if (cipd != null) {
      $result.cipd = cipd;
    }
    if (onPath != null) {
      $result.onPath.addAll(onPath);
    }
    return $result;
  }
  InputDataRef._() : super();
  factory InputDataRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory InputDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, InputDataRef_DataType> _InputDataRef_DataTypeByTag = {
    1: InputDataRef_DataType.cas,
    2: InputDataRef_DataType.cipd,
    0: InputDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'InputDataRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<InputDataRef_CAS>(1, _omitFieldNames ? '' : 'cas', subBuilder: InputDataRef_CAS.create)
    ..aOM<InputDataRef_CIPD>(2, _omitFieldNames ? '' : 'cipd', subBuilder: InputDataRef_CIPD.create)
    ..pPS(3, _omitFieldNames ? '' : 'onPath')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  InputDataRef clone() => InputDataRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  InputDataRef copyWith(void Function(InputDataRef) updates) =>
      super.copyWith((message) => updates(message as InputDataRef)) as InputDataRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static InputDataRef create() => InputDataRef._();
  InputDataRef createEmptyInstance() => create();
  static $pb.PbList<InputDataRef> createRepeated() => $pb.PbList<InputDataRef>();
  @$core.pragma('dart2js:noInline')
  static InputDataRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<InputDataRef>(create);
  static InputDataRef? _defaultInstance;

  InputDataRef_DataType whichDataType() => _InputDataRef_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  InputDataRef_CAS get cas => $_getN(0);
  @$pb.TagNumber(1)
  set cas(InputDataRef_CAS v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  InputDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  InputDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(InputDataRef_CIPD v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCipd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipd() => clearField(2);
  @$pb.TagNumber(2)
  InputDataRef_CIPD ensureCipd() => $_ensure(1);

  ///  TODO(crbug.com/1266060): TBD. `on_path` may need to move out to be incorporated into a field which captures other envvars.
  ///  Subdirectories relative to the root of `ref` which should be set as a prefix to
  ///  the $PATH variable.
  ///
  ///  A substitute of `env_prefixes` in SwarmingRpcsTaskProperties field -
  ///  https://chromium.googlesource.com/infra/luci/luci-go/+/0048a84944e872776fba3542aa96d5943ae64bab/common/api/swarming/swarming/v1/swarming-gen.go#1495
  @$pb.TagNumber(3)
  $core.List<$core.String> get onPath => $_getList(2);
}

class ResolvedDataRef_Timing extends $pb.GeneratedMessage {
  factory ResolvedDataRef_Timing({
    $4.Duration? fetchDuration,
    $4.Duration? installDuration,
  }) {
    final $result = create();
    if (fetchDuration != null) {
      $result.fetchDuration = fetchDuration;
    }
    if (installDuration != null) {
      $result.installDuration = installDuration;
    }
    return $result;
  }
  ResolvedDataRef_Timing._() : super();
  factory ResolvedDataRef_Timing.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_Timing.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.Timing',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$4.Duration>(1, _omitFieldNames ? '' : 'fetchDuration', subBuilder: $4.Duration.create)
    ..aOM<$4.Duration>(2, _omitFieldNames ? '' : 'installDuration', subBuilder: $4.Duration.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_Timing clone() => ResolvedDataRef_Timing()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_Timing copyWith(void Function(ResolvedDataRef_Timing) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_Timing)) as ResolvedDataRef_Timing;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing create() => ResolvedDataRef_Timing._();
  ResolvedDataRef_Timing createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_Timing> createRepeated() => $pb.PbList<ResolvedDataRef_Timing>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_Timing getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_Timing>(create);
  static ResolvedDataRef_Timing? _defaultInstance;

  @$pb.TagNumber(1)
  $4.Duration get fetchDuration => $_getN(0);
  @$pb.TagNumber(1)
  set fetchDuration($4.Duration v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFetchDuration() => $_has(0);
  @$pb.TagNumber(1)
  void clearFetchDuration() => clearField(1);
  @$pb.TagNumber(1)
  $4.Duration ensureFetchDuration() => $_ensure(0);

  @$pb.TagNumber(2)
  $4.Duration get installDuration => $_getN(1);
  @$pb.TagNumber(2)
  set installDuration($4.Duration v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInstallDuration() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstallDuration() => clearField(2);
  @$pb.TagNumber(2)
  $4.Duration ensureInstallDuration() => $_ensure(1);
}

class ResolvedDataRef_CAS extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CAS({
    ResolvedDataRef_Timing? timing,
  }) {
    final $result = create();
    if (timing != null) {
      $result.timing = timing;
    }
    return $result;
  }
  ResolvedDataRef_CAS._() : super();
  factory ResolvedDataRef_CAS.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CAS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CAS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<ResolvedDataRef_Timing>(1, _omitFieldNames ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CAS clone() => ResolvedDataRef_CAS()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CAS copyWith(void Function(ResolvedDataRef_CAS) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CAS)) as ResolvedDataRef_CAS;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS create() => ResolvedDataRef_CAS._();
  ResolvedDataRef_CAS createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CAS> createRepeated() => $pb.PbList<ResolvedDataRef_CAS>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CAS getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CAS>(create);
  static ResolvedDataRef_CAS? _defaultInstance;

  /// TODO(crbug.com/1266060): potential fields can be
  /// int64 cache_hits = ?;
  /// int64 cache_hit_size = ?:
  /// int64 cache_misses = ?;
  /// int64 cache_miss_size = ?;
  /// need more thinking and better to determine when starting writing code
  /// to download binaries in bbagent.
  @$pb.TagNumber(1)
  ResolvedDataRef_Timing get timing => $_getN(0);
  @$pb.TagNumber(1)
  set timing(ResolvedDataRef_Timing v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasTiming() => $_has(0);
  @$pb.TagNumber(1)
  void clearTiming() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(0);
}

class ResolvedDataRef_CIPD_PkgSpec extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CIPD_PkgSpec({
    $core.bool? skipped,
    $core.String? package,
    $core.String? version,
    $3.Trinary? wasCached,
    ResolvedDataRef_Timing? timing,
  }) {
    final $result = create();
    if (skipped != null) {
      $result.skipped = skipped;
    }
    if (package != null) {
      $result.package = package;
    }
    if (version != null) {
      $result.version = version;
    }
    if (wasCached != null) {
      $result.wasCached = wasCached;
    }
    if (timing != null) {
      $result.timing = timing;
    }
    return $result;
  }
  ResolvedDataRef_CIPD_PkgSpec._() : super();
  factory ResolvedDataRef_CIPD_PkgSpec.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD_PkgSpec.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CIPD.PkgSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'skipped')
    ..aOS(2, _omitFieldNames ? '' : 'package')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..e<$3.Trinary>(4, _omitFieldNames ? '' : 'wasCached', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Trinary.UNSET, valueOf: $3.Trinary.valueOf, enumValues: $3.Trinary.values)
    ..aOM<ResolvedDataRef_Timing>(5, _omitFieldNames ? '' : 'timing', subBuilder: ResolvedDataRef_Timing.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec clone() => ResolvedDataRef_CIPD_PkgSpec()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD_PkgSpec copyWith(void Function(ResolvedDataRef_CIPD_PkgSpec) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CIPD_PkgSpec)) as ResolvedDataRef_CIPD_PkgSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec create() => ResolvedDataRef_CIPD_PkgSpec._();
  ResolvedDataRef_CIPD_PkgSpec createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD_PkgSpec> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD_PkgSpec>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD_PkgSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD_PkgSpec>(create);
  static ResolvedDataRef_CIPD_PkgSpec? _defaultInstance;

  /// True if this package wasn't installed because `package` contained a
  /// non-applicable conditional (e.g. ${os=windows} on a mac machine).
  @$pb.TagNumber(1)
  $core.bool get skipped => $_getBF(0);
  @$pb.TagNumber(1)
  set skipped($core.bool v) {
    $_setBool(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSkipped() => $_has(0);
  @$pb.TagNumber(1)
  void clearSkipped() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get package => $_getSZ(1);
  @$pb.TagNumber(2)
  set package($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasPackage() => $_has(1);
  @$pb.TagNumber(2)
  void clearPackage() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);

  @$pb.TagNumber(4)
  $3.Trinary get wasCached => $_getN(3);
  @$pb.TagNumber(4)
  set wasCached($3.Trinary v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasWasCached() => $_has(3);
  @$pb.TagNumber(4)
  void clearWasCached() => clearField(4);

  @$pb.TagNumber(5)
  ResolvedDataRef_Timing get timing => $_getN(4);
  @$pb.TagNumber(5)
  set timing(ResolvedDataRef_Timing v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTiming() => $_has(4);
  @$pb.TagNumber(5)
  void clearTiming() => clearField(5);
  @$pb.TagNumber(5)
  ResolvedDataRef_Timing ensureTiming() => $_ensure(4);
}

class ResolvedDataRef_CIPD extends $pb.GeneratedMessage {
  factory ResolvedDataRef_CIPD({
    $core.Iterable<ResolvedDataRef_CIPD_PkgSpec>? specs,
  }) {
    final $result = create();
    if (specs != null) {
      $result.specs.addAll(specs);
    }
    return $result;
  }
  ResolvedDataRef_CIPD._() : super();
  factory ResolvedDataRef_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef_CIPD.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<ResolvedDataRef_CIPD_PkgSpec>(2, _omitFieldNames ? '' : 'specs', $pb.PbFieldType.PM,
        subBuilder: ResolvedDataRef_CIPD_PkgSpec.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD clone() => ResolvedDataRef_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef_CIPD copyWith(void Function(ResolvedDataRef_CIPD) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef_CIPD)) as ResolvedDataRef_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD create() => ResolvedDataRef_CIPD._();
  ResolvedDataRef_CIPD createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef_CIPD> createRepeated() => $pb.PbList<ResolvedDataRef_CIPD>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef_CIPD>(create);
  static ResolvedDataRef_CIPD? _defaultInstance;

  @$pb.TagNumber(2)
  $core.List<ResolvedDataRef_CIPD_PkgSpec> get specs => $_getList(0);
}

enum ResolvedDataRef_DataType { cas, cipd, notSet }

class ResolvedDataRef extends $pb.GeneratedMessage {
  factory ResolvedDataRef({
    ResolvedDataRef_CAS? cas,
    ResolvedDataRef_CIPD? cipd,
  }) {
    final $result = create();
    if (cas != null) {
      $result.cas = cas;
    }
    if (cipd != null) {
      $result.cipd = cipd;
    }
    return $result;
  }
  ResolvedDataRef._() : super();
  factory ResolvedDataRef.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory ResolvedDataRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ResolvedDataRef_DataType> _ResolvedDataRef_DataTypeByTag = {
    1: ResolvedDataRef_DataType.cas,
    2: ResolvedDataRef_DataType.cipd,
    0: ResolvedDataRef_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ResolvedDataRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<ResolvedDataRef_CAS>(1, _omitFieldNames ? '' : 'cas', subBuilder: ResolvedDataRef_CAS.create)
    ..aOM<ResolvedDataRef_CIPD>(2, _omitFieldNames ? '' : 'cipd', subBuilder: ResolvedDataRef_CIPD.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  ResolvedDataRef clone() => ResolvedDataRef()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  ResolvedDataRef copyWith(void Function(ResolvedDataRef) updates) =>
      super.copyWith((message) => updates(message as ResolvedDataRef)) as ResolvedDataRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef create() => ResolvedDataRef._();
  ResolvedDataRef createEmptyInstance() => create();
  static $pb.PbList<ResolvedDataRef> createRepeated() => $pb.PbList<ResolvedDataRef>();
  @$core.pragma('dart2js:noInline')
  static ResolvedDataRef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ResolvedDataRef>(create);
  static ResolvedDataRef? _defaultInstance;

  ResolvedDataRef_DataType whichDataType() => _ResolvedDataRef_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ResolvedDataRef_CAS get cas => $_getN(0);
  @$pb.TagNumber(1)
  set cas(ResolvedDataRef_CAS v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCas() => $_has(0);
  @$pb.TagNumber(1)
  void clearCas() => clearField(1);
  @$pb.TagNumber(1)
  ResolvedDataRef_CAS ensureCas() => $_ensure(0);

  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD get cipd => $_getN(1);
  @$pb.TagNumber(2)
  set cipd(ResolvedDataRef_CIPD v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCipd() => $_has(1);
  @$pb.TagNumber(2)
  void clearCipd() => clearField(2);
  @$pb.TagNumber(2)
  ResolvedDataRef_CIPD ensureCipd() => $_ensure(1);
}

class BuildInfra_Buildbucket_Agent_Source_CIPD extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Source_CIPD({
    $core.String? package,
    $core.String? version,
    $core.String? server,
    $core.Map<$core.String, $core.String>? resolvedInstances,
  }) {
    final $result = create();
    if (package != null) {
      $result.package = package;
    }
    if (version != null) {
      $result.version = version;
    }
    if (server != null) {
      $result.server = server;
    }
    if (resolvedInstances != null) {
      $result.resolvedInstances.addAll(resolvedInstances);
    }
    return $result;
  }
  BuildInfra_Buildbucket_Agent_Source_CIPD._() : super();
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source_CIPD.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Source.CIPD',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'package')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'server')
    ..m<$core.String, $core.String>(4, _omitFieldNames ? '' : 'resolvedInstances',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Source.CIPD.ResolvedInstancesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD clone() =>
      BuildInfra_Buildbucket_Agent_Source_CIPD()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source_CIPD copyWith(void Function(BuildInfra_Buildbucket_Agent_Source_CIPD) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source_CIPD))
          as BuildInfra_Buildbucket_Agent_Source_CIPD;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD create() => BuildInfra_Buildbucket_Agent_Source_CIPD._();
  BuildInfra_Buildbucket_Agent_Source_CIPD createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Source_CIPD>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source_CIPD getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source_CIPD>(create);
  static BuildInfra_Buildbucket_Agent_Source_CIPD? _defaultInstance;

  ///  The CIPD package to use for the agent.
  ///
  ///  Must end in "/${platform}" with no other CIPD variables.
  ///
  ///  If using an experimental agent binary, please make sure the package
  ///  prefix has been configured here -
  ///  https://chrome-internal.googlesource.com/infradata/config/+/refs/heads/main/configs/chrome-infra-packages/bootstrap.cfg
  @$pb.TagNumber(1)
  $core.String get package => $_getSZ(0);
  @$pb.TagNumber(1)
  set package($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPackage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPackage() => clearField(1);

  /// The CIPD version to use for the agent.
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  /// The CIPD server to use.
  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  ///  maps ${platform} -> instance_id for resolved agent packages.
  ///
  ///  Will be overwritten at CreateBuild time, should be left empty
  ///  when creating a new Build.
  @$pb.TagNumber(4)
  $core.Map<$core.String, $core.String> get resolvedInstances => $_getMap(3);
}

enum BuildInfra_Buildbucket_Agent_Source_DataType { cipd, notSet }

/// Source describes where the Agent should be fetched from.
class BuildInfra_Buildbucket_Agent_Source extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Source({
    BuildInfra_Buildbucket_Agent_Source_CIPD? cipd,
  }) {
    final $result = create();
    if (cipd != null) {
      $result.cipd = cipd;
    }
    return $result;
  }
  BuildInfra_Buildbucket_Agent_Source._() : super();
  factory BuildInfra_Buildbucket_Agent_Source.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Source.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, BuildInfra_Buildbucket_Agent_Source_DataType>
      _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag = {
    1: BuildInfra_Buildbucket_Agent_Source_DataType.cipd,
    0: BuildInfra_Buildbucket_Agent_Source_DataType.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Source',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<BuildInfra_Buildbucket_Agent_Source_CIPD>(1, _omitFieldNames ? '' : 'cipd',
        subBuilder: BuildInfra_Buildbucket_Agent_Source_CIPD.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source clone() => BuildInfra_Buildbucket_Agent_Source()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Source copyWith(void Function(BuildInfra_Buildbucket_Agent_Source) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Source))
          as BuildInfra_Buildbucket_Agent_Source;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source create() => BuildInfra_Buildbucket_Agent_Source._();
  BuildInfra_Buildbucket_Agent_Source createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Source> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Source>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Source getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Source>(create);
  static BuildInfra_Buildbucket_Agent_Source? _defaultInstance;

  BuildInfra_Buildbucket_Agent_Source_DataType whichDataType() =>
      _BuildInfra_Buildbucket_Agent_Source_DataTypeByTag[$_whichOneof(0)]!;
  void clearDataType() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD get cipd => $_getN(0);
  @$pb.TagNumber(1)
  set cipd(BuildInfra_Buildbucket_Agent_Source_CIPD v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasCipd() => $_has(0);
  @$pb.TagNumber(1)
  void clearCipd() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Source_CIPD ensureCipd() => $_ensure(0);
}

class BuildInfra_Buildbucket_Agent_Input extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Input({
    $core.Map<$core.String, InputDataRef>? data,
    $core.Map<$core.String, InputDataRef>? cipdSource,
  }) {
    final $result = create();
    if (data != null) {
      $result.data.addAll(data);
    }
    if (cipdSource != null) {
      $result.cipdSource.addAll(cipdSource);
    }
    return $result;
  }
  BuildInfra_Buildbucket_Agent_Input._() : super();
  factory BuildInfra_Buildbucket_Agent_Input.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Input.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, InputDataRef>(1, _omitFieldNames ? '' : 'data',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Input.DataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: InputDataRef.create,
        valueDefaultOrMaker: InputDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, InputDataRef>(2, _omitFieldNames ? '' : 'cipdSource',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Input.CipdSourceEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: InputDataRef.create,
        valueDefaultOrMaker: InputDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input clone() => BuildInfra_Buildbucket_Agent_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Input copyWith(void Function(BuildInfra_Buildbucket_Agent_Input) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Input))
          as BuildInfra_Buildbucket_Agent_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input create() => BuildInfra_Buildbucket_Agent_Input._();
  BuildInfra_Buildbucket_Agent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Input> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Input getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Input>(create);
  static BuildInfra_Buildbucket_Agent_Input? _defaultInstance;

  ///  Maps relative-to-root directory to the data.
  ///
  ///  For now, data is only allowed at the 'leaves', e.g. you cannot
  ///  specify data at "a/b/c" and "a/b" (but "a/b/c" and "a/q" would be OK).
  ///  All directories beginning with "luci." are reserved for Buildbucket's own use.
  ///
  ///  TODO(crbug.com/1266060): Enforce the above constraints in a later phase.
  ///  Currently users don't have the flexibility to set the parent directory path.
  @$pb.TagNumber(1)
  $core.Map<$core.String, InputDataRef> get data => $_getMap(0);

  /// Maps relative-to-root directory to the cipd package itself.
  /// This is the CIPD client itself and  should be downloaded first so that
  /// the packages in the data field above can be downloaded.
  @$pb.TagNumber(2)
  $core.Map<$core.String, InputDataRef> get cipdSource => $_getMap(1);
}

class BuildInfra_Buildbucket_Agent_Output extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent_Output({
    $core.Map<$core.String, ResolvedDataRef>? resolvedData,
    $3.Status? status,
    $3.StatusDetails? statusDetails,
    @$core.Deprecated('This field is deprecated.') $core.String? summaryHtml,
    $core.String? agentPlatform,
    $4.Duration? totalDuration,
    $core.String? summaryMarkdown,
  }) {
    final $result = create();
    if (resolvedData != null) {
      $result.resolvedData.addAll(resolvedData);
    }
    if (status != null) {
      $result.status = status;
    }
    if (statusDetails != null) {
      $result.statusDetails = statusDetails;
    }
    if (summaryHtml != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.summaryHtml = summaryHtml;
    }
    if (agentPlatform != null) {
      $result.agentPlatform = agentPlatform;
    }
    if (totalDuration != null) {
      $result.totalDuration = totalDuration;
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    return $result;
  }
  BuildInfra_Buildbucket_Agent_Output._() : super();
  factory BuildInfra_Buildbucket_Agent_Output.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent_Output.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent.Output',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..m<$core.String, ResolvedDataRef>(1, _omitFieldNames ? '' : 'resolvedData',
        entryClassName: 'BuildInfra.Buildbucket.Agent.Output.ResolvedDataEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ResolvedDataRef.create,
        valueDefaultOrMaker: ResolvedDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..e<$3.Status>(2, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $3.Status.STATUS_UNSPECIFIED, valueOf: $3.Status.valueOf, enumValues: $3.Status.values)
    ..aOM<$3.StatusDetails>(3, _omitFieldNames ? '' : 'statusDetails', subBuilder: $3.StatusDetails.create)
    ..aOS(4, _omitFieldNames ? '' : 'summaryHtml')
    ..aOS(5, _omitFieldNames ? '' : 'agentPlatform')
    ..aOM<$4.Duration>(6, _omitFieldNames ? '' : 'totalDuration', subBuilder: $4.Duration.create)
    ..aOS(7, _omitFieldNames ? '' : 'summaryMarkdown')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output clone() => BuildInfra_Buildbucket_Agent_Output()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent_Output copyWith(void Function(BuildInfra_Buildbucket_Agent_Output) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent_Output))
          as BuildInfra_Buildbucket_Agent_Output;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output create() => BuildInfra_Buildbucket_Agent_Output._();
  BuildInfra_Buildbucket_Agent_Output createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent_Output> createRepeated() =>
      $pb.PbList<BuildInfra_Buildbucket_Agent_Output>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent_Output getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent_Output>(create);
  static BuildInfra_Buildbucket_Agent_Output? _defaultInstance;

  ///  Maps relative-to-root directory to the fully-resolved ref.
  ///
  ///  This will always have 1:1 mapping to Agent.Input.data
  @$pb.TagNumber(1)
  $core.Map<$core.String, ResolvedDataRef> get resolvedData => $_getMap(0);

  @$pb.TagNumber(2)
  $3.Status get status => $_getN(1);
  @$pb.TagNumber(2)
  set status($3.Status v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $3.StatusDetails get statusDetails => $_getN(2);
  @$pb.TagNumber(3)
  set statusDetails($3.StatusDetails v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStatusDetails() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusDetails() => clearField(3);
  @$pb.TagNumber(3)
  $3.StatusDetails ensureStatusDetails() => $_ensure(2);

  /// Deprecated. Use summary_markdown instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.String get summaryHtml => $_getSZ(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  set summaryHtml($core.String v) {
    $_setString(3, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool hasSummaryHtml() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  void clearSummaryHtml() => clearField(4);

  ///  The agent's resolved CIPD ${platform} (e.g. "linux-amd64",
  ///  "windows-386", etc.).
  ///
  ///  This is trivial for bbagent to calculate (unlike trying to embed
  ///  its cipd package version inside or along with the executable).
  ///  Buildbucket is doing a full package -> instance ID resolution at
  ///  CreateBuild time anyway, so Agent.Source.resolved_instances
  ///  will give the mapping from `agent_platform` to a precise instance_id
  ///  which was used.
  @$pb.TagNumber(5)
  $core.String get agentPlatform => $_getSZ(4);
  @$pb.TagNumber(5)
  set agentPlatform($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAgentPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearAgentPlatform() => clearField(5);

  /// Total installation duration for all input data. Currently only record
  /// cipd packages installation time.
  @$pb.TagNumber(6)
  $4.Duration get totalDuration => $_getN(5);
  @$pb.TagNumber(6)
  set totalDuration($4.Duration v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasTotalDuration() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalDuration() => clearField(6);
  @$pb.TagNumber(6)
  $4.Duration ensureTotalDuration() => $_ensure(5);

  @$pb.TagNumber(7)
  $core.String get summaryMarkdown => $_getSZ(6);
  @$pb.TagNumber(7)
  set summaryMarkdown($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasSummaryMarkdown() => $_has(6);
  @$pb.TagNumber(7)
  void clearSummaryMarkdown() => clearField(7);
}

/// bbagent will interpret Agent.input, as well as update Agent.output.
class BuildInfra_Buildbucket_Agent extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket_Agent({
    BuildInfra_Buildbucket_Agent_Input? input,
    BuildInfra_Buildbucket_Agent_Output? output,
    BuildInfra_Buildbucket_Agent_Source? source,
    $core.Map<$core.String, BuildInfra_Buildbucket_Agent_Purpose>? purposes,
    $3.CacheEntry? cipdClientCache,
    $3.CacheEntry? cipdPackagesCache,
  }) {
    final $result = create();
    if (input != null) {
      $result.input = input;
    }
    if (output != null) {
      $result.output = output;
    }
    if (source != null) {
      $result.source = source;
    }
    if (purposes != null) {
      $result.purposes.addAll(purposes);
    }
    if (cipdClientCache != null) {
      $result.cipdClientCache = cipdClientCache;
    }
    if (cipdPackagesCache != null) {
      $result.cipdPackagesCache = cipdPackagesCache;
    }
    return $result;
  }
  BuildInfra_Buildbucket_Agent._() : super();
  factory BuildInfra_Buildbucket_Agent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket_Agent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket.Agent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket_Agent_Input>(1, _omitFieldNames ? '' : 'input',
        subBuilder: BuildInfra_Buildbucket_Agent_Input.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Output>(2, _omitFieldNames ? '' : 'output',
        subBuilder: BuildInfra_Buildbucket_Agent_Output.create)
    ..aOM<BuildInfra_Buildbucket_Agent_Source>(3, _omitFieldNames ? '' : 'source',
        subBuilder: BuildInfra_Buildbucket_Agent_Source.create)
    ..m<$core.String, BuildInfra_Buildbucket_Agent_Purpose>(4, _omitFieldNames ? '' : 'purposes',
        entryClassName: 'BuildInfra.Buildbucket.Agent.PurposesEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OE,
        valueOf: BuildInfra_Buildbucket_Agent_Purpose.valueOf,
        enumValues: BuildInfra_Buildbucket_Agent_Purpose.values,
        valueDefaultOrMaker: BuildInfra_Buildbucket_Agent_Purpose.PURPOSE_UNSPECIFIED,
        defaultEnumValue: BuildInfra_Buildbucket_Agent_Purpose.PURPOSE_UNSPECIFIED,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<$3.CacheEntry>(5, _omitFieldNames ? '' : 'cipdClientCache', subBuilder: $3.CacheEntry.create)
    ..aOM<$3.CacheEntry>(6, _omitFieldNames ? '' : 'cipdPackagesCache', subBuilder: $3.CacheEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent clone() => BuildInfra_Buildbucket_Agent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket_Agent copyWith(void Function(BuildInfra_Buildbucket_Agent) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket_Agent)) as BuildInfra_Buildbucket_Agent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent create() => BuildInfra_Buildbucket_Agent._();
  BuildInfra_Buildbucket_Agent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket_Agent> createRepeated() => $pb.PbList<BuildInfra_Buildbucket_Agent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket_Agent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket_Agent>(create);
  static BuildInfra_Buildbucket_Agent? _defaultInstance;

  /// TODO(crbug.com/1297809): for a long-term solution, we may need to add
  /// a top-level `on_path` array field in the input and read the value from
  /// configuration files (eg.settings.cfg, builder configs). So it can store
  /// the intended order of PATH env var. Then the per-inputDataRef level
  /// `on_path` field will be deprecated.
  /// Currently, the new BBagent flow merges all inputDataRef-level `on_path`
  /// values and sort. This mimics the same behavior of PyBB backend in order
  /// to have the cipd_installation migration to roll out first under a minimal risk.
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input get input => $_getN(0);
  @$pb.TagNumber(1)
  set input(BuildInfra_Buildbucket_Agent_Input v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasInput() => $_has(0);
  @$pb.TagNumber(1)
  void clearInput() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket_Agent_Input ensureInput() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output get output => $_getN(1);
  @$pb.TagNumber(2)
  set output(BuildInfra_Buildbucket_Agent_Output v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasOutput() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutput() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Buildbucket_Agent_Output ensureOutput() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_Buildbucket_Agent_Source get source => $_getN(2);
  @$pb.TagNumber(3)
  set source(BuildInfra_Buildbucket_Agent_Source v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => clearField(3);
  @$pb.TagNumber(3)
  BuildInfra_Buildbucket_Agent_Source ensureSource() => $_ensure(2);

  ///  Maps the relative-to-root directory path in both `input` and `output`
  ///  to the Purpose of the software in that directory.
  ///
  ///  If a path is not listed here, it is the same as PURPOSE_UNSPECIFIED.
  @$pb.TagNumber(4)
  $core.Map<$core.String, BuildInfra_Buildbucket_Agent_Purpose> get purposes => $_getMap(3);

  /// Cache for the cipd client.
  /// The cache name should be in the format like `cipd_client_<sha(client_version)>`.
  @$pb.TagNumber(5)
  $3.CacheEntry get cipdClientCache => $_getN(4);
  @$pb.TagNumber(5)
  set cipdClientCache($3.CacheEntry v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasCipdClientCache() => $_has(4);
  @$pb.TagNumber(5)
  void clearCipdClientCache() => clearField(5);
  @$pb.TagNumber(5)
  $3.CacheEntry ensureCipdClientCache() => $_ensure(4);

  /// Cache for the cipd packages.
  /// The cache name should be in the format like `cipd_cache_<sha(task_service_account)>`.
  @$pb.TagNumber(6)
  $3.CacheEntry get cipdPackagesCache => $_getN(5);
  @$pb.TagNumber(6)
  set cipdPackagesCache($3.CacheEntry v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasCipdPackagesCache() => $_has(5);
  @$pb.TagNumber(6)
  void clearCipdPackagesCache() => clearField(6);
  @$pb.TagNumber(6)
  $3.CacheEntry ensureCipdPackagesCache() => $_ensure(5);
}

/// Buildbucket-specific information, captured at the build creation time.
class BuildInfra_Buildbucket extends $pb.GeneratedMessage {
  factory BuildInfra_Buildbucket({
    $core.String? serviceConfigRevision,
    $5.Struct? requestedProperties,
    $core.Iterable<$3.RequestedDimension>? requestedDimensions,
    $core.String? hostname,
    $core.Map<$core.String, BuildInfra_Buildbucket_ExperimentReason>? experimentReasons,
    @$core.Deprecated('This field is deprecated.') $core.Map<$core.String, ResolvedDataRef>? agentExecutable,
    BuildInfra_Buildbucket_Agent? agent,
    $core.Iterable<$core.String>? knownPublicGerritHosts,
    $core.bool? buildNumber,
  }) {
    final $result = create();
    if (serviceConfigRevision != null) {
      $result.serviceConfigRevision = serviceConfigRevision;
    }
    if (requestedProperties != null) {
      $result.requestedProperties = requestedProperties;
    }
    if (requestedDimensions != null) {
      $result.requestedDimensions.addAll(requestedDimensions);
    }
    if (hostname != null) {
      $result.hostname = hostname;
    }
    if (experimentReasons != null) {
      $result.experimentReasons.addAll(experimentReasons);
    }
    if (agentExecutable != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.agentExecutable.addAll(agentExecutable);
    }
    if (agent != null) {
      $result.agent = agent;
    }
    if (knownPublicGerritHosts != null) {
      $result.knownPublicGerritHosts.addAll(knownPublicGerritHosts);
    }
    if (buildNumber != null) {
      $result.buildNumber = buildNumber;
    }
    return $result;
  }
  BuildInfra_Buildbucket._() : super();
  factory BuildInfra_Buildbucket.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Buildbucket.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Buildbucket',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'serviceConfigRevision')
    ..aOM<$5.Struct>(5, _omitFieldNames ? '' : 'requestedProperties', subBuilder: $5.Struct.create)
    ..pc<$3.RequestedDimension>(6, _omitFieldNames ? '' : 'requestedDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..aOS(7, _omitFieldNames ? '' : 'hostname')
    ..m<$core.String, BuildInfra_Buildbucket_ExperimentReason>(8, _omitFieldNames ? '' : 'experimentReasons',
        entryClassName: 'BuildInfra.Buildbucket.ExperimentReasonsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OE,
        valueOf: BuildInfra_Buildbucket_ExperimentReason.valueOf,
        enumValues: BuildInfra_Buildbucket_ExperimentReason.values,
        valueDefaultOrMaker: BuildInfra_Buildbucket_ExperimentReason.EXPERIMENT_REASON_UNSET,
        defaultEnumValue: BuildInfra_Buildbucket_ExperimentReason.EXPERIMENT_REASON_UNSET,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..m<$core.String, ResolvedDataRef>(9, _omitFieldNames ? '' : 'agentExecutable',
        entryClassName: 'BuildInfra.Buildbucket.AgentExecutableEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OM,
        valueCreator: ResolvedDataRef.create,
        valueDefaultOrMaker: ResolvedDataRef.getDefault,
        packageName: const $pb.PackageName('buildbucket.v2'))
    ..aOM<BuildInfra_Buildbucket_Agent>(10, _omitFieldNames ? '' : 'agent',
        subBuilder: BuildInfra_Buildbucket_Agent.create)
    ..pPS(11, _omitFieldNames ? '' : 'knownPublicGerritHosts')
    ..aOB(12, _omitFieldNames ? '' : 'buildNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket clone() => BuildInfra_Buildbucket()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Buildbucket copyWith(void Function(BuildInfra_Buildbucket) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Buildbucket)) as BuildInfra_Buildbucket;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket create() => BuildInfra_Buildbucket._();
  BuildInfra_Buildbucket createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Buildbucket> createRepeated() => $pb.PbList<BuildInfra_Buildbucket>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Buildbucket getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Buildbucket>(create);
  static BuildInfra_Buildbucket? _defaultInstance;

  /// Version of swarming task template. Defines
  /// versions of kitchen, git, git wrapper, python, vpython, etc.
  @$pb.TagNumber(2)
  $core.String get serviceConfigRevision => $_getSZ(0);
  @$pb.TagNumber(2)
  set serviceConfigRevision($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasServiceConfigRevision() => $_has(0);
  @$pb.TagNumber(2)
  void clearServiceConfigRevision() => clearField(2);

  ///  Properties that were specified in ScheduleBuildRequest to create this
  ///  build.
  ///
  ///  In particular, CQ uses this to decide whether the build created by
  ///  someone else is appropriate for CQ, e.g. it was created with the same
  ///  properties that CQ would use.
  @$pb.TagNumber(5)
  $5.Struct get requestedProperties => $_getN(1);
  @$pb.TagNumber(5)
  set requestedProperties($5.Struct v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasRequestedProperties() => $_has(1);
  @$pb.TagNumber(5)
  void clearRequestedProperties() => clearField(5);
  @$pb.TagNumber(5)
  $5.Struct ensureRequestedProperties() => $_ensure(1);

  /// Dimensions that were specified in ScheduleBuildRequest to create this
  /// build.
  @$pb.TagNumber(6)
  $core.List<$3.RequestedDimension> get requestedDimensions => $_getList(2);

  /// Buildbucket hostname, e.g. "cr-buildbucket.appspot.com".
  @$pb.TagNumber(7)
  $core.String get hostname => $_getSZ(3);
  @$pb.TagNumber(7)
  set hostname($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasHostname() => $_has(3);
  @$pb.TagNumber(7)
  void clearHostname() => clearField(7);

  ///  This contains a map of all the experiments involved for this build, as
  ///  well as which bit of configuration lead to them being set (or unset).
  ///
  ///  Note that if the reason here is EXPERIMENT_REASON_GLOBAL_INACTIVE,
  ///  then that means that the experiment is completely disabled and has no
  ///  effect, but your builder or ScheduleBuildRequest still indicated that
  ///  the experiment should be set. If you see this, then please remove it
  ///  from your configuration and/or requests.
  @$pb.TagNumber(8)
  $core.Map<$core.String, BuildInfra_Buildbucket_ExperimentReason> get experimentReasons => $_getMap(4);

  /// The agent binary (bbagent or kitchen) resolutions Buildbucket made for this build.
  /// This includes all agent_executable references supplied to
  /// the TaskBackend in "original" (CIPD) form, to facilitate debugging.
  /// DEPRECATED: Use agent.source instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(9)
  $core.Map<$core.String, ResolvedDataRef> get agentExecutable => $_getMap(5);

  @$pb.TagNumber(10)
  BuildInfra_Buildbucket_Agent get agent => $_getN(6);
  @$pb.TagNumber(10)
  set agent(BuildInfra_Buildbucket_Agent v) {
    setField(10, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasAgent() => $_has(6);
  @$pb.TagNumber(10)
  void clearAgent() => clearField(10);
  @$pb.TagNumber(10)
  BuildInfra_Buildbucket_Agent ensureAgent() => $_ensure(6);

  @$pb.TagNumber(11)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(7);

  /// Flag for if the build should have a build number.
  @$pb.TagNumber(12)
  $core.bool get buildNumber => $_getBF(8);
  @$pb.TagNumber(12)
  set buildNumber($core.bool v) {
    $_setBool(8, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasBuildNumber() => $_has(8);
  @$pb.TagNumber(12)
  void clearBuildNumber() => clearField(12);
}

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
///  Builder cache.
///
///  Buildbucket implicitly declares cache
///    {"name": "<hash(project/bucket/builder)>", "path": "builder"}.
///  This means that any LUCI builder has a "personal disk space" on the bot.
///  Builder cache is often a good start before customizing caching.
///  In recipes, it is available at api.buildbucket.builder_cache_path.
class BuildInfra_Swarming_CacheEntry extends $pb.GeneratedMessage {
  factory BuildInfra_Swarming_CacheEntry({
    $core.String? name,
    $core.String? path,
    $4.Duration? waitForWarmCache,
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
  BuildInfra_Swarming_CacheEntry._() : super();
  factory BuildInfra_Swarming_CacheEntry.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming_CacheEntry.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Swarming.CacheEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOM<$4.Duration>(3, _omitFieldNames ? '' : 'waitForWarmCache', subBuilder: $4.Duration.create)
    ..aOS(4, _omitFieldNames ? '' : 'envVar')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry clone() => BuildInfra_Swarming_CacheEntry()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming_CacheEntry copyWith(void Function(BuildInfra_Swarming_CacheEntry) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Swarming_CacheEntry)) as BuildInfra_Swarming_CacheEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry create() => BuildInfra_Swarming_CacheEntry._();
  BuildInfra_Swarming_CacheEntry createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming_CacheEntry> createRepeated() => $pb.PbList<BuildInfra_Swarming_CacheEntry>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming_CacheEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming_CacheEntry>(create);
  static BuildInfra_Swarming_CacheEntry? _defaultInstance;

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
  set name($core.String v) {
    $_setString(0, v);
  }

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
  set path($core.String v) {
    $_setString(1, v);
  }

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
  $4.Duration get waitForWarmCache => $_getN(2);
  @$pb.TagNumber(3)
  set waitForWarmCache($4.Duration v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasWaitForWarmCache() => $_has(2);
  @$pb.TagNumber(3)
  void clearWaitForWarmCache() => clearField(3);
  @$pb.TagNumber(3)
  $4.Duration ensureWaitForWarmCache() => $_ensure(2);

  /// Environment variable with this name will be set to the path to the cache
  /// directory.
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

///  Swarming-specific information.
///
///  Next ID: 10.
class BuildInfra_Swarming extends $pb.GeneratedMessage {
  factory BuildInfra_Swarming({
    $core.String? hostname,
    $core.String? taskId,
    $core.String? taskServiceAccount,
    $core.int? priority,
    $core.Iterable<$3.RequestedDimension>? taskDimensions,
    $core.Iterable<$3.StringPair>? botDimensions,
    $core.Iterable<BuildInfra_Swarming_CacheEntry>? caches,
    $core.String? parentRunId,
  }) {
    final $result = create();
    if (hostname != null) {
      $result.hostname = hostname;
    }
    if (taskId != null) {
      $result.taskId = taskId;
    }
    if (taskServiceAccount != null) {
      $result.taskServiceAccount = taskServiceAccount;
    }
    if (priority != null) {
      $result.priority = priority;
    }
    if (taskDimensions != null) {
      $result.taskDimensions.addAll(taskDimensions);
    }
    if (botDimensions != null) {
      $result.botDimensions.addAll(botDimensions);
    }
    if (caches != null) {
      $result.caches.addAll(caches);
    }
    if (parentRunId != null) {
      $result.parentRunId = parentRunId;
    }
    return $result;
  }
  BuildInfra_Swarming._() : super();
  factory BuildInfra_Swarming.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Swarming.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Swarming',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'taskId')
    ..aOS(3, _omitFieldNames ? '' : 'taskServiceAccount')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'priority', $pb.PbFieldType.O3)
    ..pc<$3.RequestedDimension>(5, _omitFieldNames ? '' : 'taskDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..pc<$3.StringPair>(6, _omitFieldNames ? '' : 'botDimensions', $pb.PbFieldType.PM, subBuilder: $3.StringPair.create)
    ..pc<BuildInfra_Swarming_CacheEntry>(7, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM,
        subBuilder: BuildInfra_Swarming_CacheEntry.create)
    ..aOS(9, _omitFieldNames ? '' : 'parentRunId')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming clone() => BuildInfra_Swarming()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Swarming copyWith(void Function(BuildInfra_Swarming) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Swarming)) as BuildInfra_Swarming;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming create() => BuildInfra_Swarming._();
  BuildInfra_Swarming createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Swarming> createRepeated() => $pb.PbList<BuildInfra_Swarming>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Swarming getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Swarming>(create);
  static BuildInfra_Swarming? _defaultInstance;

  /// Swarming hostname, e.g. "chromium-swarm.appspot.com".
  /// Populated at the build creation time.
  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  /// Swarming task id.
  /// Not guaranteed to be populated at the build creation time.
  @$pb.TagNumber(2)
  $core.String get taskId => $_getSZ(1);
  @$pb.TagNumber(2)
  set taskId($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTaskId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTaskId() => clearField(2);

  /// Task service account email address.
  /// This is the service account used for all authenticated requests by the
  /// build.
  @$pb.TagNumber(3)
  $core.String get taskServiceAccount => $_getSZ(2);
  @$pb.TagNumber(3)
  set taskServiceAccount($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTaskServiceAccount() => $_has(2);
  @$pb.TagNumber(3)
  void clearTaskServiceAccount() => clearField(3);

  /// Priority of the task. The lower the more important.
  /// Valid values are [20..255].
  @$pb.TagNumber(4)
  $core.int get priority => $_getIZ(3);
  @$pb.TagNumber(4)
  set priority($core.int v) {
    $_setSignedInt32(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPriority() => $_has(3);
  @$pb.TagNumber(4)
  void clearPriority() => clearField(4);

  /// Swarming dimensions for the task.
  @$pb.TagNumber(5)
  $core.List<$3.RequestedDimension> get taskDimensions => $_getList(4);

  /// Swarming dimensions of the bot used for the task.
  @$pb.TagNumber(6)
  $core.List<$3.StringPair> get botDimensions => $_getList(5);

  /// Caches requested by this build.
  @$pb.TagNumber(7)
  $core.List<BuildInfra_Swarming_CacheEntry> get caches => $_getList(6);

  /// Swarming run id of the parent task from which this build is triggered.
  /// If set, swarming promises to ensure this build won't outlive its parent
  /// swarming task (which may or may not itself be a Buildbucket build).
  /// Populated at the build creation time.
  @$pb.TagNumber(9)
  $core.String get parentRunId => $_getSZ(7);
  @$pb.TagNumber(9)
  set parentRunId($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasParentRunId() => $_has(7);
  @$pb.TagNumber(9)
  void clearParentRunId() => clearField(9);
}

/// LogDog-specific information.
class BuildInfra_LogDog extends $pb.GeneratedMessage {
  factory BuildInfra_LogDog({
    $core.String? hostname,
    $core.String? project,
    $core.String? prefix,
  }) {
    final $result = create();
    if (hostname != null) {
      $result.hostname = hostname;
    }
    if (project != null) {
      $result.project = project;
    }
    if (prefix != null) {
      $result.prefix = prefix;
    }
    return $result;
  }
  BuildInfra_LogDog._() : super();
  factory BuildInfra_LogDog.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_LogDog.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.LogDog',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'project')
    ..aOS(3, _omitFieldNames ? '' : 'prefix')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_LogDog clone() => BuildInfra_LogDog()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_LogDog copyWith(void Function(BuildInfra_LogDog) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_LogDog)) as BuildInfra_LogDog;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog create() => BuildInfra_LogDog._();
  BuildInfra_LogDog createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_LogDog> createRepeated() => $pb.PbList<BuildInfra_LogDog>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_LogDog getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_LogDog>(create);
  static BuildInfra_LogDog? _defaultInstance;

  /// LogDog hostname, e.g. "logs.chromium.org".
  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  /// LogDog project, e.g. "chromium".
  /// Typically matches Build.builder.project.
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

  /// A slash-separated path prefix shared by all logs and artifacts of this
  /// build.
  /// No other build can have the same prefix.
  /// Can be used to discover logs and/or load log contents.
  @$pb.TagNumber(3)
  $core.String get prefix => $_getSZ(2);
  @$pb.TagNumber(3)
  set prefix($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasPrefix() => $_has(2);
  @$pb.TagNumber(3)
  void clearPrefix() => clearField(3);
}

/// Recipe-specific information.
class BuildInfra_Recipe extends $pb.GeneratedMessage {
  factory BuildInfra_Recipe({
    $core.String? cipdPackage,
    $core.String? name,
  }) {
    final $result = create();
    if (cipdPackage != null) {
      $result.cipdPackage = cipdPackage;
    }
    if (name != null) {
      $result.name = name;
    }
    return $result;
  }
  BuildInfra_Recipe._() : super();
  factory BuildInfra_Recipe.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Recipe.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Recipe',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'cipdPackage')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Recipe clone() => BuildInfra_Recipe()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Recipe copyWith(void Function(BuildInfra_Recipe) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Recipe)) as BuildInfra_Recipe;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe create() => BuildInfra_Recipe._();
  BuildInfra_Recipe createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Recipe> createRepeated() => $pb.PbList<BuildInfra_Recipe>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Recipe getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Recipe>(create);
  static BuildInfra_Recipe? _defaultInstance;

  /// CIPD package name containing the recipe used to run this build.
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

  /// Name of the recipe used to run this build.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => clearField(2);
}

/// ResultDB-specific information.
class BuildInfra_ResultDB extends $pb.GeneratedMessage {
  factory BuildInfra_ResultDB({
    $core.String? hostname,
    $core.String? invocation,
    $core.bool? enable,
    $core.Iterable<$6.BigQueryExport>? bqExports,
    $6.HistoryOptions? historyOptions,
  }) {
    final $result = create();
    if (hostname != null) {
      $result.hostname = hostname;
    }
    if (invocation != null) {
      $result.invocation = invocation;
    }
    if (enable != null) {
      $result.enable = enable;
    }
    if (bqExports != null) {
      $result.bqExports.addAll(bqExports);
    }
    if (historyOptions != null) {
      $result.historyOptions = historyOptions;
    }
    return $result;
  }
  BuildInfra_ResultDB._() : super();
  factory BuildInfra_ResultDB.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_ResultDB.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.ResultDB',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'hostname')
    ..aOS(2, _omitFieldNames ? '' : 'invocation')
    ..aOB(3, _omitFieldNames ? '' : 'enable')
    ..pc<$6.BigQueryExport>(4, _omitFieldNames ? '' : 'bqExports', $pb.PbFieldType.PM,
        subBuilder: $6.BigQueryExport.create)
    ..aOM<$6.HistoryOptions>(5, _omitFieldNames ? '' : 'historyOptions', subBuilder: $6.HistoryOptions.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_ResultDB clone() => BuildInfra_ResultDB()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_ResultDB copyWith(void Function(BuildInfra_ResultDB) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_ResultDB)) as BuildInfra_ResultDB;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB create() => BuildInfra_ResultDB._();
  BuildInfra_ResultDB createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_ResultDB> createRepeated() => $pb.PbList<BuildInfra_ResultDB>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_ResultDB getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_ResultDB>(create);
  static BuildInfra_ResultDB? _defaultInstance;

  /// Hostname of the ResultDB instance, such as "results.api.cr.dev".
  @$pb.TagNumber(1)
  $core.String get hostname => $_getSZ(0);
  @$pb.TagNumber(1)
  set hostname($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasHostname() => $_has(0);
  @$pb.TagNumber(1)
  void clearHostname() => clearField(1);

  /// Name of the invocation for results of this build.
  /// Typically "invocations/build:<build_id>".
  @$pb.TagNumber(2)
  $core.String get invocation => $_getSZ(1);
  @$pb.TagNumber(2)
  set invocation($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasInvocation() => $_has(1);
  @$pb.TagNumber(2)
  void clearInvocation() => clearField(2);

  /// Whether to enable ResultDB:Buildbucket integration.
  @$pb.TagNumber(3)
  $core.bool get enable => $_getBF(2);
  @$pb.TagNumber(3)
  set enable($core.bool v) {
    $_setBool(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEnable() => $_has(2);
  @$pb.TagNumber(3)
  void clearEnable() => clearField(3);

  /// Configuration for exporting test results to BigQuery.
  /// This can have multiple values to export results to multiple BigQuery
  /// tables, or to support multiple test result predicates.
  @$pb.TagNumber(4)
  $core.List<$6.BigQueryExport> get bqExports => $_getList(3);

  /// Deprecated. Any values specified here are ignored.
  @$pb.TagNumber(5)
  $6.HistoryOptions get historyOptions => $_getN(4);
  @$pb.TagNumber(5)
  set historyOptions($6.HistoryOptions v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasHistoryOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearHistoryOptions() => clearField(5);
  @$pb.TagNumber(5)
  $6.HistoryOptions ensureHistoryOptions() => $_ensure(4);
}

/// Led specific information.
class BuildInfra_Led extends $pb.GeneratedMessage {
  factory BuildInfra_Led({
    $core.String? shadowedBucket,
  }) {
    final $result = create();
    if (shadowedBucket != null) {
      $result.shadowedBucket = shadowedBucket;
    }
    return $result;
  }
  BuildInfra_Led._() : super();
  factory BuildInfra_Led.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Led.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Led',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'shadowedBucket')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Led clone() => BuildInfra_Led()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Led copyWith(void Function(BuildInfra_Led) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Led)) as BuildInfra_Led;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Led create() => BuildInfra_Led._();
  BuildInfra_Led createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Led> createRepeated() => $pb.PbList<BuildInfra_Led>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Led getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Led>(create);
  static BuildInfra_Led? _defaultInstance;

  /// The original bucket this led build is shadowing.
  @$pb.TagNumber(1)
  $core.String get shadowedBucket => $_getSZ(0);
  @$pb.TagNumber(1)
  set shadowedBucket($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasShadowedBucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearShadowedBucket() => clearField(1);
}

/// CIPD Packages to make available for this build.
class BuildInfra_BBAgent_Input_CIPDPackage extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent_Input_CIPDPackage({
    $core.String? name,
    $core.String? version,
    $core.String? server,
    $core.String? path,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (version != null) {
      $result.version = version;
    }
    if (server != null) {
      $result.server = server;
    }
    if (path != null) {
      $result.path = path;
    }
    return $result;
  }
  BuildInfra_BBAgent_Input_CIPDPackage._() : super();
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input_CIPDPackage.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent.Input.CIPDPackage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'version')
    ..aOS(3, _omitFieldNames ? '' : 'server')
    ..aOS(4, _omitFieldNames ? '' : 'path')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage clone() => BuildInfra_BBAgent_Input_CIPDPackage()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input_CIPDPackage copyWith(void Function(BuildInfra_BBAgent_Input_CIPDPackage) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input_CIPDPackage))
          as BuildInfra_BBAgent_Input_CIPDPackage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage create() => BuildInfra_BBAgent_Input_CIPDPackage._();
  BuildInfra_BBAgent_Input_CIPDPackage createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage> createRepeated() =>
      $pb.PbList<BuildInfra_BBAgent_Input_CIPDPackage>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input_CIPDPackage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input_CIPDPackage>(create);
  static BuildInfra_BBAgent_Input_CIPDPackage? _defaultInstance;

  ///  Name of this CIPD package.
  ///
  ///  Required.
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

  ///  CIPD package version.
  ///
  ///  Required.
  @$pb.TagNumber(2)
  $core.String get version => $_getSZ(1);
  @$pb.TagNumber(2)
  set version($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => clearField(2);

  ///  CIPD server to fetch this package from.
  ///
  ///  Required.
  @$pb.TagNumber(3)
  $core.String get server => $_getSZ(2);
  @$pb.TagNumber(3)
  set server($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => clearField(3);

  ///  Path where this CIPD package should be installed.
  ///
  ///  Required.
  @$pb.TagNumber(4)
  $core.String get path => $_getSZ(3);
  @$pb.TagNumber(4)
  set path($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasPath() => $_has(3);
  @$pb.TagNumber(4)
  void clearPath() => clearField(4);
}

/// BBAgent-specific input.
class BuildInfra_BBAgent_Input extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent_Input({
    $core.Iterable<BuildInfra_BBAgent_Input_CIPDPackage>? cipdPackages,
  }) {
    final $result = create();
    if (cipdPackages != null) {
      $result.cipdPackages.addAll(cipdPackages);
    }
    return $result;
  }
  BuildInfra_BBAgent_Input._() : super();
  factory BuildInfra_BBAgent_Input.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent_Input.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent.Input',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..pc<BuildInfra_BBAgent_Input_CIPDPackage>(1, _omitFieldNames ? '' : 'cipdPackages', $pb.PbFieldType.PM,
        subBuilder: BuildInfra_BBAgent_Input_CIPDPackage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input clone() => BuildInfra_BBAgent_Input()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent_Input copyWith(void Function(BuildInfra_BBAgent_Input) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent_Input)) as BuildInfra_BBAgent_Input;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input create() => BuildInfra_BBAgent_Input._();
  BuildInfra_BBAgent_Input createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent_Input> createRepeated() => $pb.PbList<BuildInfra_BBAgent_Input>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent_Input getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent_Input>(create);
  static BuildInfra_BBAgent_Input? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<BuildInfra_BBAgent_Input_CIPDPackage> get cipdPackages => $_getList(0);
}

///  BBAgent-specific information.
///
///  All paths are relateive to bbagent's working directory, and must be delimited
///  with slashes ("/"), regardless of the host OS.
class BuildInfra_BBAgent extends $pb.GeneratedMessage {
  factory BuildInfra_BBAgent({
    $core.String? payloadPath,
    $core.String? cacheDir,
    @$core.Deprecated('This field is deprecated.') $core.Iterable<$core.String>? knownPublicGerritHosts,
    @$core.Deprecated('This field is deprecated.') BuildInfra_BBAgent_Input? input,
  }) {
    final $result = create();
    if (payloadPath != null) {
      $result.payloadPath = payloadPath;
    }
    if (cacheDir != null) {
      $result.cacheDir = cacheDir;
    }
    if (knownPublicGerritHosts != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.knownPublicGerritHosts.addAll(knownPublicGerritHosts);
    }
    if (input != null) {
      // ignore: deprecated_member_use_from_same_package
      $result.input = input;
    }
    return $result;
  }
  BuildInfra_BBAgent._() : super();
  factory BuildInfra_BBAgent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_BBAgent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.BBAgent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'payloadPath')
    ..aOS(2, _omitFieldNames ? '' : 'cacheDir')
    ..pPS(3, _omitFieldNames ? '' : 'knownPublicGerritHosts')
    ..aOM<BuildInfra_BBAgent_Input>(4, _omitFieldNames ? '' : 'input', subBuilder: BuildInfra_BBAgent_Input.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent clone() => BuildInfra_BBAgent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_BBAgent copyWith(void Function(BuildInfra_BBAgent) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_BBAgent)) as BuildInfra_BBAgent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent create() => BuildInfra_BBAgent._();
  BuildInfra_BBAgent createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_BBAgent> createRepeated() => $pb.PbList<BuildInfra_BBAgent>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_BBAgent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_BBAgent>(create);
  static BuildInfra_BBAgent? _defaultInstance;

  ///  Path to the base of the user executable package.
  ///
  ///  Required.
  @$pb.TagNumber(1)
  $core.String get payloadPath => $_getSZ(0);
  @$pb.TagNumber(1)
  set payloadPath($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPayloadPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPayloadPath() => clearField(1);

  ///  Path to a directory where each subdirectory is a cache dir.
  ///
  ///  Required.
  @$pb.TagNumber(2)
  $core.String get cacheDir => $_getSZ(1);
  @$pb.TagNumber(2)
  set cacheDir($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCacheDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearCacheDir() => clearField(2);

  ///  List of Gerrit hosts to force git authentication for.
  ///
  ///  By default public hosts are accessed anonymously, and the anonymous access
  ///  has very low quota. Context needs to know all such hostnames in advance to
  ///  be able to force authenticated access to them.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(3)
  $core.List<$core.String> get knownPublicGerritHosts => $_getList(2);

  /// DEPRECATED: Use build.Infra.Buildbucket.Agent.Input instead.
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  BuildInfra_BBAgent_Input get input => $_getN(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  set input(BuildInfra_BBAgent_Input v) {
    setField(4, v);
  }

  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  $core.bool hasInput() => $_has(3);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  void clearInput() => clearField(4);
  @$core.Deprecated('This field is deprecated.')
  @$pb.TagNumber(4)
  BuildInfra_BBAgent_Input ensureInput() => $_ensure(3);
}

/// Backend-specific information.
class BuildInfra_Backend extends $pb.GeneratedMessage {
  factory BuildInfra_Backend({
    $5.Struct? config,
    $7.Task? task,
    $core.Iterable<$3.CacheEntry>? caches,
    $core.Iterable<$3.RequestedDimension>? taskDimensions,
    $core.String? hostname,
  }) {
    final $result = create();
    if (config != null) {
      $result.config = config;
    }
    if (task != null) {
      $result.task = task;
    }
    if (caches != null) {
      $result.caches.addAll(caches);
    }
    if (taskDimensions != null) {
      $result.taskDimensions.addAll(taskDimensions);
    }
    if (hostname != null) {
      $result.hostname = hostname;
    }
    return $result;
  }
  BuildInfra_Backend._() : super();
  factory BuildInfra_Backend.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra_Backend.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra.Backend',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<$5.Struct>(1, _omitFieldNames ? '' : 'config', subBuilder: $5.Struct.create)
    ..aOM<$7.Task>(2, _omitFieldNames ? '' : 'task', subBuilder: $7.Task.create)
    ..pc<$3.CacheEntry>(3, _omitFieldNames ? '' : 'caches', $pb.PbFieldType.PM, subBuilder: $3.CacheEntry.create)
    ..pc<$3.RequestedDimension>(5, _omitFieldNames ? '' : 'taskDimensions', $pb.PbFieldType.PM,
        subBuilder: $3.RequestedDimension.create)
    ..aOS(6, _omitFieldNames ? '' : 'hostname')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra_Backend clone() => BuildInfra_Backend()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra_Backend copyWith(void Function(BuildInfra_Backend) updates) =>
      super.copyWith((message) => updates(message as BuildInfra_Backend)) as BuildInfra_Backend;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend create() => BuildInfra_Backend._();
  BuildInfra_Backend createEmptyInstance() => create();
  static $pb.PbList<BuildInfra_Backend> createRepeated() => $pb.PbList<BuildInfra_Backend>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra_Backend getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra_Backend>(create);
  static BuildInfra_Backend? _defaultInstance;

  /// Configuration supplied to the backend at the time it was instructed to
  /// run this build.
  @$pb.TagNumber(1)
  $5.Struct get config => $_getN(0);
  @$pb.TagNumber(1)
  set config($5.Struct v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasConfig() => $_has(0);
  @$pb.TagNumber(1)
  void clearConfig() => clearField(1);
  @$pb.TagNumber(1)
  $5.Struct ensureConfig() => $_ensure(0);

  /// Current backend task status.
  /// Updated as build runs.
  @$pb.TagNumber(2)
  $7.Task get task => $_getN(1);
  @$pb.TagNumber(2)
  set task($7.Task v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTask() => $_has(1);
  @$pb.TagNumber(2)
  void clearTask() => clearField(2);
  @$pb.TagNumber(2)
  $7.Task ensureTask() => $_ensure(1);

  /// Caches requested by this build.
  @$pb.TagNumber(3)
  $core.List<$3.CacheEntry> get caches => $_getList(2);

  /// Dimensions for the task.
  @$pb.TagNumber(5)
  $core.List<$3.RequestedDimension> get taskDimensions => $_getList(3);

  /// Hostname is the hostname for the backend itself.
  @$pb.TagNumber(6)
  $core.String get hostname => $_getSZ(4);
  @$pb.TagNumber(6)
  set hostname($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasHostname() => $_has(4);
  @$pb.TagNumber(6)
  void clearHostname() => clearField(6);
}

/// Build infrastructure that was used for a particular build.
class BuildInfra extends $pb.GeneratedMessage {
  factory BuildInfra({
    BuildInfra_Buildbucket? buildbucket,
    BuildInfra_Swarming? swarming,
    BuildInfra_LogDog? logdog,
    BuildInfra_Recipe? recipe,
    BuildInfra_ResultDB? resultdb,
    BuildInfra_BBAgent? bbagent,
    BuildInfra_Backend? backend,
    BuildInfra_Led? led,
  }) {
    final $result = create();
    if (buildbucket != null) {
      $result.buildbucket = buildbucket;
    }
    if (swarming != null) {
      $result.swarming = swarming;
    }
    if (logdog != null) {
      $result.logdog = logdog;
    }
    if (recipe != null) {
      $result.recipe = recipe;
    }
    if (resultdb != null) {
      $result.resultdb = resultdb;
    }
    if (bbagent != null) {
      $result.bbagent = bbagent;
    }
    if (backend != null) {
      $result.backend = backend;
    }
    if (led != null) {
      $result.led = led;
    }
    return $result;
  }
  BuildInfra._() : super();
  factory BuildInfra.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory BuildInfra.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BuildInfra',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOM<BuildInfra_Buildbucket>(1, _omitFieldNames ? '' : 'buildbucket', subBuilder: BuildInfra_Buildbucket.create)
    ..aOM<BuildInfra_Swarming>(2, _omitFieldNames ? '' : 'swarming', subBuilder: BuildInfra_Swarming.create)
    ..aOM<BuildInfra_LogDog>(3, _omitFieldNames ? '' : 'logdog', subBuilder: BuildInfra_LogDog.create)
    ..aOM<BuildInfra_Recipe>(4, _omitFieldNames ? '' : 'recipe', subBuilder: BuildInfra_Recipe.create)
    ..aOM<BuildInfra_ResultDB>(5, _omitFieldNames ? '' : 'resultdb', subBuilder: BuildInfra_ResultDB.create)
    ..aOM<BuildInfra_BBAgent>(6, _omitFieldNames ? '' : 'bbagent', subBuilder: BuildInfra_BBAgent.create)
    ..aOM<BuildInfra_Backend>(7, _omitFieldNames ? '' : 'backend', subBuilder: BuildInfra_Backend.create)
    ..aOM<BuildInfra_Led>(8, _omitFieldNames ? '' : 'led', subBuilder: BuildInfra_Led.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  BuildInfra clone() => BuildInfra()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  BuildInfra copyWith(void Function(BuildInfra) updates) =>
      super.copyWith((message) => updates(message as BuildInfra)) as BuildInfra;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BuildInfra create() => BuildInfra._();
  BuildInfra createEmptyInstance() => create();
  static $pb.PbList<BuildInfra> createRepeated() => $pb.PbList<BuildInfra>();
  @$core.pragma('dart2js:noInline')
  static BuildInfra getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BuildInfra>(create);
  static BuildInfra? _defaultInstance;

  @$pb.TagNumber(1)
  BuildInfra_Buildbucket get buildbucket => $_getN(0);
  @$pb.TagNumber(1)
  set buildbucket(BuildInfra_Buildbucket v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasBuildbucket() => $_has(0);
  @$pb.TagNumber(1)
  void clearBuildbucket() => clearField(1);
  @$pb.TagNumber(1)
  BuildInfra_Buildbucket ensureBuildbucket() => $_ensure(0);

  @$pb.TagNumber(2)
  BuildInfra_Swarming get swarming => $_getN(1);
  @$pb.TagNumber(2)
  set swarming(BuildInfra_Swarming v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasSwarming() => $_has(1);
  @$pb.TagNumber(2)
  void clearSwarming() => clearField(2);
  @$pb.TagNumber(2)
  BuildInfra_Swarming ensureSwarming() => $_ensure(1);

  @$pb.TagNumber(3)
  BuildInfra_LogDog get logdog => $_getN(2);
  @$pb.TagNumber(3)
  set logdog(BuildInfra_LogDog v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasLogdog() => $_has(2);
  @$pb.TagNumber(3)
  void clearLogdog() => clearField(3);
  @$pb.TagNumber(3)
  BuildInfra_LogDog ensureLogdog() => $_ensure(2);

  @$pb.TagNumber(4)
  BuildInfra_Recipe get recipe => $_getN(3);
  @$pb.TagNumber(4)
  set recipe(BuildInfra_Recipe v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasRecipe() => $_has(3);
  @$pb.TagNumber(4)
  void clearRecipe() => clearField(4);
  @$pb.TagNumber(4)
  BuildInfra_Recipe ensureRecipe() => $_ensure(3);

  @$pb.TagNumber(5)
  BuildInfra_ResultDB get resultdb => $_getN(4);
  @$pb.TagNumber(5)
  set resultdb(BuildInfra_ResultDB v) {
    setField(5, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasResultdb() => $_has(4);
  @$pb.TagNumber(5)
  void clearResultdb() => clearField(5);
  @$pb.TagNumber(5)
  BuildInfra_ResultDB ensureResultdb() => $_ensure(4);

  @$pb.TagNumber(6)
  BuildInfra_BBAgent get bbagent => $_getN(5);
  @$pb.TagNumber(6)
  set bbagent(BuildInfra_BBAgent v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasBbagent() => $_has(5);
  @$pb.TagNumber(6)
  void clearBbagent() => clearField(6);
  @$pb.TagNumber(6)
  BuildInfra_BBAgent ensureBbagent() => $_ensure(5);

  @$pb.TagNumber(7)
  BuildInfra_Backend get backend => $_getN(6);
  @$pb.TagNumber(7)
  set backend(BuildInfra_Backend v) {
    setField(7, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBackend() => $_has(6);
  @$pb.TagNumber(7)
  void clearBackend() => clearField(7);
  @$pb.TagNumber(7)
  BuildInfra_Backend ensureBackend() => $_ensure(6);

  /// It should only be set for led builds.
  @$pb.TagNumber(8)
  BuildInfra_Led get led => $_getN(7);
  @$pb.TagNumber(8)
  set led(BuildInfra_Led v) {
    setField(8, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasLed() => $_has(7);
  @$pb.TagNumber(8)
  void clearLed() => clearField(8);
  @$pb.TagNumber(8)
  BuildInfra_Led ensureLed() => $_ensure(7);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
