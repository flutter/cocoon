//
//  Generated code. Do not modify.
//  source: lib/model/commit_status.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use commitStatusDescriptor instead')
const CommitStatus$json = {
  '1': 'CommitStatus',
  '2': [
    {'1': 'commit', '3': 1, '4': 1, '5': 11, '6': '.dashboard.Commit', '10': 'commit'},
    {'1': 'tasks', '3': 2, '4': 3, '5': 11, '6': '.dashboard.Task', '10': 'tasks'},
    {'1': 'branch', '3': 3, '4': 1, '5': 9, '10': 'branch'},
  ],
};

/// Descriptor for `CommitStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitStatusDescriptor =
    $convert.base64Decode('CgxDb21taXRTdGF0dXMSKQoGY29tbWl0GAEgASgLMhEuZGFzaGJvYXJkLkNvbW1pdFIGY29tbW'
        'l0EiUKBXRhc2tzGAIgAygLMg8uZGFzaGJvYXJkLlRhc2tSBXRhc2tzEhYKBmJyYW5jaBgDIAEo'
        'CVIGYnJhbmNo');
