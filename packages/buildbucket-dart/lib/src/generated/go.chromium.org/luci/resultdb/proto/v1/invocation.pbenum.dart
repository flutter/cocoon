///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Invocation_State extends $pb.ProtobufEnum {
  static const Invocation_State STATE_UNSPECIFIED =
      Invocation_State._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STATE_UNSPECIFIED');
  static const Invocation_State ACTIVE =
      Invocation_State._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ACTIVE');
  static const Invocation_State FINALIZING =
      Invocation_State._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FINALIZING');
  static const Invocation_State FINALIZED =
      Invocation_State._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FINALIZED');

  static const $core.List<Invocation_State> values = <Invocation_State>[
    STATE_UNSPECIFIED,
    ACTIVE,
    FINALIZING,
    FINALIZED,
  ];

  static final $core.Map<$core.int, Invocation_State> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Invocation_State? valueOf($core.int value) => _byValue[value];

  const Invocation_State._($core.int v, $core.String n) : super(v, n);
}
