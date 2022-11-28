///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use statusDescriptor instead')
const Status$json = const {
  '1': 'Status',
  '2': const [
    const {'1': 'STATUS_UNSPECIFIED', '2': 0},
    const {'1': 'SCHEDULED', '2': 1},
    const {'1': 'STARTED', '2': 2},
    const {'1': 'ENDED_MASK', '2': 4},
    const {'1': 'SUCCESS', '2': 12},
    const {'1': 'FAILURE', '2': 20},
    const {'1': 'INFRA_FAILURE', '2': 36},
    const {'1': 'CANCELED', '2': 68},
  ],
};

/// Descriptor for `Status`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List statusDescriptor = $convert.base64Decode('CgZTdGF0dXMSFgoSU1RBVFVTX1VOU1BFQ0lGSUVEEAASDQoJU0NIRURVTEVEEAESCwoHU1RBUlRFRBACEg4KCkVOREVEX01BU0sQBBILCgdTVUNDRVNTEAwSCwoHRkFJTFVSRRAUEhEKDUlORlJBX0ZBSUxVUkUQJBIMCghDQU5DRUxFRBBE');
@$core.Deprecated('Use trinaryDescriptor instead')
const Trinary$json = const {
  '1': 'Trinary',
  '2': const [
    const {'1': 'UNSET', '2': 0},
    const {'1': 'YES', '2': 1},
    const {'1': 'NO', '2': 2},
  ],
};

/// Descriptor for `Trinary`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List trinaryDescriptor = $convert.base64Decode('CgdUcmluYXJ5EgkKBVVOU0VUEAASBwoDWUVTEAESBgoCTk8QAg==');
@$core.Deprecated('Use compressionDescriptor instead')
const Compression$json = const {
  '1': 'Compression',
  '2': const [
    const {'1': 'ZLIB', '2': 0},
    const {'1': 'ZSTD', '2': 1},
  ],
};

/// Descriptor for `Compression`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List compressionDescriptor = $convert.base64Decode('CgtDb21wcmVzc2lvbhIICgRaTElCEAASCAoEWlNURBAB');
@$core.Deprecated('Use executableDescriptor instead')
const Executable$json = const {
  '1': 'Executable',
  '2': const [
    const {'1': 'cipd_package', '3': 1, '4': 1, '5': 9, '10': 'cipdPackage'},
    const {'1': 'cipd_version', '3': 2, '4': 1, '5': 9, '10': 'cipdVersion'},
    const {'1': 'cmd', '3': 3, '4': 3, '5': 9, '10': 'cmd'},
    const {'1': 'wrapper', '3': 4, '4': 3, '5': 9, '10': 'wrapper'},
  ],
};

/// Descriptor for `Executable`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List executableDescriptor = $convert.base64Decode('CgpFeGVjdXRhYmxlEiEKDGNpcGRfcGFja2FnZRgBIAEoCVILY2lwZFBhY2thZ2USIQoMY2lwZF92ZXJzaW9uGAIgASgJUgtjaXBkVmVyc2lvbhIQCgNjbWQYAyADKAlSA2NtZBIYCgd3cmFwcGVyGAQgAygJUgd3cmFwcGVy');
@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails$json = const {
  '1': 'StatusDetails',
  '2': const [
    const {'1': 'resource_exhaustion', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails.ResourceExhaustion', '10': 'resourceExhaustion'},
    const {'1': 'timeout', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails.Timeout', '10': 'timeout'},
  ],
  '3': const [StatusDetails_ResourceExhaustion$json, StatusDetails_Timeout$json],
  '9': const [
    const {'1': 1, '2': 2},
    const {'1': 2, '2': 3},
  ],
};

@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails_ResourceExhaustion$json = const {
  '1': 'ResourceExhaustion',
};

@$core.Deprecated('Use statusDetailsDescriptor instead')
const StatusDetails_Timeout$json = const {
  '1': 'Timeout',
};

/// Descriptor for `StatusDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statusDetailsDescriptor = $convert.base64Decode('Cg1TdGF0dXNEZXRhaWxzEmEKE3Jlc291cmNlX2V4aGF1c3Rpb24YAyABKAsyMC5idWlsZGJ1Y2tldC52Mi5TdGF0dXNEZXRhaWxzLlJlc291cmNlRXhoYXVzdGlvblIScmVzb3VyY2VFeGhhdXN0aW9uEj8KB3RpbWVvdXQYBCABKAsyJS5idWlsZGJ1Y2tldC52Mi5TdGF0dXNEZXRhaWxzLlRpbWVvdXRSB3RpbWVvdXQaFAoSUmVzb3VyY2VFeGhhdXN0aW9uGgkKB1RpbWVvdXRKBAgBEAJKBAgCEAM=');
@$core.Deprecated('Use logDescriptor instead')
const Log$json = const {
  '1': 'Log',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'view_url', '3': 2, '4': 1, '5': 9, '10': 'viewUrl'},
    const {'1': 'url', '3': 3, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `Log`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logDescriptor = $convert.base64Decode('CgNMb2cSEgoEbmFtZRgBIAEoCVIEbmFtZRIZCgh2aWV3X3VybBgCIAEoCVIHdmlld1VybBIQCgN1cmwYAyABKAlSA3VybA==');
@$core.Deprecated('Use gerritChangeDescriptor instead')
const GerritChange$json = const {
  '1': 'GerritChange',
  '2': const [
    const {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    const {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    const {'1': 'change', '3': 3, '4': 1, '5': 3, '10': 'change'},
    const {'1': 'patchset', '3': 4, '4': 1, '5': 3, '10': 'patchset'},
  ],
};

/// Descriptor for `GerritChange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gerritChangeDescriptor = $convert.base64Decode('CgxHZXJyaXRDaGFuZ2USEgoEaG9zdBgBIAEoCVIEaG9zdBIYCgdwcm9qZWN0GAIgASgJUgdwcm9qZWN0EhYKBmNoYW5nZRgDIAEoA1IGY2hhbmdlEhoKCHBhdGNoc2V0GAQgASgDUghwYXRjaHNldA==');
@$core.Deprecated('Use gitilesCommitDescriptor instead')
const GitilesCommit$json = const {
  '1': 'GitilesCommit',
  '2': const [
    const {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    const {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    const {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
    const {'1': 'ref', '3': 4, '4': 1, '5': 9, '10': 'ref'},
    const {'1': 'position', '3': 5, '4': 1, '5': 13, '10': 'position'},
  ],
};

/// Descriptor for `GitilesCommit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitilesCommitDescriptor = $convert.base64Decode('Cg1HaXRpbGVzQ29tbWl0EhIKBGhvc3QYASABKAlSBGhvc3QSGAoHcHJvamVjdBgCIAEoCVIHcHJvamVjdBIOCgJpZBgDIAEoCVICaWQSEAoDcmVmGAQgASgJUgNyZWYSGgoIcG9zaXRpb24YBSABKA1SCHBvc2l0aW9u');
@$core.Deprecated('Use stringPairDescriptor instead')
const StringPair$json = const {
  '1': 'StringPair',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `StringPair`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringPairDescriptor = $convert.base64Decode('CgpTdHJpbmdQYWlyEhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZQ==');
@$core.Deprecated('Use timeRangeDescriptor instead')
const TimeRange$json = const {
  '1': 'TimeRange',
  '2': const [
    const {'1': 'start_time', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    const {'1': 'end_time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endTime'},
  ],
};

/// Descriptor for `TimeRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeRangeDescriptor = $convert.base64Decode('CglUaW1lUmFuZ2USOQoKc3RhcnRfdGltZRgBIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgCIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWU=');
@$core.Deprecated('Use requestedDimensionDescriptor instead')
const RequestedDimension$json = const {
  '1': 'RequestedDimension',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
    const {'1': 'expiration', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'expiration'},
  ],
};

/// Descriptor for `RequestedDimension`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestedDimensionDescriptor = $convert.base64Decode('ChJSZXF1ZXN0ZWREaW1lbnNpb24SEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlEjkKCmV4cGlyYXRpb24YAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCmV4cGlyYXRpb24=');
