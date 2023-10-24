//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use variantDescriptor instead')
const Variant$json = {
  '1': 'Variant',
  '2': [
    {'1': 'def', '3': 1, '4': 3, '5': 11, '6': '.luci.resultdb.v1.Variant.DefEntry', '10': 'def'},
  ],
  '3': [Variant_DefEntry$json],
};

@$core.Deprecated('Use variantDescriptor instead')
const Variant_DefEntry$json = {
  '1': 'DefEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `Variant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List variantDescriptor =
    $convert.base64Decode('CgdWYXJpYW50EjQKA2RlZhgBIAMoCzIiLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudC5EZWZFbn'
        'RyeVIDZGVmGjYKCERlZkVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2'
        'YWx1ZToCOAE=');

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

@$core.Deprecated('Use gitilesCommitDescriptor instead')
const GitilesCommit$json = {
  '1': 'GitilesCommit',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'ref', '3': 3, '4': 1, '5': 9, '10': 'ref'},
    {'1': 'commit_hash', '3': 4, '4': 1, '5': 9, '10': 'commitHash'},
    {'1': 'position', '3': 5, '4': 1, '5': 3, '10': 'position'},
  ],
};

/// Descriptor for `GitilesCommit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitilesCommitDescriptor =
    $convert.base64Decode('Cg1HaXRpbGVzQ29tbWl0EhIKBGhvc3QYASABKAlSBGhvc3QSGAoHcHJvamVjdBgCIAEoCVIHcH'
        'JvamVjdBIQCgNyZWYYAyABKAlSA3JlZhIfCgtjb21taXRfaGFzaBgEIAEoCVIKY29tbWl0SGFz'
        'aBIaCghwb3NpdGlvbhgFIAEoA1IIcG9zaXRpb24=');

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

@$core.Deprecated('Use commitPositionDescriptor instead')
const CommitPosition$json = {
  '1': 'CommitPosition',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'ref', '3': 3, '4': 1, '5': 9, '10': 'ref'},
    {'1': 'position', '3': 4, '4': 1, '5': 3, '10': 'position'},
  ],
};

/// Descriptor for `CommitPosition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitPositionDescriptor =
    $convert.base64Decode('Cg5Db21taXRQb3NpdGlvbhISCgRob3N0GAEgASgJUgRob3N0EhgKB3Byb2plY3QYAiABKAlSB3'
        'Byb2plY3QSEAoDcmVmGAMgASgJUgNyZWYSGgoIcG9zaXRpb24YBCABKANSCHBvc2l0aW9u');

@$core.Deprecated('Use commitPositionRangeDescriptor instead')
const CommitPositionRange$json = {
  '1': 'CommitPositionRange',
  '2': [
    {'1': 'earliest', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.CommitPosition', '10': 'earliest'},
    {'1': 'latest', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.CommitPosition', '10': 'latest'},
  ],
};

/// Descriptor for `CommitPositionRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitPositionRangeDescriptor =
    $convert.base64Decode('ChNDb21taXRQb3NpdGlvblJhbmdlEjwKCGVhcmxpZXN0GAEgASgLMiAubHVjaS5yZXN1bHRkYi'
        '52MS5Db21taXRQb3NpdGlvblIIZWFybGllc3QSOAoGbGF0ZXN0GAIgASgLMiAubHVjaS5yZXN1'
        'bHRkYi52MS5Db21taXRQb3NpdGlvblIGbGF0ZXN0');

@$core.Deprecated('Use timeRangeDescriptor instead')
const TimeRange$json = {
  '1': 'TimeRange',
  '2': [
    {'1': 'earliest', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'earliest'},
    {'1': 'latest', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'latest'},
  ],
};

/// Descriptor for `TimeRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeRangeDescriptor =
    $convert.base64Decode('CglUaW1lUmFuZ2USNgoIZWFybGllc3QYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW'
        '1wUghlYXJsaWVzdBIyCgZsYXRlc3QYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w'
        'UgZsYXRlc3Q=');

@$core.Deprecated('Use sourceRefDescriptor instead')
const SourceRef$json = {
  '1': 'SourceRef',
  '2': [
    {'1': 'gitiles', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.GitilesRef', '9': 0, '10': 'gitiles'},
  ],
  '8': [
    {'1': 'system'},
  ],
};

/// Descriptor for `SourceRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourceRefDescriptor =
    $convert.base64Decode('CglTb3VyY2VSZWYSOAoHZ2l0aWxlcxgBIAEoCzIcLmx1Y2kucmVzdWx0ZGIudjEuR2l0aWxlc1'
        'JlZkgAUgdnaXRpbGVzQggKBnN5c3RlbQ==');

@$core.Deprecated('Use gitilesRefDescriptor instead')
const GitilesRef$json = {
  '1': 'GitilesRef',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'ref', '3': 3, '4': 1, '5': 9, '10': 'ref'},
  ],
};

/// Descriptor for `GitilesRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gitilesRefDescriptor =
    $convert.base64Decode('CgpHaXRpbGVzUmVmEhIKBGhvc3QYASABKAlSBGhvc3QSGAoHcHJvamVjdBgCIAEoCVIHcHJvam'
        'VjdBIQCgNyZWYYAyABKAlSA3JlZg==');
