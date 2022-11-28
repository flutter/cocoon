///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Toggle extends $pb.ProtobufEnum {
  static const Toggle UNSET = Toggle._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNSET');
  static const Toggle YES = Toggle._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'YES');
  static const Toggle NO = Toggle._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NO');

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
  static const Acl_Role READER = Acl_Role._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'READER');
  static const Acl_Role SCHEDULER = Acl_Role._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SCHEDULER');
  static const Acl_Role WRITER = Acl_Role._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'WRITER');

  static const $core.List<Acl_Role> values = <Acl_Role> [
    READER,
    SCHEDULER,
    WRITER,
  ];

  static final $core.Map<$core.int, Acl_Role> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Acl_Role? valueOf($core.int value) => _byValue[value];

  const Acl_Role._($core.int v, $core.String n) : super(v, n);
}

