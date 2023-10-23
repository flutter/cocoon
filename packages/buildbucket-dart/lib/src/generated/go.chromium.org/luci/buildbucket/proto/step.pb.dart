//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/step.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/timestamp.pb.dart' as $0;
import 'common.pb.dart' as $1;
import 'common.pbenum.dart' as $1;

class Step_MergeBuild extends $pb.GeneratedMessage {
  factory Step_MergeBuild() => create();
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

  @$pb.TagNumber(1)
  $core.String get fromLogdogStream => $_getSZ(0);
  @$pb.TagNumber(1)
  set fromLogdogStream($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFromLogdogStream() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromLogdogStream() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get legacyGlobalNamespace => $_getBF(1);
  @$pb.TagNumber(2)
  set legacyGlobalNamespace($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLegacyGlobalNamespace() => $_has(1);
  @$pb.TagNumber(2)
  void clearLegacyGlobalNamespace() => clearField(2);
}

class Step extends $pb.GeneratedMessage {
  factory Step() => create();
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

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

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

  @$pb.TagNumber(4)
  $1.Status get status => $_getN(3);
  @$pb.TagNumber(4)
  set status($1.Status v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$1.Log> get logs => $_getList(4);

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

  @$pb.TagNumber(7)
  $core.String get summaryMarkdown => $_getSZ(6);
  @$pb.TagNumber(7)
  set summaryMarkdown($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasSummaryMarkdown() => $_has(6);
  @$pb.TagNumber(7)
  void clearSummaryMarkdown() => clearField(7);

  @$pb.TagNumber(8)
  $core.List<$1.StringPair> get tags => $_getList(7);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
