//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_common.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use builderIDDescriptor instead')
const BuilderID$json = {
  '1': 'BuilderID',
  '2': [
    {'1': 'project', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'project'},
    {'1': 'bucket', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'bucket'},
    {'1': 'builder', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'builder'},
  ],
};

/// Descriptor for `BuilderID`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderIDDescriptor = $convert.base64Decode(
    'CglCdWlsZGVySUQSLgoHcHJvamVjdBgBIAEoCUIUmsMaEFNldEJ1aWxkZXJIZWFsdGhSB3Byb2'
    'plY3QSLAoGYnVja2V0GAIgASgJQhSawxoQU2V0QnVpbGRlckhlYWx0aFIGYnVja2V0Ei4KB2J1'
    'aWxkZXIYAyABKAlCFJrDGhBTZXRCdWlsZGVySGVhbHRoUgdidWlsZGVy');

@$core.Deprecated('Use builderMetadataDescriptor instead')
const BuilderMetadata$json = {
  '1': 'BuilderMetadata',
  '2': [
    {'1': 'owner', '3': 1, '4': 1, '5': 9, '10': 'owner'},
    {
      '1': 'health',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.HealthStatus',
      '10': 'health'
    },
  ],
};

/// Descriptor for `BuilderMetadata`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderMetadataDescriptor = $convert.base64Decode(
    'Cg9CdWlsZGVyTWV0YWRhdGESFAoFb3duZXIYASABKAlSBW93bmVyEjQKBmhlYWx0aBgCIAEoCz'
    'IcLmJ1aWxkYnVja2V0LnYyLkhlYWx0aFN0YXR1c1IGaGVhbHRo');

@$core.Deprecated('Use builderItemDescriptor instead')
const BuilderItem$json = {
  '1': 'BuilderItem',
  '2': [
    {
      '1': 'id',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuilderID',
      '10': 'id'
    },
    {
      '1': 'config',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.BuilderConfig',
      '10': 'config'
    },
    {
      '1': 'metadata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuilderMetadata',
      '10': 'metadata'
    },
  ],
};

/// Descriptor for `BuilderItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderItemDescriptor = $convert.base64Decode(
    'CgtCdWlsZGVySXRlbRIpCgJpZBgBIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZXJJRFICaW'
    'QSMgoGY29uZmlnGAIgASgLMhouYnVpbGRidWNrZXQuQnVpbGRlckNvbmZpZ1IGY29uZmlnEjsK'
    'CG1ldGFkYXRhGAMgASgLMh8uYnVpbGRidWNrZXQudjIuQnVpbGRlck1ldGFkYXRhUghtZXRhZG'
    'F0YQ==');
