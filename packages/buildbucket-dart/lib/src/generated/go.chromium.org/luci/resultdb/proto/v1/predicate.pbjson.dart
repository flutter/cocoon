//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/predicate.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use testResultPredicateDescriptor instead')
const TestResultPredicate$json = {
  '1': 'TestResultPredicate',
  '2': [
    {'1': 'test_id_regexp', '3': 1, '4': 1, '5': 9, '10': 'testIdRegexp'},
    {'1': 'variant', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.VariantPredicate', '10': 'variant'},
    {'1': 'expectancy', '3': 3, '4': 1, '5': 14, '6': '.luci.resultdb.v1.TestResultPredicate.Expectancy', '10': 'expectancy'},
    {'1': 'exclude_exonerated', '3': 4, '4': 1, '5': 8, '10': 'excludeExonerated'},
  ],
  '4': [TestResultPredicate_Expectancy$json],
};

@$core.Deprecated('Use testResultPredicateDescriptor instead')
const TestResultPredicate_Expectancy$json = {
  '1': 'Expectancy',
  '2': [
    {'1': 'ALL', '2': 0},
    {'1': 'VARIANTS_WITH_UNEXPECTED_RESULTS', '2': 1},
    {'1': 'VARIANTS_WITH_ONLY_UNEXPECTED_RESULTS', '2': 2},
  ],
};

/// Descriptor for `TestResultPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testResultPredicateDescriptor = $convert.base64Decode(
    'ChNUZXN0UmVzdWx0UHJlZGljYXRlEiQKDnRlc3RfaWRfcmVnZXhwGAEgASgJUgx0ZXN0SWRSZW'
    'dleHASPAoHdmFyaWFudBgCIAEoCzIiLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudFByZWRpY2F0'
    'ZVIHdmFyaWFudBJQCgpleHBlY3RhbmN5GAMgASgOMjAubHVjaS5yZXN1bHRkYi52MS5UZXN0Um'
    'VzdWx0UHJlZGljYXRlLkV4cGVjdGFuY3lSCmV4cGVjdGFuY3kSLQoSZXhjbHVkZV9leG9uZXJh'
    'dGVkGAQgASgIUhFleGNsdWRlRXhvbmVyYXRlZCJmCgpFeHBlY3RhbmN5EgcKA0FMTBAAEiQKIF'
    'ZBUklBTlRTX1dJVEhfVU5FWFBFQ1RFRF9SRVNVTFRTEAESKQolVkFSSUFOVFNfV0lUSF9PTkxZ'
    'X1VORVhQRUNURURfUkVTVUxUUxAC');

@$core.Deprecated('Use testExonerationPredicateDescriptor instead')
const TestExonerationPredicate$json = {
  '1': 'TestExonerationPredicate',
  '2': [
    {'1': 'test_id_regexp', '3': 1, '4': 1, '5': 9, '10': 'testIdRegexp'},
    {'1': 'variant', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.VariantPredicate', '10': 'variant'},
  ],
};

/// Descriptor for `TestExonerationPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testExonerationPredicateDescriptor = $convert.base64Decode(
    'ChhUZXN0RXhvbmVyYXRpb25QcmVkaWNhdGUSJAoOdGVzdF9pZF9yZWdleHAYASABKAlSDHRlc3'
    'RJZFJlZ2V4cBI8Cgd2YXJpYW50GAIgASgLMiIubHVjaS5yZXN1bHRkYi52MS5WYXJpYW50UHJl'
    'ZGljYXRlUgd2YXJpYW50');

@$core.Deprecated('Use variantPredicateDescriptor instead')
const VariantPredicate$json = {
  '1': 'VariantPredicate',
  '2': [
    {'1': 'equals', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.Variant', '9': 0, '10': 'equals'},
    {'1': 'contains', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.Variant', '9': 0, '10': 'contains'},
  ],
  '8': [
    {'1': 'predicate'},
  ],
};

/// Descriptor for `VariantPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List variantPredicateDescriptor = $convert.base64Decode(
    'ChBWYXJpYW50UHJlZGljYXRlEjMKBmVxdWFscxgBIAEoCzIZLmx1Y2kucmVzdWx0ZGIudjEuVm'
    'FyaWFudEgAUgZlcXVhbHMSNwoIY29udGFpbnMYAiABKAsyGS5sdWNpLnJlc3VsdGRiLnYxLlZh'
    'cmlhbnRIAFIIY29udGFpbnNCCwoJcHJlZGljYXRl');

@$core.Deprecated('Use artifactPredicateDescriptor instead')
const ArtifactPredicate$json = {
  '1': 'ArtifactPredicate',
  '2': [
    {'1': 'follow_edges', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.ArtifactPredicate.EdgeTypeSet', '10': 'followEdges'},
    {'1': 'test_result_predicate', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.TestResultPredicate', '10': 'testResultPredicate'},
    {'1': 'content_type_regexp', '3': 3, '4': 1, '5': 9, '10': 'contentTypeRegexp'},
    {'1': 'artifact_id_regexp', '3': 4, '4': 1, '5': 9, '10': 'artifactIdRegexp'},
  ],
  '3': [ArtifactPredicate_EdgeTypeSet$json],
};

@$core.Deprecated('Use artifactPredicateDescriptor instead')
const ArtifactPredicate_EdgeTypeSet$json = {
  '1': 'EdgeTypeSet',
  '2': [
    {'1': 'included_invocations', '3': 1, '4': 1, '5': 8, '10': 'includedInvocations'},
    {'1': 'test_results', '3': 2, '4': 1, '5': 8, '10': 'testResults'},
  ],
};

/// Descriptor for `ArtifactPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactPredicateDescriptor = $convert.base64Decode(
    'ChFBcnRpZmFjdFByZWRpY2F0ZRJSCgxmb2xsb3dfZWRnZXMYASABKAsyLy5sdWNpLnJlc3VsdG'
    'RiLnYxLkFydGlmYWN0UHJlZGljYXRlLkVkZ2VUeXBlU2V0Ugtmb2xsb3dFZGdlcxJZChV0ZXN0'
    'X3Jlc3VsdF9wcmVkaWNhdGUYAiABKAsyJS5sdWNpLnJlc3VsdGRiLnYxLlRlc3RSZXN1bHRQcm'
    'VkaWNhdGVSE3Rlc3RSZXN1bHRQcmVkaWNhdGUSLgoTY29udGVudF90eXBlX3JlZ2V4cBgDIAEo'
    'CVIRY29udGVudFR5cGVSZWdleHASLAoSYXJ0aWZhY3RfaWRfcmVnZXhwGAQgASgJUhBhcnRpZm'
    'FjdElkUmVnZXhwGmMKC0VkZ2VUeXBlU2V0EjEKFGluY2x1ZGVkX2ludm9jYXRpb25zGAEgASgI'
    'UhNpbmNsdWRlZEludm9jYXRpb25zEiEKDHRlc3RfcmVzdWx0cxgCIAEoCFILdGVzdFJlc3VsdH'
    'M=');

@$core.Deprecated('Use testMetadataPredicateDescriptor instead')
const TestMetadataPredicate$json = {
  '1': 'TestMetadataPredicate',
  '2': [
    {'1': 'test_ids', '3': 1, '4': 3, '5': 9, '10': 'testIds'},
  ],
};

/// Descriptor for `TestMetadataPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testMetadataPredicateDescriptor = $convert.base64Decode(
    'ChVUZXN0TWV0YWRhdGFQcmVkaWNhdGUSGQoIdGVzdF9pZHMYASADKAlSB3Rlc3RJZHM=');

