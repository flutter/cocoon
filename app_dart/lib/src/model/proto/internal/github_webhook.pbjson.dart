///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/github_webhook.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use githubWebhookMessageDescriptor instead')
const GithubWebhookMessage$json = const {
  '1': 'GithubWebhookMessage',
  '2': const [
    const {'1': 'event', '3': 1, '4': 1, '5': 9, '10': 'event'},
    const {'1': 'payload', '3': 2, '4': 1, '5': 9, '10': 'payload'},
  ],
};

/// Descriptor for `GithubWebhookMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List githubWebhookMessageDescriptor = $convert
    .base64Decode('ChRHaXRodWJXZWJob29rTWVzc2FnZRIUCgVldmVudBgBIAEoCVIFZXZlbnQSGAoHcGF5bG9hZBgCIAEoCVIHcGF5bG9hZA==');
