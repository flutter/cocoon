//
//  Generated code. Do not modify.
//  source: task.proto
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
    {'1': 'create_timestamp', '3': 3, '4': 1, '5': 3, '10': 'createTimestamp'},
    {'1': 'start_timestamp', '3': 4, '4': 1, '5': 3, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 5, '4': 1, '5': 3, '10': 'endTimestamp'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'attempts', '3': 7, '4': 1, '5': 5, '10': 'attempts'},
    {'1': 'is_flaky', '3': 8, '4': 1, '5': 8, '10': 'isFlaky'},
    {'1': 'stage_name', '3': 13, '4': 1, '5': 9, '10': 'stageName'},
    {'1': 'status', '3': 14, '4': 1, '5': 9, '10': 'status'},
    {'1': 'buildNumberList', '3': 16, '4': 1, '5': 9, '10': 'buildNumberList'},
    {'1': 'builderName', '3': 17, '4': 1, '5': 9, '10': 'builderName'},
    {'1': 'is_test_flaky', '3': 19, '4': 1, '5': 8, '10': 'isTestFlaky'},
  ],
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 9, '2': 10},
    {'1': 10, '2': 11},
    {'1': 11, '2': 12},
    {'1': 12, '2': 13},
    {'1': 15, '2': 16},
    {'1': 18, '2': 19},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEikKEGNyZWF0ZV90aW1lc3RhbXAYAyABKANSD2NyZWF0ZVRpbWVzdGFtcBInCg9zdG'
    'FydF90aW1lc3RhbXAYBCABKANSDnN0YXJ0VGltZXN0YW1wEiMKDWVuZF90aW1lc3RhbXAYBSAB'
    'KANSDGVuZFRpbWVzdGFtcBISCgRuYW1lGAYgASgJUgRuYW1lEhoKCGF0dGVtcHRzGAcgASgFUg'
    'hhdHRlbXB0cxIZCghpc19mbGFreRgIIAEoCFIHaXNGbGFreRIdCgpzdGFnZV9uYW1lGA0gASgJ'
    'UglzdGFnZU5hbWUSFgoGc3RhdHVzGA4gASgJUgZzdGF0dXMSKAoPYnVpbGROdW1iZXJMaXN0GB'
    'AgASgJUg9idWlsZE51bWJlckxpc3QSIAoLYnVpbGRlck5hbWUYESABKAlSC2J1aWxkZXJOYW1l'
    'EiIKDWlzX3Rlc3RfZmxha3kYEyABKAhSC2lzVGVzdEZsYWt5SgQIARACSgQIAhADSgQICRAKSg'
    'QIChALSgQICxAMSgQIDBANSgQIDxAQSgQIEhAT');
