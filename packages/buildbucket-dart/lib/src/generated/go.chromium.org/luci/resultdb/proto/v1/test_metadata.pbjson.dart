//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/test_metadata.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use testMetadataDetailDescriptor instead')
const TestMetadataDetail$json = {
  '1': 'TestMetadataDetail',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'name'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'test_id', '3': 3, '4': 1, '5': 9, '10': 'testId'},
    {'1': 'ref_hash', '3': 12, '4': 1, '5': 9, '10': 'refHash'},
    {
      '1': 'source_ref',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.SourceRef',
      '10': 'sourceRef'
    },
    {
      '1': 'testMetadata',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestMetadata',
      '10': 'testMetadata'
    },
  ],
};

/// Descriptor for `TestMetadataDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testMetadataDetailDescriptor = $convert.base64Decode(
    'ChJUZXN0TWV0YWRhdGFEZXRhaWwSFwoEbmFtZRgBIAEoCUID4EEDUgRuYW1lEhgKB3Byb2plY3'
    'QYAiABKAlSB3Byb2plY3QSFwoHdGVzdF9pZBgDIAEoCVIGdGVzdElkEhkKCHJlZl9oYXNoGAwg'
    'ASgJUgdyZWZIYXNoEjoKCnNvdXJjZV9yZWYYBCABKAsyGy5sdWNpLnJlc3VsdGRiLnYxLlNvdX'
    'JjZVJlZlIJc291cmNlUmVmEkIKDHRlc3RNZXRhZGF0YRgFIAEoCzIeLmx1Y2kucmVzdWx0ZGIu'
    'djEuVGVzdE1ldGFkYXRhUgx0ZXN0TWV0YWRhdGE=');

@$core.Deprecated('Use testMetadataDescriptor instead')
const TestMetadata$json = {
  '1': 'TestMetadata',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'location',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.TestLocation',
      '10': 'location'
    },
    {
      '1': 'bug_component',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.BugComponent',
      '10': 'bugComponent'
    },
    {
      '1': 'properties_schema',
      '3': 4,
      '4': 1,
      '5': 9,
      '10': 'propertiesSchema'
    },
    {
      '1': 'properties',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'properties'
    },
  ],
};

/// Descriptor for `TestMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testMetadataDescriptor = $convert.base64Decode(
    'CgxUZXN0TWV0YWRhdGESEgoEbmFtZRgBIAEoCVIEbmFtZRI6Cghsb2NhdGlvbhgCIAEoCzIeLm'
    'x1Y2kucmVzdWx0ZGIudjEuVGVzdExvY2F0aW9uUghsb2NhdGlvbhJDCg1idWdfY29tcG9uZW50'
    'GAMgASgLMh4ubHVjaS5yZXN1bHRkYi52MS5CdWdDb21wb25lbnRSDGJ1Z0NvbXBvbmVudBIrCh'
    'Fwcm9wZXJ0aWVzX3NjaGVtYRgEIAEoCVIQcHJvcGVydGllc1NjaGVtYRI3Cgpwcm9wZXJ0aWVz'
    'GAUgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKcHJvcGVydGllcw==');

@$core.Deprecated('Use testLocationDescriptor instead')
const TestLocation$json = {
  '1': 'TestLocation',
  '2': [
    {'1': 'repo', '3': 1, '4': 1, '5': 9, '10': 'repo'},
    {'1': 'file_name', '3': 2, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'line', '3': 3, '4': 1, '5': 5, '10': 'line'},
  ],
};

/// Descriptor for `TestLocation`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testLocationDescriptor = $convert.base64Decode(
    'CgxUZXN0TG9jYXRpb24SEgoEcmVwbxgBIAEoCVIEcmVwbxIbCglmaWxlX25hbWUYAiABKAlSCG'
    'ZpbGVOYW1lEhIKBGxpbmUYAyABKAVSBGxpbmU=');

@$core.Deprecated('Use bugComponentDescriptor instead')
const BugComponent$json = {
  '1': 'BugComponent',
  '2': [
    {
      '1': 'issue_tracker',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.IssueTrackerComponent',
      '9': 0,
      '10': 'issueTracker'
    },
    {
      '1': 'monorail',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.luci.resultdb.v1.MonorailComponent',
      '9': 0,
      '10': 'monorail'
    },
  ],
  '8': [
    {'1': 'system'},
  ],
};

/// Descriptor for `BugComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bugComponentDescriptor = $convert.base64Decode(
    'CgxCdWdDb21wb25lbnQSTgoNaXNzdWVfdHJhY2tlchgBIAEoCzInLmx1Y2kucmVzdWx0ZGIudj'
    'EuSXNzdWVUcmFja2VyQ29tcG9uZW50SABSDGlzc3VlVHJhY2tlchJBCghtb25vcmFpbBgCIAEo'
    'CzIjLmx1Y2kucmVzdWx0ZGIudjEuTW9ub3JhaWxDb21wb25lbnRIAFIIbW9ub3JhaWxCCAoGc3'
    'lzdGVt');

@$core.Deprecated('Use issueTrackerComponentDescriptor instead')
const IssueTrackerComponent$json = {
  '1': 'IssueTrackerComponent',
  '2': [
    {'1': 'component_id', '3': 1, '4': 1, '5': 3, '10': 'componentId'},
  ],
};

/// Descriptor for `IssueTrackerComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List issueTrackerComponentDescriptor = $convert.base64Decode(
    'ChVJc3N1ZVRyYWNrZXJDb21wb25lbnQSIQoMY29tcG9uZW50X2lkGAEgASgDUgtjb21wb25lbn'
    'RJZA==');

@$core.Deprecated('Use monorailComponentDescriptor instead')
const MonorailComponent$json = {
  '1': 'MonorailComponent',
  '2': [
    {'1': 'project', '3': 1, '4': 1, '5': 9, '10': 'project'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
};

/// Descriptor for `MonorailComponent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List monorailComponentDescriptor = $convert.base64Decode(
    'ChFNb25vcmFpbENvbXBvbmVudBIYCgdwcm9qZWN0GAEgASgJUgdwcm9qZWN0EhQKBXZhbHVlGA'
    'IgASgJUgV2YWx1ZQ==');
