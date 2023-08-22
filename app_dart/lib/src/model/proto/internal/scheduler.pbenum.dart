///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/scheduler.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class SchedulerSystem extends $pb.ProtobufEnum {
  static const SchedulerSystem cocoon =
      SchedulerSystem._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'cocoon');
  static const SchedulerSystem luci =
      SchedulerSystem._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'luci');
  static const SchedulerSystem google_internal =
      SchedulerSystem._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'google_internal');
  static const SchedulerSystem release =
      SchedulerSystem._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'release');

  static const $core.List<SchedulerSystem> values = <SchedulerSystem>[
    cocoon,
    luci,
    google_internal,
    release,
  ];

  static final $core.Map<$core.int, SchedulerSystem> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SchedulerSystem? valueOf($core.int value) => _byValue[value];

  const SchedulerSystem._($core.int v, $core.String n) : super(v, n);
}
