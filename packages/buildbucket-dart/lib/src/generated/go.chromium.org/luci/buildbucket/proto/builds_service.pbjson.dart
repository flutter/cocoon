//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/builds_service.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use getBuildRequestDescriptor instead')
const GetBuildRequest$json = {
  '1': 'GetBuildRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'builder', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'builder'},
    {'1': 'build_number', '3': 3, '4': 1, '5': 5, '10': 'buildNumber'},
    {
      '1': 'fields',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '8': {'3': true},
      '10': 'fields',
    },
    {'1': 'mask', '3': 101, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
  ],
};

/// Descriptor for `GetBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBuildRequestDescriptor =
    $convert.base64Decode('Cg9HZXRCdWlsZFJlcXVlc3QSDgoCaWQYASABKANSAmlkEjMKB2J1aWxkZXIYAiABKAsyGS5idW'
        'lsZGJ1Y2tldC52Mi5CdWlsZGVySURSB2J1aWxkZXISIQoMYnVpbGRfbnVtYmVyGAMgASgFUgti'
        'dWlsZE51bWJlchI2CgZmaWVsZHMYZCABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRNYXNrQg'
        'IYAVIGZmllbGRzEi0KBG1hc2sYZSABKAsyGS5idWlsZGJ1Y2tldC52Mi5CdWlsZE1hc2tSBG1h'
        'c2s=');

@$core.Deprecated('Use searchBuildsRequestDescriptor instead')
const SearchBuildsRequest$json = {
  '1': 'SearchBuildsRequest',
  '2': [
    {'1': 'predicate', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildPredicate', '10': 'predicate'},
    {
      '1': 'fields',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '8': {'3': true},
      '10': 'fields',
    },
    {'1': 'mask', '3': 103, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
    {'1': 'page_size', '3': 101, '4': 1, '5': 5, '10': 'pageSize'},
    {'1': 'page_token', '3': 102, '4': 1, '5': 9, '10': 'pageToken'},
  ],
};

/// Descriptor for `SearchBuildsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchBuildsRequestDescriptor =
    $convert.base64Decode('ChNTZWFyY2hCdWlsZHNSZXF1ZXN0EjwKCXByZWRpY2F0ZRgBIAEoCzIeLmJ1aWxkYnVja2V0Ln'
        'YyLkJ1aWxkUHJlZGljYXRlUglwcmVkaWNhdGUSNgoGZmllbGRzGGQgASgLMhouZ29vZ2xlLnBy'
        'b3RvYnVmLkZpZWxkTWFza0ICGAFSBmZpZWxkcxItCgRtYXNrGGcgASgLMhkuYnVpbGRidWNrZX'
        'QudjIuQnVpbGRNYXNrUgRtYXNrEhsKCXBhZ2Vfc2l6ZRhlIAEoBVIIcGFnZVNpemUSHQoKcGFn'
        'ZV90b2tlbhhmIAEoCVIJcGFnZVRva2Vu');

@$core.Deprecated('Use searchBuildsResponseDescriptor instead')
const SearchBuildsResponse$json = {
  '1': 'SearchBuildsResponse',
  '2': [
    {'1': 'builds', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.v2.Build', '10': 'builds'},
    {'1': 'next_page_token', '3': 100, '4': 1, '5': 9, '10': 'nextPageToken'},
  ],
};

/// Descriptor for `SearchBuildsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List searchBuildsResponseDescriptor =
    $convert.base64Decode('ChRTZWFyY2hCdWlsZHNSZXNwb25zZRItCgZidWlsZHMYASADKAsyFS5idWlsZGJ1Y2tldC52Mi'
        '5CdWlsZFIGYnVpbGRzEiYKD25leHRfcGFnZV90b2tlbhhkIAEoCVINbmV4dFBhZ2VUb2tlbg==');

@$core.Deprecated('Use batchRequestDescriptor instead')
const BatchRequest$json = {
  '1': 'BatchRequest',
  '2': [
    {'1': 'requests', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.v2.BatchRequest.Request', '10': 'requests'},
  ],
  '3': [BatchRequest_Request$json],
};

@$core.Deprecated('Use batchRequestDescriptor instead')
const BatchRequest_Request$json = {
  '1': 'Request',
  '2': [
    {'1': 'get_build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.GetBuildRequest', '9': 0, '10': 'getBuild'},
    {
      '1': 'search_builds',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.SearchBuildsRequest',
      '9': 0,
      '10': 'searchBuilds'
    },
    {
      '1': 'schedule_build',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.ScheduleBuildRequest',
      '9': 0,
      '10': 'scheduleBuild'
    },
    {
      '1': 'cancel_build',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.CancelBuildRequest',
      '9': 0,
      '10': 'cancelBuild'
    },
    {
      '1': 'get_build_status',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.GetBuildStatusRequest',
      '9': 0,
      '10': 'getBuildStatus'
    },
  ],
  '8': [
    {'1': 'request'},
  ],
};

/// Descriptor for `BatchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchRequestDescriptor =
    $convert.base64Decode('CgxCYXRjaFJlcXVlc3QSQAoIcmVxdWVzdHMYASADKAsyJC5idWlsZGJ1Y2tldC52Mi5CYXRjaF'
        'JlcXVlc3QuUmVxdWVzdFIIcmVxdWVzdHMaiwMKB1JlcXVlc3QSPgoJZ2V0X2J1aWxkGAEgASgL'
        'Mh8uYnVpbGRidWNrZXQudjIuR2V0QnVpbGRSZXF1ZXN0SABSCGdldEJ1aWxkEkoKDXNlYXJjaF'
        '9idWlsZHMYAiABKAsyIy5idWlsZGJ1Y2tldC52Mi5TZWFyY2hCdWlsZHNSZXF1ZXN0SABSDHNl'
        'YXJjaEJ1aWxkcxJNCg5zY2hlZHVsZV9idWlsZBgDIAEoCzIkLmJ1aWxkYnVja2V0LnYyLlNjaG'
        'VkdWxlQnVpbGRSZXF1ZXN0SABSDXNjaGVkdWxlQnVpbGQSRwoMY2FuY2VsX2J1aWxkGAQgASgL'
        'MiIuYnVpbGRidWNrZXQudjIuQ2FuY2VsQnVpbGRSZXF1ZXN0SABSC2NhbmNlbEJ1aWxkElEKEG'
        'dldF9idWlsZF9zdGF0dXMYBSABKAsyJS5idWlsZGJ1Y2tldC52Mi5HZXRCdWlsZFN0YXR1c1Jl'
        'cXVlc3RIAFIOZ2V0QnVpbGRTdGF0dXNCCQoHcmVxdWVzdA==');

@$core.Deprecated('Use batchResponseDescriptor instead')
const BatchResponse$json = {
  '1': 'BatchResponse',
  '2': [
    {'1': 'responses', '3': 1, '4': 3, '5': 11, '6': '.buildbucket.v2.BatchResponse.Response', '10': 'responses'},
  ],
  '3': [BatchResponse_Response$json],
};

@$core.Deprecated('Use batchResponseDescriptor instead')
const BatchResponse_Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'get_build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '9': 0, '10': 'getBuild'},
    {
      '1': 'search_builds',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.SearchBuildsResponse',
      '9': 0,
      '10': 'searchBuilds'
    },
    {'1': 'schedule_build', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '9': 0, '10': 'scheduleBuild'},
    {'1': 'cancel_build', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '9': 0, '10': 'cancelBuild'},
    {'1': 'get_build_status', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '9': 0, '10': 'getBuildStatus'},
    {'1': 'error', '3': 100, '4': 1, '5': 11, '6': '.google.rpc.Status', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'response'},
  ],
};

/// Descriptor for `BatchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchResponseDescriptor =
    $convert.base64Decode('Cg1CYXRjaFJlc3BvbnNlEkQKCXJlc3BvbnNlcxgBIAMoCzImLmJ1aWxkYnVja2V0LnYyLkJhdG'
        'NoUmVzcG9uc2UuUmVzcG9uc2VSCXJlc3BvbnNlcxqEAwoIUmVzcG9uc2USNAoJZ2V0X2J1aWxk'
        'GAEgASgLMhUuYnVpbGRidWNrZXQudjIuQnVpbGRIAFIIZ2V0QnVpbGQSSwoNc2VhcmNoX2J1aW'
        'xkcxgCIAEoCzIkLmJ1aWxkYnVja2V0LnYyLlNlYXJjaEJ1aWxkc1Jlc3BvbnNlSABSDHNlYXJj'
        'aEJ1aWxkcxI+Cg5zY2hlZHVsZV9idWlsZBgDIAEoCzIVLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSA'
        'BSDXNjaGVkdWxlQnVpbGQSOgoMY2FuY2VsX2J1aWxkGAQgASgLMhUuYnVpbGRidWNrZXQudjIu'
        'QnVpbGRIAFILY2FuY2VsQnVpbGQSQQoQZ2V0X2J1aWxkX3N0YXR1cxgFIAEoCzIVLmJ1aWxkYn'
        'Vja2V0LnYyLkJ1aWxkSABSDmdldEJ1aWxkU3RhdHVzEioKBWVycm9yGGQgASgLMhIuZ29vZ2xl'
        'LnJwYy5TdGF0dXNIAFIFZXJyb3JCCgoIcmVzcG9uc2U=');

@$core.Deprecated('Use updateBuildRequestDescriptor instead')
const UpdateBuildRequest$json = {
  '1': 'UpdateBuildRequest',
  '2': [
    {'1': 'build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '10': 'build'},
    {'1': 'update_mask', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.FieldMask', '10': 'updateMask'},
    {
      '1': 'fields',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '8': {'3': true},
      '10': 'fields',
    },
    {'1': 'mask', '3': 101, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
  ],
};

/// Descriptor for `UpdateBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateBuildRequestDescriptor =
    $convert.base64Decode('ChJVcGRhdGVCdWlsZFJlcXVlc3QSKwoFYnVpbGQYASABKAsyFS5idWlsZGJ1Y2tldC52Mi5CdW'
        'lsZFIFYnVpbGQSOwoLdXBkYXRlX21hc2sYAiABKAsyGi5nb29nbGUucHJvdG9idWYuRmllbGRN'
        'YXNrUgp1cGRhdGVNYXNrEjYKBmZpZWxkcxhkIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5GaWVsZE'
        '1hc2tCAhgBUgZmaWVsZHMSLQoEbWFzaxhlIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkTWFz'
        'a1IEbWFzaw==');

@$core.Deprecated('Use scheduleBuildRequestDescriptor instead')
const ScheduleBuildRequest$json = {
  '1': 'ScheduleBuildRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'template_build_id', '3': 2, '4': 1, '5': 3, '10': 'templateBuildId'},
    {'1': 'builder', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'builder'},
    {'1': 'canary', '3': 4, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'canary'},
    {'1': 'experimental', '3': 5, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'experimental'},
    {
      '1': 'experiments',
      '3': 16,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.ScheduleBuildRequest.ExperimentsEntry',
      '10': 'experiments'
    },
    {'1': 'properties', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'properties'},
    {'1': 'gitiles_commit', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.v2.GitilesCommit', '10': 'gitilesCommit'},
    {'1': 'gerrit_changes', '3': 8, '4': 3, '5': 11, '6': '.buildbucket.v2.GerritChange', '10': 'gerritChanges'},
    {'1': 'tags', '3': 9, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'tags'},
    {'1': 'dimensions', '3': 10, '4': 3, '5': 11, '6': '.buildbucket.v2.RequestedDimension', '10': 'dimensions'},
    {'1': 'priority', '3': 11, '4': 1, '5': 5, '10': 'priority'},
    {'1': 'notify', '3': 12, '4': 1, '5': 11, '6': '.buildbucket.v2.NotificationConfig', '10': 'notify'},
    {
      '1': 'fields',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '8': {'3': true},
      '10': 'fields',
    },
    {'1': 'mask', '3': 101, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
    {'1': 'critical', '3': 13, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'critical'},
    {'1': 'exe', '3': 14, '4': 1, '5': 11, '6': '.buildbucket.v2.Executable', '10': 'exe'},
    {'1': 'swarming', '3': 15, '4': 1, '5': 11, '6': '.buildbucket.v2.ScheduleBuildRequest.Swarming', '10': 'swarming'},
    {'1': 'scheduling_timeout', '3': 17, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'schedulingTimeout'},
    {'1': 'execution_timeout', '3': 18, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'executionTimeout'},
    {'1': 'grace_period', '3': 19, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'gracePeriod'},
    {'1': 'dry_run', '3': 20, '4': 1, '5': 8, '10': 'dryRun'},
    {'1': 'can_outlive_parent', '3': 21, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'canOutliveParent'},
    {'1': 'retriable', '3': 22, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'retriable'},
    {
      '1': 'shadow_input',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.ScheduleBuildRequest.ShadowInput',
      '10': 'shadowInput'
    },
  ],
  '3': [
    ScheduleBuildRequest_ExperimentsEntry$json,
    ScheduleBuildRequest_Swarming$json,
    ScheduleBuildRequest_ShadowInput$json
  ],
};

@$core.Deprecated('Use scheduleBuildRequestDescriptor instead')
const ScheduleBuildRequest_ExperimentsEntry$json = {
  '1': 'ExperimentsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use scheduleBuildRequestDescriptor instead')
const ScheduleBuildRequest_Swarming$json = {
  '1': 'Swarming',
  '2': [
    {'1': 'parent_run_id', '3': 1, '4': 1, '5': 9, '10': 'parentRunId'},
  ],
};

@$core.Deprecated('Use scheduleBuildRequestDescriptor instead')
const ScheduleBuildRequest_ShadowInput$json = {
  '1': 'ShadowInput',
};

/// Descriptor for `ScheduleBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scheduleBuildRequestDescriptor =
    $convert.base64Decode('ChRTY2hlZHVsZUJ1aWxkUmVxdWVzdBIdCgpyZXF1ZXN0X2lkGAEgASgJUglyZXF1ZXN0SWQSKg'
        'oRdGVtcGxhdGVfYnVpbGRfaWQYAiABKANSD3RlbXBsYXRlQnVpbGRJZBIzCgdidWlsZGVyGAMg'
        'ASgLMhkuYnVpbGRidWNrZXQudjIuQnVpbGRlcklEUgdidWlsZGVyEi8KBmNhbmFyeRgEIAEoDj'
        'IXLmJ1aWxkYnVja2V0LnYyLlRyaW5hcnlSBmNhbmFyeRI7CgxleHBlcmltZW50YWwYBSABKA4y'
        'Fy5idWlsZGJ1Y2tldC52Mi5UcmluYXJ5UgxleHBlcmltZW50YWwSVwoLZXhwZXJpbWVudHMYEC'
        'ADKAsyNS5idWlsZGJ1Y2tldC52Mi5TY2hlZHVsZUJ1aWxkUmVxdWVzdC5FeHBlcmltZW50c0Vu'
        'dHJ5UgtleHBlcmltZW50cxI3Cgpwcm9wZXJ0aWVzGAYgASgLMhcuZ29vZ2xlLnByb3RvYnVmLl'
        'N0cnVjdFIKcHJvcGVydGllcxJECg5naXRpbGVzX2NvbW1pdBgHIAEoCzIdLmJ1aWxkYnVja2V0'
        'LnYyLkdpdGlsZXNDb21taXRSDWdpdGlsZXNDb21taXQSQwoOZ2Vycml0X2NoYW5nZXMYCCADKA'
        'syHC5idWlsZGJ1Y2tldC52Mi5HZXJyaXRDaGFuZ2VSDWdlcnJpdENoYW5nZXMSLgoEdGFncxgJ'
        'IAMoCzIaLmJ1aWxkYnVja2V0LnYyLlN0cmluZ1BhaXJSBHRhZ3MSQgoKZGltZW5zaW9ucxgKIA'
        'MoCzIiLmJ1aWxkYnVja2V0LnYyLlJlcXVlc3RlZERpbWVuc2lvblIKZGltZW5zaW9ucxIaCghw'
        'cmlvcml0eRgLIAEoBVIIcHJpb3JpdHkSOgoGbm90aWZ5GAwgASgLMiIuYnVpbGRidWNrZXQudj'
        'IuTm90aWZpY2F0aW9uQ29uZmlnUgZub3RpZnkSNgoGZmllbGRzGGQgASgLMhouZ29vZ2xlLnBy'
        'b3RvYnVmLkZpZWxkTWFza0ICGAFSBmZpZWxkcxItCgRtYXNrGGUgASgLMhkuYnVpbGRidWNrZX'
        'QudjIuQnVpbGRNYXNrUgRtYXNrEjMKCGNyaXRpY2FsGA0gASgOMhcuYnVpbGRidWNrZXQudjIu'
        'VHJpbmFyeVIIY3JpdGljYWwSLAoDZXhlGA4gASgLMhouYnVpbGRidWNrZXQudjIuRXhlY3V0YW'
        'JsZVIDZXhlEkkKCHN3YXJtaW5nGA8gASgLMi0uYnVpbGRidWNrZXQudjIuU2NoZWR1bGVCdWls'
        'ZFJlcXVlc3QuU3dhcm1pbmdSCHN3YXJtaW5nEkgKEnNjaGVkdWxpbmdfdGltZW91dBgRIAEoCz'
        'IZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRc2NoZWR1bGluZ1RpbWVvdXQSRgoRZXhlY3V0'
        'aW9uX3RpbWVvdXQYEiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SEGV4ZWN1dGlvbl'
        'RpbWVvdXQSPAoMZ3JhY2VfcGVyaW9kGBMgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9u'
        'UgtncmFjZVBlcmlvZBIXCgdkcnlfcnVuGBQgASgIUgZkcnlSdW4SRQoSY2FuX291dGxpdmVfcG'
        'FyZW50GBUgASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVIQY2FuT3V0bGl2ZVBhcmVudBI1'
        'CglyZXRyaWFibGUYFiABKA4yFy5idWlsZGJ1Y2tldC52Mi5UcmluYXJ5UglyZXRyaWFibGUSUw'
        'oMc2hhZG93X2lucHV0GBcgASgLMjAuYnVpbGRidWNrZXQudjIuU2NoZWR1bGVCdWlsZFJlcXVl'
        'c3QuU2hhZG93SW5wdXRSC3NoYWRvd0lucHV0Gj4KEEV4cGVyaW1lbnRzRW50cnkSEAoDa2V5GA'
        'EgASgJUgNrZXkSFAoFdmFsdWUYAiABKAhSBXZhbHVlOgI4ARouCghTd2FybWluZxIiCg1wYXJl'
        'bnRfcnVuX2lkGAEgASgJUgtwYXJlbnRSdW5JZBoNCgtTaGFkb3dJbnB1dA==');

@$core.Deprecated('Use cancelBuildRequestDescriptor instead')
const CancelBuildRequest$json = {
  '1': 'CancelBuildRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'summary_markdown', '3': 2, '4': 1, '5': 9, '10': 'summaryMarkdown'},
    {
      '1': 'fields',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.FieldMask',
      '8': {'3': true},
      '10': 'fields',
    },
    {'1': 'mask', '3': 101, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
  ],
};

/// Descriptor for `CancelBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cancelBuildRequestDescriptor =
    $convert.base64Decode('ChJDYW5jZWxCdWlsZFJlcXVlc3QSDgoCaWQYASABKANSAmlkEikKEHN1bW1hcnlfbWFya2Rvd2'
        '4YAiABKAlSD3N1bW1hcnlNYXJrZG93bhI2CgZmaWVsZHMYZCABKAsyGi5nb29nbGUucHJvdG9i'
        'dWYuRmllbGRNYXNrQgIYAVIGZmllbGRzEi0KBG1hc2sYZSABKAsyGS5idWlsZGJ1Y2tldC52Mi'
        '5CdWlsZE1hc2tSBG1hc2s=');

@$core.Deprecated('Use createBuildRequestDescriptor instead')
const CreateBuildRequest$json = {
  '1': 'CreateBuildRequest',
  '2': [
    {'1': 'build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '8': {}, '10': 'build'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'mask', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildMask', '10': 'mask'},
  ],
};

/// Descriptor for `CreateBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createBuildRequestDescriptor =
    $convert.base64Decode('ChJDcmVhdGVCdWlsZFJlcXVlc3QSMAoFYnVpbGQYASABKAsyFS5idWlsZGJ1Y2tldC52Mi5CdW'
        'lsZEID4EECUgVidWlsZBIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0SWQSLQoEbWFzaxgD'
        'IAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkTWFza1IEbWFzaw==');

@$core.Deprecated('Use synthesizeBuildRequestDescriptor instead')
const SynthesizeBuildRequest$json = {
  '1': 'SynthesizeBuildRequest',
  '2': [
    {'1': 'template_build_id', '3': 1, '4': 1, '5': 3, '10': 'templateBuildId'},
    {'1': 'builder', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'builder'},
    {
      '1': 'experiments',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.SynthesizeBuildRequest.ExperimentsEntry',
      '10': 'experiments'
    },
  ],
  '3': [SynthesizeBuildRequest_ExperimentsEntry$json],
};

@$core.Deprecated('Use synthesizeBuildRequestDescriptor instead')
const SynthesizeBuildRequest_ExperimentsEntry$json = {
  '1': 'ExperimentsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 8, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `SynthesizeBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List synthesizeBuildRequestDescriptor =
    $convert.base64Decode('ChZTeW50aGVzaXplQnVpbGRSZXF1ZXN0EioKEXRlbXBsYXRlX2J1aWxkX2lkGAEgASgDUg90ZW'
        '1wbGF0ZUJ1aWxkSWQSMwoHYnVpbGRlchgCIAEoCzIZLmJ1aWxkYnVja2V0LnYyLkJ1aWxkZXJJ'
        'RFIHYnVpbGRlchJZCgtleHBlcmltZW50cxgDIAMoCzI3LmJ1aWxkYnVja2V0LnYyLlN5bnRoZX'
        'NpemVCdWlsZFJlcXVlc3QuRXhwZXJpbWVudHNFbnRyeVILZXhwZXJpbWVudHMaPgoQRXhwZXJp'
        'bWVudHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCFIFdmFsdWU6AjgB');

@$core.Deprecated('Use startBuildRequestDescriptor instead')
const StartBuildRequest$json = {
  '1': 'StartBuildRequest',
  '2': [
    {'1': 'request_id', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'requestId'},
    {'1': 'build_id', '3': 2, '4': 1, '5': 3, '8': {}, '10': 'buildId'},
    {'1': 'task_id', '3': 3, '4': 1, '5': 9, '8': {}, '10': 'taskId'},
  ],
};

/// Descriptor for `StartBuildRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startBuildRequestDescriptor =
    $convert.base64Decode('ChFTdGFydEJ1aWxkUmVxdWVzdBIiCgpyZXF1ZXN0X2lkGAEgASgJQgPgQQJSCXJlcXVlc3RJZB'
        'IeCghidWlsZF9pZBgCIAEoA0ID4EECUgdidWlsZElkEhwKB3Rhc2tfaWQYAyABKAlCA+BBAlIG'
        'dGFza0lk');

@$core.Deprecated('Use startBuildResponseDescriptor instead')
const StartBuildResponse$json = {
  '1': 'StartBuildResponse',
  '2': [
    {'1': 'build', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.Build', '10': 'build'},
    {'1': 'update_build_token', '3': 2, '4': 1, '5': 9, '10': 'updateBuildToken'},
  ],
};

/// Descriptor for `StartBuildResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startBuildResponseDescriptor =
    $convert.base64Decode('ChJTdGFydEJ1aWxkUmVzcG9uc2USKwoFYnVpbGQYASABKAsyFS5idWlsZGJ1Y2tldC52Mi5CdW'
        'lsZFIFYnVpbGQSLAoSdXBkYXRlX2J1aWxkX3Rva2VuGAIgASgJUhB1cGRhdGVCdWlsZFRva2Vu');

@$core.Deprecated('Use getBuildStatusRequestDescriptor instead')
const GetBuildStatusRequest$json = {
  '1': 'GetBuildStatusRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'builder', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'builder'},
    {'1': 'build_number', '3': 3, '4': 1, '5': 5, '10': 'buildNumber'},
  ],
};

/// Descriptor for `GetBuildStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getBuildStatusRequestDescriptor =
    $convert.base64Decode('ChVHZXRCdWlsZFN0YXR1c1JlcXVlc3QSDgoCaWQYASABKANSAmlkEjMKB2J1aWxkZXIYAiABKA'
        'syGS5idWlsZGJ1Y2tldC52Mi5CdWlsZGVySURSB2J1aWxkZXISIQoMYnVpbGRfbnVtYmVyGAMg'
        'ASgFUgtidWlsZE51bWJlcg==');

@$core.Deprecated('Use buildMaskDescriptor instead')
const BuildMask$json = {
  '1': 'BuildMask',
  '2': [
    {'1': 'fields', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.FieldMask', '10': 'fields'},
    {'1': 'input_properties', '3': 2, '4': 3, '5': 11, '6': '.structmask.StructMask', '10': 'inputProperties'},
    {'1': 'output_properties', '3': 3, '4': 3, '5': 11, '6': '.structmask.StructMask', '10': 'outputProperties'},
    {'1': 'requested_properties', '3': 4, '4': 3, '5': 11, '6': '.structmask.StructMask', '10': 'requestedProperties'},
    {'1': 'all_fields', '3': 5, '4': 1, '5': 8, '10': 'allFields'},
    {'1': 'step_status', '3': 6, '4': 3, '5': 14, '6': '.buildbucket.v2.Status', '10': 'stepStatus'},
  ],
};

/// Descriptor for `BuildMask`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildMaskDescriptor =
    $convert.base64Decode('CglCdWlsZE1hc2sSMgoGZmllbGRzGAEgASgLMhouZ29vZ2xlLnByb3RvYnVmLkZpZWxkTWFza1'
        'IGZmllbGRzEkEKEGlucHV0X3Byb3BlcnRpZXMYAiADKAsyFi5zdHJ1Y3RtYXNrLlN0cnVjdE1h'
        'c2tSD2lucHV0UHJvcGVydGllcxJDChFvdXRwdXRfcHJvcGVydGllcxgDIAMoCzIWLnN0cnVjdG'
        '1hc2suU3RydWN0TWFza1IQb3V0cHV0UHJvcGVydGllcxJJChRyZXF1ZXN0ZWRfcHJvcGVydGll'
        'cxgEIAMoCzIWLnN0cnVjdG1hc2suU3RydWN0TWFza1ITcmVxdWVzdGVkUHJvcGVydGllcxIdCg'
        'phbGxfZmllbGRzGAUgASgIUglhbGxGaWVsZHMSNwoLc3RlcF9zdGF0dXMYBiADKA4yFi5idWls'
        'ZGJ1Y2tldC52Mi5TdGF0dXNSCnN0ZXBTdGF0dXM=');

@$core.Deprecated('Use buildPredicateDescriptor instead')
const BuildPredicate$json = {
  '1': 'BuildPredicate',
  '2': [
    {'1': 'builder', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '10': 'builder'},
    {'1': 'status', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    {'1': 'gerrit_changes', '3': 3, '4': 3, '5': 11, '6': '.buildbucket.v2.GerritChange', '10': 'gerritChanges'},
    {
      '1': 'output_gitiles_commit',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.GitilesCommit',
      '10': 'outputGitilesCommit'
    },
    {'1': 'created_by', '3': 5, '4': 1, '5': 9, '10': 'createdBy'},
    {'1': 'tags', '3': 6, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'tags'},
    {'1': 'create_time', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.v2.TimeRange', '10': 'createTime'},
    {'1': 'include_experimental', '3': 8, '4': 1, '5': 8, '10': 'includeExperimental'},
    {'1': 'build', '3': 9, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildRange', '10': 'build'},
    {'1': 'canary', '3': 10, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'canary'},
    {'1': 'experiments', '3': 11, '4': 3, '5': 9, '10': 'experiments'},
    {'1': 'descendant_of', '3': 12, '4': 1, '5': 3, '10': 'descendantOf'},
    {'1': 'child_of', '3': 13, '4': 1, '5': 3, '10': 'childOf'},
  ],
};

/// Descriptor for `BuildPredicate`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildPredicateDescriptor =
    $convert.base64Decode('Cg5CdWlsZFByZWRpY2F0ZRIzCgdidWlsZGVyGAEgASgLMhkuYnVpbGRidWNrZXQudjIuQnVpbG'
        'RlcklEUgdidWlsZGVyEi4KBnN0YXR1cxgCIAEoDjIWLmJ1aWxkYnVja2V0LnYyLlN0YXR1c1IG'
        'c3RhdHVzEkMKDmdlcnJpdF9jaGFuZ2VzGAMgAygLMhwuYnVpbGRidWNrZXQudjIuR2Vycml0Q2'
        'hhbmdlUg1nZXJyaXRDaGFuZ2VzElEKFW91dHB1dF9naXRpbGVzX2NvbW1pdBgEIAEoCzIdLmJ1'
        'aWxkYnVja2V0LnYyLkdpdGlsZXNDb21taXRSE291dHB1dEdpdGlsZXNDb21taXQSHQoKY3JlYX'
        'RlZF9ieRgFIAEoCVIJY3JlYXRlZEJ5Ei4KBHRhZ3MYBiADKAsyGi5idWlsZGJ1Y2tldC52Mi5T'
        'dHJpbmdQYWlyUgR0YWdzEjoKC2NyZWF0ZV90aW1lGAcgASgLMhkuYnVpbGRidWNrZXQudjIuVG'
        'ltZVJhbmdlUgpjcmVhdGVUaW1lEjEKFGluY2x1ZGVfZXhwZXJpbWVudGFsGAggASgIUhNpbmNs'
        'dWRlRXhwZXJpbWVudGFsEjAKBWJ1aWxkGAkgASgLMhouYnVpbGRidWNrZXQudjIuQnVpbGRSYW'
        '5nZVIFYnVpbGQSLwoGY2FuYXJ5GAogASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVIGY2Fu'
        'YXJ5EiAKC2V4cGVyaW1lbnRzGAsgAygJUgtleHBlcmltZW50cxIjCg1kZXNjZW5kYW50X29mGA'
        'wgASgDUgxkZXNjZW5kYW50T2YSGQoIY2hpbGRfb2YYDSABKANSB2NoaWxkT2Y=');

@$core.Deprecated('Use buildRangeDescriptor instead')
const BuildRange$json = {
  '1': 'BuildRange',
  '2': [
    {'1': 'start_build_id', '3': 1, '4': 1, '5': 3, '10': 'startBuildId'},
    {'1': 'end_build_id', '3': 2, '4': 1, '5': 3, '10': 'endBuildId'},
  ],
};

/// Descriptor for `BuildRange`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildRangeDescriptor =
    $convert.base64Decode('CgpCdWlsZFJhbmdlEiQKDnN0YXJ0X2J1aWxkX2lkGAEgASgDUgxzdGFydEJ1aWxkSWQSIAoMZW'
        '5kX2J1aWxkX2lkGAIgASgDUgplbmRCdWlsZElk');
