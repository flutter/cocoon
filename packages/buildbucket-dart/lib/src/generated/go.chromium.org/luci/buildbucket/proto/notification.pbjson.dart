//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/notification.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use notificationConfigDescriptor instead')
const NotificationConfig$json = {
  '1': 'NotificationConfig',
  '2': [
    {'1': 'pubsub_topic', '3': 1, '4': 1, '5': 9, '10': 'pubsubTopic'},
    {'1': 'user_data', '3': 2, '4': 1, '5': 12, '10': 'userData'},
  ],
};

/// Descriptor for `NotificationConfig`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notificationConfigDescriptor =
    $convert.base64Decode('ChJOb3RpZmljYXRpb25Db25maWcSIQoMcHVic3ViX3RvcGljGAEgASgJUgtwdWJzdWJUb3BpYx'
        'IbCgl1c2VyX2RhdGEYAiABKAxSCHVzZXJEYXRh');

@$core.Deprecated('Use buildsV2PubSubDescriptor instead')
const BuildsV2PubSub$json = {
  '1': 'BuildsV2PubSub',
  '2': [
    {'1': 'build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '10': 'build'},
    {'1': 'build_large_fields', '3': 2, '4': 1, '5': 12, '10': 'buildLargeFields'},
    {'1': 'compression', '3': 3, '4': 1, '5': 14, '6': '.buildbucket.v2.Compression', '10': 'compression'},
  ],
};

/// Descriptor for `BuildsV2PubSub`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildsV2PubSubDescriptor =
    $convert.base64Decode('Cg5CdWlsZHNWMlB1YlN1YhIrCgVidWlsZBgBIAEoCzIVLmJ1aWxkYnVja2V0LnYyLkJ1aWxkUg'
        'VidWlsZBIsChJidWlsZF9sYXJnZV9maWVsZHMYAiABKAxSEGJ1aWxkTGFyZ2VGaWVsZHMSPQoL'
        'Y29tcHJlc3Npb24YAyABKA4yGy5idWlsZGJ1Y2tldC52Mi5Db21wcmVzc2lvblILY29tcHJlc3'
        'Npb24=');

@$core.Deprecated('Use pubSubCallBackDescriptor instead')
const PubSubCallBack$json = {
  '1': 'PubSubCallBack',
  '2': [
    {'1': 'build_pubsub', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildsV2PubSub', '10': 'buildPubsub'},
    {'1': 'user_data', '3': 2, '4': 1, '5': 12, '10': 'userData'},
  ],
};

/// Descriptor for `PubSubCallBack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pubSubCallBackDescriptor =
    $convert.base64Decode('Cg5QdWJTdWJDYWxsQmFjaxJBCgxidWlsZF9wdWJzdWIYASABKAsyHi5idWlsZGJ1Y2tldC52Mi'
        '5CdWlsZHNWMlB1YlN1YlILYnVpbGRQdWJzdWISGwoJdXNlcl9kYXRhGAIgASgMUgh1c2VyRGF0'
        'YQ==');
