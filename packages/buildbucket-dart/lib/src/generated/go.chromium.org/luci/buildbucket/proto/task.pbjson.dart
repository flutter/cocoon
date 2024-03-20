//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.TaskID', '10': 'id'},
    {'1': 'link', '3': 2, '4': 1, '5': 9, '10': 'link'},
    {'1': 'status', '3': 3, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    {'1': 'status_details', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    {'1': 'summary_html', '3': 5, '4': 1, '5': 9, '10': 'summaryHtml'},
    {'1': 'details', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'details'},
    {'1': 'update_id', '3': 7, '4': 1, '5': 3, '10': 'updateId'},
    {'1': 'summary_markdown', '3': 8, '4': 1, '5': 9, '10': 'summaryMarkdown'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEiYKAmlkGAEgASgLMhYuYnVpbGRidWNrZXQudjIuVGFza0lEUgJpZBISCgRsaW5rGA'
    'IgASgJUgRsaW5rEi4KBnN0YXR1cxgDIAEoDjIWLmJ1aWxkYnVja2V0LnYyLlN0YXR1c1IGc3Rh'
    'dHVzEkQKDnN0YXR1c19kZXRhaWxzGAQgASgLMh0uYnVpbGRidWNrZXQudjIuU3RhdHVzRGV0YW'
    'lsc1INc3RhdHVzRGV0YWlscxIhCgxzdW1tYXJ5X2h0bWwYBSABKAlSC3N1bW1hcnlIdG1sEjEK'
    'B2RldGFpbHMYBiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgdkZXRhaWxzEhsKCXVwZG'
    'F0ZV9pZBgHIAEoA1IIdXBkYXRlSWQSKQoQc3VtbWFyeV9tYXJrZG93bhgIIAEoCVIPc3VtbWFy'
    'eU1hcmtkb3du');

@$core.Deprecated('Use taskIDDescriptor instead')
const TaskID$json = {
  '1': 'TaskID',
  '2': [
    {'1': 'target', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'target'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `TaskID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskIDDescriptor = $convert.base64Decode(
    'CgZUYXNrSUQSHgoGdGFyZ2V0GAEgASgJQgaKwxoCCAJSBnRhcmdldBIOCgJpZBgCIAEoCVICaW'
    'Q=');

@$core.Deprecated('Use buildTaskUpdateDescriptor instead')
const BuildTaskUpdate$json = {
  '1': 'BuildTaskUpdate',
  '2': [
    {'1': 'build_id', '3': 1, '4': 1, '5': 9, '10': 'buildId'},
    {'1': 'task', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.Task', '10': 'task'},
  ],
};

/// Descriptor for `BuildTaskUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildTaskUpdateDescriptor = $convert.base64Decode(
    'Cg9CdWlsZFRhc2tVcGRhdGUSGQoIYnVpbGRfaWQYASABKAlSB2J1aWxkSWQSKAoEdGFzaxgCIA'
    'EoCzIULmJ1aWxkYnVja2V0LnYyLlRhc2tSBHRhc2s=');

