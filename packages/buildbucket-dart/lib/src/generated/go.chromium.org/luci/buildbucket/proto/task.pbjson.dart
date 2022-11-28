///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/task.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = const {
  '1': 'Task',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.TaskID', '10': 'id'},
    const {'1': 'link', '3': 2, '4': 1, '5': 9, '10': 'link'},
    const {'1': 'status', '3': 3, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    const {'1': 'status_details', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    const {'1': 'summary_html', '3': 5, '4': 1, '5': 9, '10': 'summaryHtml'},
    const {'1': 'details', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'details'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEiYKAmlkGAEgASgLMhYuYnVpbGRidWNrZXQudjIuVGFza0lEUgJpZBISCgRsaW5rGAIgASgJUgRsaW5rEi4KBnN0YXR1cxgDIAEoDjIWLmJ1aWxkYnVja2V0LnYyLlN0YXR1c1IGc3RhdHVzEkQKDnN0YXR1c19kZXRhaWxzGAQgASgLMh0uYnVpbGRidWNrZXQudjIuU3RhdHVzRGV0YWlsc1INc3RhdHVzRGV0YWlscxIhCgxzdW1tYXJ5X2h0bWwYBSABKAlSC3N1bW1hcnlIdG1sEjEKB2RldGFpbHMYBiABKAsyFy5nb29nbGUucHJvdG9idWYuU3RydWN0UgdkZXRhaWxz');
@$core.Deprecated('Use taskIDDescriptor instead')
const TaskID$json = const {
  '1': 'TaskID',
  '2': const [
    const {'1': 'target', '3': 1, '4': 1, '5': 9, '10': 'target'},
    const {'1': 'id', '3': 2, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `TaskID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskIDDescriptor =
    $convert.base64Decode('CgZUYXNrSUQSFgoGdGFyZ2V0GAEgASgJUgZ0YXJnZXQSDgoCaWQYAiABKAlSAmlk');
