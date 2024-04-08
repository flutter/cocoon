//
//  Generated code. Do not modify.
//  source: lib/model/task_firestore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskDocumentDescriptor instead')
const TaskDocument$json = {
  '1': 'TaskDocument',
  '2': [
    {'1': 'document_name', '3': 1, '4': 1, '5': 9, '10': 'documentName'},
    {'1': 'create_timestamp', '3': 2, '4': 1, '5': 3, '10': 'createTimestamp'},
    {'1': 'start_timestamp', '3': 3, '4': 1, '5': 3, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 4, '4': 1, '5': 3, '10': 'endTimestamp'},
    {'1': 'task_name', '3': 5, '4': 1, '5': 9, '10': 'taskName'},
    {'1': 'attempts', '3': 6, '4': 1, '5': 5, '10': 'attempts'},
    {'1': 'bringup', '3': 7, '4': 1, '5': 8, '10': 'bringup'},
    {'1': 'test_flaky', '3': 8, '4': 1, '5': 8, '10': 'testFlaky'},
    {'1': 'build_number', '3': 9, '4': 1, '5': 5, '10': 'buildNumber'},
    {'1': 'status', '3': 10, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `TaskDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDocumentDescriptor = $convert.base64Decode(
    'CgxUYXNrRG9jdW1lbnQSIwoNZG9jdW1lbnRfbmFtZRgBIAEoCVIMZG9jdW1lbnROYW1lEikKEG'
    'NyZWF0ZV90aW1lc3RhbXAYAiABKANSD2NyZWF0ZVRpbWVzdGFtcBInCg9zdGFydF90aW1lc3Rh'
    'bXAYAyABKANSDnN0YXJ0VGltZXN0YW1wEiMKDWVuZF90aW1lc3RhbXAYBCABKANSDGVuZFRpbW'
    'VzdGFtcBIbCgl0YXNrX25hbWUYBSABKAlSCHRhc2tOYW1lEhoKCGF0dGVtcHRzGAYgASgFUghh'
    'dHRlbXB0cxIYCgdicmluZ3VwGAcgASgIUgdicmluZ3VwEh0KCnRlc3RfZmxha3kYCCABKAhSCX'
    'Rlc3RGbGFreRIhCgxidWlsZF9udW1iZXIYCSABKAVSC2J1aWxkTnVtYmVyEhYKBnN0YXR1cxgK'
    'IAEoCVIGc3RhdHVz');

