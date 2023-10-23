//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builder_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getBuilderRequestDescriptor instead')
const GetBuilderRequest$json = {
  '1': 'GetBuilderRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'id'},
    {'1': 'mask', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderMask', '10': 'mask'},
  ],
};

/// Descriptor for `GetBuilderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBuilderRequestDescriptor =
    $convert.base64Decode('ChFHZXRCdWlsZGVyUmVxdWVzdBIpCgJpZBgBIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZX'
        'JJRFICaWQSLwoEbWFzaxgCIAEoCzIbLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZXJNYXNrUgRtYXNr');

@$core.Deprecated('Use listBuildersRequestDescriptor instead')
const ListBuildersRequest$json = {
  '1': 'ListBuildersRequest',
  '2': [
    {'1': 'project', '3': 1, '4': 1, '5': 9, '10': 'project'},
    {'1': 'bucket', '3': 2, '4': 1, '5': 9, '10': 'bucket'},
    {'1': 'page_size', '3': 3, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 4, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `ListBuildersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBuildersRequestDescriptor =
    $convert.base64Decode('ChNMaXN0QnVpbGRlcnNSZXF1ZXN0EhgKB3Byb2plY3QYASABKAlSB3Byb2plY3QSFgoGYnVja2'
        'V0GAIgASgJUgZidWNrZXQSGwoJcGFnZV9zaXplGAMgASgFUghwYWdlU2l6ZRIdCgpwYWdlX3Rv'
        'a2VuGAQgASgJUglwYWdlVG9rZW4=');

@$core.Deprecated('Use listBuildersResponseDescriptor instead')
const ListBuildersResponse$json = {
  '1': 'ListBuildersResponse',
  '2': [
    {'1': 'builders', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.v2.BuilderItem', '10': 'builders'},
    {'1': 'next_page_token', '3': 2, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `ListBuildersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listBuildersResponseDescriptor =
    $convert.base64Decode('ChRMaXN0QnVpbGRlcnNSZXNwb25zZRI3CghidWlsZGVycxgBIAMoCzIbLmJ1aWxkYnVja2V0Ln'
        'YyLkJ1aWxkZXJJdGVtUghidWlsZGVycxImCg9uZXh0X3BhZ2VfdG9rZW4YAiABKAlSDW5leHRQ'
        'YWdlVG9rZW4=');

@$core.Deprecated('Use setBuilderHealthRequestDescriptor instead')
const SetBuilderHealthRequest$json = {
  '1': 'SetBuilderHealthRequest',
  '2': [
    {
      '1': 'health',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.SetBuilderHealthRequest.BuilderHealth',
      '10': 'health'
    },
  ],
  '3': [SetBuilderHealthRequest_BuilderHealth$json],
};

@$core.Deprecated('Use setBuilderHealthRequestDescriptor instead')
const SetBuilderHealthRequest_BuilderHealth$json = {
  '1': 'BuilderHealth',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '8': {}, '10': 'id'},
    {'1': 'health', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.HealthStatus', '8': {}, '10': 'health'},
  ],
};

/// Descriptor for `SetBuilderHealthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setBuilderHealthRequestDescriptor =
    $convert.base64Decode('ChdTZXRCdWlsZGVySGVhbHRoUmVxdWVzdBJNCgZoZWFsdGgYASADKAsyNS5idWlsZGJ1Y2tldC'
        '52Mi5TZXRCdWlsZGVySGVhbHRoUmVxdWVzdC5CdWlsZGVySGVhbHRoUgZoZWFsdGgaegoNQnVp'
        'bGRlckhlYWx0aBIuCgJpZBgBIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZXJJREID4EECUg'
        'JpZBI5CgZoZWFsdGgYAiABKAsyHC5idWlsZGJ1Y2tldC52Mi5IZWFsdGhTdGF0dXNCA+BBAlIG'
        'aGVhbHRo');

@$core.Deprecated('Use setBuilderHealthResponseDescriptor instead')
const SetBuilderHealthResponse$json = {
  '1': 'SetBuilderHealthResponse',
  '2': [
    {
      '1': 'responses',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.SetBuilderHealthResponse.Response',
      '10': 'responses'
    },
  ],
  '3': [SetBuilderHealthResponse_Response$json],
};

@$core.Deprecated('Use setBuilderHealthResponseDescriptor instead')
const SetBuilderHealthResponse_Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'result', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Empty', '9': 0, '10': 'result'},
    {'1': 'error', '3': 100, '4': 1, '5': 11, '6': '.google.rpc.Status', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'response'},
  ],
};

/// Descriptor for `SetBuilderHealthResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setBuilderHealthResponseDescriptor =
    $convert.base64Decode('ChhTZXRCdWlsZGVySGVhbHRoUmVzcG9uc2USTwoJcmVzcG9uc2VzGAEgAygLMjEuYnVpbGRidW'
        'NrZXQudjIuU2V0QnVpbGRlckhlYWx0aFJlc3BvbnNlLlJlc3BvbnNlUglyZXNwb25zZXMadAoI'
        'UmVzcG9uc2USMAoGcmVzdWx0GAEgASgLMhYuZ29vZ2xlLnByb3RvYnVmLkVtcHR5SABSBnJlc3'
        'VsdBIqCgVlcnJvchhkIAEoCzISLmdvb2dsZS5ycGMuU3RhdHVzSABSBWVycm9yQgoKCHJlc3Bv'
        'bnNl');

@$core.Deprecated('Use builderMaskDescriptor instead')
const BuilderMask$json = {
  '1': 'BuilderMask',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.buildbucket.v2.BuilderMask.BuilderMaskType', '10': 'type'},
  ],
  '4': [BuilderMask_BuilderMaskType$json],
};

@$core.Deprecated('Use builderMaskDescriptor instead')
const BuilderMask_BuilderMaskType$json = {
  '1': 'BuilderMaskType',
  '2': [
    {'1': 'BUILDER_MASK_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'CONFIG_ONLY', '2': 1},
    {'1': 'ALL', '2': 2},
    {'1': 'METADATA_ONLY', '2': 3},
  ],
};

/// Descriptor for `BuilderMask`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List builderMaskDescriptor =
    $convert.base64Decode('CgtCdWlsZGVyTWFzaxI/CgR0eXBlGAEgASgOMisuYnVpbGRidWNrZXQudjIuQnVpbGRlck1hc2'
        'suQnVpbGRlck1hc2tUeXBlUgR0eXBlImEKD0J1aWxkZXJNYXNrVHlwZRIhCh1CVUlMREVSX01B'
        'U0tfVFlQRV9VTlNQRUNJRklFRBAAEg8KC0NPTkZJR19PTkxZEAESBwoDQUxMEAISEQoNTUVUQU'
        'RBVEFfT05MWRAD');
