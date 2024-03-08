//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/launcher.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use buildSecretsDescriptor instead')
const BuildSecrets$json = {
  '1': 'BuildSecrets',
  '2': [
    {'1': 'build_token', '3': 1, '4': 1, '5': 9, '10': 'buildToken'},
    {'1': 'resultdb_invocation_update_token', '3': 2, '4': 1, '5': 9, '10': 'resultdbInvocationUpdateToken'},
    {'1': 'start_build_token', '3': 3, '4': 1, '5': 9, '10': 'startBuildToken'},
  ],
};

/// Descriptor for `BuildSecrets`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildSecretsDescriptor = $convert.base64Decode(
    'CgxCdWlsZFNlY3JldHMSHwoLYnVpbGRfdG9rZW4YASABKAlSCmJ1aWxkVG9rZW4SRwogcmVzdW'
    'x0ZGJfaW52b2NhdGlvbl91cGRhdGVfdG9rZW4YAiABKAlSHXJlc3VsdGRiSW52b2NhdGlvblVw'
    'ZGF0ZVRva2VuEioKEXN0YXJ0X2J1aWxkX3Rva2VuGAMgASgJUg9zdGFydEJ1aWxkVG9rZW4=');

@$core.Deprecated('Use bBAgentArgsDescriptor instead')
const BBAgentArgs$json = {
  '1': 'BBAgentArgs',
  '2': [
    {'1': 'executable_path', '3': 1, '4': 1, '5': 9, '10': 'executablePath'},
    {'1': 'payload_path', '3': 5, '4': 1, '5': 9, '10': 'payloadPath'},
    {'1': 'cache_dir', '3': 2, '4': 1, '5': 9, '10': 'cacheDir'},
    {'1': 'known_public_gerrit_hosts', '3': 3, '4': 3, '5': 9, '10': 'knownPublicGerritHosts'},
    {'1': 'build', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '10': 'build'},
  ],
};

/// Descriptor for `BBAgentArgs`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bBAgentArgsDescriptor = $convert.base64Decode(
    'CgtCQkFnZW50QXJncxInCg9leGVjdXRhYmxlX3BhdGgYASABKAlSDmV4ZWN1dGFibGVQYXRoEi'
    'EKDHBheWxvYWRfcGF0aBgFIAEoCVILcGF5bG9hZFBhdGgSGwoJY2FjaGVfZGlyGAIgASgJUghj'
    'YWNoZURpchI5Chlrbm93bl9wdWJsaWNfZ2Vycml0X2hvc3RzGAMgAygJUhZrbm93blB1YmxpY0'
    'dlcnJpdEhvc3RzEisKBWJ1aWxkGAQgASgLMhUuYnVpbGRidWNrZXQudjIuQnVpbGRSBWJ1aWxk');

@$core.Deprecated('Use buildbucketAgentContextDescriptor instead')
const BuildbucketAgentContext$json = {
  '1': 'BuildbucketAgentContext',
  '2': [
    {'1': 'task_id', '3': 1, '4': 1, '5': 9, '10': 'taskId'},
    {'1': 'secrets', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildSecrets', '10': 'secrets'},
  ],
};

/// Descriptor for `BuildbucketAgentContext`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildbucketAgentContextDescriptor = $convert.base64Decode(
    'ChdCdWlsZGJ1Y2tldEFnZW50Q29udGV4dBIXCgd0YXNrX2lkGAEgASgJUgZ0YXNrSWQSNgoHc2'
    'VjcmV0cxgCIAEoCzIcLmJ1aWxkYnVja2V0LnYyLkJ1aWxkU2VjcmV0c1IHc2VjcmV0cw==');

