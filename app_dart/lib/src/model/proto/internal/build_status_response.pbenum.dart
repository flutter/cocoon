///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/build_status_response.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class EnumBuildStatus extends $pb.ProtobufEnum {
  static const EnumBuildStatus success =
      EnumBuildStatus._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'success');
  static const EnumBuildStatus failure =
      EnumBuildStatus._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'failure');

  static const $core.List<EnumBuildStatus> values = <EnumBuildStatus>[
    success,
    failure,
  ];

  static final $core.Map<$core.int, EnumBuildStatus> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EnumBuildStatus? valueOf($core.int value) => _byValue[value];

  const EnumBuildStatus._($core.int v, $core.String n) : super(v, n);
}
