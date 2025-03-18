//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/resultdb.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getInvocationRequestDescriptor instead')
const GetInvocationRequest$json = {
  '1': 'GetInvocationRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
  ],
};

/// Descriptor for `GetInvocationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getInvocationRequestDescriptor =
    $convert.base64Decode(
        'ChRHZXRJbnZvY2F0aW9uUmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWU=');

@$core.Deprecated('Use getTestResultRequestDescriptor instead')
const GetTestResultRequest$json = {
  '1': 'GetTestResultRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
  ],
};

/// Descriptor for `GetTestResultRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTestResultRequestDescriptor =
    $convert.base64Decode(
        'ChRHZXRUZXN0UmVzdWx0UmVxdWVzdBIXCgRuYW1lGAEgASgJQgPgQQJSBG5hbWU=');

@$core.Deprecated('Use listTestResultsRequestDescriptor instead')
const ListTestResultsRequest$json = {
  '1': 'ListTestResultsRequest',
  '2': [
    {'1': 'invocation', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'invocation'},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
    {
      '1': 'read_mask',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '10': 'readMask'
    },
  ],
};

/// Descriptor for `ListTestResultsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTestResultsRequestDescriptor = $convert.base64Decode(
    'ChZMaXN0VGVzdFJlc3VsdHNSZXF1ZXN0EiMKCmludm9jYXRpb24YASABKAlCA+BBAlIKaW52b2'
    'NhdGlvbhIbCglwYWdlX3NpemUYAiABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW4YAyABKAlS'
    'CXBhZ2VUb2tlbhI3CglyZWFkX21hc2sYBCABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYX'
    'NrUghyZWFkTWFzaw==');

@$core.Deprecated('Use listTestResultsResponseDescriptor instead')
const ListTestResultsResponse$json = {
  '1': 'ListTestResultsResponse',
  '2': [
    {
      '1': 'test_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestResult',
      '10': 'testResults'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListTestResultsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTestResultsResponseDescriptor = $convert.base64Decode(
    'ChdMaXN0VGVzdFJlc3VsdHNSZXNwb25zZRI/Cgx0ZXN0X3Jlc3VsdHMYASADKAsyHC5sdWNpLn'
    'Jlc3VsdGRiLnYxLlRlc3RSZXN1bHRSC3Rlc3RSZXN1bHRzEiYKD25leHRfcGFnZV90b2tlbhgC'
    'IAEoCVINbmV4dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use getTestExonerationRequestDescriptor instead')
const GetTestExonerationRequest$json = {
  '1': 'GetTestExonerationRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `GetTestExonerationRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTestExonerationRequestDescriptor =
    $convert.base64Decode(
        'ChlHZXRUZXN0RXhvbmVyYXRpb25SZXF1ZXN0EhIKBG5hbWUYASABKAlSBG5hbWU=');

@$core.Deprecated('Use listTestExonerationsRequestDescriptor instead')
const ListTestExonerationsRequest$json = {
  '1': 'ListTestExonerationsRequest',
  '2': [
    {'1': 'invocation', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'invocation'},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListTestExonerationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTestExonerationsRequestDescriptor =
    $convert.base64Decode(
        'ChtMaXN0VGVzdEV4b25lcmF0aW9uc1JlcXVlc3QSIwoKaW52b2NhdGlvbhgBIAEoCUID4EECUg'
        'ppbnZvY2F0aW9uEhsKCXBhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgD'
        'IAEoCVIJcGFnZVRva2Vu');

@$core.Deprecated('Use listTestExonerationsResponseDescriptor instead')
const ListTestExonerationsResponse$json = {
  '1': 'ListTestExonerationsResponse',
  '2': [
    {
      '1': 'test_exonerations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestExoneration',
      '10': 'testExonerations'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListTestExonerationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listTestExonerationsResponseDescriptor =
    $convert.base64Decode(
        'ChxMaXN0VGVzdEV4b25lcmF0aW9uc1Jlc3BvbnNlEk4KEXRlc3RfZXhvbmVyYXRpb25zGAEgAy'
        'gLMiEubHVjaS5yZXN1bHRkYi52MS5UZXN0RXhvbmVyYXRpb25SEHRlc3RFeG9uZXJhdGlvbnMS'
        'JgoPbmV4dF9wYWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu');

@$core.Deprecated('Use queryTestResultsRequestDescriptor instead')
const QueryTestResultsRequest$json = {
  '1': 'QueryTestResultsRequest',
  '2': [
    {'1': 'invocations', '3': 1, '4': 3, '5': 9, '10': 'invocations'},
    {
      '1': 'predicate',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestResultPredicate',
      '10': 'predicate'
    },
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 5, '4': 1, '5': 9, '10': 'pageToken'},
    {
      '1': 'read_mask',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '10': 'readMask'
    },
  ],
};

/// Descriptor for `QueryTestResultsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestResultsRequestDescriptor = $convert.base64Decode(
    'ChdRdWVyeVRlc3RSZXN1bHRzUmVxdWVzdBIgCgtpbnZvY2F0aW9ucxgBIAMoCVILaW52b2NhdG'
    'lvbnMSQwoJcHJlZGljYXRlGAIgASgLMiUubHVjaS5yZXN1bHRkYi52MS5UZXN0UmVzdWx0UHJl'
    'ZGljYXRlUglwcmVkaWNhdGUSGwoJcGFnZV9zaXplGAQgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3'
    'Rva2VuGAUgASgJUglwYWdlVG9rZW4SNwoJcmVhZF9tYXNrGAYgASgLMhouZ29vZ2xlLnByb3Rv'
    'YnVmLkZpZWxkTWFza1IIcmVhZE1hc2s=');

@$core.Deprecated('Use queryTestResultsResponseDescriptor instead')
const QueryTestResultsResponse$json = {
  '1': 'QueryTestResultsResponse',
  '2': [
    {
      '1': 'test_results',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestResult',
      '10': 'testResults'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `QueryTestResultsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestResultsResponseDescriptor = $convert.base64Decode(
    'ChhRdWVyeVRlc3RSZXN1bHRzUmVzcG9uc2USPwoMdGVzdF9yZXN1bHRzGAEgAygLMhwubHVjaS'
    '5yZXN1bHRkYi52MS5UZXN0UmVzdWx0Ugt0ZXN0UmVzdWx0cxImCg9uZXh0X3BhZ2VfdG9rZW4Y'
    'AiABKAlSDW5leHRQYWdlVG9rZW4=');

@$core.Deprecated('Use queryTestExonerationsRequestDescriptor instead')
const QueryTestExonerationsRequest$json = {
  '1': 'QueryTestExonerationsRequest',
  '2': [
    {'1': 'invocations', '3': 1, '4': 3, '5': 9, '10': 'invocations'},
    {
      '1': 'predicate',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestExonerationPredicate',
      '8': {},
      '10': 'predicate'
    },
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 5, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `QueryTestExonerationsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestExonerationsRequestDescriptor = $convert.base64Decode(
    'ChxRdWVyeVRlc3RFeG9uZXJhdGlvbnNSZXF1ZXN0EiAKC2ludm9jYXRpb25zGAEgAygJUgtpbn'
    'ZvY2F0aW9ucxJNCglwcmVkaWNhdGUYAiABKAsyKi5sdWNpLnJlc3VsdGRiLnYxLlRlc3RFeG9u'
    'ZXJhdGlvblByZWRpY2F0ZUID4EECUglwcmVkaWNhdGUSGwoJcGFnZV9zaXplGAQgASgFUghwYW'
    'dlU2l6ZRIdCgpwYWdlX3Rva2VuGAUgASgJUglwYWdlVG9rZW4=');

@$core.Deprecated('Use queryTestExonerationsResponseDescriptor instead')
const QueryTestExonerationsResponse$json = {
  '1': 'QueryTestExonerationsResponse',
  '2': [
    {
      '1': 'test_exonerations',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestExoneration',
      '10': 'testExonerations'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `QueryTestExonerationsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestExonerationsResponseDescriptor =
    $convert.base64Decode(
        'Ch1RdWVyeVRlc3RFeG9uZXJhdGlvbnNSZXNwb25zZRJOChF0ZXN0X2V4b25lcmF0aW9ucxgBIA'
        'MoCzIhLmx1Y2kucmVzdWx0ZGIudjEuVGVzdEV4b25lcmF0aW9uUhB0ZXN0RXhvbmVyYXRpb25z'
        'EiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use queryTestResultStatisticsRequestDescriptor instead')
const QueryTestResultStatisticsRequest$json = {
  '1': 'QueryTestResultStatisticsRequest',
  '2': [
    {'1': 'invocations', '3': 1, '4': 3, '5': 9, '10': 'invocations'},
  ],
};

/// Descriptor for `QueryTestResultStatisticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestResultStatisticsRequestDescriptor =
    $convert.base64Decode(
        'CiBRdWVyeVRlc3RSZXN1bHRTdGF0aXN0aWNzUmVxdWVzdBIgCgtpbnZvY2F0aW9ucxgBIAMoCV'
        'ILaW52b2NhdGlvbnM=');

@$core.Deprecated('Use queryTestResultStatisticsResponseDescriptor instead')
const QueryTestResultStatisticsResponse$json = {
  '1': 'QueryTestResultStatisticsResponse',
  '2': [
    {
      '1': 'total_test_results',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'totalTestResults'
    },
  ],
};

/// Descriptor for `QueryTestResultStatisticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestResultStatisticsResponseDescriptor =
    $convert.base64Decode(
        'CiFRdWVyeVRlc3RSZXN1bHRTdGF0aXN0aWNzUmVzcG9uc2USLAoSdG90YWxfdGVzdF9yZXN1bH'
        'RzGAEgASgDUhB0b3RhbFRlc3RSZXN1bHRz');

@$core.Deprecated('Use getArtifactRequestDescriptor instead')
const GetArtifactRequest$json = {
  '1': 'GetArtifactRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
  ],
};

/// Descriptor for `GetArtifactRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getArtifactRequestDescriptor =
    $convert.base64Decode(
        'ChJHZXRBcnRpZmFjdFJlcXVlc3QSFwoEbmFtZRgBIAEoCUID4EECUgRuYW1l');

@$core.Deprecated('Use listArtifactsRequestDescriptor instead')
const ListArtifactsRequest$json = {
  '1': 'ListArtifactsRequest',
  '2': [
    {'1': 'parent', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'parent'},
    {'1': 'page_size', '3': 2, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 3, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListArtifactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listArtifactsRequestDescriptor = $convert.base64Decode(
    'ChRMaXN0QXJ0aWZhY3RzUmVxdWVzdBIbCgZwYXJlbnQYASABKAlCA+BBAlIGcGFyZW50EhsKCX'
    'BhZ2Vfc2l6ZRgCIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgDIAEoCVIJcGFnZVRva2Vu');

@$core.Deprecated('Use listArtifactsResponseDescriptor instead')
const ListArtifactsResponse$json = {
  '1': 'ListArtifactsResponse',
  '2': [
    {
      '1': 'artifacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.Artifact',
      '10': 'artifacts'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListArtifactsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listArtifactsResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0QXJ0aWZhY3RzUmVzcG9uc2USOAoJYXJ0aWZhY3RzGAEgAygLMhoubHVjaS5yZXN1bH'
    'RkYi52MS5BcnRpZmFjdFIJYXJ0aWZhY3RzEiYKD25leHRfcGFnZV90b2tlbhgCIAEoCVINbmV4'
    'dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use queryArtifactsRequestDescriptor instead')
const QueryArtifactsRequest$json = {
  '1': 'QueryArtifactsRequest',
  '2': [
    {'1': 'invocations', '3': 1, '4': 3, '5': 9, '10': 'invocations'},
    {
      '1': 'predicate',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.ArtifactPredicate',
      '10': 'predicate'
    },
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 5, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `QueryArtifactsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryArtifactsRequestDescriptor = $convert.base64Decode(
    'ChVRdWVyeUFydGlmYWN0c1JlcXVlc3QSIAoLaW52b2NhdGlvbnMYASADKAlSC2ludm9jYXRpb2'
    '5zEkEKCXByZWRpY2F0ZRgCIAEoCzIjLmx1Y2kucmVzdWx0ZGIudjEuQXJ0aWZhY3RQcmVkaWNh'
    'dGVSCXByZWRpY2F0ZRIbCglwYWdlX3NpemUYBCABKAVSCHBhZ2VTaXplEh0KCnBhZ2VfdG9rZW'
    '4YBSABKAlSCXBhZ2VUb2tlbg==');

@$core.Deprecated('Use queryArtifactsResponseDescriptor instead')
const QueryArtifactsResponse$json = {
  '1': 'QueryArtifactsResponse',
  '2': [
    {
      '1': 'artifacts',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.Artifact',
      '10': 'artifacts'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `QueryArtifactsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryArtifactsResponseDescriptor = $convert.base64Decode(
    'ChZRdWVyeUFydGlmYWN0c1Jlc3BvbnNlEjgKCWFydGlmYWN0cxgBIAMoCzIaLmx1Y2kucmVzdW'
    'x0ZGIudjEuQXJ0aWZhY3RSCWFydGlmYWN0cxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5l'
    'eHRQYWdlVG9rZW4=');

@$core.Deprecated('Use queryTestVariantsRequestDescriptor instead')
const QueryTestVariantsRequest$json = {
  '1': 'QueryTestVariantsRequest',
  '2': [
    {'1': 'invocations', '3': 2, '4': 3, '5': 9, '10': 'invocations'},
    {
      '1': 'predicate',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestVariantPredicate',
      '10': 'predicate'
    },
    {'1': 'result_limit', '3': 8, '4': 1, '5': 5, '10': 'resultLimit'},
    {'1': 'page_size', '3': 4, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 5, '4': 1, '5': 9, '10': 'pageToken'},
    {
      '1': 'read_mask',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '10': 'readMask'
    },
  ],
};

/// Descriptor for `QueryTestVariantsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestVariantsRequestDescriptor = $convert.base64Decode(
    'ChhRdWVyeVRlc3RWYXJpYW50c1JlcXVlc3QSIAoLaW52b2NhdGlvbnMYAiADKAlSC2ludm9jYX'
    'Rpb25zEkQKCXByZWRpY2F0ZRgGIAEoCzImLmx1Y2kucmVzdWx0ZGIudjEuVGVzdFZhcmlhbnRQ'
    'cmVkaWNhdGVSCXByZWRpY2F0ZRIhCgxyZXN1bHRfbGltaXQYCCABKAVSC3Jlc3VsdExpbWl0Eh'
    'sKCXBhZ2Vfc2l6ZRgEIAEoBVIIcGFnZVNpemUSHQoKcGFnZV90b2tlbhgFIAEoCVIJcGFnZVRv'
    'a2VuEjcKCXJlYWRfbWFzaxgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE1hc2tSCHJlYW'
    'RNYXNr');

@$core.Deprecated('Use queryTestVariantsResponseDescriptor instead')
const QueryTestVariantsResponse$json = {
  '1': 'QueryTestVariantsResponse',
  '2': [
    {
      '1': 'test_variants',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestVariant',
      '10': 'testVariants'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
    {
      '1': 'sources',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.QueryTestVariantsResponse.SourcesEntry',
      '10': 'sources'
    },
  ],
  '3': [QueryTestVariantsResponse_SourcesEntry$json],
};

@$core.Deprecated('Use queryTestVariantsResponseDescriptor instead')
const QueryTestVariantsResponse_SourcesEntry$json = {
  '1': 'SourcesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Sources',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `QueryTestVariantsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestVariantsResponseDescriptor = $convert.base64Decode(
    'ChlRdWVyeVRlc3RWYXJpYW50c1Jlc3BvbnNlEkIKDXRlc3RfdmFyaWFudHMYASADKAsyHS5sdW'
    'NpLnJlc3VsdGRiLnYxLlRlc3RWYXJpYW50Ugx0ZXN0VmFyaWFudHMSJgoPbmV4dF9wYWdlX3Rv'
    'a2VuGAIgASgJUg1uZXh0UGFnZVRva2VuElIKB3NvdXJjZXMYAyADKAsyOC5sdWNpLnJlc3VsdG'
    'RiLnYxLlF1ZXJ5VGVzdFZhcmlhbnRzUmVzcG9uc2UuU291cmNlc0VudHJ5Ugdzb3VyY2VzGlUK'
    'DFNvdXJjZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIvCgV2YWx1ZRgCIAEoCzIZLmx1Y2kucm'
    'VzdWx0ZGIudjEuU291cmNlc1IFdmFsdWU6AjgB');

@$core.Deprecated('Use batchGetTestVariantsRequestDescriptor instead')
const BatchGetTestVariantsRequest$json = {
  '1': 'BatchGetTestVariantsRequest',
  '2': [
    {'1': 'invocation', '3': 1, '4': 1, '5': 9, '10': 'invocation'},
    {
      '1': 'test_variants',
      '3': 2,
      '4': 3,
      '5': 11,
      '6':
          '.luci.resultdb.v1.BatchGetTestVariantsRequest.TestVariantIdentifier',
      '10': 'testVariants'
    },
    {'1': 'result_limit', '3': 3, '4': 1, '5': 5, '10': 'resultLimit'},
  ],
  '3': [BatchGetTestVariantsRequest_TestVariantIdentifier$json],
};

@$core.Deprecated('Use batchGetTestVariantsRequestDescriptor instead')
const BatchGetTestVariantsRequest_TestVariantIdentifier$json = {
  '1': 'TestVariantIdentifier',
  '2': [
    {'1': 'test_id', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'testId'},
    {'1': 'variant_hash', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'variantHash'},
  ],
};

/// Descriptor for `BatchGetTestVariantsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchGetTestVariantsRequestDescriptor = $convert.base64Decode(
    'ChtCYXRjaEdldFRlc3RWYXJpYW50c1JlcXVlc3QSHgoKaW52b2NhdGlvbhgBIAEoCVIKaW52b2'
    'NhdGlvbhJoCg10ZXN0X3ZhcmlhbnRzGAIgAygLMkMubHVjaS5yZXN1bHRkYi52MS5CYXRjaEdl'
    'dFRlc3RWYXJpYW50c1JlcXVlc3QuVGVzdFZhcmlhbnRJZGVudGlmaWVyUgx0ZXN0VmFyaWFudH'
    'MSIQoMcmVzdWx0X2xpbWl0GAMgASgFUgtyZXN1bHRMaW1pdBpdChVUZXN0VmFyaWFudElkZW50'
    'aWZpZXISHAoHdGVzdF9pZBgBIAEoCUID4EECUgZ0ZXN0SWQSJgoMdmFyaWFudF9oYXNoGAIgAS'
    'gJQgPgQQJSC3ZhcmlhbnRIYXNo');

@$core.Deprecated('Use batchGetTestVariantsResponseDescriptor instead')
const BatchGetTestVariantsResponse$json = {
  '1': 'BatchGetTestVariantsResponse',
  '2': [
    {
      '1': 'test_variants',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestVariant',
      '10': 'testVariants'
    },
    {
      '1': 'sources',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.BatchGetTestVariantsResponse.SourcesEntry',
      '10': 'sources'
    },
  ],
  '3': [BatchGetTestVariantsResponse_SourcesEntry$json],
};

@$core.Deprecated('Use batchGetTestVariantsResponseDescriptor instead')
const BatchGetTestVariantsResponse_SourcesEntry$json = {
  '1': 'SourcesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Sources',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

/// Descriptor for `BatchGetTestVariantsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchGetTestVariantsResponseDescriptor = $convert.base64Decode(
    'ChxCYXRjaEdldFRlc3RWYXJpYW50c1Jlc3BvbnNlEkIKDXRlc3RfdmFyaWFudHMYASADKAsyHS'
    '5sdWNpLnJlc3VsdGRiLnYxLlRlc3RWYXJpYW50Ugx0ZXN0VmFyaWFudHMSVQoHc291cmNlcxgC'
    'IAMoCzI7Lmx1Y2kucmVzdWx0ZGIudjEuQmF0Y2hHZXRUZXN0VmFyaWFudHNSZXNwb25zZS5Tb3'
    'VyY2VzRW50cnlSB3NvdXJjZXMaVQoMU291cmNlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5Ei8K'
    'BXZhbHVlGAIgASgLMhkubHVjaS5yZXN1bHRkYi52MS5Tb3VyY2VzUgV2YWx1ZToCOAE=');

@$core.Deprecated('Use queryTestMetadataRequestDescriptor instead')
const QueryTestMetadataRequest$json = {
  '1': 'QueryTestMetadataRequest',
  '2': [
    {'1': 'project', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'project'},
    {
      '1': 'predicate',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestMetadataPredicate',
      '10': 'predicate'
    },
    {'1': 'page_size', '3': 3, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 4, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `QueryTestMetadataRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestMetadataRequestDescriptor = $convert.base64Decode(
    'ChhRdWVyeVRlc3RNZXRhZGF0YVJlcXVlc3QSHQoHcHJvamVjdBgBIAEoCUID4EECUgdwcm9qZW'
    'N0EkUKCXByZWRpY2F0ZRgCIAEoCzInLmx1Y2kucmVzdWx0ZGIudjEuVGVzdE1ldGFkYXRhUHJl'
    'ZGljYXRlUglwcmVkaWNhdGUSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3'
    'Rva2VuGAQgASgJUglwYWdlVG9rZW4=');

@$core.Deprecated('Use queryTestMetadataResponseDescriptor instead')
const QueryTestMetadataResponse$json = {
  '1': 'QueryTestMetadataResponse',
  '2': [
    {
      '1': 'testMetadata',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.TestMetadataDetail',
      '10': 'testMetadata'
    },
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `QueryTestMetadataResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryTestMetadataResponseDescriptor = $convert.base64Decode(
    'ChlRdWVyeVRlc3RNZXRhZGF0YVJlc3BvbnNlEkgKDHRlc3RNZXRhZGF0YRgBIAMoCzIkLmx1Y2'
    'kucmVzdWx0ZGIudjEuVGVzdE1ldGFkYXRhRGV0YWlsUgx0ZXN0TWV0YWRhdGESJgoPbmV4dF9w'
    'YWdlX3Rva2VuGAIgASgJUg1uZXh0UGFnZVRva2Vu');

@$core.Deprecated('Use queryNewTestVariantsRequestDescriptor instead')
const QueryNewTestVariantsRequest$json = {
  '1': 'QueryNewTestVariantsRequest',
  '2': [
    {'1': 'invocation', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'invocation'},
    {'1': 'baseline', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'baseline'},
  ],
};

/// Descriptor for `QueryNewTestVariantsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryNewTestVariantsRequestDescriptor =
    $convert.base64Decode(
        'ChtRdWVyeU5ld1Rlc3RWYXJpYW50c1JlcXVlc3QSIwoKaW52b2NhdGlvbhgBIAEoCUID4EECUg'
        'ppbnZvY2F0aW9uEh8KCGJhc2VsaW5lGAIgASgJQgPgQQJSCGJhc2VsaW5l');

@$core.Deprecated('Use queryNewTestVariantsResponseDescriptor instead')
const QueryNewTestVariantsResponse$json = {
  '1': 'QueryNewTestVariantsResponse',
  '2': [
    {'1': 'is_baseline_ready', '3': 1, '4': 1, '5': 8, '10': 'isBaselineReady'},
    {
      '1': 'new_test_variants',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.QueryNewTestVariantsResponse.NewTestVariant',
      '10': 'newTestVariants'
    },
  ],
  '3': [QueryNewTestVariantsResponse_NewTestVariant$json],
};

@$core.Deprecated('Use queryNewTestVariantsResponseDescriptor instead')
const QueryNewTestVariantsResponse_NewTestVariant$json = {
  '1': 'NewTestVariant',
  '2': [
    {'1': 'test_id', '3': 1, '4': 1, '5': 9, '10': 'testId'},
    {'1': 'variant_hash', '3': 2, '4': 1, '5': 9, '10': 'variantHash'},
  ],
};

/// Descriptor for `QueryNewTestVariantsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryNewTestVariantsResponseDescriptor = $convert.base64Decode(
    'ChxRdWVyeU5ld1Rlc3RWYXJpYW50c1Jlc3BvbnNlEioKEWlzX2Jhc2VsaW5lX3JlYWR5GAEgAS'
    'gIUg9pc0Jhc2VsaW5lUmVhZHkSaQoRbmV3X3Rlc3RfdmFyaWFudHMYAiADKAsyPS5sdWNpLnJl'
    'c3VsdGRiLnYxLlF1ZXJ5TmV3VGVzdFZhcmlhbnRzUmVzcG9uc2UuTmV3VGVzdFZhcmlhbnRSD2'
    '5ld1Rlc3RWYXJpYW50cxpMCg5OZXdUZXN0VmFyaWFudBIXCgd0ZXN0X2lkGAEgASgJUgZ0ZXN0'
    'SWQSIQoMdmFyaWFudF9oYXNoGAIgASgJUgt2YXJpYW50SGFzaA==');
