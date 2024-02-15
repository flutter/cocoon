//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use statusDescriptor instead')
const Status$json = {
  '1': 'Status',
  '2': [
    {'1': 'STATUS_UNSPECIFIED', '2': 0},
    {'1': 'SCHEDULED', '2': 1},
    {'1': 'STARTED', '2': 2},
    {'1': 'ENDED_MASK', '2': 4},
    {'1': 'SUCCESS', '2': 12},
    {'1': 'FAILURE', '2': 20},
    {'1': 'INFRA_FAILURE', '2': 36},
    {'1': 'CANCELED', '2': 68},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List statusDescriptor =
    $convert.base64Decode('CgZTdGF0dXMSFgoSU1RBVFVTX1VOU1BFQ0lGSUVEEAASDQoJU0NIRURVTEVEEAESCwoHU1RBUl'
        'RFRBACEg4KCkVOREVEX01BU0sQBBILCgdTVUNDRVNTEAwSCwoHRkFJTFVSRRAUEhEKDUlORlJB'
        'X0ZBSUxVUkUQJBIMCghDQU5DRUxFRBBE');

@$core.Deprecated('Use trinaryDescriptor instead')
const Trinary$json = {
  '1': 'Trinary',
  '2': [
    {'1': 'UNSET', '2': 0},
    {'1': 'YES', '2': 1},
    {'1': 'NO', '2': 2},
  ],
};

/// Descriptor for `Trinary`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trinaryDescriptor =
    $convert.base64Decode('CgdUcmluYXJ5EgkKBVVOU0VUEAASBwoDWUVTEAESBgoCTk8QAg==');

@$core.Deprecated('Use compressionDescriptor instead')
const Compression$json = {
  '1': 'Compression',
  '2': [
    {'1': 'ZLIB', '2': 0},
    {'1': 'ZSTD', '2': 1},
  ],
};

/// Descriptor for `Compression`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List compressionDescriptor =
    $convert.base64Decode('CgtDb21wcmVzc2lvbhIICgRaTElCEAASCAoEWlNURBAB');

@$core.Deprecated('Use executableDescriptor instead')
const Executable$json = {
  '1': 'Executable',
  '2': [
    {'1': 'cipd_package', '3': 1, '4': 1, '5': 9, '10': 'cipdPackage'},
    {'1': 'cipd_version', '3': 2, '4': 1, '5': 9, '10': 'cipdVersion'},
    {'1': 'cmd', '3': 3, '4': 3, '5': 9, '10': 'cmd'},
    {'1': 'wrapper', '3': 4, '4': 3, '5': 9, '10': 'wrapper'},
  ],
};

/// Descriptor for `Executable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableDescriptor =
    $convert.base64Decode('CgpFeGVjdXRhYmxlEiEKDGNpcGRfcGFja2FnZRgBIAEoCVILY2lwZFBhY2thZ2USIQoMY2lwZF'
        '92ZXJzaW9uGAIgASgJUgtjaXBkVmVyc2lvbhIQCgNjbWQYAyADKAlSA2NtZBIYCgd3cmFwcGVy'
        'GAQgAygJUgd3cmFwcGVy');

@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails$json = {
  '1': 'StatusDetails',
  '2': [
    {
      '1': 'resource_exhaustion',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.StatusDetails.ResourceExhaustion',
      '10': 'resourceExhaustion'
    },
    {'1': 'timeout', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails.Timeout', '10': 'timeout'},
  ],
  '3': [StatusDetails_ResourceExhaustion$json, StatusDetails_Timeout$json],
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
  ],
};

@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails_ResourceExhaustion$json = {
  '1': 'ResourceExhaustion',
};

@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails_Timeout$json = {
  '1': 'Timeout',
};

/// Descriptor for `StatusDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDetailsDescriptor =
    $convert.base64Decode('Cg1TdGF0dXNEZXRhaWxzEmEKE3Jlc291cmNlX2V4aGF1c3Rpb24YAyABKAsyMC5idWlsZGJ1Y2'
        'tldC52Mi5TdGF0dXNEZXRhaWxzLlJlc291cmNlRXhoYXVzdGlvblIScmVzb3VyY2VFeGhhdXN0'
        'aW9uEj8KB3RpbWVvdXQYBCABKAsyJS5idWlsZGJ1Y2tldC52Mi5TdGF0dXNEZXRhaWxzLlRpbW'
        'VvdXRSB3RpbWVvdXQaFAoSUmVzb3VyY2VFeGhhdXN0aW9uGgkKB1RpbWVvdXRKBAgBEAJKBAgC'
        'EAM=');

@$core.Deprecated('Use logDescriptor instead')
const Log$json = {
  '1': 'Log',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'view_url', '3': 2, '4': 1, '5': 9, '10': 'viewUrl'},
    {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `Log`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logDescriptor =
    $convert.base64Decode('CgNMb2cSEgoEbmFtZRgBIAEoCVIEbmFtZRIZCgh2aWV3X3VybBgCIAEoCVIHdmlld1VybBIQCg'
        'N1cmwYAyABKAlSA3VybA==');

@$core.Deprecated('Use gerritChangeDescriptor instead')
const GerritChange$json = {
  '1': 'GerritChange',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'change', '3': 3, '4': 1, '5': 3, '10': 'change'},
    {'1': 'patchset', '3': 4, '4': 1, '5': 3, '10': 'patchset'},
  ],
};

/// Descriptor for `GerritChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gerritChangeDescriptor =
    $convert.base64Decode('CgxHZXJyaXRDaGFuZ2USEgoEaG9zdBgBIAEoCVIEaG9zdBIYCgdwcm9qZWN0GAIgASgJUgdwcm'
        '9qZWN0EhYKBmNoYW5nZRgDIAEoA1IGY2hhbmdlEhoKCHBhdGNoc2V0GAQgASgDUghwYXRjaHNl'
        'dA==');

@$core.Deprecated('Use gitilesCommitDescriptor instead')
const GitilesCommit$json = {
  '1': 'GitilesCommit',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
    {'1': 'ref', '3': 4, '4': 1, '5': 9, '10': 'ref'},
    {'1': 'position', '3': 5, '4': 1, '5': 13, '10': 'position'},
  ],
};

/// Descriptor for `GitilesCommit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitilesCommitDescriptor =
    $convert.base64Decode('Cg1HaXRpbGVzQ29tbWl0EhIKBGhvc3QYASABKAlSBGhvc3QSGAoHcHJvamVjdBgCIAEoCVIHcH'
        'JvamVjdBIOCgJpZBgDIAEoCVICaWQSEAoDcmVmGAQgASgJUgNyZWYSGgoIcG9zaXRpb24YBSAB'
        'KA1SCHBvc2l0aW9u');

@$core.Deprecated('Use stringPairDescriptor instead')
const StringPair$json = {
  '1': 'StringPair',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `StringPair`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringPairDescriptor =
    $convert.base64Decode('CgpTdHJpbmdQYWlyEhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZQ==');

@$core.Deprecated('Use timeRangeDescriptor instead')
const TimeRange$json = {
  '1': 'TimeRange',
  '2': [
    {'1': 'start_time', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    {'1': 'end_time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endTime'},
  ],
};

/// Descriptor for `TimeRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeRangeDescriptor =
    $convert.base64Decode('CglUaW1lUmFuZ2USOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3'
        'RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1l'
        'c3RhbXBSB2VuZFRpbWU=');

@$core.Deprecated('Use requestedDimensionDescriptor instead')
const RequestedDimension$json = {
  '1': 'RequestedDimension',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    {'1': 'expiration', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'expiration'},
  ],
};

/// Descriptor for `RequestedDimension`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestedDimensionDescriptor =
    $convert.base64Decode('ChJSZXF1ZXN0ZWREaW1lbnNpb24SEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBX'
        'ZhbHVlEjkKCmV4cGlyYXRpb24YAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCmV4'
        'cGlyYXRpb24=');

@$core.Deprecated('Use cacheEntryDescriptor instead')
const CacheEntry$json = {
  '1': 'CacheEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'wait_for_warm_cache', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'waitForWarmCache'},
    {'1': 'env_var', '3': 4, '4': 1, '5': 9, '10': 'envVar'},
  ],
};

/// Descriptor for `CacheEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cacheEntryDescriptor =
    $convert.base64Decode('CgpDYWNoZUVudHJ5EhIKBG5hbWUYASABKAlSBG5hbWUSEgoEcGF0aBgCIAEoCVIEcGF0aBJICh'
        'N3YWl0X2Zvcl93YXJtX2NhY2hlGAMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhB3'
        'YWl0Rm9yV2FybUNhY2hlEhcKB2Vudl92YXIYBCABKAlSBmVudlZhcg==');

@$core.Deprecated('Use healthStatusDescriptor instead')
const HealthStatus$json = {
  '1': 'HealthStatus',
  '2': [
    {'1': 'health_score', '3': 1, '4': 1, '5': 3, '10': 'healthScore'},
    {
      '1': 'health_metrics',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.HealthStatus.HealthMetricsEntry',
      '10': 'healthMetrics'
    },
    {'1': 'description', '3': 3, '4': 1, '5': 9, '10': 'description'},
    {'1': 'doc_links', '3': 4, '4': 3, '5': 11, '6': '.buildbucket.v2.HealthStatus.DocLinksEntry', '10': 'docLinks'},
    {'1': 'data_links', '3': 5, '4': 3, '5': 11, '6': '.buildbucket.v2.HealthStatus.DataLinksEntry', '10': 'dataLinks'},
    {'1': 'reporter', '3': 6, '4': 1, '5': 9, '8': {}, '10': 'reporter'},
    {'1': 'reported_time', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'reportedTime'},
    {'1': 'contact_team_email', '3': 8, '4': 1, '5': 9, '10': 'contactTeamEmail'},
  ],
  '3': [HealthStatus_HealthMetricsEntry$json, HealthStatus_DocLinksEntry$json, HealthStatus_DataLinksEntry$json],
};

@$core.Deprecated('Use healthStatusDescriptor instead')
const HealthStatus_HealthMetricsEntry$json = {
  '1': 'HealthMetricsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 2, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use healthStatusDescriptor instead')
const HealthStatus_DocLinksEntry$json = {
  '1': 'DocLinksEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use healthStatusDescriptor instead')
const HealthStatus_DataLinksEntry$json = {
  '1': 'DataLinksEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `HealthStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthStatusDescriptor =
    $convert.base64Decode('CgxIZWFsdGhTdGF0dXMSIQoMaGVhbHRoX3Njb3JlGAEgASgDUgtoZWFsdGhTY29yZRJWCg5oZW'
        'FsdGhfbWV0cmljcxgCIAMoCzIvLmJ1aWxkYnVja2V0LnYyLkhlYWx0aFN0YXR1cy5IZWFsdGhN'
        'ZXRyaWNzRW50cnlSDWhlYWx0aE1ldHJpY3MSIAoLZGVzY3JpcHRpb24YAyABKAlSC2Rlc2NyaX'
        'B0aW9uEkcKCWRvY19saW5rcxgEIAMoCzIqLmJ1aWxkYnVja2V0LnYyLkhlYWx0aFN0YXR1cy5E'
        'b2NMaW5rc0VudHJ5Ughkb2NMaW5rcxJKCgpkYXRhX2xpbmtzGAUgAygLMisuYnVpbGRidWNrZX'
        'QudjIuSGVhbHRoU3RhdHVzLkRhdGFMaW5rc0VudHJ5UglkYXRhTGlua3MSHwoIcmVwb3J0ZXIY'
        'BiABKAlCA+BBA1IIcmVwb3J0ZXISRAoNcmVwb3J0ZWRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm'
        '90b2J1Zi5UaW1lc3RhbXBCA+BBA1IMcmVwb3J0ZWRUaW1lEiwKEmNvbnRhY3RfdGVhbV9lbWFp'
        'bBgIIAEoCVIQY29udGFjdFRlYW1FbWFpbBpAChJIZWFsdGhNZXRyaWNzRW50cnkSEAoDa2V5GA'
        'EgASgJUgNrZXkSFAoFdmFsdWUYAiABKAJSBXZhbHVlOgI4ARo7Cg1Eb2NMaW5rc0VudHJ5EhAK'
        'A2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAEaPAoORGF0YUxpbmtzRW'
        '50cnkSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AQ==');
