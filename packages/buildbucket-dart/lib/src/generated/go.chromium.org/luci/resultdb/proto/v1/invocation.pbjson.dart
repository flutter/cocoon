///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use invocationDescriptor instead')
const Invocation$json = const {
  '1': 'Invocation',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '8': const {}, '10': 'name'},
    const {'1': 'state', '3': 2, '4': 1, '5': 14, '6': '.luci.resultdb.v1.Invocation.State', '10': 'state'},
    const {
      '1': 'create_time',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'createTime'
    },
    const {'1': 'tags', '3': 5, '4': 3, '5': 11, '6': '.luci.resultdb.v1.StringPair', '10': 'tags'},
    const {
      '1': 'finalize_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'finalizeTime'
    },
    const {'1': 'deadline', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'deadline'},
    const {'1': 'included_invocations', '3': 8, '4': 3, '5': 9, '10': 'includedInvocations'},
    const {
      '1': 'bigquery_exports',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport',
      '10': 'bigqueryExports'
    },
    const {'1': 'created_by', '3': 10, '4': 1, '5': 9, '8': const {}, '10': 'createdBy'},
    const {'1': 'producer_resource', '3': 11, '4': 1, '5': 9, '10': 'producerResource'},
    const {'1': 'realm', '3': 12, '4': 1, '5': 9, '10': 'realm'},
    const {
      '1': 'history_options',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.HistoryOptions',
      '10': 'historyOptions'
    },
  ],
  '4': const [Invocation_State$json],
  '9': const [
    const {'1': 3, '2': 4},
  ],
};

@$core.Deprecated('Use invocationDescriptor instead')
const Invocation_State$json = const {
  '1': 'State',
  '2': const [
    const {'1': 'STATE_UNSPECIFIED', '2': 0},
    const {'1': 'ACTIVE', '2': 1},
    const {'1': 'FINALIZING', '2': 2},
    const {'1': 'FINALIZED', '2': 3},
  ],
};

/// Descriptor for `Invocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invocationDescriptor = $convert.base64Decode(
    'CgpJbnZvY2F0aW9uEhoKBG5hbWUYASABKAlCBuBBA+BBBVIEbmFtZRI4CgVzdGF0ZRgCIAEoDjIiLmx1Y2kucmVzdWx0ZGIudjEuSW52b2NhdGlvbi5TdGF0ZVIFc3RhdGUSQwoLY3JlYXRlX3RpbWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgbgQQPgQQVSCmNyZWF0ZVRpbWUSMAoEdGFncxgFIAMoCzIcLmx1Y2kucmVzdWx0ZGIudjEuU3RyaW5nUGFpclIEdGFncxJECg1maW5hbGl6ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgxmaW5hbGl6ZVRpbWUSNgoIZGVhZGxpbmUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUghkZWFkbGluZRIxChRpbmNsdWRlZF9pbnZvY2F0aW9ucxgIIAMoCVITaW5jbHVkZWRJbnZvY2F0aW9ucxJLChBiaWdxdWVyeV9leHBvcnRzGAkgAygLMiAubHVjaS5yZXN1bHRkYi52MS5CaWdRdWVyeUV4cG9ydFIPYmlncXVlcnlFeHBvcnRzEiIKCmNyZWF0ZWRfYnkYCiABKAlCA+BBA1IJY3JlYXRlZEJ5EisKEXByb2R1Y2VyX3Jlc291cmNlGAsgASgJUhBwcm9kdWNlclJlc291cmNlEhQKBXJlYWxtGAwgASgJUgVyZWFsbRJJCg9oaXN0b3J5X29wdGlvbnMYDSABKAsyIC5sdWNpLnJlc3VsdGRiLnYxLkhpc3RvcnlPcHRpb25zUg5oaXN0b3J5T3B0aW9ucyJJCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRBAAEgoKBkFDVElWRRABEg4KCkZJTkFMSVpJTkcQAhINCglGSU5BTElaRUQQA0oECAMQBA==');
@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport$json = const {
  '1': 'BigQueryExport',
  '2': const [
    const {'1': 'project', '3': 1, '4': 1, '5': 9, '8': const {}, '10': 'project'},
    const {'1': 'dataset', '3': 2, '4': 1, '5': 9, '8': const {}, '10': 'dataset'},
    const {'1': 'table', '3': 3, '4': 1, '5': 9, '8': const {}, '10': 'table'},
    const {
      '1': 'test_results',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport.TestResults',
      '9': 0,
      '10': 'testResults'
    },
    const {
      '1': 'text_artifacts',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport.TextArtifacts',
      '9': 0,
      '10': 'textArtifacts'
    },
  ],
  '3': const [BigQueryExport_TestResults$json, BigQueryExport_TextArtifacts$json],
  '8': const [
    const {'1': 'result_type'},
  ],
};

@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport_TestResults$json = const {
  '1': 'TestResults',
  '2': const [
    const {'1': 'predicate', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.TestResultPredicate', '10': 'predicate'},
  ],
};

@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport_TextArtifacts$json = const {
  '1': 'TextArtifacts',
  '2': const [
    const {'1': 'predicate', '3': 1, '4': 1, '5': 11, '6': '.luci.resultdb.v1.ArtifactPredicate', '10': 'predicate'},
  ],
};

/// Descriptor for `BigQueryExport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bigQueryExportDescriptor = $convert.base64Decode(
    'Cg5CaWdRdWVyeUV4cG9ydBIdCgdwcm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHQoHZGF0YXNldBgCIAEoCUID4EECUgdkYXRhc2V0EhkKBXRhYmxlGAMgASgJQgPgQQJSBXRhYmxlElEKDHRlc3RfcmVzdWx0cxgEIAEoCzIsLmx1Y2kucmVzdWx0ZGIudjEuQmlnUXVlcnlFeHBvcnQuVGVzdFJlc3VsdHNIAFILdGVzdFJlc3VsdHMSVwoOdGV4dF9hcnRpZmFjdHMYBiABKAsyLi5sdWNpLnJlc3VsdGRiLnYxLkJpZ1F1ZXJ5RXhwb3J0LlRleHRBcnRpZmFjdHNIAFINdGV4dEFydGlmYWN0cxpSCgtUZXN0UmVzdWx0cxJDCglwcmVkaWNhdGUYASABKAsyJS5sdWNpLnJlc3VsdGRiLnYxLlRlc3RSZXN1bHRQcmVkaWNhdGVSCXByZWRpY2F0ZRpSCg1UZXh0QXJ0aWZhY3RzEkEKCXByZWRpY2F0ZRgBIAEoCzIjLmx1Y2kucmVzdWx0ZGIudjEuQXJ0aWZhY3RQcmVkaWNhdGVSCXByZWRpY2F0ZUINCgtyZXN1bHRfdHlwZQ==');
@$core.Deprecated('Use historyOptionsDescriptor instead')
const HistoryOptions$json = const {
  '1': 'HistoryOptions',
  '2': const [
    const {'1': 'use_invocation_timestamp', '3': 1, '4': 1, '5': 8, '10': 'useInvocationTimestamp'},
    const {'1': 'commit', '3': 2, '4': 1, '5': 11, '6': '.luci.resultdb.v1.CommitPosition', '10': 'commit'},
  ],
};

/// Descriptor for `HistoryOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List historyOptionsDescriptor = $convert.base64Decode(
    'Cg5IaXN0b3J5T3B0aW9ucxI4Chh1c2VfaW52b2NhdGlvbl90aW1lc3RhbXAYASABKAhSFnVzZUludm9jYXRpb25UaW1lc3RhbXASOAoGY29tbWl0GAIgASgLMiAubHVjaS5yZXN1bHRkYi52MS5Db21taXRQb3NpdGlvblIGY29tbWl0');
