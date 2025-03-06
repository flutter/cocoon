//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/invocation.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use invocationDescriptor instead')
const Invocation$json = {
  '1': 'Invocation',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {
      '1': 'state',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.luci.resultdb.v1.Invocation.State',
      '10': 'state'
    },
    {
      '1': 'create_time',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': {},
      '10': 'createTime'
    },
    {
      '1': 'tags',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.StringPair',
      '10': 'tags'
    },
    {
      '1': 'finalize_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': {},
      '10': 'finalizeTime'
    },
    {
      '1': 'deadline',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'deadline'
    },
    {
      '1': 'included_invocations',
      '3': 8,
      '4': 3,
      '5': 9,
      '10': 'includedInvocations'
    },
    {
      '1': 'bigquery_exports',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport',
      '10': 'bigqueryExports'
    },
    {'1': 'created_by', '3': 10, '4': 1, '5': 9, '8': {}, '10': 'createdBy'},
    {
      '1': 'producer_resource',
      '3': 11,
      '4': 1,
      '5': 9,
      '10': 'producerResource'
    },
    {'1': 'realm', '3': 12, '4': 1, '5': 9, '10': 'realm'},
    {
      '1': 'history_options',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.HistoryOptions',
      '10': 'historyOptions'
    },
    {
      '1': 'properties',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'properties'
    },
    {
      '1': 'source_spec',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.SourceSpec',
      '10': 'sourceSpec'
    },
    {'1': 'baseline_id', '3': 16, '4': 1, '5': 9, '10': 'baselineId'},
  ],
  '4': [Invocation_State$json],
  '9': [
    {'1': 3, '2': 4},
  ],
};

@$core.Deprecated('Use invocationDescriptor instead')
const Invocation_State$json = {
  '1': 'State',
  '2': [
    {'1': 'STATE_UNSPECIFIED', '2': 0},
    {'1': 'ACTIVE', '2': 1},
    {'1': 'FINALIZING', '2': 2},
    {'1': 'FINALIZED', '2': 3},
  ],
};

/// Descriptor for `Invocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List invocationDescriptor = $convert.base64Decode(
    'CgpJbnZvY2F0aW9uEhoKBG5hbWUYASABKAlCBuBBA+BBBVIEbmFtZRI4CgVzdGF0ZRgCIAEoDj'
    'IiLmx1Y2kucmVzdWx0ZGIudjEuSW52b2NhdGlvbi5TdGF0ZVIFc3RhdGUSQwoLY3JlYXRlX3Rp'
    'bWUYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgbgQQPgQQVSCmNyZWF0ZVRpbW'
    'USMAoEdGFncxgFIAMoCzIcLmx1Y2kucmVzdWx0ZGIudjEuU3RyaW5nUGFpclIEdGFncxJECg1m'
    'aW5hbGl6ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEID4EEDUgxmaW'
    '5hbGl6ZVRpbWUSNgoIZGVhZGxpbmUYByABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1w'
    'UghkZWFkbGluZRIxChRpbmNsdWRlZF9pbnZvY2F0aW9ucxgIIAMoCVITaW5jbHVkZWRJbnZvY2'
    'F0aW9ucxJLChBiaWdxdWVyeV9leHBvcnRzGAkgAygLMiAubHVjaS5yZXN1bHRkYi52MS5CaWdR'
    'dWVyeUV4cG9ydFIPYmlncXVlcnlFeHBvcnRzEiIKCmNyZWF0ZWRfYnkYCiABKAlCA+BBA1IJY3'
    'JlYXRlZEJ5EisKEXByb2R1Y2VyX3Jlc291cmNlGAsgASgJUhBwcm9kdWNlclJlc291cmNlEhQK'
    'BXJlYWxtGAwgASgJUgVyZWFsbRJJCg9oaXN0b3J5X29wdGlvbnMYDSABKAsyIC5sdWNpLnJlc3'
    'VsdGRiLnYxLkhpc3RvcnlPcHRpb25zUg5oaXN0b3J5T3B0aW9ucxI3Cgpwcm9wZXJ0aWVzGA4g'
    'ASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKcHJvcGVydGllcxI9Cgtzb3VyY2Vfc3BlYx'
    'gPIAEoCzIcLmx1Y2kucmVzdWx0ZGIudjEuU291cmNlU3BlY1IKc291cmNlU3BlYxIfCgtiYXNl'
    'bGluZV9pZBgQIAEoCVIKYmFzZWxpbmVJZCJJCgVTdGF0ZRIVChFTVEFURV9VTlNQRUNJRklFRB'
    'AAEgoKBkFDVElWRRABEg4KCkZJTkFMSVpJTkcQAhINCglGSU5BTElaRUQQA0oECAMQBA==');

@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport$json = {
  '1': 'BigQueryExport',
  '2': [
    {'1': 'project', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'project'},
    {'1': 'dataset', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'dataset'},
    {'1': 'table', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'table'},
    {
      '1': 'test_results',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport.TestResults',
      '9': 0,
      '10': 'testResults'
    },
    {
      '1': 'text_artifacts',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.BigQueryExport.TextArtifacts',
      '9': 0,
      '10': 'textArtifacts'
    },
  ],
  '3': [BigQueryExport_TestResults$json, BigQueryExport_TextArtifacts$json],
  '8': [
    {'1': 'result_type'},
  ],
};

@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport_TestResults$json = {
  '1': 'TestResults',
  '2': [
    {
      '1': 'predicate',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestResultPredicate',
      '10': 'predicate'
    },
  ],
};

@$core.Deprecated('Use bigQueryExportDescriptor instead')
const BigQueryExport_TextArtifacts$json = {
  '1': 'TextArtifacts',
  '2': [
    {
      '1': 'predicate',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.ArtifactPredicate',
      '10': 'predicate'
    },
  ],
};

/// Descriptor for `BigQueryExport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bigQueryExportDescriptor = $convert.base64Decode(
    'Cg5CaWdRdWVyeUV4cG9ydBIdCgdwcm9qZWN0GAEgASgJQgPgQQJSB3Byb2plY3QSHQoHZGF0YX'
    'NldBgCIAEoCUID4EECUgdkYXRhc2V0EhkKBXRhYmxlGAMgASgJQgPgQQJSBXRhYmxlElEKDHRl'
    'c3RfcmVzdWx0cxgEIAEoCzIsLmx1Y2kucmVzdWx0ZGIudjEuQmlnUXVlcnlFeHBvcnQuVGVzdF'
    'Jlc3VsdHNIAFILdGVzdFJlc3VsdHMSVwoOdGV4dF9hcnRpZmFjdHMYBiABKAsyLi5sdWNpLnJl'
    'c3VsdGRiLnYxLkJpZ1F1ZXJ5RXhwb3J0LlRleHRBcnRpZmFjdHNIAFINdGV4dEFydGlmYWN0cx'
    'pSCgtUZXN0UmVzdWx0cxJDCglwcmVkaWNhdGUYASABKAsyJS5sdWNpLnJlc3VsdGRiLnYxLlRl'
    'c3RSZXN1bHRQcmVkaWNhdGVSCXByZWRpY2F0ZRpSCg1UZXh0QXJ0aWZhY3RzEkEKCXByZWRpY2'
    'F0ZRgBIAEoCzIjLmx1Y2kucmVzdWx0ZGIudjEuQXJ0aWZhY3RQcmVkaWNhdGVSCXByZWRpY2F0'
    'ZUINCgtyZXN1bHRfdHlwZQ==');

@$core.Deprecated('Use historyOptionsDescriptor instead')
const HistoryOptions$json = {
  '1': 'HistoryOptions',
  '2': [
    {
      '1': 'use_invocation_timestamp',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'useInvocationTimestamp'
    },
    {
      '1': 'commit',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.CommitPosition',
      '10': 'commit'
    },
  ],
};

/// Descriptor for `HistoryOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List historyOptionsDescriptor = $convert.base64Decode(
    'Cg5IaXN0b3J5T3B0aW9ucxI4Chh1c2VfaW52b2NhdGlvbl90aW1lc3RhbXAYASABKAhSFnVzZU'
    'ludm9jYXRpb25UaW1lc3RhbXASOAoGY29tbWl0GAIgASgLMiAubHVjaS5yZXN1bHRkYi52MS5D'
    'b21taXRQb3NpdGlvblIGY29tbWl0');

@$core.Deprecated('Use sourceSpecDescriptor instead')
const SourceSpec$json = {
  '1': 'SourceSpec',
  '2': [
    {
      '1': 'sources',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.Sources',
      '10': 'sources'
    },
    {'1': 'inherit', '3': 2, '4': 1, '5': 8, '10': 'inherit'},
  ],
};

/// Descriptor for `SourceSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourceSpecDescriptor = $convert.base64Decode(
    'CgpTb3VyY2VTcGVjEjMKB3NvdXJjZXMYASABKAsyGS5sdWNpLnJlc3VsdGRiLnYxLlNvdXJjZX'
    'NSB3NvdXJjZXMSGAoHaW5oZXJpdBgCIAEoCFIHaW5oZXJpdA==');

@$core.Deprecated('Use sourcesDescriptor instead')
const Sources$json = {
  '1': 'Sources',
  '2': [
    {
      '1': 'gitiles_commit',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.GitilesCommit',
      '10': 'gitilesCommit'
    },
    {
      '1': 'changelists',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.luci.resultdb.v1.GerritChange',
      '10': 'changelists'
    },
    {'1': 'is_dirty', '3': 3, '4': 1, '5': 8, '10': 'isDirty'},
  ],
};

/// Descriptor for `Sources`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourcesDescriptor = $convert.base64Decode(
    'CgdTb3VyY2VzEkYKDmdpdGlsZXNfY29tbWl0GAEgASgLMh8ubHVjaS5yZXN1bHRkYi52MS5HaX'
    'RpbGVzQ29tbWl0Ug1naXRpbGVzQ29tbWl0EkAKC2NoYW5nZWxpc3RzGAIgAygLMh4ubHVjaS5y'
    'ZXN1bHRkYi52MS5HZXJyaXRDaGFuZ2VSC2NoYW5nZWxpc3RzEhkKCGlzX2RpcnR5GAMgASgIUg'
    'dpc0RpcnR5');
