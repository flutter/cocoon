///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/agent.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Agent extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Agent', createEmptyInstance: create)
    ..aOM<$0.RootKey>(1, 'key', subBuilder: $0.RootKey.create)
    ..aOS(2, 'agentId')
    ..aInt64(3, 'healthCheckTimestamp')
    ..aOB(4, 'isHealthy')
    ..aOB(5, 'isHidden')
    ..pPS(6, 'capabilities')
    ..aOS(7, 'healthDetails')
    ..aOS(8, 'authToken')
    ..hasRequiredFields = false
  ;

  Agent._() : super();
  factory Agent() => create();
  factory Agent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Agent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Agent clone() => Agent()..mergeFromMessage(this);
  Agent copyWith(void Function(Agent) updates) => super.copyWith((message) => updates(message as Agent));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Agent create() => Agent._();
  Agent createEmptyInstance() => create();
  static $pb.PbList<Agent> createRepeated() => $pb.PbList<Agent>();
  @$core.pragma('dart2js:noInline')
  static Agent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Agent>(create);
  static Agent _defaultInstance;

  @$pb.TagNumber(1)
  $0.RootKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($0.RootKey v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
  @$pb.TagNumber(1)
  $0.RootKey ensureKey() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get agentId => $_getSZ(1);
  @$pb.TagNumber(2)
  set agentId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAgentId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAgentId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get healthCheckTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set healthCheckTimestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHealthCheckTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearHealthCheckTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get isHealthy => $_getBF(3);
  @$pb.TagNumber(4)
  set isHealthy($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasIsHealthy() => $_has(3);
  @$pb.TagNumber(4)
  void clearIsHealthy() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isHidden => $_getBF(4);
  @$pb.TagNumber(5)
  set isHidden($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasIsHidden() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsHidden() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.String> get capabilities => $_getList(5);

  @$pb.TagNumber(7)
  $core.String get healthDetails => $_getSZ(6);
  @$pb.TagNumber(7)
  set healthDetails($core.String v) { $_setString(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasHealthDetails() => $_has(6);
  @$pb.TagNumber(7)
  void clearHealthDetails() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get authToken => $_getSZ(7);
  @$pb.TagNumber(8)
  set authToken($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasAuthToken() => $_has(7);
  @$pb.TagNumber(8)
  void clearAuthToken() => clearField(8);
}

