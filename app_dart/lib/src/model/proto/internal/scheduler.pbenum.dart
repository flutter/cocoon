///
//  Generated code. Do not modify.
//  source: scheduler.proto
//
// @dart = 2.7
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class Pool extends $pb.ProtobufEnum {
  static const Pool prod = Pool._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'prod');
  static const Pool test = Pool._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'test');
  static const Pool staging = Pool._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'staging');

  static const $core.List<Pool> values = <Pool>[
    prod,
    test,
    staging,
  ];

  static final $core.Map<$core.int, Pool> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Pool valueOf($core.int value) => _byValue[value];

  const Pool._($core.int v, $core.String n) : super(v, n);
}

class SchedulerSystem extends $pb.ProtobufEnum {
  static const SchedulerSystem cocoon =
      SchedulerSystem._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'cocoon');
  static const SchedulerSystem luci =
      SchedulerSystem._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'luci');

  static const $core.List<SchedulerSystem> values = <SchedulerSystem>[
    cocoon,
    luci,
  ];

  static final $core.Map<$core.int, SchedulerSystem> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SchedulerSystem valueOf($core.int value) => _byValue[value];

  const SchedulerSystem._($core.int v, $core.String n) : super(v, n);
}
