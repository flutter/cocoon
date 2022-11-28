///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Status extends $pb.ProtobufEnum {
  static const Status STATUS_UNSPECIFIED = Status._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STATUS_UNSPECIFIED');
  static const Status SCHEDULED = Status._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SCHEDULED');
  static const Status STARTED = Status._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'STARTED');
  static const Status ENDED_MASK = Status._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ENDED_MASK');
  static const Status SUCCESS = Status._(12, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'SUCCESS');
  static const Status FAILURE = Status._(20, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'FAILURE');
  static const Status INFRA_FAILURE = Status._(36, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'INFRA_FAILURE');
  static const Status CANCELED = Status._(68, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'CANCELED');

  static const $core.List<Status> values = <Status> [
    STATUS_UNSPECIFIED,
    SCHEDULED,
    STARTED,
    ENDED_MASK,
    SUCCESS,
    FAILURE,
    INFRA_FAILURE,
    CANCELED,
  ];

  static final $core.Map<$core.int, Status> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Status? valueOf($core.int value) => _byValue[value];

  const Status._($core.int v, $core.String n) : super(v, n);
}

class Trinary extends $pb.ProtobufEnum {
  static const Trinary UNSET = Trinary._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'UNSET');
  static const Trinary YES = Trinary._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'YES');
  static const Trinary NO = Trinary._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'NO');

  static const $core.List<Trinary> values = <Trinary> [
    UNSET,
    YES,
    NO,
  ];

  static final $core.Map<$core.int, Trinary> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Trinary? valueOf($core.int value) => _byValue[value];

  const Trinary._($core.int v, $core.String n) : super(v, n);
}

class Compression extends $pb.ProtobufEnum {
  static const Compression ZLIB = Compression._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ZLIB');
  static const Compression ZSTD = Compression._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ZSTD');

  static const $core.List<Compression> values = <Compression> [
    ZLIB,
    ZSTD,
  ];

  static final $core.Map<$core.int, Compression> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Compression? valueOf($core.int value) => _byValue[value];

  const Compression._($core.int v, $core.String n) : super(v, n);
}

