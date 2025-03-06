//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/sink.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use reportTestResultsRequestDescriptor instead')
const ReportTestResultsRequest$json = {
  '1': 'ReportTestResultsRequest',
  '2': [
    {
      '1': 'test_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultsink.v1.TestResult',
      '10': 'testResults'
    },
  ],
};

/// Descriptor for `ReportTestResultsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportTestResultsRequestDescriptor =
    $convert.base64Decode(
        'ChhSZXBvcnRUZXN0UmVzdWx0c1JlcXVlc3QSQQoMdGVzdF9yZXN1bHRzGAEgAygLMh4ubHVjaS'
        '5yZXN1bHRzaW5rLnYxLlRlc3RSZXN1bHRSC3Rlc3RSZXN1bHRz');

@$core.Deprecated('Use reportTestResultsResponseDescriptor instead')
const ReportTestResultsResponse$json = {
  '1': 'ReportTestResultsResponse',
  '2': [
    {'1': 'test_result_names', '3': 1, '4': 3, '5': 9, '10': 'testResultNames'},
  ],
};

/// Descriptor for `ReportTestResultsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportTestResultsResponseDescriptor =
    $convert.base64Decode(
        'ChlSZXBvcnRUZXN0UmVzdWx0c1Jlc3BvbnNlEioKEXRlc3RfcmVzdWx0X25hbWVzGAEgAygJUg'
        '90ZXN0UmVzdWx0TmFtZXM=');

@$core.Deprecated('Use reportInvocationLevelArtifactsRequestDescriptor instead')
const ReportInvocationLevelArtifactsRequest$json = {
  '1': 'ReportInvocationLevelArtifactsRequest',
  '2': [
    {
      '1': 'artifacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6':
          '.luci.resultsink.v1.ReportInvocationLevelArtifactsRequest.ArtifactsEntry',
      '10': 'artifacts'
    },
  ],
  '3': [ReportInvocationLevelArtifactsRequest_ArtifactsEntry$json],
};

@$core.Deprecated('Use reportInvocationLevelArtifactsRequestDescriptor instead')
const ReportInvocationLevelArtifactsRequest_ArtifactsEntry$json = {
  '1': 'ArtifactsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultsink.v1.Artifact',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `ReportInvocationLevelArtifactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportInvocationLevelArtifactsRequestDescriptor =
    $convert.base64Decode(
        'CiVSZXBvcnRJbnZvY2F0aW9uTGV2ZWxBcnRpZmFjdHNSZXF1ZXN0EmYKCWFydGlmYWN0cxgBIA'
        'MoCzJILmx1Y2kucmVzdWx0c2luay52MS5SZXBvcnRJbnZvY2F0aW9uTGV2ZWxBcnRpZmFjdHNS'
        'ZXF1ZXN0LkFydGlmYWN0c0VudHJ5UglhcnRpZmFjdHMaWgoOQXJ0aWZhY3RzRW50cnkSEAoDa2'
        'V5GAEgASgJUgNrZXkSMgoFdmFsdWUYAiABKAsyHC5sdWNpLnJlc3VsdHNpbmsudjEuQXJ0aWZh'
        'Y3RSBXZhbHVlOgI4AQ==');
