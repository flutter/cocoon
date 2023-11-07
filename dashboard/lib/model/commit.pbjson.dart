//
//  Generated code. Do not modify.
//  source: lib/model/commit.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use commitDescriptor instead')
const Commit$json = {
  '1': 'Commit',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 11, '6': '.dashboard.RootKey', '10': 'key'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'sha', '3': 3, '4': 1, '5': 9, '10': 'sha'},
    {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    {'1': 'authorAvatarUrl', '3': 5, '4': 1, '5': 9, '10': 'authorAvatarUrl'},
    {'1': 'message', '3': 8, '4': 1, '5': 9, '10': 'message'},
    {'1': 'repository', '3': 6, '4': 1, '5': 9, '10': 'repository'},
    {'1': 'branch', '3': 7, '4': 1, '5': 9, '10': 'branch'},
  ],
};

/// Descriptor for `Commit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitDescriptor =
    $convert.base64Decode('CgZDb21taXQSJAoDa2V5GAEgASgLMhIuZGFzaGJvYXJkLlJvb3RLZXlSA2tleRIcCgl0aW1lc3'
        'RhbXAYAiABKANSCXRpbWVzdGFtcBIQCgNzaGEYAyABKAlSA3NoYRIWCgZhdXRob3IYBCABKAlS'
        'BmF1dGhvchIoCg9hdXRob3JBdmF0YXJVcmwYBSABKAlSD2F1dGhvckF2YXRhclVybBIYCgdtZX'
        'NzYWdlGAggASgJUgdtZXNzYWdlEh4KCnJlcG9zaXRvcnkYBiABKAlSCnJlcG9zaXRvcnkSFgoG'
        'YnJhbmNoGAcgASgJUgZicmFuY2g=');
