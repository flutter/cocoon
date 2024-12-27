//
//  Generated code. Do not modify.
//  source: internal/key.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'uid', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'uid'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    {'1': 'child', '3': 4, '4': 1, '5': 11, '6': '.cocoon.Key', '10': 'child'},
  ],
  '8': [
    {'1': 'id'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgN1aWQYAiABKANIAFIDdWlkEhQKBG5hbWUYAy'
    'ABKAlIAFIEbmFtZRIhCgVjaGlsZBgEIAEoCzILLmNvY29vbi5LZXlSBWNoaWxkQgQKAmlk');

@$core.Deprecated('Use rootKeyDescriptor instead')
const RootKey$json = {
  '1': 'RootKey',
  '2': [
    {'1': 'namespace', '3': 1, '4': 1, '5': 9, '10': 'namespace'},
    {'1': 'child', '3': 2, '4': 1, '5': 11, '6': '.cocoon.Key', '10': 'child'},
  ],
};

/// Descriptor for `RootKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rootKeyDescriptor = $convert.base64Decode(
    'CgdSb290S2V5EhwKCW5hbWVzcGFjZRgBIAEoCVIJbmFtZXNwYWNlEiEKBWNoaWxkGAIgASgLMg'
    'suY29jb29uLktleVIFY2hpbGQ=');

