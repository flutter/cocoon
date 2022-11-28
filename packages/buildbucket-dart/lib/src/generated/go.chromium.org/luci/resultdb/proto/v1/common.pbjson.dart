///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use variantDescriptor instead')
const Variant$json = const {
  '1': 'Variant',
  '2': const [
    const {'1': 'def', '3': 1, '4': 3, '5': 11, '6': '.luci.resultdb.v1.Variant.DefEntry', '10': 'def'},
  ],
  '3': const [Variant_DefEntry$json],
};

@$core.Deprecated('Use variantDescriptor instead')
const Variant_DefEntry$json = const {
  '1': 'DefEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

/// Descriptor for `Variant`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List variantDescriptor = $convert.base64Decode('CgdWYXJpYW50EjQKA2RlZhgBIAMoCzIiLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudC5EZWZFbnRyeVIDZGVmGjYKCERlZkVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAE=');
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
@$core.Deprecated('Use commitPositionDescriptor instead')
const CommitPosition$json = const {
  '1': 'CommitPosition',
  '2': const [
    const {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    const {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    const {'1': 'ref', '3': 3, '4': 1, '5': 9, '10': 'ref'},
    const {'1': 'position', '3': 4, '4': 1, '5': 3, '10': 'position'},
  ],
};

/// Descriptor for `CommitPosition`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitPositionDescriptor = $convert.base64Decode('Cg5Db21taXRQb3NpdGlvbhISCgRob3N0GAEgASgJUgRob3N0EhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSEAoDcmVmGAMgASgJUgNyZWYSGgoIcG9zaXRpb24YBCABKANSCHBvc2l0aW9u');
@$core.Deprecated('Use commitPositionRangeDescriptor instead')
const CommitPositionRange$json = const {
  '1': 'CommitPositionRange',
  '2': const [
    const {'1': 'earliest', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.CommitPosition', '10': 'earliest'},
    const {'1': 'latest', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.CommitPosition', '10': 'latest'},
  ],
};

/// Descriptor for `CommitPositionRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitPositionRangeDescriptor = $convert.base64Decode('ChNDb21taXRQb3NpdGlvblJhbmdlEjwKCGVhcmxpZXN0GAEgASgLMiAubHVjaS5yZXN1bHRkYi52MS5Db21taXRQb3NpdGlvblIIZWFybGllc3QSOAoGbGF0ZXN0GAIgASgLMiAubHVjaS5yZXN1bHRkYi52MS5Db21taXRQb3NpdGlvblIGbGF0ZXN0');
@$core.Deprecated('Use timeRangeDescriptor instead')
const TimeRange$json = const {
  '1': 'TimeRange',
  '2': const [
    const {'1': 'earliest', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'earliest'},
    const {'1': 'latest', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'latest'},
  ],
};

/// Descriptor for `TimeRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List timeRangeDescriptor = $convert.base64Decode('CglUaW1lUmFuZ2USNgoIZWFybGllc3QYASABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUghlYXJsaWVzdBIyCgZsYXRlc3QYAiABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgZsYXRlc3Q=');
