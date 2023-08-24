///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/key.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = const {
  '1': 'Key',
  '2': const [
    const {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    const {'1': 'uid', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'uid'},
    const {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    const {'1': 'child', '3': 4, '4': 1, '5': 11, '6': '.cocoon.Key', '10': 'child'},
  ],
  '8': const [
    const {'1': 'id'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgN1aWQYAiABKANIAFIDdWlkEhQKBG5hbWUYAyABKAlIAFIEbmFtZRIhCgVjaGlsZBgEIAEoCzILLmNvY29vbi5LZXlSBWNoaWxkQgQKAmlk');
@$core.Deprecated('Use rootKeyDescriptor instead')
const RootKey$json = const {
  '1': 'RootKey',
  '2': const [
    const {'1': 'namespace', '3': 1, '4': 1, '5': 9, '10': 'namespace'},
    const {'1': 'child', '3': 2, '4': 1, '5': 11, '6': '.cocoon.Key', '10': 'child'},
  ],
};

/// Descriptor for `RootKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rootKeyDescriptor = $convert.base64Decode(
    'CgdSb290S2V5EhwKCW5hbWVzcGFjZRgBIAEoCVIJbmFtZXNwYWNlEiEKBWNoaWxkGAIgASgLMgsuY29jb29uLktleVIFY2hpbGQ=');
