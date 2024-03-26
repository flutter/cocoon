//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/artifact.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use artifactDescriptor instead')
const Artifact$json = {
  '1': 'Artifact',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'artifact_id', '3': 2, '4': 1, '5': 9, '10': 'artifactId'},
    {'1': 'fetch_url', '3': 3, '4': 1, '5': 9, '10': 'fetchUrl'},
    {
      '1': 'fetch_url_expiration',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'fetchUrlExpiration'
    },
    {'1': 'content_type', '3': 5, '4': 1, '5': 9, '10': 'contentType'},
    {'1': 'size_bytes', '3': 6, '4': 1, '5': 3, '10': 'sizeBytes'},
    {'1': 'contents', '3': 7, '4': 1, '5': 12, '8': {}, '10': 'contents'},
    {'1': 'gcs_uri', '3': 8, '4': 1, '5': 9, '10': 'gcsUri'},
    {'1': 'test_status', '3': 9, '4': 1, '5': 14, '6': '.luci.resultdb.v1.TestStatus', '10': 'testStatus'},
  ],
};

/// Descriptor for `Artifact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List artifactDescriptor =
    $convert.base64Decode('CghBcnRpZmFjdBISCgRuYW1lGAEgASgJUgRuYW1lEh8KC2FydGlmYWN0X2lkGAIgASgJUgphcn'
        'RpZmFjdElkEhsKCWZldGNoX3VybBgDIAEoCVIIZmV0Y2hVcmwSTAoUZmV0Y2hfdXJsX2V4cGly'
        'YXRpb24YBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhJmZXRjaFVybEV4cGlyYX'
        'Rpb24SIQoMY29udGVudF90eXBlGAUgASgJUgtjb250ZW50VHlwZRIdCgpzaXplX2J5dGVzGAYg'
        'ASgDUglzaXplQnl0ZXMSHwoIY29udGVudHMYByABKAxCA+BBBFIIY29udGVudHMSFwoHZ2NzX3'
        'VyaRgIIAEoCVIGZ2NzVXJpEj0KC3Rlc3Rfc3RhdHVzGAkgASgOMhwubHVjaS5yZXN1bHRkYi52'
        'MS5UZXN0U3RhdHVzUgp0ZXN0U3RhdHVz');
