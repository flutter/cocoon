///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/scheduler.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use schedulerSystemDescriptor instead')
const SchedulerSystem$json = const {
  '1': 'SchedulerSystem',
  '2': const [
    const {'1': 'cocoon', '2': 1},
    const {'1': 'luci', '2': 2},
    const {'1': 'google_internal', '2': 3},
    const {'1': 'release', '2': 4},
  ],
};

/// Descriptor for `SchedulerSystem`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List schedulerSystemDescriptor = $convert.base64Decode(
    'Cg9TY2hlZHVsZXJTeXN0ZW0SCgoGY29jb29uEAESCAoEbHVjaRACEhMKD2dvb2dsZV9pbnRlcm5hbBADEgsKB3JlbGVhc2UQBA==');
@$core.Deprecated('Use schedulerConfigDescriptor instead')
const SchedulerConfig$json = const {
  '1': 'SchedulerConfig',
  '2': const [
    const {'1': 'targets', '3': 1, '4': 3, '5': 11, '6': '.scheduler.Target', '10': 'targets'},
    const {'1': 'enabled_branches', '3': 2, '4': 3, '5': 9, '10': 'enabledBranches'},
    const {
      '1': 'platform_properties',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.scheduler.SchedulerConfig.PlatformPropertiesEntry',
      '10': 'platformProperties'
    },
  ],
  '3': const [SchedulerConfig_PlatformPropertiesEntry$json, SchedulerConfig_PlatformProperties$json],
};

@$core.Deprecated('Use schedulerConfigDescriptor instead')
const SchedulerConfig_PlatformPropertiesEntry$json = const {
  '1': 'PlatformPropertiesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.scheduler.SchedulerConfig.PlatformProperties', '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use schedulerConfigDescriptor instead')
const SchedulerConfig_PlatformProperties$json = const {
  '1': 'PlatformProperties',
  '2': const [
    const {
      '1': 'properties',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.scheduler.SchedulerConfig.PlatformProperties.PropertiesEntry',
      '10': 'properties'
    },
    const {
      '1': 'dimensions',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.scheduler.SchedulerConfig.PlatformProperties.DimensionsEntry',
      '10': 'dimensions'
    },
  ],
  '3': const [
    SchedulerConfig_PlatformProperties_PropertiesEntry$json,
    SchedulerConfig_PlatformProperties_DimensionsEntry$json
  ],
};

@$core.Deprecated('Use schedulerConfigDescriptor instead')
const SchedulerConfig_PlatformProperties_PropertiesEntry$json = const {
  '1': 'PropertiesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use schedulerConfigDescriptor instead')
const SchedulerConfig_PlatformProperties_DimensionsEntry$json = const {
  '1': 'DimensionsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `SchedulerConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List schedulerConfigDescriptor = $convert.base64Decode(
    'Cg9TY2hlZHVsZXJDb25maWcSKwoHdGFyZ2V0cxgBIAMoCzIRLnNjaGVkdWxlci5UYXJnZXRSB3RhcmdldHMSKQoQZW5hYmxlZF9icmFuY2hlcxgCIAMoCVIPZW5hYmxlZEJyYW5jaGVzEmMKE3BsYXRmb3JtX3Byb3BlcnRpZXMYAyADKAsyMi5zY2hlZHVsZXIuU2NoZWR1bGVyQ29uZmlnLlBsYXRmb3JtUHJvcGVydGllc0VudHJ5UhJwbGF0Zm9ybVByb3BlcnRpZXMadAoXUGxhdGZvcm1Qcm9wZXJ0aWVzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSQwoFdmFsdWUYAiABKAsyLS5zY2hlZHVsZXIuU2NoZWR1bGVyQ29uZmlnLlBsYXRmb3JtUHJvcGVydGllc1IFdmFsdWU6AjgBGtACChJQbGF0Zm9ybVByb3BlcnRpZXMSXQoKcHJvcGVydGllcxgBIAMoCzI9LnNjaGVkdWxlci5TY2hlZHVsZXJDb25maWcuUGxhdGZvcm1Qcm9wZXJ0aWVzLlByb3BlcnRpZXNFbnRyeVIKcHJvcGVydGllcxJdCgpkaW1lbnNpb25zGAIgAygLMj0uc2NoZWR1bGVyLlNjaGVkdWxlckNvbmZpZy5QbGF0Zm9ybVByb3BlcnRpZXMuRGltZW5zaW9uc0VudHJ5UgpkaW1lbnNpb25zGj0KD1Byb3BlcnRpZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj0KD0RpbWVuc2lvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB');
@$core.Deprecated('Use targetDescriptor instead')
const Target$json = const {
  '1': 'Target',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'dependencies', '3': 2, '4': 3, '5': 9, '10': 'dependencies'},
    const {'1': 'bringup', '3': 3, '4': 1, '5': 8, '7': 'false', '10': 'bringup'},
    const {'1': 'timeout', '3': 4, '4': 1, '5': 5, '7': '30', '10': 'timeout'},
    const {'1': 'testbed', '3': 5, '4': 1, '5': 9, '7': 'linux-vm', '10': 'testbed'},
    const {'1': 'properties', '3': 6, '4': 3, '5': 11, '6': '.scheduler.Target.PropertiesEntry', '10': 'properties'},
    const {
      '1': 'builder',
      '3': 7,
      '4': 1,
      '5': 9,
      '8': const {'3': true},
      '10': 'builder',
    },
    const {
      '1': 'scheduler',
      '3': 8,
      '4': 1,
      '5': 14,
      '6': '.scheduler.SchedulerSystem',
      '7': 'cocoon',
      '10': 'scheduler'
    },
    const {'1': 'presubmit', '3': 9, '4': 1, '5': 8, '7': 'true', '10': 'presubmit'},
    const {'1': 'postsubmit', '3': 10, '4': 1, '5': 8, '7': 'true', '10': 'postsubmit'},
    const {'1': 'run_if', '3': 11, '4': 3, '5': 9, '10': 'runIf'},
    const {'1': 'enabled_branches', '3': 12, '4': 3, '5': 9, '10': 'enabledBranches'},
    const {'1': 'recipe', '3': 13, '4': 1, '5': 9, '10': 'recipe'},
    const {
      '1': 'postsubmit_properties',
      '3': 15,
      '4': 3,
      '5': 11,
      '6': '.scheduler.Target.PostsubmitPropertiesEntry',
      '10': 'postsubmitProperties'
    },
    const {'1': 'dimensions', '3': 16, '4': 3, '5': 11, '6': '.scheduler.Target.DimensionsEntry', '10': 'dimensions'},
    const {'1': 'drone_dimensions', '3': 17, '4': 3, '5': 9, '10': 'droneDimensions'},
    const {'1': 'run_if_not', '3': 18, '4': 3, '5': 9, '10': 'runIfNot'},
  ],
  '3': const [Target_PropertiesEntry$json, Target_PostsubmitPropertiesEntry$json, Target_DimensionsEntry$json],
  '9': const [
    const {'1': 14, '2': 15},
  ],
};

@$core.Deprecated('Use targetDescriptor instead')
const Target_PropertiesEntry$json = const {
  '1': 'PropertiesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use targetDescriptor instead')
const Target_PostsubmitPropertiesEntry$json = const {
  '1': 'PostsubmitPropertiesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use targetDescriptor instead')
const Target_DimensionsEntry$json = const {
  '1': 'DimensionsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Target`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List targetDescriptor = $convert.base64Decode(
    'CgZUYXJnZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIiCgxkZXBlbmRlbmNpZXMYAiADKAlSDGRlcGVuZGVuY2llcxIfCgdicmluZ3VwGAMgASgIOgVmYWxzZVIHYnJpbmd1cBIcCgd0aW1lb3V0GAQgASgFOgIzMFIHdGltZW91dBIiCgd0ZXN0YmVkGAUgASgJOghsaW51eC12bVIHdGVzdGJlZBJBCgpwcm9wZXJ0aWVzGAYgAygLMiEuc2NoZWR1bGVyLlRhcmdldC5Qcm9wZXJ0aWVzRW50cnlSCnByb3BlcnRpZXMSHAoHYnVpbGRlchgHIAEoCUICGAFSB2J1aWxkZXISQAoJc2NoZWR1bGVyGAggASgOMhouc2NoZWR1bGVyLlNjaGVkdWxlclN5c3RlbToGY29jb29uUglzY2hlZHVsZXISIgoJcHJlc3VibWl0GAkgASgIOgR0cnVlUglwcmVzdWJtaXQSJAoKcG9zdHN1Ym1pdBgKIAEoCDoEdHJ1ZVIKcG9zdHN1Ym1pdBIVCgZydW5faWYYCyADKAlSBXJ1bklmEikKEGVuYWJsZWRfYnJhbmNoZXMYDCADKAlSD2VuYWJsZWRCcmFuY2hlcxIWCgZyZWNpcGUYDSABKAlSBnJlY2lwZRJgChVwb3N0c3VibWl0X3Byb3BlcnRpZXMYDyADKAsyKy5zY2hlZHVsZXIuVGFyZ2V0LlBvc3RzdWJtaXRQcm9wZXJ0aWVzRW50cnlSFHBvc3RzdWJtaXRQcm9wZXJ0aWVzEkEKCmRpbWVuc2lvbnMYECADKAsyIS5zY2hlZHVsZXIuVGFyZ2V0LkRpbWVuc2lvbnNFbnRyeVIKZGltZW5zaW9ucxIpChBkcm9uZV9kaW1lbnNpb25zGBEgAygJUg9kcm9uZURpbWVuc2lvbnMSHAoKcnVuX2lmX25vdBgSIAMoCVIIcnVuSWZOb3QaPQoPUHJvcGVydGllc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaRwoZUG9zdHN1Ym1pdFByb3BlcnRpZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBGj0KD0RpbWVuc2lvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgBSgQIDhAP');
