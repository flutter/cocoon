//
//  Generated code. Do not modify.
//  source: lib/model/commit_firestore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use commitDocumentDescriptor instead')
const CommitDocument$json = {
  '1': 'CommitDocument',
  '2': [
    {'1': 'documentName', '3': 1, '4': 1, '5': 9, '10': 'documentName'},
    {'1': 'createTimestamp', '3': 2, '4': 1, '5': 3, '10': 'createTimestamp'},
    {'1': 'sha', '3': 3, '4': 1, '5': 9, '10': 'sha'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'avatar', '3': 5, '4': 1, '5': 9, '10': 'avatar'},
    {'1': 'repositoryPath', '3': 6, '4': 1, '5': 9, '10': 'repositoryPath'},
    {'1': 'branch', '3': 7, '4': 1, '5': 9, '10': 'branch'},
    {'1': 'message', '3': 8, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `CommitDocument`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitDocumentDescriptor = $convert.base64Decode(
    'Cg5Db21taXREb2N1bWVudBIiCgxkb2N1bWVudE5hbWUYASABKAlSDGRvY3VtZW50TmFtZRIoCg'
    '9jcmVhdGVUaW1lc3RhbXAYAiABKANSD2NyZWF0ZVRpbWVzdGFtcBIQCgNzaGEYAyABKAlSA3No'
    'YRIWCgZhdXRob3IYBCABKAlSBmF1dGhvchIWCgZhdmF0YXIYBSABKAlSBmF2YXRhchImCg5yZX'
    'Bvc2l0b3J5UGF0aBgGIAEoCVIOcmVwb3NpdG9yeVBhdGgSFgoGYnJhbmNoGAcgASgJUgZicmFu'
    'Y2gSGAoHbWVzc2FnZRgIIAEoCVIHbWVzc2FnZQ==');

