//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/test_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use testStatusDescriptor instead')
const TestStatus$json = {
  '1': 'TestStatus',
  '2': [
    {'1': 'STATUS_UNSPECIFIED', '2': 0},
    {'1': 'PASS', '2': 1},
    {'1': 'FAIL', '2': 2},
    {'1': 'CRASH', '2': 3},
    {'1': 'ABORT', '2': 4},
    {'1': 'SKIP', '2': 5},
  ],
};

/// Descriptor for `TestStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List testStatusDescriptor = $convert.base64Decode(
    'CgpUZXN0U3RhdHVzEhYKElNUQVRVU19VTlNQRUNJRklFRBAAEggKBFBBU1MQARIICgRGQUlMEA'
    'ISCQoFQ1JBU0gQAxIJCgVBQk9SVBAEEggKBFNLSVAQBQ==');

@$core.Deprecated('Use skipReasonDescriptor instead')
const SkipReason$json = {
  '1': 'SkipReason',
  '2': [
    {'1': 'SKIP_REASON_UNSPECIFIED', '2': 0},
    {'1': 'AUTOMATICALLY_DISABLED_FOR_FLAKINESS', '2': 1},
  ],
};

/// Descriptor for `SkipReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List skipReasonDescriptor = $convert.base64Decode(
    'CgpTa2lwUmVhc29uEhsKF1NLSVBfUkVBU09OX1VOU1BFQ0lGSUVEEAASKAokQVVUT01BVElDQU'
    'xMWV9ESVNBQkxFRF9GT1JfRkxBS0lORVNTEAE=');

@$core.Deprecated('Use exonerationReasonDescriptor instead')
const ExonerationReason$json = {
  '1': 'ExonerationReason',
  '2': [
    {'1': 'EXONERATION_REASON_UNSPECIFIED', '2': 0},
    {'1': 'OCCURS_ON_MAINLINE', '2': 1},
    {'1': 'OCCURS_ON_OTHER_CLS', '2': 2},
    {'1': 'NOT_CRITICAL', '2': 3},
    {'1': 'UNEXPECTED_PASS', '2': 4},
  ],
};

/// Descriptor for `ExonerationReason`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List exonerationReasonDescriptor = $convert.base64Decode(
    'ChFFeG9uZXJhdGlvblJlYXNvbhIiCh5FWE9ORVJBVElPTl9SRUFTT05fVU5TUEVDSUZJRUQQAB'
    'IWChJPQ0NVUlNfT05fTUFJTkxJTkUQARIXChNPQ0NVUlNfT05fT1RIRVJfQ0xTEAISEAoMTk9U'
    'X0NSSVRJQ0FMEAMSEwoPVU5FWFBFQ1RFRF9QQVNTEAQ=');

@$core.Deprecated('Use testResultDescriptor instead')
const TestResult$json = {
  '1': 'TestResult',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'test_id', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'testId'},
    {'1': 'result_id', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'resultId'},
    {
      '1': 'variant',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Variant',
      '8': {},
      '10': 'variant'
    },
    {'1': 'expected', '3': 5, '4': 1, '5': 8, '8': {}, '10': 'expected'},
    {
      '1': 'status',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.luci.resultdb.v1.TestStatus',
      '8': {},
      '10': 'status'
    },
    {'1': 'summary_html', '3': 7, '4': 1, '5': 9, '8': {}, '10': 'summaryHtml'},
    {
      '1': 'start_time',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': {},
      '10': 'startTime'
    },
    {
      '1': 'duration',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '8': {},
      '10': 'duration'
    },
    {
      '1': 'tags',
      '3': 10,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.StringPair',
      '8': {},
      '10': 'tags'
    },
    {
      '1': 'variant_hash',
      '3': 12,
      '4': 1,
      '5': 9,
      '8': {},
      '10': 'variantHash'
    },
    {
      '1': 'test_metadata',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestMetadata',
      '10': 'testMetadata'
    },
    {
      '1': 'failure_reason',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.FailureReason',
      '10': 'failureReason'
    },
    {
      '1': 'properties',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'properties'
    },
    {'1': 'is_masked', '3': 16, '4': 1, '5': 8, '8': {}, '10': 'isMasked'},
    {
      '1': 'skip_reason',
      '3': 18,
      '4': 1,
      '5': 14,
      '6': '.luci.resultdb.v1.SkipReason',
      '10': 'skipReason'
    },
  ],
  '9': [
    {'1': 11, '2': 12},
  ],
};

/// Descriptor for `TestResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testResultDescriptor = $convert.base64Decode(
    'CgpUZXN0UmVzdWx0EhoKBG5hbWUYASABKAlCBuBBA+BBBVIEbmFtZRIcCgd0ZXN0X2lkGAIgAS'
    'gJQgPgQQVSBnRlc3RJZBIjCglyZXN1bHRfaWQYAyABKAlCBuBBBeBBAlIIcmVzdWx0SWQSOAoH'
    'dmFyaWFudBgEIAEoCzIZLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudEID4EEFUgd2YXJpYW50Eh'
    '8KCGV4cGVjdGVkGAUgASgIQgPgQQVSCGV4cGVjdGVkEjkKBnN0YXR1cxgGIAEoDjIcLmx1Y2ku'
    'cmVzdWx0ZGIudjEuVGVzdFN0YXR1c0ID4EEFUgZzdGF0dXMSJgoMc3VtbWFyeV9odG1sGAcgAS'
    'gJQgPgQQVSC3N1bW1hcnlIdG1sEj4KCnN0YXJ0X3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9i'
    'dWYuVGltZXN0YW1wQgPgQQVSCXN0YXJ0VGltZRI6CghkdXJhdGlvbhgJIAEoCzIZLmdvb2dsZS'
    '5wcm90b2J1Zi5EdXJhdGlvbkID4EEFUghkdXJhdGlvbhI1CgR0YWdzGAogAygLMhwubHVjaS5y'
    'ZXN1bHRkYi52MS5TdHJpbmdQYWlyQgPgQQVSBHRhZ3MSKQoMdmFyaWFudF9oYXNoGAwgASgJQg'
    'bgQQPgQQVSC3ZhcmlhbnRIYXNoEkMKDXRlc3RfbWV0YWRhdGEYDSABKAsyHi5sdWNpLnJlc3Vs'
    'dGRiLnYxLlRlc3RNZXRhZGF0YVIMdGVzdE1ldGFkYXRhEkYKDmZhaWx1cmVfcmVhc29uGA4gAS'
    'gLMh8ubHVjaS5yZXN1bHRkYi52MS5GYWlsdXJlUmVhc29uUg1mYWlsdXJlUmVhc29uEjcKCnBy'
    'b3BlcnRpZXMYDyABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0Ugpwcm9wZXJ0aWVzEiAKCW'
    'lzX21hc2tlZBgQIAEoCEID4EEDUghpc01hc2tlZBI9Cgtza2lwX3JlYXNvbhgSIAEoDjIcLmx1'
    'Y2kucmVzdWx0ZGIudjEuU2tpcFJlYXNvblIKc2tpcFJlYXNvbkoECAsQDA==');

@$core.Deprecated('Use testExonerationDescriptor instead')
const TestExoneration$json = {
  '1': 'TestExoneration',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'test_id', '3': 2, '4': 1, '5': 9, '10': 'testId'},
    {
      '1': 'variant',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Variant',
      '10': 'variant'
    },
    {
      '1': 'exoneration_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '8': {},
      '10': 'exonerationId'
    },
    {
      '1': 'explanation_html',
      '3': 5,
      '4': 1,
      '5': 9,
      '8': {},
      '10': 'explanationHtml'
    },
    {'1': 'variant_hash', '3': 6, '4': 1, '5': 9, '8': {}, '10': 'variantHash'},
    {
      '1': 'reason',
      '3': 7,
      '4': 1,
      '5': 14,
      '6': '.luci.resultdb.v1.ExonerationReason',
      '8': {},
      '10': 'reason'
    },
    {'1': 'is_masked', '3': 8, '4': 1, '5': 8, '8': {}, '10': 'isMasked'},
  ],
};

/// Descriptor for `TestExoneration`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testExonerationDescriptor = $convert.base64Decode(
    'Cg9UZXN0RXhvbmVyYXRpb24SGgoEbmFtZRgBIAEoCUIG4EED4EEFUgRuYW1lEhcKB3Rlc3RfaW'
    'QYAiABKAlSBnRlc3RJZBIzCgd2YXJpYW50GAMgASgLMhkubHVjaS5yZXN1bHRkYi52MS5WYXJp'
    'YW50Ugd2YXJpYW50Ei0KDmV4b25lcmF0aW9uX2lkGAQgASgJQgbgQQPgQQVSDWV4b25lcmF0aW'
    '9uSWQSLgoQZXhwbGFuYXRpb25faHRtbBgFIAEoCUID4EEFUg9leHBsYW5hdGlvbkh0bWwSJgoM'
    'dmFyaWFudF9oYXNoGAYgASgJQgPgQQVSC3ZhcmlhbnRIYXNoEkAKBnJlYXNvbhgHIAEoDjIjLm'
    'x1Y2kucmVzdWx0ZGIudjEuRXhvbmVyYXRpb25SZWFzb25CA+BBBVIGcmVhc29uEiAKCWlzX21h'
    'c2tlZBgIIAEoCEID4EEDUghpc01hc2tlZA==');
