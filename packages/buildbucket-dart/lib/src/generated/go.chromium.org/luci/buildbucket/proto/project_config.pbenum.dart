//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Toggle extends $pb.ProtobufEnum {
  static const Toggle UNSET = Toggle._(0, _omitEnumNames ? '' : 'UNSET');
  static const Toggle YES = Toggle._(1, _omitEnumNames ? '' : 'YES');
  static const Toggle NO = Toggle._(2, _omitEnumNames ? '' : 'NO');

  static const $core.List<Toggle> values = <Toggle> [
    UNSET,
    YES,
    NO,
  ];

  static final $core.Map<$core.int, Toggle> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Toggle? valueOf($core.int value) => _byValue[value];

  const Toggle._($core.int v, $core.String n) : super(v, n);
}

class Acl_Role extends $pb.ProtobufEnum {
  static const Acl_Role READER = Acl_Role._(0, _omitEnumNames ? '' : 'READER');
  static const Acl_Role SCHEDULER = Acl_Role._(1, _omitEnumNames ? '' : 'SCHEDULER');
  static const Acl_Role WRITER = Acl_Role._(2, _omitEnumNames ? '' : 'WRITER');

  static const $core.List<Acl_Role> values = <Acl_Role> [
    READER,
    SCHEDULER,
    WRITER,
  ];

  static final $core.Map<$core.int, Acl_Role> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Acl_Role? valueOf($core.int value) => _byValue[value];

  const Acl_Role._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
