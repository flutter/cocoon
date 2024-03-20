//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/step.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/timestamp.pb.dart' as $0;
import 'common.pb.dart' as $1;
import 'common.pbenum.dart' as $1;

class Step_MergeBuild extends $pb.GeneratedMessage {
  factory Step_MergeBuild({
    $core.String? fromLogdogStream,
    $core.bool? legacyGlobalNamespace,
  }) {
    final $result = create();
    if (fromLogdogStream != null) {
      $result.fromLogdogStream = fromLogdogStream;
    }
    if (legacyGlobalNamespace != null) {
      $result.legacyGlobalNamespace = legacyGlobalNamespace;
    }
    return $result;
  }
  Step_MergeBuild._() : super();
  factory Step_MergeBuild.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Step_MergeBuild.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Step.MergeBuild', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fromLogdogStream')
    ..aOB(2, _omitFieldNames ? '' : 'legacyGlobalNamespace')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Step_MergeBuild clone() => Step_MergeBuild()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Step_MergeBuild copyWith(void Function(Step_MergeBuild) updates) => super.copyWith((message) => updates(message as Step_MergeBuild)) as Step_MergeBuild;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Step_MergeBuild create() => Step_MergeBuild._();
  Step_MergeBuild createEmptyInstance() => create();
  static $pb.PbList<Step_MergeBuild> createRepeated() => $pb.PbList<Step_MergeBuild>();
  @$core.pragma('dart2js:noInline')
  static Step_MergeBuild getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Step_MergeBuild>(create);
  static Step_MergeBuild? _defaultInstance;

  ///  If set, then this stream is expected to be a datagram stream
  ///  containing Build messages.
  ///
  ///  This should be the stream name relative to the current build's
  ///  $LOGDOG_NAMESPACE.
  @$pb.TagNumber(1)
  $core.String get fromLogdogStream => $_getSZ(0);
  @$pb.TagNumber(1)
  set fromLogdogStream($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFromLogdogStream() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromLogdogStream() => clearField(1);

  ///  If set, then this stream will be merged "in line" with this step.
  ///
  ///  Properties emitted by the merge build stream will overwrite global
  ///  outputs with the same top-level key.
  ///
  ///  Steps emitted by the merge build stream will NOT have their names
  ///  namespaced (though the log stream names are still expected to
  ///  adhere to the regular luciexe rules).
  ///
  ///  Because this is a legacy feature, this intentionally omits other fields
  ///  which "could be" merged, because there was no affordance to emit them
  ///  under the legacy annotator scheme:
  ///    * output.gitiles_commit will not be merged.
  ///    * output.logs will not be merged.
  ///    * summary_markdown will not be merged.
  ///
  ///  This is NOT a recommended mode of operation, but legacy ChromeOS
  ///  builders rely on this behavior.
  ///
  ///  See crbug.com/1310155.
  @$pb.TagNumber(2)
  $core.bool get legacyGlobalNamespace => $_getBF(1);
  @$pb.TagNumber(2)
  set legacyGlobalNamespace($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLegacyGlobalNamespace() => $_has(1);
  @$pb.TagNumber(2)
  void clearLegacyGlobalNamespace() => clearField(2);
}

///  A build step.
///
///  A step may have children, see name field.
class Step extends $pb.GeneratedMessage {
  factory Step({
    $core.String? name,
    $0.Timestamp? startTime,
    $0.Timestamp? endTime,
    $1.Status? status,
    $core.Iterable<$1.Log>? logs,
    Step_MergeBuild? mergeBuild,
    $core.String? summaryMarkdown,
    $core.Iterable<$1.StringPair>? tags,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (startTime != null) {
      $result.startTime = startTime;
    }
    if (endTime != null) {
      $result.endTime = endTime;
    }
    if (status != null) {
      $result.status = status;
    }
    if (logs != null) {
      $result.logs.addAll(logs);
    }
    if (mergeBuild != null) {
      $result.mergeBuild = mergeBuild;
    }
    if (summaryMarkdown != null) {
      $result.summaryMarkdown = summaryMarkdown;
    }
    if (tags != null) {
      $result.tags.addAll(tags);
    }
    return $result;
  }
  Step._() : super();
  factory Step.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Step.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Step', package: const $pb.PackageName(_omitMessageNames ? '' : 'buildbucket.v2'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOM<$0.Timestamp>(2, _omitFieldNames ? '' : 'startTime', subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(3, _omitFieldNames ? '' : 'endTime', subBuilder: $0.Timestamp.create)
    ..e<$1.Status>(4, _omitFieldNames ? '' : 'status', $pb.PbFieldType.OE, defaultOrMaker: $1.Status.STATUS_UNSPECIFIED, valueOf: $1.Status.valueOf, enumValues: $1.Status.values)
    ..pc<$1.Log>(5, _omitFieldNames ? '' : 'logs', $pb.PbFieldType.PM, subBuilder: $1.Log.create)
    ..aOM<Step_MergeBuild>(6, _omitFieldNames ? '' : 'mergeBuild', subBuilder: Step_MergeBuild.create)
    ..aOS(7, _omitFieldNames ? '' : 'summaryMarkdown')
    ..pc<$1.StringPair>(8, _omitFieldNames ? '' : 'tags', $pb.PbFieldType.PM, subBuilder: $1.StringPair.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Step clone() => Step()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Step copyWith(void Function(Step) updates) => super.copyWith((message) => updates(message as Step)) as Step;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Step create() => Step._();
  Step createEmptyInstance() => create();
  static $pb.PbList<Step> createRepeated() => $pb.PbList<Step>();
  @$core.pragma('dart2js:noInline')
  static Step getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Step>(create);
  static Step? _defaultInstance;

  ///  Name of the step, unique within the build.
  ///  Identifies the step.
  ///
  ///  Pipe character ("|") is reserved to separate parent and child step names.
  ///  For example, value "a|b" indicates step "b" under step "a".
  ///  If this is a child step, a parent MUST exist and MUST precede this step in
  ///  the list of steps.
  ///  All step names, including child and parent names recursively,
  ///  MUST NOT be an empty string.
  ///  For example, all of the below names are invalid.
  ///  - |a
  ///  - a|
  ///  - a||b
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  ///  The timestamp when the step started.
  ///
  ///  MUST NOT be specified, if status is SCHEDULED.
  ///  MUST be specified, if status is STARTED, SUCCESS, FAILURE, or INFRA_FAILURE
  ///  MAY be specified, if status is CANCELED.
  @$pb.TagNumber(2)
  $0.Timestamp get startTime => $_getN(1);
  @$pb.TagNumber(2)
  set startTime($0.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasStartTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartTime() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureStartTime() => $_ensure(1);

  /// The timestamp when the step ended.
  /// Present iff status is terminal.
  /// MUST NOT be before start_time.
  @$pb.TagNumber(3)
  $0.Timestamp get endTime => $_getN(2);
  @$pb.TagNumber(3)
  set endTime($0.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEndTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndTime() => clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureEndTime() => $_ensure(2);

  /// Status of the step.
  /// Must be specified, i.e. not STATUS_UNSPECIFIED.
  @$pb.TagNumber(4)
  $1.Status get status => $_getN(3);
  @$pb.TagNumber(4)
  set status($1.Status v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => clearField(4);

  ///  Logs produced by the step.
  ///  Log order is up to the step.
  ///
  ///  BigQuery: excluded from rows.
  @$pb.TagNumber(5)
  $core.List<$1.Log> get logs => $_getList(4);

  ///  MergeBuild is used for go.chromium.org/luci/luciexe to indicate to the
  ///  luciexe host process if some Build stream should be merged under this step.
  ///
  ///  BigQuery: excluded from rows.
  @$pb.TagNumber(6)
  Step_MergeBuild get mergeBuild => $_getN(5);
  @$pb.TagNumber(6)
  set mergeBuild(Step_MergeBuild v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasMergeBuild() => $_has(5);
  @$pb.TagNumber(6)
  void clearMergeBuild() => clearField(6);
  @$pb.TagNumber(6)
  Step_MergeBuild ensureMergeBuild() => $_ensure(5);

  ///  Human-readable summary of the step provided by the step itself,
  ///  in Markdown format (https://spec.commonmark.org/0.28/).
  ///
  ///  V1 equivalent: combines and supersedes Buildbot's step_text and step links and also supports
  ///  other formatted text.
  ///
  ///  BigQuery: excluded from rows.
  @$pb.TagNumber(7)
  $core.String get summaryMarkdown => $_getSZ(6);
  @$pb.TagNumber(7)
  set summaryMarkdown($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSummaryMarkdown() => $_has(6);
  @$pb.TagNumber(7)
  void clearSummaryMarkdown() => clearField(7);

  ///  Arbitrary annotations for the step.
  ///
  ///  One key may have multiple values, which is why this is not a map<string,string>.
  ///
  ///  These are NOT interpreted by Buildbucket.
  ///
  ///  Tag keys SHOULD indicate the domain/system that interprets them, e.g.:
  ///
  ///    my_service.category = COMPILE
  ///
  ///  Rather than
  ///
  ///    is_compile = true
  ///
  ///  This will help contextualize the tag values when looking at a build (who
  ///  set this tag? who will interpret this tag?))
  ///
  ///  The 'luci.' key prefix is reserved for LUCI's own usage.
  ///
  ///  The Key may not exceed 256 bytes.
  ///  The Value may not exceed 1024 bytes.
  ///
  ///  Key and Value may not be empty.
  @$pb.TagNumber(8)
  $core.List<$1.StringPair> get tags => $_getList(7);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
