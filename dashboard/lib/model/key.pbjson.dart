///
//  Generated code. Do not modify.
//  source: lib/model/key.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use keyDescriptor instead')
const Key$json = {
  '1': 'Key',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'uid', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'uid'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'name'},
    {'1': 'child', '3': 4, '4': 1, '5': 11, '6': '.Key', '10': 'child'},
  ],
  '8': [
    {'1': 'id'},
  ],
};

/// Descriptor for `Key`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyDescriptor = $convert.base64Decode(
    'CgNLZXkSEgoEdHlwZRgBIAEoCVIEdHlwZRISCgN1aWQYAiABKANIAFIDdWlkEhQKBG5hbWUYAyABKAlIAFIEbmFtZRIaCgVjaGlsZBgEIAEoCzIELktleVIFY2hpbGRCBAoCaWQ=');
@$core.Deprecated('Use rootKeyDescriptor instead')
const RootKey$json = {
  '1': 'RootKey',
  '2': [
    {'1': 'namespace', '3': 1, '4': 1, '5': 9, '10': 'namespace'},
    {'1': 'child', '3': 2, '4': 1, '5': 11, '6': '.Key', '10': 'child'},
  ],
};

/// Descriptor for `RootKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List rootKeyDescriptor = $convert.base64Decode(
    'CgdSb290S2V5EhwKCW5hbWVzcGFjZRgBIAEoCVIJbmFtZXNwYWNlEhoKBWNoaWxkGAIgASgLMgQuS2V5UgVjaGlsZA==');
