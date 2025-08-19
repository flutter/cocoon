//
//  Generated code. Do not modify.
//  source: internal/scheduler.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Schedulers supported in SchedulerConfig.
/// Next ID: 5
class SchedulerSystem extends $pb.ProtobufEnum {
  static const SchedulerSystem cocoon =
      SchedulerSystem._(1, _omitEnumNames ? '' : 'cocoon');
  static const SchedulerSystem luci =
      SchedulerSystem._(2, _omitEnumNames ? '' : 'luci');
  static const SchedulerSystem google_internal =
      SchedulerSystem._(3, _omitEnumNames ? '' : 'google_internal');
  static const SchedulerSystem release =
      SchedulerSystem._(4, _omitEnumNames ? '' : 'release');

  static const $core.List<SchedulerSystem> values = <SchedulerSystem>[
    cocoon,
    luci,
    google_internal,
    release,
  ];

  static final $core.Map<$core.int, SchedulerSystem> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SchedulerSystem? valueOf($core.int value) => _byValue[value];

  const SchedulerSystem._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
