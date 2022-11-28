///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class BuildInfra_Buildbucket_ExperimentReason extends $pb.ProtobufEnum {
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_UNSET = BuildInfra_Buildbucket_ExperimentReason._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_UNSET');
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_GLOBAL_DEFAULT = BuildInfra_Buildbucket_ExperimentReason._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_GLOBAL_DEFAULT');
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_BUILDER_CONFIG = BuildInfra_Buildbucket_ExperimentReason._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_BUILDER_CONFIG');
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_GLOBAL_MINIMUM = BuildInfra_Buildbucket_ExperimentReason._(3, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_GLOBAL_MINIMUM');
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_REQUESTED = BuildInfra_Buildbucket_ExperimentReason._(4, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_REQUESTED');
  static const BuildInfra_Buildbucket_ExperimentReason EXPERIMENT_REASON_GLOBAL_INACTIVE = BuildInfra_Buildbucket_ExperimentReason._(5, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'EXPERIMENT_REASON_GLOBAL_INACTIVE');

  static const $core.List<BuildInfra_Buildbucket_ExperimentReason> values = <BuildInfra_Buildbucket_ExperimentReason> [
    EXPERIMENT_REASON_UNSET,
    EXPERIMENT_REASON_GLOBAL_DEFAULT,
    EXPERIMENT_REASON_BUILDER_CONFIG,
    EXPERIMENT_REASON_GLOBAL_MINIMUM,
    EXPERIMENT_REASON_REQUESTED,
    EXPERIMENT_REASON_GLOBAL_INACTIVE,
  ];

  static final $core.Map<$core.int, BuildInfra_Buildbucket_ExperimentReason> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BuildInfra_Buildbucket_ExperimentReason? valueOf($core.int value) => _byValue[value];

  const BuildInfra_Buildbucket_ExperimentReason._($core.int v, $core.String n) : super(v, n);
}

class BuildInfra_Buildbucket_Agent_Purpose extends $pb.ProtobufEnum {
  static const BuildInfra_Buildbucket_Agent_Purpose PURPOSE_UNSPECIFIED = BuildInfra_Buildbucket_Agent_Purpose._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PURPOSE_UNSPECIFIED');
  static const BuildInfra_Buildbucket_Agent_Purpose PURPOSE_EXE_PAYLOAD = BuildInfra_Buildbucket_Agent_Purpose._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PURPOSE_EXE_PAYLOAD');
  static const BuildInfra_Buildbucket_Agent_Purpose PURPOSE_BBAGENT_UTILITY = BuildInfra_Buildbucket_Agent_Purpose._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'PURPOSE_BBAGENT_UTILITY');

  static const $core.List<BuildInfra_Buildbucket_Agent_Purpose> values = <BuildInfra_Buildbucket_Agent_Purpose> [
    PURPOSE_UNSPECIFIED,
    PURPOSE_EXE_PAYLOAD,
    PURPOSE_BBAGENT_UTILITY,
  ];

  static final $core.Map<$core.int, BuildInfra_Buildbucket_Agent_Purpose> _byValue = $pb.ProtobufEnum.initByValue(values);
  static BuildInfra_Buildbucket_Agent_Purpose? valueOf($core.int value) => _byValue[value];

  const BuildInfra_Buildbucket_Agent_Purpose._($core.int v, $core.String n) : super(v, n);
}

