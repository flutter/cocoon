///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use toggleDescriptor instead')
const Toggle$json = const {
  '1': 'Toggle',
  '2': const [
    const {'1': 'UNSET', '2': 0},
    const {'1': 'YES', '2': 1},
    const {'1': 'NO', '2': 2},
  ],
};

/// Descriptor for `Toggle`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List toggleDescriptor = $convert.base64Decode('CgZUb2dnbGUSCQoFVU5TRVQQABIHCgNZRVMQARIGCgJOTxAC');
@$core.Deprecated('Use aclDescriptor instead')
const Acl$json = const {
  '1': 'Acl',
  '2': const [
    const {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.buildbucket.Acl.Role',
      '8': const {'3': true},
      '10': 'role',
    },
    const {
      '1': 'group',
      '3': 2,
      '4': 1,
      '5': 9,
      '8': const {'3': true},
      '10': 'group',
    },
    const {
      '1': 'identity',
      '3': 3,
      '4': 1,
      '5': 9,
      '8': const {'3': true},
      '10': 'identity',
    },
  ],
  '4': const [Acl_Role$json],
};

@$core.Deprecated('Use aclDescriptor instead')
const Acl_Role$json = const {
  '1': 'Role',
  '2': const [
    const {'1': 'READER', '2': 0},
    const {'1': 'SCHEDULER', '2': 1},
    const {'1': 'WRITER', '2': 2},
  ],
};

/// Descriptor for `Acl`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aclDescriptor = $convert.base64Decode('CgNBY2wSLQoEcm9sZRgBIAEoDjIVLmJ1aWxkYnVja2V0LkFjbC5Sb2xlQgIYAVIEcm9sZRIYCgVncm91cBgCIAEoCUICGAFSBWdyb3VwEh4KCGlkZW50aXR5GAMgASgJQgIYAVIIaWRlbnRpdHkiLQoEUm9sZRIKCgZSRUFERVIQABINCglTQ0hFRFVMRVIQARIKCgZXUklURVIQAg==');
@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig$json = const {
  '1': 'BuilderConfig',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'backend', '3': 32, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Backend', '10': 'backend'},
    const {'1': 'backend_alt', '3': 33, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Backend', '10': 'backendAlt'},
    const {'1': 'swarming_host', '3': 21, '4': 1, '5': 9, '10': 'swarmingHost'},
    const {'1': 'category', '3': 6, '4': 1, '5': 9, '10': 'category'},
    const {'1': 'swarming_tags', '3': 2, '4': 3, '5': 9, '10': 'swarmingTags'},
    const {'1': 'dimensions', '3': 3, '4': 3, '5': 9, '10': 'dimensions'},
    const {'1': 'recipe', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Recipe', '10': 'recipe'},
    const {'1': 'exe', '3': 23, '4': 1, '5': 11, '6': '.buildbucket.v2.Executable', '10': 'exe'},
    const {'1': 'properties', '3': 24, '4': 1, '5': 9, '8': const {}, '10': 'properties'},
    const {'1': 'allowed_property_overrides', '3': 34, '4': 3, '5': 9, '10': 'allowedPropertyOverrides'},
    const {'1': 'priority', '3': 5, '4': 1, '5': 13, '10': 'priority'},
    const {'1': 'execution_timeout_secs', '3': 7, '4': 1, '5': 13, '10': 'executionTimeoutSecs'},
    const {'1': 'expiration_secs', '3': 20, '4': 1, '5': 13, '10': 'expirationSecs'},
    const {'1': 'grace_period', '3': 31, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'gracePeriod'},
    const {'1': 'wait_for_capacity', '3': 29, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'waitForCapacity'},
    const {'1': 'caches', '3': 9, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.CacheEntry', '10': 'caches'},
    const {'1': 'build_numbers', '3': 16, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'buildNumbers'},
    const {'1': 'service_account', '3': 12, '4': 1, '5': 9, '10': 'serviceAccount'},
    const {'1': 'auto_builder_dimension', '3': 17, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'autoBuilderDimension'},
    const {'1': 'experimental', '3': 18, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'experimental'},
    const {'1': 'task_template_canary_percentage', '3': 22, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'taskTemplateCanaryPercentage'},
    const {'1': 'experiments', '3': 28, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.ExperimentsEntry', '10': 'experiments'},
    const {'1': 'critical', '3': 25, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'critical'},
    const {'1': 'resultdb', '3': 26, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.ResultDB', '10': 'resultdb'},
    const {'1': 'description_html', '3': 30, '4': 1, '5': 9, '10': 'descriptionHtml'},
  ],
  '3': const [BuilderConfig_CacheEntry$json, BuilderConfig_Recipe$json, BuilderConfig_ResultDB$json, BuilderConfig_Backend$json, BuilderConfig_ExperimentsEntry$json],
  '9': const [
    const {'1': 8, '2': 9},
    const {'1': 11, '2': 12},
    const {'1': 13, '2': 14},
    const {'1': 15, '2': 16},
    const {'1': 19, '2': 20},
    const {'1': 27, '2': 28},
    const {'1': 10, '2': 11},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_CacheEntry$json = const {
  '1': 'CacheEntry',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    const {'1': 'wait_for_warm_cache_secs', '3': 3, '4': 1, '5': 5, '10': 'waitForWarmCacheSecs'},
    const {'1': 'env_var', '3': 4, '4': 1, '5': 9, '10': 'envVar'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_Recipe$json = const {
  '1': 'Recipe',
  '2': const [
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'cipd_package', '3': 6, '4': 1, '5': 9, '10': 'cipdPackage'},
    const {'1': 'cipd_version', '3': 5, '4': 1, '5': 9, '10': 'cipdVersion'},
    const {'1': 'properties', '3': 3, '4': 3, '5': 9, '10': 'properties'},
    const {'1': 'properties_j', '3': 4, '4': 3, '5': 9, '10': 'propertiesJ'},
  ],
  '9': const [
    const {'1': 1, '2': 2},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_ResultDB$json = const {
  '1': 'ResultDB',
  '2': const [
    const {'1': 'enable', '3': 1, '4': 1, '5': 8, '10': 'enable'},
    const {'1': 'bq_exports', '3': 2, '4': 3, '5': 11, '6': '.luci.resultdb.v1.BigQueryExport', '10': 'bqExports'},
    const {'1': 'history_options', '3': 3, '4': 1, '5': 11, '6': '.luci.resultdb.v1.HistoryOptions', '10': 'historyOptions'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_Backend$json = const {
  '1': 'Backend',
  '2': const [
    const {'1': 'target', '3': 1, '4': 1, '5': 9, '10': 'target'},
    const {'1': 'config_json', '3': 2, '4': 1, '5': 9, '10': 'configJson'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_ExperimentsEntry$json = const {
  '1': 'ExperimentsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `BuilderConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderConfigDescriptor = $convert.base64Decode('Cg1CdWlsZGVyQ29uZmlnEhIKBG5hbWUYASABKAlSBG5hbWUSPAoHYmFja2VuZBggIAEoCzIiLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQmFja2VuZFIHYmFja2VuZBJDCgtiYWNrZW5kX2FsdBghIAEoCzIiLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQmFja2VuZFIKYmFja2VuZEFsdBIjCg1zd2FybWluZ19ob3N0GBUgASgJUgxzd2FybWluZ0hvc3QSGgoIY2F0ZWdvcnkYBiABKAlSCGNhdGVnb3J5EiMKDXN3YXJtaW5nX3RhZ3MYAiADKAlSDHN3YXJtaW5nVGFncxIeCgpkaW1lbnNpb25zGAMgAygJUgpkaW1lbnNpb25zEjkKBnJlY2lwZRgEIAEoCzIhLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuUmVjaXBlUgZyZWNpcGUSLAoDZXhlGBcgASgLMhouYnVpbGRidWNrZXQudjIuRXhlY3V0YWJsZVIDZXhlEiQKCnByb3BlcnRpZXMYGCABKAlCBKj+IwFSCnByb3BlcnRpZXMSPAoaYWxsb3dlZF9wcm9wZXJ0eV9vdmVycmlkZXMYIiADKAlSGGFsbG93ZWRQcm9wZXJ0eU92ZXJyaWRlcxIaCghwcmlvcml0eRgFIAEoDVIIcHJpb3JpdHkSNAoWZXhlY3V0aW9uX3RpbWVvdXRfc2VjcxgHIAEoDVIUZXhlY3V0aW9uVGltZW91dFNlY3MSJwoPZXhwaXJhdGlvbl9zZWNzGBQgASgNUg5leHBpcmF0aW9uU2VjcxI8CgxncmFjZV9wZXJpb2QYHyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SC2dyYWNlUGVyaW9kEkMKEXdhaXRfZm9yX2NhcGFjaXR5GB0gASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVIPd2FpdEZvckNhcGFjaXR5Ej0KBmNhY2hlcxgJIAMoCzIlLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQ2FjaGVFbnRyeVIGY2FjaGVzEjgKDWJ1aWxkX251bWJlcnMYECABKA4yEy5idWlsZGJ1Y2tldC5Ub2dnbGVSDGJ1aWxkTnVtYmVycxInCg9zZXJ2aWNlX2FjY291bnQYDCABKAlSDnNlcnZpY2VBY2NvdW50EkkKFmF1dG9fYnVpbGRlcl9kaW1lbnNpb24YESABKA4yEy5idWlsZGJ1Y2tldC5Ub2dnbGVSFGF1dG9CdWlsZGVyRGltZW5zaW9uEjcKDGV4cGVyaW1lbnRhbBgSIAEoDjITLmJ1aWxkYnVja2V0LlRvZ2dsZVIMZXhwZXJpbWVudGFsEmMKH3Rhc2tfdGVtcGxhdGVfY2FuYXJ5X3BlcmNlbnRhZ2UYFiABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdWVSHHRhc2tUZW1wbGF0ZUNhbmFyeVBlcmNlbnRhZ2USTQoLZXhwZXJpbWVudHMYHCADKAsyKy5idWlsZGJ1Y2tldC5CdWlsZGVyQ29uZmlnLkV4cGVyaW1lbnRzRW50cnlSC2V4cGVyaW1lbnRzEjMKCGNyaXRpY2FsGBkgASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVIIY3JpdGljYWwSPwoIcmVzdWx0ZGIYGiABKAsyIy5idWlsZGJ1Y2tldC5CdWlsZGVyQ29uZmlnLlJlc3VsdERCUghyZXN1bHRkYhIpChBkZXNjcmlwdGlvbl9odG1sGB4gASgJUg9kZXNjcmlwdGlvbkh0bWwahQEKCkNhY2hlRW50cnkSEgoEbmFtZRgBIAEoCVIEbmFtZRISCgRwYXRoGAIgASgJUgRwYXRoEjYKGHdhaXRfZm9yX3dhcm1fY2FjaGVfc2VjcxgDIAEoBVIUd2FpdEZvcldhcm1DYWNoZVNlY3MSFwoHZW52X3ZhchgEIAEoCVIGZW52VmFyGqsBCgZSZWNpcGUSEgoEbmFtZRgCIAEoCVIEbmFtZRIhCgxjaXBkX3BhY2thZ2UYBiABKAlSC2NpcGRQYWNrYWdlEiEKDGNpcGRfdmVyc2lvbhgFIAEoCVILY2lwZFZlcnNpb24SHgoKcHJvcGVydGllcxgDIAMoCVIKcHJvcGVydGllcxIhCgxwcm9wZXJ0aWVzX2oYBCADKAlSC3Byb3BlcnRpZXNKSgQIARACGq4BCghSZXN1bHREQhIWCgZlbmFibGUYASABKAhSBmVuYWJsZRI/CgpicV9leHBvcnRzGAIgAygLMiAubHVjaS5yZXN1bHRkYi52MS5CaWdRdWVyeUV4cG9ydFIJYnFFeHBvcnRzEkkKD2hpc3Rvcnlfb3B0aW9ucxgDIAEoCzIgLmx1Y2kucmVzdWx0ZGIudjEuSGlzdG9yeU9wdGlvbnNSDmhpc3RvcnlPcHRpb25zGkIKB0JhY2tlbmQSFgoGdGFyZ2V0GAEgASgJUgZ0YXJnZXQSHwoLY29uZmlnX2pzb24YAiABKAlSCmNvbmZpZ0pzb24aPgoQRXhwZXJpbWVudHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoBVIFdmFsdWU6AjgBSgQICBAJSgQICxAMSgQIDRAOSgQIDxAQSgQIExAUSgQIGxAcSgQIChAL');
@$core.Deprecated('Use swarmingDescriptor instead')
const Swarming$json = const {
  '1': 'Swarming',
  '2': const [
    const {'1': 'builders', '3': 4, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig', '10': 'builders'},
    const {'1': 'task_template_canary_percentage', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'taskTemplateCanaryPercentage'},
  ],
  '9': const [
    const {'1': 1, '2': 2},
    const {'1': 2, '2': 3},
    const {'1': 3, '2': 4},
  ],
};

/// Descriptor for `Swarming`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List swarmingDescriptor = $convert.base64Decode('CghTd2FybWluZxI2CghidWlsZGVycxgEIAMoCzIaLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWdSCGJ1aWxkZXJzEmMKH3Rhc2tfdGVtcGxhdGVfY2FuYXJ5X3BlcmNlbnRhZ2UYBSABKAsyHC5nb29nbGUucHJvdG9idWYuVUludDMyVmFsdWVSHHRhc2tUZW1wbGF0ZUNhbmFyeVBlcmNlbnRhZ2VKBAgBEAJKBAgCEANKBAgDEAQ=');
@$core.Deprecated('Use bucketDescriptor instead')
const Bucket$json = const {
  '1': 'Bucket',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {
      '1': 'acls',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.Acl',
      '8': const {'3': true},
      '10': 'acls',
    },
    const {'1': 'swarming', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.Swarming', '10': 'swarming'},
    const {'1': 'shadow', '3': 5, '4': 1, '5': 9, '10': 'shadow'},
    const {'1': 'constraints', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.Bucket.Constraints', '10': 'constraints'},
    const {'1': 'dynamic_builder_template', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.Bucket.DynamicBuilderTemplate', '10': 'dynamicBuilderTemplate'},
  ],
  '3': const [Bucket_Constraints$json, Bucket_DynamicBuilderTemplate$json],
  '9': const [
    const {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket_Constraints$json = const {
  '1': 'Constraints',
  '2': const [
    const {'1': 'pools', '3': 1, '4': 3, '5': 9, '10': 'pools'},
    const {'1': 'service_accounts', '3': 2, '4': 3, '5': 9, '10': 'serviceAccounts'},
  ],
};

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket_DynamicBuilderTemplate$json = const {
  '1': 'DynamicBuilderTemplate',
};

/// Descriptor for `Bucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bucketDescriptor = $convert.base64Decode('CgZCdWNrZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIoCgRhY2xzGAIgAygLMhAuYnVpbGRidWNrZXQuQWNsQgIYAVIEYWNscxIxCghzd2FybWluZxgDIAEoCzIVLmJ1aWxkYnVja2V0LlN3YXJtaW5nUghzd2FybWluZxIWCgZzaGFkb3cYBSABKAlSBnNoYWRvdxJBCgtjb25zdHJhaW50cxgGIAEoCzIfLmJ1aWxkYnVja2V0LkJ1Y2tldC5Db25zdHJhaW50c1ILY29uc3RyYWludHMSZAoYZHluYW1pY19idWlsZGVyX3RlbXBsYXRlGAcgASgLMiouYnVpbGRidWNrZXQuQnVja2V0LkR5bmFtaWNCdWlsZGVyVGVtcGxhdGVSFmR5bmFtaWNCdWlsZGVyVGVtcGxhdGUaTgoLQ29uc3RyYWludHMSFAoFcG9vbHMYASADKAlSBXBvb2xzEikKEHNlcnZpY2VfYWNjb3VudHMYAiADKAlSD3NlcnZpY2VBY2NvdW50cxoYChZEeW5hbWljQnVpbGRlclRlbXBsYXRlSgQIBBAF');
@$core.Deprecated('Use buildbucketCfgDescriptor instead')
const BuildbucketCfg$json = const {
  '1': 'BuildbucketCfg',
  '2': const [
    const {'1': 'buckets', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.Bucket', '10': 'buckets'},
    const {'1': 'builds_notification_topics', '3': 4, '4': 3, '5': 11, '6': '.buildbucket.BuildbucketCfg.topic', '10': 'buildsNotificationTopics'},
  ],
  '3': const [BuildbucketCfg_topic$json],
  '9': const [
    const {'1': 2, '2': 3},
    const {'1': 3, '2': 4},
  ],
};

@$core.Deprecated('Use buildbucketCfgDescriptor instead')
const BuildbucketCfg_topic$json = const {
  '1': 'topic',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'compression', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.Compression', '10': 'compression'},
  ],
};

/// Descriptor for `BuildbucketCfg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildbucketCfgDescriptor = $convert.base64Decode('Cg5CdWlsZGJ1Y2tldENmZxItCgdidWNrZXRzGAEgAygLMhMuYnVpbGRidWNrZXQuQnVja2V0UgdidWNrZXRzEl8KGmJ1aWxkc19ub3RpZmljYXRpb25fdG9waWNzGAQgAygLMiEuYnVpbGRidWNrZXQuQnVpbGRidWNrZXRDZmcudG9waWNSGGJ1aWxkc05vdGlmaWNhdGlvblRvcGljcxpaCgV0b3BpYxISCgRuYW1lGAEgASgJUgRuYW1lEj0KC2NvbXByZXNzaW9uGAIgASgOMhsuYnVpbGRidWNrZXQudjIuQ29tcHJlc3Npb25SC2NvbXByZXNzaW9uSgQIAhADSgQIAxAE');
