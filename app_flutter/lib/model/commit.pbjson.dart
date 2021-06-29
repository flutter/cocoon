///
//  Generated code. Do not modify.
//  source: lib/model/commit.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use commitDescriptor instead')
const Commit$json = const {
  '1': 'Commit',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 11, '6': '.RootKey', '10': 'key'},
    const {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    const {'1': 'sha', '3': 3, '4': 1, '5': 9, '10': 'sha'},
    const {'1': 'author', '3': 4, '4': 1, '5': 9, '10': 'author'},
    const {'1': 'authorAvatarUrl', '3': 5, '4': 1, '5': 9, '10': 'authorAvatarUrl'},
    const {'1': 'message', '3': 8, '4': 1, '5': 9, '10': 'message'},
    const {'1': 'repository', '3': 6, '4': 1, '5': 9, '10': 'repository'},
    const {'1': 'branch', '3': 7, '4': 1, '5': 9, '10': 'branch'},
  ],
};

/// Descriptor for `Commit`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commitDescriptor = $convert.base64Decode('CgZDb21taXQSGgoDa2V5GAEgASgLMgguUm9vdEtleVIDa2V5EhwKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1wEhAKA3NoYRgDIAEoCVIDc2hhEhYKBmF1dGhvchgEIAEoCVIGYXV0aG9yEigKD2F1dGhvckF2YXRhclVybBgFIAEoCVIPYXV0aG9yQXZhdGFyVXJsEhgKB21lc3NhZ2UYCCABKAlSB21lc3NhZ2USHgoKcmVwb3NpdG9yeRgGIAEoCVIKcmVwb3NpdG9yeRIWCgZicmFuY2gYByABKAlSBmJyYW5jaA==');
