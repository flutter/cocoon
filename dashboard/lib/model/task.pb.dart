//
//  Generated code. Do not modify.
//  source: task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Task extends $pb.GeneratedMessage {
  factory Task({
    $fixnum.Int64? createTimestamp,
    $fixnum.Int64? startTimestamp,
    $fixnum.Int64? endTimestamp,
    $core.int? attempts,
    $core.bool? isFlaky,
    $core.String? status,
    $core.String? buildNumberList,
    $core.String? builderName,
  }) {
    final $result = create();
    if (createTimestamp != null) {
      $result.createTimestamp = createTimestamp;
    }
    if (startTimestamp != null) {
      $result.startTimestamp = startTimestamp;
    }
    if (endTimestamp != null) {
      $result.endTimestamp = endTimestamp;
    }
    if (attempts != null) {
      $result.attempts = attempts;
    }
    if (isFlaky != null) {
      $result.isFlaky = isFlaky;
    }
    if (status != null) {
      $result.status = status;
    }
    if (buildNumberList != null) {
      $result.buildNumberList = buildNumberList;
    }
    if (builderName != null) {
      $result.builderName = builderName;
    }
    return $result;
  }
  Task._() : super();
  factory Task.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Task.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Task', package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'), createEmptyInstance: create)
    ..aInt64(3, _omitFieldNames ? '' : 'createTimestamp')
    ..aInt64(4, _omitFieldNames ? '' : 'startTimestamp')
    ..aInt64(5, _omitFieldNames ? '' : 'endTimestamp')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'attempts', $pb.PbFieldType.O3)
    ..aOB(8, _omitFieldNames ? '' : 'isFlaky')
    ..aOS(14, _omitFieldNames ? '' : 'status')
    ..aOS(16, _omitFieldNames ? '' : 'buildNumberList', protoName: 'buildNumberList')
    ..aOS(17, _omitFieldNames ? '' : 'builderName', protoName: 'builderName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Task clone() => Task()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
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

  @$pb.TagNumber(3)
  $fixnum.Int64 get createTimestamp => $_getI64(0);
  @$pb.TagNumber(3)
  set createTimestamp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasCreateTimestamp() => $_has(0);
  @$pb.TagNumber(3)
  void clearCreateTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimestamp => $_getI64(1);
  @$pb.TagNumber(4)
  set startTimestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(4)
  $core.bool hasStartTimestamp() => $_has(1);
  @$pb.TagNumber(4)
  void clearStartTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimestamp => $_getI64(2);
  @$pb.TagNumber(5)
  set endTimestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(5)
  $core.bool hasEndTimestamp() => $_has(2);
  @$pb.TagNumber(5)
  void clearEndTimestamp() => clearField(5);

  @$pb.TagNumber(7)
  $core.int get attempts => $_getIZ(3);
  @$pb.TagNumber(7)
  set attempts($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(7)
  $core.bool hasAttempts() => $_has(3);
  @$pb.TagNumber(7)
  void clearAttempts() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isFlaky => $_getBF(4);
  @$pb.TagNumber(8)
  set isFlaky($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsFlaky() => $_has(4);
  @$pb.TagNumber(8)
  void clearIsFlaky() => clearField(8);

  @$pb.TagNumber(14)
  $core.String get status => $_getSZ(5);
  @$pb.TagNumber(14)
  set status($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(14)
  $core.bool hasStatus() => $_has(5);
  @$pb.TagNumber(14)
  void clearStatus() => clearField(14);

  @$pb.TagNumber(16)
  $core.String get buildNumberList => $_getSZ(6);
  @$pb.TagNumber(16)
  set buildNumberList($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(16)
  $core.bool hasBuildNumberList() => $_has(6);
  @$pb.TagNumber(16)
  void clearBuildNumberList() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get builderName => $_getSZ(7);
  @$pb.TagNumber(17)
  set builderName($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(17)
  $core.bool hasBuilderName() => $_has(7);
  @$pb.TagNumber(17)
  void clearBuilderName() => clearField(17);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
