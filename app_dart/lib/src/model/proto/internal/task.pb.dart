///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/task.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Task extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Task')
    ..a<$0.RootKey>(1, 'key', $pb.PbFieldType.OM, $0.RootKey.getDefault, $0.RootKey.create)
    ..a<$0.RootKey>(2, 'commitKey', $pb.PbFieldType.OM, $0.RootKey.getDefault, $0.RootKey.create)
    ..aInt64(3, 'createTimestamp')
    ..aInt64(4, 'startTimestamp')
    ..aInt64(5, 'endTimestamp')
    ..aOS(6, 'name')
    ..a<$core.int>(7, 'attempts', $pb.PbFieldType.O3)
    ..aOB(8, 'isFlaky')
    ..a<$core.int>(9, 'timeoutInMinutes', $pb.PbFieldType.O3)
    ..aOS(10, 'reason')
    ..pPS(11, 'requiredCapabilities')
    ..aOS(12, 'reservedForAgentId')
    ..aOS(13, 'stageName')
    ..aOS(14, 'status')
    ..hasRequiredFields = false
  ;

  Task._() : super();
  factory Task() => create();
  factory Task.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Task.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Task clone() => Task()..mergeFromMessage(this);
  Task copyWith(void Function(Task) updates) => super.copyWith((message) => updates(message as Task));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Task create() => Task._();
  Task createEmptyInstance() => create();
  static $pb.PbList<Task> createRepeated() => $pb.PbList<Task>();
  static Task getDefault() => _defaultInstance ??= create()..freeze();
  static Task _defaultInstance;

  $0.RootKey get key => $_getN(0);
  set key($0.RootKey v) { setField(1, v); }
  $core.bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  $0.RootKey get commitKey => $_getN(1);
  set commitKey($0.RootKey v) { setField(2, v); }
  $core.bool hasCommitKey() => $_has(1);
  void clearCommitKey() => clearField(2);

  Int64 get createTimestamp => $_getI64(2);
  set createTimestamp(Int64 v) { $_setInt64(2, v); }
  $core.bool hasCreateTimestamp() => $_has(2);
  void clearCreateTimestamp() => clearField(3);

  Int64 get startTimestamp => $_getI64(3);
  set startTimestamp(Int64 v) { $_setInt64(3, v); }
  $core.bool hasStartTimestamp() => $_has(3);
  void clearStartTimestamp() => clearField(4);

  Int64 get endTimestamp => $_getI64(4);
  set endTimestamp(Int64 v) { $_setInt64(4, v); }
  $core.bool hasEndTimestamp() => $_has(4);
  void clearEndTimestamp() => clearField(5);

  $core.String get name => $_getS(5, '');
  set name($core.String v) { $_setString(5, v); }
  $core.bool hasName() => $_has(5);
  void clearName() => clearField(6);

  $core.int get attempts => $_get(6, 0);
  set attempts($core.int v) { $_setSignedInt32(6, v); }
  $core.bool hasAttempts() => $_has(6);
  void clearAttempts() => clearField(7);

  $core.bool get isFlaky => $_get(7, false);
  set isFlaky($core.bool v) { $_setBool(7, v); }
  $core.bool hasIsFlaky() => $_has(7);
  void clearIsFlaky() => clearField(8);

  $core.int get timeoutInMinutes => $_get(8, 0);
  set timeoutInMinutes($core.int v) { $_setSignedInt32(8, v); }
  $core.bool hasTimeoutInMinutes() => $_has(8);
  void clearTimeoutInMinutes() => clearField(9);

  $core.String get reason => $_getS(9, '');
  set reason($core.String v) { $_setString(9, v); }
  $core.bool hasReason() => $_has(9);
  void clearReason() => clearField(10);

  $core.List<$core.String> get requiredCapabilities => $_getList(10);

  $core.String get reservedForAgentId => $_getS(11, '');
  set reservedForAgentId($core.String v) { $_setString(11, v); }
  $core.bool hasReservedForAgentId() => $_has(11);
  void clearReservedForAgentId() => clearField(12);

  $core.String get stageName => $_getS(12, '');
  set stageName($core.String v) { $_setString(12, v); }
  $core.bool hasStageName() => $_has(12);
  void clearStageName() => clearField(13);

  $core.String get status => $_getS(13, '');
  set status($core.String v) { $_setString(13, v); }
  $core.bool hasStatus() => $_has(13);
  void clearStatus() => clearField(14);
}

