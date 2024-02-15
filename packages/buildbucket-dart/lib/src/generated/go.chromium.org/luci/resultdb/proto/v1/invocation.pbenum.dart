//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Invocation_State extends $pb.ProtobufEnum {
  static const Invocation_State STATE_UNSPECIFIED = Invocation_State._(0, _omitEnumNames ? '' : 'STATE_UNSPECIFIED');
  static const Invocation_State ACTIVE = Invocation_State._(1, _omitEnumNames ? '' : 'ACTIVE');
  static const Invocation_State FINALIZING = Invocation_State._(2, _omitEnumNames ? '' : 'FINALIZING');
  static const Invocation_State FINALIZED = Invocation_State._(3, _omitEnumNames ? '' : 'FINALIZED');

  static const $core.List<Invocation_State> values = <Invocation_State> [
    STATE_UNSPECIFIED,
    ACTIVE,
    FINALIZING,
    FINALIZED,
  ];

  static final $core.Map<$core.int, Invocation_State> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Invocation_State? valueOf($core.int value) => _byValue[value];

  const Invocation_State._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
