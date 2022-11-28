///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/predicate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use testResultPredicateDescriptor instead')
const TestResultPredicate$json = const {
  '1': 'TestResultPredicate',
  '2': const [
    const {'1': 'test_id_regexp', '3': 1, '4': 1, '5': 9, '10': 'testIdRegexp'},
    const {'1': 'variant', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.VariantPredicate', '10': 'variant'},
    const {'1': 'expectancy', '3': 3, '4': 1, '5': 14, '6': '.luci.resultdb.v1.TestResultPredicate.Expectancy', '10': 'expectancy'},
    const {'1': 'exclude_exonerated', '3': 4, '4': 1, '5': 8, '10': 'excludeExonerated'},
  ],
  '4': const [TestResultPredicate_Expectancy$json],
};

@$core.Deprecated('Use testResultPredicateDescriptor instead')
const TestResultPredicate_Expectancy$json = const {
  '1': 'Expectancy',
  '2': const [
    const {'1': 'ALL', '2': 0},
    const {'1': 'VARIANTS_WITH_UNEXPECTED_RESULTS', '2': 1},
    const {'1': 'VARIANTS_WITH_ONLY_UNEXPECTED_RESULTS', '2': 2},
  ],
};

/// Descriptor for `TestResultPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testResultPredicateDescriptor = $convert.base64Decode('ChNUZXN0UmVzdWx0UHJlZGljYXRlEiQKDnRlc3RfaWRfcmVnZXhwGAEgASgJUgx0ZXN0SWRSZWdleHASPAoHdmFyaWFudBgCIAEoCzIiLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudFByZWRpY2F0ZVIHdmFyaWFudBJQCgpleHBlY3RhbmN5GAMgASgOMjAubHVjaS5yZXN1bHRkYi52MS5UZXN0UmVzdWx0UHJlZGljYXRlLkV4cGVjdGFuY3lSCmV4cGVjdGFuY3kSLQoSZXhjbHVkZV9leG9uZXJhdGVkGAQgASgIUhFleGNsdWRlRXhvbmVyYXRlZCJmCgpFeHBlY3RhbmN5EgcKA0FMTBAAEiQKIFZBUklBTlRTX1dJVEhfVU5FWFBFQ1RFRF9SRVNVTFRTEAESKQolVkFSSUFOVFNfV0lUSF9PTkxZX1VORVhQRUNURURfUkVTVUxUUxAC');
@$core.Deprecated('Use testExonerationPredicateDescriptor instead')
const TestExonerationPredicate$json = const {
  '1': 'TestExonerationPredicate',
  '2': const [
    const {'1': 'test_id_regexp', '3': 1, '4': 1, '5': 9, '10': 'testIdRegexp'},
    const {'1': 'variant', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.VariantPredicate', '10': 'variant'},
  ],
};

/// Descriptor for `TestExonerationPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testExonerationPredicateDescriptor = $convert.base64Decode('ChhUZXN0RXhvbmVyYXRpb25QcmVkaWNhdGUSJAoOdGVzdF9pZF9yZWdleHAYASABKAlSDHRlc3RJZFJlZ2V4cBI8Cgd2YXJpYW50GAIgASgLMiIubHVjaS5yZXN1bHRkYi52MS5WYXJpYW50UHJlZGljYXRlUgd2YXJpYW50');
@$core.Deprecated('Use variantPredicateDescriptor instead')
const VariantPredicate$json = const {
  '1': 'VariantPredicate',
  '2': const [
    const {'1': 'equals', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.Variant', '9': 0, '10': 'equals'},
    const {'1': 'contains', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.Variant', '9': 0, '10': 'contains'},
  ],
  '8': const [
    const {'1': 'predicate'},
  ],
};

/// Descriptor for `VariantPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List variantPredicateDescriptor = $convert.base64Decode('ChBWYXJpYW50UHJlZGljYXRlEjMKBmVxdWFscxgBIAEoCzIZLmx1Y2kucmVzdWx0ZGIudjEuVmFyaWFudEgAUgZlcXVhbHMSNwoIY29udGFpbnMYAiABKAsyGS5sdWNpLnJlc3VsdGRiLnYxLlZhcmlhbnRIAFIIY29udGFpbnNCCwoJcHJlZGljYXRl');
@$core.Deprecated('Use artifactPredicateDescriptor instead')
const ArtifactPredicate$json = const {
  '1': 'ArtifactPredicate',
  '2': const [
    const {'1': 'follow_edges', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.ArtifactPredicate.EdgeTypeSet', '10': 'followEdges'},
    const {'1': 'test_result_predicate', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.TestResultPredicate', '10': 'testResultPredicate'},
    const {'1': 'content_type_regexp', '3': 3, '4': 1, '5': 9, '10': 'contentTypeRegexp'},
    const {'1': 'artifact_id_regexp', '3': 4, '4': 1, '5': 9, '10': 'artifactIdRegexp'},
  ],
  '3': const [ArtifactPredicate_EdgeTypeSet$json],
};

@$core.Deprecated('Use artifactPredicateDescriptor instead')
const ArtifactPredicate_EdgeTypeSet$json = const {
  '1': 'EdgeTypeSet',
  '2': const [
    const {'1': 'included_invocations', '3': 1, '4': 1, '5': 8, '10': 'includedInvocations'},
    const {'1': 'test_results', '3': 2, '4': 1, '5': 8, '10': 'testResults'},
  ],
};

/// Descriptor for `ArtifactPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactPredicateDescriptor = $convert.base64Decode('ChFBcnRpZmFjdFByZWRpY2F0ZRJSCgxmb2xsb3dfZWRnZXMYASABKAsyLy5sdWNpLnJlc3VsdGRiLnYxLkFydGlmYWN0UHJlZGljYXRlLkVkZ2VUeXBlU2V0Ugtmb2xsb3dFZGdlcxJZChV0ZXN0X3Jlc3VsdF9wcmVkaWNhdGUYAiABKAsyJS5sdWNpLnJlc3VsdGRiLnYxLlRlc3RSZXN1bHRQcmVkaWNhdGVSE3Rlc3RSZXN1bHRQcmVkaWNhdGUSLgoTY29udGVudF90eXBlX3JlZ2V4cBgDIAEoCVIRY29udGVudFR5cGVSZWdleHASLAoSYXJ0aWZhY3RfaWRfcmVnZXhwGAQgASgJUhBhcnRpZmFjdElkUmVnZXhwGmMKC0VkZ2VUeXBlU2V0EjEKFGluY2x1ZGVkX2ludm9jYXRpb25zGAEgASgIUhNpbmNsdWRlZEludm9jYXRpb25zEiEKDHRlc3RfcmVzdWx0cxgCIAEoCFILdGVzdFJlc3VsdHM=');
