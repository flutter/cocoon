//
//  Generated code. Do not modify.
//  source: internal/github_webhook.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use githubWebhookMessageDescriptor instead')
const GithubWebhookMessage$json = {
  '1': 'GithubWebhookMessage',
  '2': [
    {'1': 'event', '3': 1, '4': 1, '5': 9, '10': 'event'},
    {'1': 'payload', '3': 2, '4': 1, '5': 9, '10': 'payload'},
  ],
};

/// Descriptor for `GithubWebhookMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List githubWebhookMessageDescriptor = $convert.base64Decode(
    'ChRHaXRodWJXZWJob29rTWVzc2FnZRIUCgVldmVudBgBIAEoCVIFZXZlbnQSGAoHcGF5bG9hZB'
    'gCIAEoCVIHcGF5bG9hZA==');
