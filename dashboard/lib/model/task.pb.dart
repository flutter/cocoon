//
//  Generated code. Do not modify.
//  source: lib/model/task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Task extends $pb.GeneratedMessage {
  factory Task({
    $0.RootKey? key,
    $0.RootKey? commitKey,
    $fixnum.Int64? createTimestamp,
    $fixnum.Int64? startTimestamp,
    $fixnum.Int64? endTimestamp,
    $core.String? name,
    $core.int? attempts,
    $core.bool? isFlaky,
    $core.int? timeoutInMinutes,
    $core.String? reason,
    $core.String? stageName,
    $core.String? status,
    $core.int? buildNumber,
    $core.String? buildNumberList,
    $core.String? luciBucket,
    $core.bool? isTestFlaky,
  }) {
    final $result = create();
    if (key != null) {
      $result.key = key;
    }
    if (commitKey != null) {
      $result.commitKey = commitKey;
    }
    if (createTimestamp != null) {
      $result.createTimestamp = createTimestamp;
    }
    if (startTimestamp != null) {
      $result.startTimestamp = startTimestamp;
    }
    if (endTimestamp != null) {
      $result.endTimestamp = endTimestamp;
    }
    if (name != null) {
      $result.name = name;
    }
    if (attempts != null) {
      $result.attempts = attempts;
    }
    if (isFlaky != null) {
      $result.isFlaky = isFlaky;
    }
    if (timeoutInMinutes != null) {
      $result.timeoutInMinutes = timeoutInMinutes;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    if (stageName != null) {
      $result.stageName = stageName;
    }
    if (status != null) {
      $result.status = status;
    }
    if (buildNumber != null) {
      $result.buildNumber = buildNumber;
    }
    if (buildNumberList != null) {
      $result.buildNumberList = buildNumberList;
    }
    if (luciBucket != null) {
      $result.luciBucket = luciBucket;
    }
    if (isTestFlaky != null) {
      $result.isTestFlaky = isTestFlaky;
    }
    return $result;
  }
  Task._() : super();
  factory Task.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Task.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Task',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'), createEmptyInstance: create)
    ..aOM<$0.RootKey>(1, _omitFieldNames ? '' : 'key', subBuilder: $0.RootKey.create)
    ..aOM<$0.RootKey>(2, _omitFieldNames ? '' : 'commitKey', subBuilder: $0.RootKey.create)
    ..aInt64(3, _omitFieldNames ? '' : 'createTimestamp')
    ..aInt64(4, _omitFieldNames ? '' : 'startTimestamp')
    ..aInt64(5, _omitFieldNames ? '' : 'endTimestamp')
    ..aOS(6, _omitFieldNames ? '' : 'name')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'attempts', $pb.PbFieldType.O3)
    ..aOB(8, _omitFieldNames ? '' : 'isFlaky')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'timeoutInMinutes', $pb.PbFieldType.O3)
    ..aOS(10, _omitFieldNames ? '' : 'reason')
    ..aOS(13, _omitFieldNames ? '' : 'stageName')
    ..aOS(14, _omitFieldNames ? '' : 'status')
    ..a<$core.int>(15, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3, protoName: 'buildNumber')
    ..aOS(16, _omitFieldNames ? '' : 'buildNumberList', protoName: 'buildNumberList')
    ..aOS(18, _omitFieldNames ? '' : 'luciBucket', protoName: 'luciBucket')
    ..aOB(19, _omitFieldNames ? '' : 'isTestFlaky')
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
  $0.RootKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($0.RootKey v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
  @$pb.TagNumber(1)
  $0.RootKey ensureKey() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.RootKey get commitKey => $_getN(1);
  @$pb.TagNumber(2)
  set commitKey($0.RootKey v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCommitKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommitKey() => clearField(2);
  @$pb.TagNumber(2)
  $0.RootKey ensureCommitKey() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createTimestamp($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCreateTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreateTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set startTimestamp($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasStartTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endTimestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set endTimestamp($fixnum.Int64 v) {
    $_setInt64(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasEndTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndTimestamp() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get name => $_getSZ(5);
  @$pb.TagNumber(6)
  set name($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasName() => $_has(5);
  @$pb.TagNumber(6)
  void clearName() => clearField(6);

  @$pb.TagNumber(7)
  $core.int get attempts => $_getIZ(6);
  @$pb.TagNumber(7)
  set attempts($core.int v) {
    $_setSignedInt32(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasAttempts() => $_has(6);
  @$pb.TagNumber(7)
  void clearAttempts() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isFlaky => $_getBF(7);
  @$pb.TagNumber(8)
  set isFlaky($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasIsFlaky() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsFlaky() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get timeoutInMinutes => $_getIZ(8);
  @$pb.TagNumber(9)
  set timeoutInMinutes($core.int v) {
    $_setSignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasTimeoutInMinutes() => $_has(8);
  @$pb.TagNumber(9)
  void clearTimeoutInMinutes() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get reason => $_getSZ(9);
  @$pb.TagNumber(10)
  set reason($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasReason() => $_has(9);
  @$pb.TagNumber(10)
  void clearReason() => clearField(10);

  @$pb.TagNumber(13)
  $core.String get stageName => $_getSZ(10);
  @$pb.TagNumber(13)
  set stageName($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasStageName() => $_has(10);
  @$pb.TagNumber(13)
  void clearStageName() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get status => $_getSZ(11);
  @$pb.TagNumber(14)
  set status($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasStatus() => $_has(11);
  @$pb.TagNumber(14)
  void clearStatus() => clearField(14);

  @$pb.TagNumber(15)
  $core.int get buildNumber => $_getIZ(12);
  @$pb.TagNumber(15)
  set buildNumber($core.int v) {
    $_setSignedInt32(12, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasBuildNumber() => $_has(12);
  @$pb.TagNumber(15)
  void clearBuildNumber() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get buildNumberList => $_getSZ(13);
  @$pb.TagNumber(16)
  set buildNumberList($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasBuildNumberList() => $_has(13);
  @$pb.TagNumber(16)
  void clearBuildNumberList() => clearField(16);

  @$pb.TagNumber(18)
  $core.String get luciBucket => $_getSZ(14);
  @$pb.TagNumber(18)
  set luciBucket($core.String v) {
    $_setString(14, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasLuciBucket() => $_has(14);
  @$pb.TagNumber(18)
  void clearLuciBucket() => clearField(18);

  @$pb.TagNumber(19)
  $core.bool get isTestFlaky => $_getBF(15);
  @$pb.TagNumber(19)
  set isTestFlaky($core.bool v) {
    $_setBool(15, v);
  }

  @$pb.TagNumber(19)
  $core.bool hasIsTestFlaky() => $_has(15);
  @$pb.TagNumber(19)
  void clearIsTestFlaky() => clearField(19);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
