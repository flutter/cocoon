//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/project_config.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use toggleDescriptor instead')
const Toggle$json = {
  '1': 'Toggle',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'YES', '2': 1},
    {'1': 'NO', '2': 2},
  ],
};

/// Descriptor for `Toggle`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List toggleDescriptor = $convert.base64Decode(
    'CgZUb2dnbGUSCQoFVU5TRVQQABIHCgNZRVMQARIGCgJOTxAC');

@$core.Deprecated('Use aclDescriptor instead')
const Acl$json = {
  '1': 'Acl',
  '2': [
    {
      '1': 'role',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.buildbucket.Acl.Role',
      '8': {'3': true},
      '10': 'role',
    },
    {
      '1': 'group',
      '3': 2,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'group',
    },
    {
      '1': 'identity',
      '3': 3,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'identity',
    },
  ],
  '4': [Acl_Role$json],
};

@$core.Deprecated('Use aclDescriptor instead')
const Acl_Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'READER', '2': 0},
    {'1': 'SCHEDULER', '2': 1},
    {'1': 'WRITER', '2': 2},
  ],
};

/// Descriptor for `Acl`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aclDescriptor = $convert.base64Decode(
    'CgNBY2wSLQoEcm9sZRgBIAEoDjIVLmJ1aWxkYnVja2V0LkFjbC5Sb2xlQgIYAVIEcm9sZRIYCg'
    'Vncm91cBgCIAEoCUICGAFSBWdyb3VwEh4KCGlkZW50aXR5GAMgASgJQgIYAVIIaWRlbnRpdHki'
    'LQoEUm9sZRIKCgZSRUFERVIQABINCglTQ0hFRFVMRVIQARIKCgZXUklURVIQAg==');

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig$json = {
  '1': 'BuilderConfig',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'backend', '3': 32, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Backend', '10': 'backend'},
    {'1': 'backend_alt', '3': 33, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Backend', '10': 'backendAlt'},
    {'1': 'swarming_host', '3': 21, '4': 1, '5': 9, '10': 'swarmingHost'},
    {'1': 'category', '3': 6, '4': 1, '5': 9, '10': 'category'},
    {'1': 'swarming_tags', '3': 2, '4': 3, '5': 9, '10': 'swarmingTags'},
    {'1': 'dimensions', '3': 3, '4': 3, '5': 9, '10': 'dimensions'},
    {'1': 'recipe', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.Recipe', '10': 'recipe'},
    {'1': 'exe', '3': 23, '4': 1, '5': 11, '6': '.buildbucket.v2.Executable', '10': 'exe'},
    {'1': 'properties', '3': 24, '4': 1, '5': 9, '8': {}, '10': 'properties'},
    {'1': 'allowed_property_overrides', '3': 34, '4': 3, '5': 9, '10': 'allowedPropertyOverrides'},
    {'1': 'priority', '3': 5, '4': 1, '5': 13, '10': 'priority'},
    {'1': 'execution_timeout_secs', '3': 7, '4': 1, '5': 13, '10': 'executionTimeoutSecs'},
    {'1': 'heartbeat_timeout_secs', '3': 39, '4': 1, '5': 13, '10': 'heartbeatTimeoutSecs'},
    {'1': 'expiration_secs', '3': 20, '4': 1, '5': 13, '10': 'expirationSecs'},
    {'1': 'grace_period', '3': 31, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'gracePeriod'},
    {'1': 'wait_for_capacity', '3': 29, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'waitForCapacity'},
    {'1': 'caches', '3': 9, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.CacheEntry', '10': 'caches'},
    {'1': 'build_numbers', '3': 16, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'buildNumbers'},
    {'1': 'service_account', '3': 12, '4': 1, '5': 9, '10': 'serviceAccount'},
    {'1': 'auto_builder_dimension', '3': 17, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'autoBuilderDimension'},
    {'1': 'experimental', '3': 18, '4': 1, '5': 14, '6': '.buildbucket.Toggle', '10': 'experimental'},
    {'1': 'task_template_canary_percentage', '3': 22, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'taskTemplateCanaryPercentage'},
    {'1': 'experiments', '3': 28, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.ExperimentsEntry', '10': 'experiments'},
    {'1': 'critical', '3': 25, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'critical'},
    {'1': 'resultdb', '3': 26, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.ResultDB', '10': 'resultdb'},
    {'1': 'description_html', '3': 30, '4': 1, '5': 9, '10': 'descriptionHtml'},
    {'1': 'shadow_builder_adjustments', '3': 35, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.ShadowBuilderAdjustments', '10': 'shadowBuilderAdjustments'},
    {'1': 'retriable', '3': 36, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'retriable'},
    {'1': 'builder_health_metrics_links', '3': 37, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig.BuilderHealthLinks', '10': 'builderHealthMetricsLinks'},
    {'1': 'contact_team_email', '3': 38, '4': 1, '5': 9, '10': 'contactTeamEmail'},
  ],
  '3': [BuilderConfig_CacheEntry$json, BuilderConfig_Recipe$json, BuilderConfig_ResultDB$json, BuilderConfig_Backend$json, BuilderConfig_ExperimentsEntry$json, BuilderConfig_ShadowBuilderAdjustments$json, BuilderConfig_BuilderHealthLinks$json],
  '9': [
    {'1': 8, '2': 9},
    {'1': 11, '2': 12},
    {'1': 13, '2': 14},
    {'1': 15, '2': 16},
    {'1': 19, '2': 20},
    {'1': 27, '2': 28},
    {'1': 10, '2': 11},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_CacheEntry$json = {
  '1': 'CacheEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'wait_for_warm_cache_secs', '3': 3, '4': 1, '5': 5, '10': 'waitForWarmCacheSecs'},
    {'1': 'env_var', '3': 4, '4': 1, '5': 9, '10': 'envVar'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_Recipe$json = {
  '1': 'Recipe',
  '2': [
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'cipd_package', '3': 6, '4': 1, '5': 9, '10': 'cipdPackage'},
    {'1': 'cipd_version', '3': 5, '4': 1, '5': 9, '10': 'cipdVersion'},
    {'1': 'properties', '3': 3, '4': 3, '5': 9, '10': 'properties'},
    {'1': 'properties_j', '3': 4, '4': 3, '5': 9, '10': 'propertiesJ'},
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_ResultDB$json = {
  '1': 'ResultDB',
  '2': [
    {'1': 'enable', '3': 1, '4': 1, '5': 8, '10': 'enable'},
    {'1': 'bq_exports', '3': 2, '4': 3, '5': 11, '6': '.luci.resultdb.v1.BigQueryExport', '10': 'bqExports'},
    {'1': 'history_options', '3': 3, '4': 1, '5': 11, '6': '.luci.resultdb.v1.HistoryOptions', '10': 'historyOptions'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_Backend$json = {
  '1': 'Backend',
  '2': [
    {'1': 'target', '3': 1, '4': 1, '5': 9, '10': 'target'},
    {'1': 'config_json', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'configJson'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_ExperimentsEntry$json = {
  '1': 'ExperimentsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 5, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_ShadowBuilderAdjustments$json = {
  '1': 'ShadowBuilderAdjustments',
  '2': [
    {'1': 'service_account', '3': 1, '4': 1, '5': 9, '10': 'serviceAccount'},
    {'1': 'pool', '3': 2, '4': 1, '5': 9, '10': 'pool'},
    {'1': 'properties', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'properties'},
    {'1': 'dimensions', '3': 4, '4': 3, '5': 9, '10': 'dimensions'},
  ],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_BuilderHealthLinks$json = {
  '1': 'BuilderHealthLinks',
  '2': [
    {'1': 'doc_links', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.BuilderHealthLinks.DocLinksEntry', '10': 'docLinks'},
    {'1': 'data_links', '3': 2, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig.BuilderHealthLinks.DataLinksEntry', '10': 'dataLinks'},
  ],
  '3': [BuilderConfig_BuilderHealthLinks_DocLinksEntry$json, BuilderConfig_BuilderHealthLinks_DataLinksEntry$json],
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_BuilderHealthLinks_DocLinksEntry$json = {
  '1': 'DocLinksEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use builderConfigDescriptor instead')
const BuilderConfig_BuilderHealthLinks_DataLinksEntry$json = {
  '1': 'DataLinksEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `BuilderConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderConfigDescriptor = $convert.base64Decode(
    'Cg1CdWlsZGVyQ29uZmlnEhIKBG5hbWUYASABKAlSBG5hbWUSPAoHYmFja2VuZBggIAEoCzIiLm'
    'J1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQmFja2VuZFIHYmFja2VuZBJDCgtiYWNrZW5kX2Fs'
    'dBghIAEoCzIiLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQmFja2VuZFIKYmFja2VuZEFsdB'
    'IjCg1zd2FybWluZ19ob3N0GBUgASgJUgxzd2FybWluZ0hvc3QSGgoIY2F0ZWdvcnkYBiABKAlS'
    'CGNhdGVnb3J5EiMKDXN3YXJtaW5nX3RhZ3MYAiADKAlSDHN3YXJtaW5nVGFncxIeCgpkaW1lbn'
    'Npb25zGAMgAygJUgpkaW1lbnNpb25zEjkKBnJlY2lwZRgEIAEoCzIhLmJ1aWxkYnVja2V0LkJ1'
    'aWxkZXJDb25maWcuUmVjaXBlUgZyZWNpcGUSLAoDZXhlGBcgASgLMhouYnVpbGRidWNrZXQudj'
    'IuRXhlY3V0YWJsZVIDZXhlEiQKCnByb3BlcnRpZXMYGCABKAlCBKj+IwFSCnByb3BlcnRpZXMS'
    'PAoaYWxsb3dlZF9wcm9wZXJ0eV9vdmVycmlkZXMYIiADKAlSGGFsbG93ZWRQcm9wZXJ0eU92ZX'
    'JyaWRlcxIaCghwcmlvcml0eRgFIAEoDVIIcHJpb3JpdHkSNAoWZXhlY3V0aW9uX3RpbWVvdXRf'
    'c2VjcxgHIAEoDVIUZXhlY3V0aW9uVGltZW91dFNlY3MSNAoWaGVhcnRiZWF0X3RpbWVvdXRfc2'
    'VjcxgnIAEoDVIUaGVhcnRiZWF0VGltZW91dFNlY3MSJwoPZXhwaXJhdGlvbl9zZWNzGBQgASgN'
    'Ug5leHBpcmF0aW9uU2VjcxI8CgxncmFjZV9wZXJpb2QYHyABKAsyGS5nb29nbGUucHJvdG9idW'
    'YuRHVyYXRpb25SC2dyYWNlUGVyaW9kEkMKEXdhaXRfZm9yX2NhcGFjaXR5GB0gASgOMhcuYnVp'
    'bGRidWNrZXQudjIuVHJpbmFyeVIPd2FpdEZvckNhcGFjaXR5Ej0KBmNhY2hlcxgJIAMoCzIlLm'
    'J1aWxkYnVja2V0LkJ1aWxkZXJDb25maWcuQ2FjaGVFbnRyeVIGY2FjaGVzEjgKDWJ1aWxkX251'
    'bWJlcnMYECABKA4yEy5idWlsZGJ1Y2tldC5Ub2dnbGVSDGJ1aWxkTnVtYmVycxInCg9zZXJ2aW'
    'NlX2FjY291bnQYDCABKAlSDnNlcnZpY2VBY2NvdW50EkkKFmF1dG9fYnVpbGRlcl9kaW1lbnNp'
    'b24YESABKA4yEy5idWlsZGJ1Y2tldC5Ub2dnbGVSFGF1dG9CdWlsZGVyRGltZW5zaW9uEjcKDG'
    'V4cGVyaW1lbnRhbBgSIAEoDjITLmJ1aWxkYnVja2V0LlRvZ2dsZVIMZXhwZXJpbWVudGFsEmMK'
    'H3Rhc2tfdGVtcGxhdGVfY2FuYXJ5X3BlcmNlbnRhZ2UYFiABKAsyHC5nb29nbGUucHJvdG9idW'
    'YuVUludDMyVmFsdWVSHHRhc2tUZW1wbGF0ZUNhbmFyeVBlcmNlbnRhZ2USTQoLZXhwZXJpbWVu'
    'dHMYHCADKAsyKy5idWlsZGJ1Y2tldC5CdWlsZGVyQ29uZmlnLkV4cGVyaW1lbnRzRW50cnlSC2'
    'V4cGVyaW1lbnRzEjMKCGNyaXRpY2FsGBkgASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVII'
    'Y3JpdGljYWwSPwoIcmVzdWx0ZGIYGiABKAsyIy5idWlsZGJ1Y2tldC5CdWlsZGVyQ29uZmlnLl'
    'Jlc3VsdERCUghyZXN1bHRkYhIpChBkZXNjcmlwdGlvbl9odG1sGB4gASgJUg9kZXNjcmlwdGlv'
    'bkh0bWwScQoac2hhZG93X2J1aWxkZXJfYWRqdXN0bWVudHMYIyABKAsyMy5idWlsZGJ1Y2tldC'
    '5CdWlsZGVyQ29uZmlnLlNoYWRvd0J1aWxkZXJBZGp1c3RtZW50c1IYc2hhZG93QnVpbGRlckFk'
    'anVzdG1lbnRzEjUKCXJldHJpYWJsZRgkIAEoDjIXLmJ1aWxkYnVja2V0LnYyLlRyaW5hcnlSCX'
    'JldHJpYWJsZRJuChxidWlsZGVyX2hlYWx0aF9tZXRyaWNzX2xpbmtzGCUgASgLMi0uYnVpbGRi'
    'dWNrZXQuQnVpbGRlckNvbmZpZy5CdWlsZGVySGVhbHRoTGlua3NSGWJ1aWxkZXJIZWFsdGhNZX'
    'RyaWNzTGlua3MSLAoSY29udGFjdF90ZWFtX2VtYWlsGCYgASgJUhBjb250YWN0VGVhbUVtYWls'
    'GoUBCgpDYWNoZUVudHJ5EhIKBG5hbWUYASABKAlSBG5hbWUSEgoEcGF0aBgCIAEoCVIEcGF0aB'
    'I2Chh3YWl0X2Zvcl93YXJtX2NhY2hlX3NlY3MYAyABKAVSFHdhaXRGb3JXYXJtQ2FjaGVTZWNz'
    'EhcKB2Vudl92YXIYBCABKAlSBmVudlZhchqrAQoGUmVjaXBlEhIKBG5hbWUYAiABKAlSBG5hbW'
    'USIQoMY2lwZF9wYWNrYWdlGAYgASgJUgtjaXBkUGFja2FnZRIhCgxjaXBkX3ZlcnNpb24YBSAB'
    'KAlSC2NpcGRWZXJzaW9uEh4KCnByb3BlcnRpZXMYAyADKAlSCnByb3BlcnRpZXMSIQoMcHJvcG'
    'VydGllc19qGAQgAygJUgtwcm9wZXJ0aWVzSkoECAEQAhquAQoIUmVzdWx0REISFgoGZW5hYmxl'
    'GAEgASgIUgZlbmFibGUSPwoKYnFfZXhwb3J0cxgCIAMoCzIgLmx1Y2kucmVzdWx0ZGIudjEuQm'
    'lnUXVlcnlFeHBvcnRSCWJxRXhwb3J0cxJJCg9oaXN0b3J5X29wdGlvbnMYAyABKAsyIC5sdWNp'
    'LnJlc3VsdGRiLnYxLkhpc3RvcnlPcHRpb25zUg5oaXN0b3J5T3B0aW9ucxpICgdCYWNrZW5kEh'
    'YKBnRhcmdldBgBIAEoCVIGdGFyZ2V0EiUKC2NvbmZpZ19qc29uGAIgASgJQgSo/iMBUgpjb25m'
    'aWdKc29uGj4KEEV4cGVyaW1lbnRzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAi'
    'ABKAVSBXZhbHVlOgI4ARqdAQoYU2hhZG93QnVpbGRlckFkanVzdG1lbnRzEicKD3NlcnZpY2Vf'
    'YWNjb3VudBgBIAEoCVIOc2VydmljZUFjY291bnQSEgoEcG9vbBgCIAEoCVIEcG9vbBIkCgpwcm'
    '9wZXJ0aWVzGAMgASgJQgSo/iMBUgpwcm9wZXJ0aWVzEh4KCmRpbWVuc2lvbnMYBCADKAlSCmRp'
    'bWVuc2lvbnMaxgIKEkJ1aWxkZXJIZWFsdGhMaW5rcxJYCglkb2NfbGlua3MYASADKAsyOy5idW'
    'lsZGJ1Y2tldC5CdWlsZGVyQ29uZmlnLkJ1aWxkZXJIZWFsdGhMaW5rcy5Eb2NMaW5rc0VudHJ5'
    'Ughkb2NMaW5rcxJbCgpkYXRhX2xpbmtzGAIgAygLMjwuYnVpbGRidWNrZXQuQnVpbGRlckNvbm'
    'ZpZy5CdWlsZGVySGVhbHRoTGlua3MuRGF0YUxpbmtzRW50cnlSCWRhdGFMaW5rcxo7Cg1Eb2NM'
    'aW5rc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaPA'
    'oORGF0YUxpbmtzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVl'
    'OgI4AUoECAgQCUoECAsQDEoECA0QDkoECA8QEEoECBMQFEoECBsQHEoECAoQCw==');

@$core.Deprecated('Use swarmingDescriptor instead')
const Swarming$json = {
  '1': 'Swarming',
  '2': [
    {'1': 'builders', '3': 4, '4': 3, '5': 11, '6': '.buildbucket.BuilderConfig', '10': 'builders'},
    {'1': 'task_template_canary_percentage', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.UInt32Value', '10': 'taskTemplateCanaryPercentage'},
  ],
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
};

/// Descriptor for `Swarming`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List swarmingDescriptor = $convert.base64Decode(
    'CghTd2FybWluZxI2CghidWlsZGVycxgEIAMoCzIaLmJ1aWxkYnVja2V0LkJ1aWxkZXJDb25maW'
    'dSCGJ1aWxkZXJzEmMKH3Rhc2tfdGVtcGxhdGVfY2FuYXJ5X3BlcmNlbnRhZ2UYBSABKAsyHC5n'
    'b29nbGUucHJvdG9idWYuVUludDMyVmFsdWVSHHRhc2tUZW1wbGF0ZUNhbmFyeVBlcmNlbnRhZ2'
    'VKBAgBEAJKBAgCEANKBAgDEAQ=');

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket$json = {
  '1': 'Bucket',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'acls',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.Acl',
      '8': {'3': true},
      '10': 'acls',
    },
    {'1': 'swarming', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.Swarming', '10': 'swarming'},
    {'1': 'shadow', '3': 5, '4': 1, '5': 9, '10': 'shadow'},
    {'1': 'constraints', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.Bucket.Constraints', '10': 'constraints'},
    {'1': 'dynamic_builder_template', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.Bucket.DynamicBuilderTemplate', '10': 'dynamicBuilderTemplate'},
  ],
  '3': [Bucket_Constraints$json, Bucket_DynamicBuilderTemplate$json],
  '9': [
    {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket_Constraints$json = {
  '1': 'Constraints',
  '2': [
    {'1': 'pools', '3': 1, '4': 3, '5': 9, '10': 'pools'},
    {'1': 'service_accounts', '3': 2, '4': 3, '5': 9, '10': 'serviceAccounts'},
  ],
};

@$core.Deprecated('Use bucketDescriptor instead')
const Bucket_DynamicBuilderTemplate$json = {
  '1': 'DynamicBuilderTemplate',
  '2': [
    {'1': 'template', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig', '10': 'template'},
  ],
};

/// Descriptor for `Bucket`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bucketDescriptor = $convert.base64Decode(
    'CgZCdWNrZXQSEgoEbmFtZRgBIAEoCVIEbmFtZRIoCgRhY2xzGAIgAygLMhAuYnVpbGRidWNrZX'
    'QuQWNsQgIYAVIEYWNscxIxCghzd2FybWluZxgDIAEoCzIVLmJ1aWxkYnVja2V0LlN3YXJtaW5n'
    'Ughzd2FybWluZxIWCgZzaGFkb3cYBSABKAlSBnNoYWRvdxJBCgtjb25zdHJhaW50cxgGIAEoCz'
    'IfLmJ1aWxkYnVja2V0LkJ1Y2tldC5Db25zdHJhaW50c1ILY29uc3RyYWludHMSZAoYZHluYW1p'
    'Y19idWlsZGVyX3RlbXBsYXRlGAcgASgLMiouYnVpbGRidWNrZXQuQnVja2V0LkR5bmFtaWNCdW'
    'lsZGVyVGVtcGxhdGVSFmR5bmFtaWNCdWlsZGVyVGVtcGxhdGUaTgoLQ29uc3RyYWludHMSFAoF'
    'cG9vbHMYASADKAlSBXBvb2xzEikKEHNlcnZpY2VfYWNjb3VudHMYAiADKAlSD3NlcnZpY2VBY2'
    'NvdW50cxpQChZEeW5hbWljQnVpbGRlclRlbXBsYXRlEjYKCHRlbXBsYXRlGAEgASgLMhouYnVp'
    'bGRidWNrZXQuQnVpbGRlckNvbmZpZ1IIdGVtcGxhdGVKBAgEEAU=');

@$core.Deprecated('Use buildbucketCfgDescriptor instead')
const BuildbucketCfg$json = {
  '1': 'BuildbucketCfg',
  '2': [
    {'1': 'buckets', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.Bucket', '10': 'buckets'},
    {'1': 'common_config', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.BuildbucketCfg.CommonConfig', '10': 'commonConfig'},
  ],
  '3': [BuildbucketCfg_Topic$json, BuildbucketCfg_CommonConfig$json],
  '9': [
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use buildbucketCfgDescriptor instead')
const BuildbucketCfg_Topic$json = {
  '1': 'Topic',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'compression', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.Compression', '10': 'compression'},
  ],
};

@$core.Deprecated('Use buildbucketCfgDescriptor instead')
const BuildbucketCfg_CommonConfig$json = {
  '1': 'CommonConfig',
  '2': [
    {'1': 'builds_notification_topics', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.BuildbucketCfg.Topic', '10': 'buildsNotificationTopics'},
  ],
};

/// Descriptor for `BuildbucketCfg`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildbucketCfgDescriptor = $convert.base64Decode(
    'Cg5CdWlsZGJ1Y2tldENmZxItCgdidWNrZXRzGAEgAygLMhMuYnVpbGRidWNrZXQuQnVja2V0Ug'
    'didWNrZXRzEk0KDWNvbW1vbl9jb25maWcYBSABKAsyKC5idWlsZGJ1Y2tldC5CdWlsZGJ1Y2tl'
    'dENmZy5Db21tb25Db25maWdSDGNvbW1vbkNvbmZpZxpaCgVUb3BpYxISCgRuYW1lGAEgASgJUg'
    'RuYW1lEj0KC2NvbXByZXNzaW9uGAIgASgOMhsuYnVpbGRidWNrZXQudjIuQ29tcHJlc3Npb25S'
    'C2NvbXByZXNzaW9uGm8KDENvbW1vbkNvbmZpZxJfChpidWlsZHNfbm90aWZpY2F0aW9uX3RvcG'
    'ljcxgBIAMoCzIhLmJ1aWxkYnVja2V0LkJ1aWxkYnVja2V0Q2ZnLlRvcGljUhhidWlsZHNOb3Rp'
    'ZmljYXRpb25Ub3BpY3NKBAgCEANKBAgDEARKBAgEEAU=');

