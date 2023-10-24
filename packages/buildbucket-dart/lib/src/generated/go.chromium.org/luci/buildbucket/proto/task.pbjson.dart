//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
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
    {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.TaskID', '8': {}, '10': 'id'},
    {'1': 'link', '3': 2, '4': 1, '5': 9, '10': 'link'},
    {'1': 'status', '3': 3, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '8': {}, '10': 'status'},
    {'1': 'status_details', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    {'1': 'summary_html', '3': 5, '4': 1, '5': 9, '10': 'summaryHtml'},
    {'1': 'details', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'details'},
    {'1': 'update_id', '3': 7, '4': 1, '5': 3, '8': {}, '10': 'updateId'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor =
    $convert.base64Decode('CgRUYXNrEi4KAmlkGAEgASgLMhYuYnVpbGRidWNrZXQudjIuVGFza0lEQgaSwxoCCAJSAmlkEh'
        'IKBGxpbmsYAiABKAlSBGxpbmsSNgoGc3RhdHVzGAMgASgOMhYuYnVpbGRidWNrZXQudjIuU3Rh'
        'dHVzQgaSwxoCCAJSBnN0YXR1cxJECg5zdGF0dXNfZGV0YWlscxgEIAEoCzIdLmJ1aWxkYnVja2'
        'V0LnYyLlN0YXR1c0RldGFpbHNSDXN0YXR1c0RldGFpbHMSIQoMc3VtbWFyeV9odG1sGAUgASgJ'
        'UgtzdW1tYXJ5SHRtbBIxCgdkZXRhaWxzGAYgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdF'
        'IHZGV0YWlscxIjCgl1cGRhdGVfaWQYByABKANCBpLDGgIIAlIIdXBkYXRlSWQ=');

@$core.Deprecated('Use taskIDDescriptor instead')
const TaskID$json = {
  '1': 'TaskID',
  '2': [
    {'1': 'target', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'target'},
    {'1': 'id', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'id'},
  ],
};

/// Descriptor for `TaskID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskIDDescriptor =
    $convert.base64Decode('CgZUYXNrSUQSJAoGdGFyZ2V0GAEgASgJQgyKwxoCCAKSwxoCCAJSBnRhcmdldBIWCgJpZBgCIA'
        'EoCUIGksMaAggCUgJpZA==');

@$core.Deprecated('Use buildTaskUpdateDescriptor instead')
const BuildTaskUpdate$json = {
  '1': 'BuildTaskUpdate',
  '2': [
    {'1': 'build_id', '3': 1, '4': 1, '5': 9, '10': 'buildId'},
    {'1': 'task', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.Task', '10': 'task'},
  ],
};

/// Descriptor for `BuildTaskUpdate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildTaskUpdateDescriptor =
    $convert.base64Decode('Cg9CdWlsZFRhc2tVcGRhdGUSGQoIYnVpbGRfaWQYASABKAlSB2J1aWxkSWQSKAoEdGFzaxgCIA'
        'EoCzIULmJ1aWxkYnVja2V0LnYyLlRhc2tSBHRhc2s=');
