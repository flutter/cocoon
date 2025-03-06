//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/test_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use testResultDescriptor instead')
const TestResult$json = {
  '1': 'TestResult',
  '2': [
    {'1': 'test_id', '3': 1, '4': 1, '5': 9, '10': 'testId'},
    {'1': 'result_id', '3': 2, '4': 1, '5': 9, '10': 'resultId'},
    {'1': 'expected', '3': 3, '4': 1, '5': 8, '10': 'expected'},
    {
      '1': 'status',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.luci.resultdb.v1.TestStatus',
      '10': 'status'
    },
    {'1': 'summary_html', '3': 5, '4': 1, '5': 9, '10': 'summaryHtml'},
    {
      '1': 'start_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'startTime'
    },
    {
      '1': 'duration',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'duration'
    },
    {
      '1': 'tags',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.StringPair',
      '10': 'tags'
    },
    {
      '1': 'artifacts',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.luci.resultsink.v1.TestResult.ArtifactsEntry',
      '10': 'artifacts'
    },
    {
      '1': 'test_metadata',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestMetadata',
      '10': 'testMetadata'
    },
    {
      '1': 'failure_reason',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.FailureReason',
      '10': 'failureReason'
    },
    {
      '1': 'variant',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Variant',
      '10': 'variant'
    },
    {
      '1': 'properties',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'properties'
    },
  ],
  '3': [TestResult_ArtifactsEntry$json],
  '9': [
    {'1': 10, '2': 11},
  ],
  '10': ['test_location'],
};

@$core.Deprecated('Use testResultDescriptor instead')
const TestResult_ArtifactsEntry$json = {
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

/// Descriptor for `TestResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testResultDescriptor = $convert.base64Decode(
    'CgpUZXN0UmVzdWx0EhcKB3Rlc3RfaWQYASABKAlSBnRlc3RJZBIbCglyZXN1bHRfaWQYAiABKA'
    'lSCHJlc3VsdElkEhoKCGV4cGVjdGVkGAMgASgIUghleHBlY3RlZBI0CgZzdGF0dXMYBCABKA4y'
    'HC5sdWNpLnJlc3VsdGRiLnYxLlRlc3RTdGF0dXNSBnN0YXR1cxIhCgxzdW1tYXJ5X2h0bWwYBS'
    'ABKAlSC3N1bW1hcnlIdG1sEjkKCnN0YXJ0X3RpbWUYBiABKAsyGi5nb29nbGUucHJvdG9idWYu'
    'VGltZXN0YW1wUglzdGFydFRpbWUSNQoIZHVyYXRpb24YByABKAsyGS5nb29nbGUucHJvdG9idW'
    'YuRHVyYXRpb25SCGR1cmF0aW9uEjAKBHRhZ3MYCCADKAsyHC5sdWNpLnJlc3VsdGRiLnYxLlN0'
    'cmluZ1BhaXJSBHRhZ3MSSwoJYXJ0aWZhY3RzGAkgAygLMi0ubHVjaS5yZXN1bHRzaW5rLnYxLl'
    'Rlc3RSZXN1bHQuQXJ0aWZhY3RzRW50cnlSCWFydGlmYWN0cxJDCg10ZXN0X21ldGFkYXRhGAsg'
    'ASgLMh4ubHVjaS5yZXN1bHRkYi52MS5UZXN0TWV0YWRhdGFSDHRlc3RNZXRhZGF0YRJGCg5mYW'
    'lsdXJlX3JlYXNvbhgMIAEoCzIfLmx1Y2kucmVzdWx0ZGIudjEuRmFpbHVyZVJlYXNvblINZmFp'
    'bHVyZVJlYXNvbhIzCgd2YXJpYW50GA0gASgLMhkubHVjaS5yZXN1bHRkYi52MS5WYXJpYW50Ug'
    'd2YXJpYW50EjcKCnByb3BlcnRpZXMYDiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ugpw'
    'cm9wZXJ0aWVzGloKDkFydGlmYWN0c0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjIKBXZhbHVlGA'
    'IgASgLMhwubHVjaS5yZXN1bHRzaW5rLnYxLkFydGlmYWN0UgV2YWx1ZToCOAFKBAgKEAtSDXRl'
    'c3RfbG9jYXRpb24=');

@$core.Deprecated('Use artifactDescriptor instead')
const Artifact$json = {
  '1': 'Artifact',
  '2': [
    {'1': 'file_path', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'filePath'},
    {'1': 'contents', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'contents'},
    {'1': 'gcs_uri', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'gcsUri'},
    {'1': 'content_type', '3': 3, '4': 1, '5': 9, '10': 'contentType'},
  ],
  '8': [
    {'1': 'body'},
  ],
};

/// Descriptor for `Artifact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactDescriptor = $convert.base64Decode(
    'CghBcnRpZmFjdBIdCglmaWxlX3BhdGgYASABKAlIAFIIZmlsZVBhdGgSHAoIY29udGVudHMYAi'
    'ABKAxIAFIIY29udGVudHMSGQoHZ2NzX3VyaRgEIAEoCUgAUgZnY3NVcmkSIQoMY29udGVudF90'
    'eXBlGAMgASgJUgtjb250ZW50VHlwZUIGCgRib2R5');

@$core.Deprecated('Use testResultFileDescriptor instead')
const TestResultFile$json = {
  '1': 'TestResultFile',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {
      '1': 'format',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.luci.resultsink.v1.TestResultFile.Format',
      '10': 'format'
    },
  ],
  '4': [TestResultFile_Format$json],
};

@$core.Deprecated('Use testResultFileDescriptor instead')
const TestResultFile_Format$json = {
  '1': 'Format',
  '2': [
    {'1': 'LUCI', '2': 0},
    {'1': 'CHROMIUM_JSON_TEST_RESULTS', '2': 1},
    {'1': 'GOOGLE_TEST', '2': 2},
  ],
};

/// Descriptor for `TestResultFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testResultFileDescriptor = $convert.base64Decode(
    'Cg5UZXN0UmVzdWx0RmlsZRISCgRwYXRoGAEgASgJUgRwYXRoEkEKBmZvcm1hdBgCIAEoDjIpLm'
    'x1Y2kucmVzdWx0c2luay52MS5UZXN0UmVzdWx0RmlsZS5Gb3JtYXRSBmZvcm1hdCJDCgZGb3Jt'
    'YXQSCAoETFVDSRAAEh4KGkNIUk9NSVVNX0pTT05fVEVTVF9SRVNVTFRTEAESDwoLR09PR0xFX1'
    'RFU1QQAg==');
