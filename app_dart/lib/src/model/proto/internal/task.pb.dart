///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/task.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Task extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Task', createEmptyInstance: create)
    ..aOM<$0.RootKey>(1, 'key', subBuilder: $0.RootKey.create)
    ..aOM<$0.RootKey>(2, 'commitKey', subBuilder: $0.RootKey.create)
    ..aInt64(3, 'createTimestamp')
    ..aInt64(4, 'startTimestamp')
    ..aInt64(5, 'endTimestamp')
    ..aOS(6, 'name')
    ..a<$core.int>(7, 'attempts', $pb.PbFieldType.O3)
    ..aOB(8, 'isFlaky')
    ..a<$core.int>(9, 'timeoutInMinutes', $pb.PbFieldType.O3)
    ..aOS(10, 'reason')
    ..pPS(11, 'requiredCapabilities')
    ..aOS(12, 'reservedForAgentId', protoName: 'reserved_for_agentId')
    ..aOS(13, 'stageName')
    ..aOS(14, 'status')
    ..a<$core.int>(15, 'buildNumber', $pb.PbFieldType.O3, protoName: 'buildNumber')
    ..aOS(16, 'buildNumberList', protoName: 'buildNumberList')
    ..aOS(17, 'builderName', protoName: 'builderName')
    ..aOS(18, 'luciBucket', protoName: 'luciBucket')
    ..hasRequiredFields = false;

  Task._() : super();
  factory Task() => create();
  factory Task.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Task.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @override
  @override
  @override
  Task clone() => Task()..mergeFromMessage(this);
  @override
  @override
  @override
  Task copyWith(void Function(Task) updates) => super.copyWith((message) => updates(message as Task));
  @override
  @override
  @override
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Task create() => Task._();
  @override
  @override
  @override
  Task createEmptyInstance() => create();
  static $pb.PbList<Task> createRepeated() => $pb.PbList<Task>();
  @$core.pragma('dart2js:noInline')
  static Task getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Task>(create);
  static Task _defaultInstance;

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

  @$pb.TagNumber(11)
  $core.List<$core.String> get requiredCapabilities => $_getList(10);

  @$pb.TagNumber(12)
  $core.String get reservedForAgentId => $_getSZ(11);
  @$pb.TagNumber(12)
  set reservedForAgentId($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasReservedForAgentId() => $_has(11);
  @$pb.TagNumber(12)
  void clearReservedForAgentId() => clearField(12);

  @$pb.TagNumber(13)
  $core.String get stageName => $_getSZ(12);
  @$pb.TagNumber(13)
  set stageName($core.String v) {
    $_setString(12, v);
  }

  @$pb.TagNumber(13)
  $core.bool hasStageName() => $_has(12);
  @$pb.TagNumber(13)
  void clearStageName() => clearField(13);

  @$pb.TagNumber(14)
  $core.String get status => $_getSZ(13);
  @$pb.TagNumber(14)
  set status($core.String v) {
    $_setString(13, v);
  }

  @$pb.TagNumber(14)
  $core.bool hasStatus() => $_has(13);
  @$pb.TagNumber(14)
  void clearStatus() => clearField(14);

  @$pb.TagNumber(15)
  $core.int get buildNumber => $_getIZ(14);
  @$pb.TagNumber(15)
  set buildNumber($core.int v) {
    $_setSignedInt32(14, v);
  }

  @$pb.TagNumber(15)
  $core.bool hasBuildNumber() => $_has(14);
  @$pb.TagNumber(15)
  void clearBuildNumber() => clearField(15);

  @$pb.TagNumber(16)
  $core.String get buildNumberList => $_getSZ(15);
  @$pb.TagNumber(16)
  set buildNumberList($core.String v) {
    $_setString(15, v);
  }

  @$pb.TagNumber(16)
  $core.bool hasBuildNumberList() => $_has(15);
  @$pb.TagNumber(16)
  void clearBuildNumberList() => clearField(16);

  @$pb.TagNumber(17)
  $core.String get builderName => $_getSZ(16);
  @$pb.TagNumber(17)
  set builderName($core.String v) {
    $_setString(16, v);
  }

  @$pb.TagNumber(17)
  $core.bool hasBuilderName() => $_has(16);
  @$pb.TagNumber(17)
  void clearBuilderName() => clearField(17);

  @$pb.TagNumber(18)
  $core.String get luciBucket => $_getSZ(17);
  @$pb.TagNumber(18)
  set luciBucket($core.String v) {
    $_setString(17, v);
  }

  @$pb.TagNumber(18)
  $core.bool hasLuciBucket() => $_has(17);
  @$pb.TagNumber(18)
  void clearLuciBucket() => clearField(18);
}
