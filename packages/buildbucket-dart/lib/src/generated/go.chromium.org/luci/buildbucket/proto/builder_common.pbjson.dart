///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_common.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use builderIDDescriptor instead')
const BuilderID$json = const {
  '1': 'BuilderID',
  '2': const [
    const {'1': 'project', '3': 1, '4': 1, '5': 9, '10': 'project'},
    const {'1': 'bucket', '3': 2, '4': 1, '5': 9, '10': 'bucket'},
    const {'1': 'builder', '3': 3, '4': 1, '5': 9, '10': 'builder'},
  ],
};

/// Descriptor for `BuilderID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderIDDescriptor = $convert.base64Decode(
    'CglCdWlsZGVySUQSGAoHcHJvamVjdBgBIAEoCVIHcHJvamVjdBIWCgZidWNrZXQYAiABKAlSBmJ1Y2tldBIYCgdidWlsZGVyGAMgASgJUgdidWlsZGVy');
@$core.Deprecated('Use builderItemDescriptor instead')
const BuilderItem$json = const {
  '1': 'BuilderItem',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'id'},
    const {'1': 'config', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.BuilderConfig', '10': 'config'},
  ],
};

/// Descriptor for `BuilderItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderItemDescriptor = $convert.base64Decode(
    'CgtCdWlsZGVySXRlbRIpCgJpZBgBIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZXJJRFICaWQSMgoGY29uZmlnGAIgASgLMhouYnVpbGRidWNrZXQuQnVpbGRlckNvbmZpZ1IGY29uZmln');
