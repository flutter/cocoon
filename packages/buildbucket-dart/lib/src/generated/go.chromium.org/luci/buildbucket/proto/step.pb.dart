///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/step.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../../../google/protobuf/timestamp.pb.dart' as $0;
import 'common.pb.dart' as $1;

import 'common.pbenum.dart' as $1;

class Step_MergeBuild extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Step.MergeBuild',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'fromLogdogStream')
    ..aOB(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'legacyGlobalNamespace')
    ..hasRequiredFields = false;

  Step_MergeBuild._() : super();
  factory Step_MergeBuild({
    $core.String? fromLogdogStream,
    $core.bool? legacyGlobalNamespace,
  }) {
    final _result = create();
    if (fromLogdogStream != null) {
      _result.fromLogdogStream = fromLogdogStream;
    }
    if (legacyGlobalNamespace != null) {
      _result.legacyGlobalNamespace = legacyGlobalNamespace;
    }
    return _result;
  }
  factory Step_MergeBuild.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Step_MergeBuild.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Step_MergeBuild clone() => Step_MergeBuild()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Step_MergeBuild copyWith(void Function(Step_MergeBuild) updates) =>
      super.copyWith((message) => updates(message as Step_MergeBuild))
          as Step_MergeBuild; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Step_MergeBuild create() => Step_MergeBuild._();
  Step_MergeBuild createEmptyInstance() => create();
  static $pb.PbList<Step_MergeBuild> createRepeated() => $pb.PbList<Step_MergeBuild>();
  @$core.pragma('dart2js:noInline')
  static Step_MergeBuild getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Step_MergeBuild>(create);
  static Step_MergeBuild? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fromLogdogStream => $_getSZ(0);
  @$pb.TagNumber(1)
  set fromLogdogStream($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasFromLogdogStream() => $_has(0);
  @$pb.TagNumber(1)
  void clearFromLogdogStream() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get legacyGlobalNamespace => $_getBF(1);
  @$pb.TagNumber(2)
  set legacyGlobalNamespace($core.bool v) {
    $_setBool(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasLegacyGlobalNamespace() => $_has(1);
  @$pb.TagNumber(2)
  void clearLegacyGlobalNamespace() => clearField(2);
}

class Step extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Step',
      package: const $pb.PackageName(
          const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'buildbucket.v2'),
      createEmptyInstance: create)
    ..aOS(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'name')
    ..aOM<$0.Timestamp>(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'startTime',
        subBuilder: $0.Timestamp.create)
    ..aOM<$0.Timestamp>(3, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'endTime',
        subBuilder: $0.Timestamp.create)
    ..e<$1.Status>(4, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'status', $pb.PbFieldType.OE,
        defaultOrMaker: $1.Status.STATUS_UNSPECIFIED, valueOf: $1.Status.valueOf, enumValues: $1.Status.values)
    ..pc<$1.Log>(5, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'logs', $pb.PbFieldType.PM,
        subBuilder: $1.Log.create)
    ..aOM<Step_MergeBuild>(6, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'mergeBuild',
        subBuilder: Step_MergeBuild.create)
    ..aOS(7, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'summaryMarkdown')
    ..pc<$1.StringPair>(
        8, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'tags', $pb.PbFieldType.PM,
        subBuilder: $1.StringPair.create)
    ..hasRequiredFields = false;

  Step._() : super();
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
    final _result = create();
    if (name != null) {
      _result.name = name;
    }
    if (startTime != null) {
      _result.startTime = startTime;
    }
    if (endTime != null) {
      _result.endTime = endTime;
    }
    if (status != null) {
      _result.status = status;
    }
    if (logs != null) {
      _result.logs.addAll(logs);
    }
    if (mergeBuild != null) {
      _result.mergeBuild = mergeBuild;
    }
    if (summaryMarkdown != null) {
      _result.summaryMarkdown = summaryMarkdown;
    }
    if (tags != null) {
      _result.tags.addAll(tags);
    }
    return _result;
  }
  factory Step.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Step.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Step clone() => Step()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Step copyWith(void Function(Step) updates) =>
      super.copyWith((message) => updates(message as Step)) as Step; // ignore: deprecated_member_use
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
  set name($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  $0.Timestamp get startTime => $_getN(1);
  @$pb.TagNumber(2)
  set startTime($0.Timestamp v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasStartTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartTime() => clearField(2);
  @$pb.TagNumber(2)
  $0.Timestamp ensureStartTime() => $_ensure(1);

  @$pb.TagNumber(3)
  $0.Timestamp get endTime => $_getN(2);
  @$pb.TagNumber(3)
  set endTime($0.Timestamp v) {
    setField(3, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasEndTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndTime() => clearField(3);
  @$pb.TagNumber(3)
  $0.Timestamp ensureEndTime() => $_ensure(2);

  @$pb.TagNumber(4)
  $1.Status get status => $_getN(3);
  @$pb.TagNumber(4)
  set status($1.Status v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasStatus() => $_has(3);
  @$pb.TagNumber(4)
  void clearStatus() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$1.Log> get logs => $_getList(4);

  @$pb.TagNumber(6)
  Step_MergeBuild get mergeBuild => $_getN(5);
  @$pb.TagNumber(6)
  set mergeBuild(Step_MergeBuild v) {
    setField(6, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasMergeBuild() => $_has(5);
  @$pb.TagNumber(6)
  void clearMergeBuild() => clearField(6);
  @$pb.TagNumber(6)
  Step_MergeBuild ensureMergeBuild() => $_ensure(5);

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

  @$pb.TagNumber(8)
  $core.List<$1.StringPair> get tags => $_getList(7);
}
