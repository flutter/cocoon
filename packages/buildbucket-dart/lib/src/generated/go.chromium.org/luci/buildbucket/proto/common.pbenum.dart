//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Status of a build or a step.
class Status extends $pb.ProtobufEnum {
  static const Status STATUS_UNSPECIFIED = Status._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const Status SCHEDULED = Status._(1, _omitEnumNames ? '' : 'SCHEDULED');
  static const Status STARTED = Status._(2, _omitEnumNames ? '' : 'STARTED');
  static const Status ENDED_MASK = Status._(4, _omitEnumNames ? '' : 'ENDED_MASK');
  static const Status SUCCESS = Status._(12, _omitEnumNames ? '' : 'SUCCESS');
  static const Status FAILURE = Status._(20, _omitEnumNames ? '' : 'FAILURE');
  static const Status INFRA_FAILURE = Status._(36, _omitEnumNames ? '' : 'INFRA_FAILURE');
  static const Status CANCELED = Status._(68, _omitEnumNames ? '' : 'CANCELED');

  static const $core.List<Status> values = <Status>[
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

/// A boolean with an undefined value.
class Trinary extends $pb.ProtobufEnum {
  static const Trinary UNSET = Trinary._(0, _omitEnumNames ? '' : 'UNSET');
  static const Trinary YES = Trinary._(1, _omitEnumNames ? '' : 'YES');
  static const Trinary NO = Trinary._(2, _omitEnumNames ? '' : 'NO');

  static const $core.List<Trinary> values = <Trinary>[
    UNSET,
    YES,
    NO,
  ];

  static final $core.Map<$core.int, Trinary> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Trinary? valueOf($core.int value) => _byValue[value];

  const Trinary._($core.int v, $core.String n) : super(v, n);
}

/// Compression method used in the corresponding data.
class Compression extends $pb.ProtobufEnum {
  static const Compression ZLIB = Compression._(0, _omitEnumNames ? '' : 'ZLIB');
  static const Compression ZSTD = Compression._(1, _omitEnumNames ? '' : 'ZSTD');

  static const $core.List<Compression> values = <Compression>[
    ZLIB,
    ZSTD,
  ];

  static final $core.Map<$core.int, Compression> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Compression? valueOf($core.int value) => _byValue[value];

  const Compression._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
