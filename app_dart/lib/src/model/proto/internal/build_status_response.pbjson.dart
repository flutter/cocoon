//
//  Generated code. Do not modify.
//  source: internal/build_status_response.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use enumBuildStatusDescriptor instead')
const EnumBuildStatus$json = {
  '1': 'EnumBuildStatus',
  '2': [
    {'1': 'success', '2': 1},
    {'1': 'failure', '2': 2},
  ],
};

/// Descriptor for `EnumBuildStatus`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List enumBuildStatusDescriptor =
    $convert.base64Decode('Cg9FbnVtQnVpbGRTdGF0dXMSCwoHc3VjY2VzcxABEgsKB2ZhaWx1cmUQAg==');

@$core.Deprecated('Use buildStatusResponseDescriptor instead')
const BuildStatusResponse$json = {
  '1': 'BuildStatusResponse',
  '2': [
    {'1': 'build_status', '3': 1, '4': 1, '5': 14, '6': '.cocoon.EnumBuildStatus', '10': 'buildStatus'},
    {'1': 'failing_tasks', '3': 2, '4': 3, '5': 9, '10': 'failingTasks'},
  ],
};

/// Descriptor for `BuildStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildStatusResponseDescriptor =
    $convert.base64Decode('ChNCdWlsZFN0YXR1c1Jlc3BvbnNlEjoKDGJ1aWxkX3N0YXR1cxgBIAEoDjIXLmNvY29vbi5Fbn'
        'VtQnVpbGRTdGF0dXNSC2J1aWxkU3RhdHVzEiMKDWZhaWxpbmdfdGFza3MYAiADKAlSDGZhaWxp'
        'bmdUYXNrcw==');
