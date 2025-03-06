//
//  Generated code. Do not modify.
//  source: internal/build_status_response.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class EnumBuildStatus extends $pb.ProtobufEnum {
  static const EnumBuildStatus success =
      EnumBuildStatus._(1, _omitEnumNames ? '' : 'success');
  static const EnumBuildStatus failure =
      EnumBuildStatus._(2, _omitEnumNames ? '' : 'failure');

  static const $core.List<EnumBuildStatus> values = <EnumBuildStatus>[
    success,
    failure,
  ];

  static final $core.Map<$core.int, EnumBuildStatus> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static EnumBuildStatus? valueOf($core.int value) => _byValue[value];

  const EnumBuildStatus._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
