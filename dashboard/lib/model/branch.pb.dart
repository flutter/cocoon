///
//  Generated code. Do not modify.
//  source: lib/model/branch.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Branch extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(const $core.bool.fromEnvironment('protobuf.omit_message_names') ? '' : 'Branch', createEmptyInstance: create)
    ..aOM<$0.RootKey>(1, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'key', subBuilder: $0.RootKey.create)
    ..aInt64(2, const $core.bool.fromEnvironment('protobuf.omit_field_names') ? '' : 'lastActivity', protoName: 'lastActivity')
    ..hasRequiredFields = false
  ;

  Branch._() : super();
  factory Branch({
    $0.RootKey? key,
    $fixnum.Int64? lastActivity,
  }) {
    final _result = create();
    if (key != null) {
      _result.key = key;
    }
    if (lastActivity != null) {
      _result.lastActivity = lastActivity;
    }
    return _result;
  }
  factory Branch.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Branch.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Branch clone() => Branch()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Branch copyWith(void Function(Branch) updates) => super.copyWith((message) => updates(message as Branch)) as Branch; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Branch create() => Branch._();
  Branch createEmptyInstance() => create();
  static $pb.PbList<Branch> createRepeated() => $pb.PbList<Branch>();
  @$core.pragma('dart2js:noInline')
  static Branch getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Branch>(create);
  static Branch? _defaultInstance;

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
  $fixnum.Int64 get lastActivity => $_getI64(1);
  @$pb.TagNumber(2)
  set lastActivity($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLastActivity() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastActivity() => clearField(2);
}

