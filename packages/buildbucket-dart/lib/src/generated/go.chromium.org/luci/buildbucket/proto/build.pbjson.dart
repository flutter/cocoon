//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use buildDescriptor instead')
const Build$json = {
  '1': 'Build',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '8': {}, '10': 'id'},
    {'1': 'builder', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '8': {}, '10': 'builder'},
    {
      '1': 'builder_info',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.Build.BuilderInfo',
      '8': {},
      '10': 'builderInfo'
    },
    {'1': 'number', '3': 3, '4': 1, '5': 5, '8': {}, '10': 'number'},
    {'1': 'created_by', '3': 4, '4': 1, '5': 9, '8': {}, '10': 'createdBy'},
    {'1': 'canceled_by', '3': 23, '4': 1, '5': 9, '8': {}, '10': 'canceledBy'},
    {'1': 'create_time', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'createTime'},
    {'1': 'start_time', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'startTime'},
    {'1': 'end_time', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'endTime'},
    {'1': 'update_time', '3': 9, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'updateTime'},
    {'1': 'cancel_time', '3': 32, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': {}, '10': 'cancelTime'},
    {'1': 'status', '3': 12, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '8': {}, '10': 'status'},
    {'1': 'summary_markdown', '3': 20, '4': 1, '5': 9, '8': {}, '10': 'summaryMarkdown'},
    {'1': 'cancellation_markdown', '3': 33, '4': 1, '5': 9, '8': {}, '10': 'cancellationMarkdown'},
    {'1': 'critical', '3': 21, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '8': {}, '10': 'critical'},
    {
      '1': 'status_details',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.StatusDetails',
      '8': {},
      '10': 'statusDetails'
    },
    {'1': 'input', '3': 15, '4': 1, '5': 11, '6': '.buildbucket.v2.Build.Input', '8': {}, '10': 'input'},
    {'1': 'output', '3': 16, '4': 1, '5': 11, '6': '.buildbucket.v2.Build.Output', '8': {}, '10': 'output'},
    {'1': 'steps', '3': 17, '4': 3, '5': 11, '6': '.buildbucket.v2.Step', '8': {}, '10': 'steps'},
    {'1': 'infra', '3': 18, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra', '8': {}, '10': 'infra'},
    {'1': 'tags', '3': 19, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'tags'},
    {'1': 'exe', '3': 24, '4': 1, '5': 11, '6': '.buildbucket.v2.Executable', '8': {}, '10': 'exe'},
    {'1': 'canary', '3': 25, '4': 1, '5': 8, '10': 'canary'},
    {'1': 'scheduling_timeout', '3': 26, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'schedulingTimeout'},
    {'1': 'execution_timeout', '3': 27, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'executionTimeout'},
    {'1': 'grace_period', '3': 29, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'gracePeriod'},
    {'1': 'wait_for_capacity', '3': 28, '4': 1, '5': 8, '10': 'waitForCapacity'},
    {'1': 'can_outlive_parent', '3': 30, '4': 1, '5': 8, '8': {}, '10': 'canOutliveParent'},
    {'1': 'ancestor_ids', '3': 31, '4': 3, '5': 3, '8': {}, '10': 'ancestorIds'},
    {'1': 'retriable', '3': 35, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'retriable'},
  ],
  '3': [Build_Input$json, Build_Output$json, Build_BuilderInfo$json],
  '9': [
    {'1': 5, '2': 6},
    {'1': 13, '2': 14},
    {'1': 14, '2': 15},
  ],
};

@$core.Deprecated('Use buildDescriptor instead')
const Build_Input$json = {
  '1': 'Input',
  '2': [
    {'1': 'properties', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'properties'},
    {
      '1': 'gitiles_commit',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.GitilesCommit',
      '8': {},
      '10': 'gitilesCommit'
    },
    {
      '1': 'gerrit_changes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.GerritChange',
      '8': {},
      '10': 'gerritChanges'
    },
    {'1': 'experimental', '3': 5, '4': 1, '5': 8, '10': 'experimental'},
    {'1': 'experiments', '3': 6, '4': 3, '5': 9, '10': 'experiments'},
  ],
};

@$core.Deprecated('Use buildDescriptor instead')
const Build_Output$json = {
  '1': 'Output',
  '2': [
    {'1': 'properties', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'properties'},
    {'1': 'gitiles_commit', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.GitilesCommit', '10': 'gitilesCommit'},
    {'1': 'logs', '3': 5, '4': 3, '5': 11, '6': '.buildbucket.v2.Log', '10': 'logs'},
    {'1': 'status', '3': 6, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    {'1': 'status_details', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    {
      '1': 'summary_html',
      '3': 8,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'summaryHtml',
    },
    {'1': 'summary_markdown', '3': 2, '4': 1, '5': 9, '10': 'summaryMarkdown'},
  ],
  '9': [
    {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use buildDescriptor instead')
const Build_BuilderInfo$json = {
  '1': 'BuilderInfo',
  '2': [
    {'1': 'description', '3': 1, '4': 1, '5': 9, '10': 'description'},
  ],
};

/// Descriptor for `Build`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildDescriptor =
    $convert.base64Decode('CgVCdWlsZBIYCgJpZBgBIAEoA0II4EEDuM68AwNSAmlkEkAKB2J1aWxkZXIYAiABKAsyGS5idW'
        'lsZGJ1Y2tldC52Mi5CdWlsZGVySURCC4rDGgIIArjOvAMCUgdidWlsZGVyEkkKDGJ1aWxkZXJf'
        'aW5mbxgiIAEoCzIhLmJ1aWxkYnVja2V0LnYyLkJ1aWxkLkJ1aWxkZXJJbmZvQgPgQQNSC2J1aW'
        'xkZXJJbmZvEiAKBm51bWJlchgDIAEoBUII4EEDuM68AwJSBm51bWJlchIiCgpjcmVhdGVkX2J5'
        'GAQgASgJQgPgQQNSCWNyZWF0ZWRCeRIkCgtjYW5jZWxlZF9ieRgXIAEoCUID4EEDUgpjYW5jZW'
        'xlZEJ5EkUKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEII'
        '4EEDuM68AwJSCmNyZWF0ZVRpbWUSQwoKc3RhcnRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2'
        'J1Zi5UaW1lc3RhbXBCCOBBA7jOvAMCUglzdGFydFRpbWUSPwoIZW5kX3RpbWUYCCABKAsyGi5n'
        'b29nbGUucHJvdG9idWYuVGltZXN0YW1wQgjgQQO4zrwDAlIHZW5kVGltZRJFCgt1cGRhdGVfdG'
        'ltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCCOBBA7jOvAMCUgp1cGRhdGVU'
        'aW1lEkUKC2NhbmNlbF90aW1lGCAgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEII4E'
        'EDuM68AwJSCmNhbmNlbFRpbWUSOwoGc3RhdHVzGAwgASgOMhYuYnVpbGRidWNrZXQudjIuU3Rh'
        'dHVzQguKwxoCCAO4zrwDA1IGc3RhdHVzEjEKEHN1bW1hcnlfbWFya2Rvd24YFCABKAlCBorDGg'
        'IIA1IPc3VtbWFyeU1hcmtkb3duEjsKFWNhbmNlbGxhdGlvbl9tYXJrZG93bhghIAEoCUIGisMa'
        'AggDUhRjYW5jZWxsYXRpb25NYXJrZG93bhI6Cghjcml0aWNhbBgVIAEoDjIXLmJ1aWxkYnVja2'
        'V0LnYyLlRyaW5hcnlCBbjOvAMCUghjcml0aWNhbBJRCg5zdGF0dXNfZGV0YWlscxgWIAEoCzId'
        'LmJ1aWxkYnVja2V0LnYyLlN0YXR1c0RldGFpbHNCC4rDGgIIA7jOvAMDUg1zdGF0dXNEZXRhaW'
        'xzEjkKBWlucHV0GA8gASgLMhsuYnVpbGRidWNrZXQudjIuQnVpbGQuSW5wdXRCBorDGgIIAlIF'
        'aW5wdXQSPAoGb3V0cHV0GBAgASgLMhwuYnVpbGRidWNrZXQudjIuQnVpbGQuT3V0cHV0QgaKwx'
        'oCCANSBm91dHB1dBIyCgVzdGVwcxgRIAMoCzIULmJ1aWxkYnVja2V0LnYyLlN0ZXBCBorDGgII'
        'A1IFc3RlcHMSOAoFaW5mcmEYEiABKAsyGi5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhQgaKwx'
        'oCCAJSBWluZnJhEi4KBHRhZ3MYEyADKAsyGi5idWlsZGJ1Y2tldC52Mi5TdHJpbmdQYWlyUgR0'
        'YWdzEjQKA2V4ZRgYIAEoCzIaLmJ1aWxkYnVja2V0LnYyLkV4ZWN1dGFibGVCBorDGgIIAlIDZX'
        'hlEhYKBmNhbmFyeRgZIAEoCFIGY2FuYXJ5EkgKEnNjaGVkdWxpbmdfdGltZW91dBgaIAEoCzIZ'
        'Lmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIRc2NoZWR1bGluZ1RpbWVvdXQSRgoRZXhlY3V0aW'
        '9uX3RpbWVvdXQYGyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SEGV4ZWN1dGlvblRp'
        'bWVvdXQSPAoMZ3JhY2VfcGVyaW9kGB0gASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg'
        'tncmFjZVBlcmlvZBIqChF3YWl0X2Zvcl9jYXBhY2l0eRgcIAEoCFIPd2FpdEZvckNhcGFjaXR5'
        'EjMKEmNhbl9vdXRsaXZlX3BhcmVudBgeIAEoCEIFuM68AwNSEGNhbk91dGxpdmVQYXJlbnQSKw'
        'oMYW5jZXN0b3JfaWRzGB8gAygDQgjgQQO4zrwDA1ILYW5jZXN0b3JJZHMSNQoJcmV0cmlhYmxl'
        'GCMgASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeVIJcmV0cmlhYmxlGp8CCgVJbnB1dBI3Cg'
        'pwcm9wZXJ0aWVzGAEgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIKcHJvcGVydGllcxJL'
        'Cg5naXRpbGVzX2NvbW1pdBgCIAEoCzIdLmJ1aWxkYnVja2V0LnYyLkdpdGlsZXNDb21taXRCBb'
        'jOvAMCUg1naXRpbGVzQ29tbWl0EkoKDmdlcnJpdF9jaGFuZ2VzGAMgAygLMhwuYnVpbGRidWNr'
        'ZXQudjIuR2Vycml0Q2hhbmdlQgW4zrwDAlINZ2Vycml0Q2hhbmdlcxIiCgxleHBlcmltZW50YW'
        'wYBSABKAhSDGV4cGVyaW1lbnRhbBIgCgtleHBlcmltZW50cxgGIAMoCVILZXhwZXJpbWVudHMa'
        '/gIKBk91dHB1dBI3Cgpwcm9wZXJ0aWVzGAEgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdF'
        'IKcHJvcGVydGllcxJECg5naXRpbGVzX2NvbW1pdBgDIAEoCzIdLmJ1aWxkYnVja2V0LnYyLkdp'
        'dGlsZXNDb21taXRSDWdpdGlsZXNDb21taXQSJwoEbG9ncxgFIAMoCzITLmJ1aWxkYnVja2V0Ln'
        'YyLkxvZ1IEbG9ncxIuCgZzdGF0dXMYBiABKA4yFi5idWlsZGJ1Y2tldC52Mi5TdGF0dXNSBnN0'
        'YXR1cxJECg5zdGF0dXNfZGV0YWlscxgHIAEoCzIdLmJ1aWxkYnVja2V0LnYyLlN0YXR1c0RldG'
        'FpbHNSDXN0YXR1c0RldGFpbHMSJQoMc3VtbWFyeV9odG1sGAggASgJQgIYAVILc3VtbWFyeUh0'
        'bWwSKQoQc3VtbWFyeV9tYXJrZG93bhgCIAEoCVIPc3VtbWFyeU1hcmtkb3duSgQIBBAFGi8KC0'
        'J1aWxkZXJJbmZvEiAKC2Rlc2NyaXB0aW9uGAEgASgJUgtkZXNjcmlwdGlvbkoECAUQBkoECA0Q'
        'DkoECA4QDw==');

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef$json = {
  '1': 'InputDataRef',
  '2': [
    {'1': 'cas', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CAS', '9': 0, '10': 'cas'},
    {'1': 'cipd', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CIPD', '9': 0, '10': 'cipd'},
    {'1': 'on_path', '3': 3, '4': 3, '5': 9, '10': 'onPath'},
  ],
  '3': [InputDataRef_CAS$json, InputDataRef_CIPD$json],
  '8': [
    {'1': 'data_type'},
  ],
  '9': [
    {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CAS$json = {
  '1': 'CAS',
  '2': [
    {'1': 'cas_instance', '3': 1, '4': 1, '5': 9, '10': 'casInstance'},
    {'1': 'digest', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CAS.Digest', '10': 'digest'},
  ],
  '3': [InputDataRef_CAS_Digest$json],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CAS_Digest$json = {
  '1': 'Digest',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CIPD$json = {
  '1': 'CIPD',
  '2': [
    {'1': 'server', '3': 1, '4': 1, '5': 9, '10': 'server'},
    {'1': 'specs', '3': 2, '4': 3, '5': 11, '6': '.buildbucket.v2.InputDataRef.CIPD.PkgSpec', '10': 'specs'},
  ],
  '3': [InputDataRef_CIPD_PkgSpec$json],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CIPD_PkgSpec$json = {
  '1': 'PkgSpec',
  '2': [
    {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `InputDataRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputDataRefDescriptor =
    $convert.base64Decode('CgxJbnB1dERhdGFSZWYSNAoDY2FzGAEgASgLMiAuYnVpbGRidWNrZXQudjIuSW5wdXREYXRhUm'
        'VmLkNBU0gAUgNjYXMSNwoEY2lwZBgCIAEoCzIhLmJ1aWxkYnVja2V0LnYyLklucHV0RGF0YVJl'
        'Zi5DSVBESABSBGNpcGQSFwoHb25fcGF0aBgDIAMoCVIGb25QYXRoGqYBCgNDQVMSIQoMY2FzX2'
        'luc3RhbmNlGAEgASgJUgtjYXNJbnN0YW5jZRI/CgZkaWdlc3QYAiABKAsyJy5idWlsZGJ1Y2tl'
        'dC52Mi5JbnB1dERhdGFSZWYuQ0FTLkRpZ2VzdFIGZGlnZXN0GjsKBkRpZ2VzdBISCgRoYXNoGA'
        'EgASgJUgRoYXNoEh0KCnNpemVfYnl0ZXMYAiABKANSCXNpemVCeXRlcxqeAQoEQ0lQRBIWCgZz'
        'ZXJ2ZXIYASABKAlSBnNlcnZlchI/CgVzcGVjcxgCIAMoCzIpLmJ1aWxkYnVja2V0LnYyLklucH'
        'V0RGF0YVJlZi5DSVBELlBrZ1NwZWNSBXNwZWNzGj0KB1BrZ1NwZWMSGAoHcGFja2FnZRgBIAEo'
        'CVIHcGFja2FnZRIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uQgsKCWRhdGFfdHlwZUoECAQQBQ'
        '==');

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef$json = {
  '1': 'ResolvedDataRef',
  '2': [
    {'1': 'cas', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CAS', '9': 0, '10': 'cas'},
    {'1': 'cipd', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CIPD', '9': 0, '10': 'cipd'},
  ],
  '3': [ResolvedDataRef_Timing$json, ResolvedDataRef_CAS$json, ResolvedDataRef_CIPD$json],
  '8': [
    {'1': 'data_type'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_Timing$json = {
  '1': 'Timing',
  '2': [
    {'1': 'fetch_duration', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'fetchDuration'},
    {'1': 'install_duration', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'installDuration'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CAS$json = {
  '1': 'CAS',
  '2': [
    {'1': 'timing', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.Timing', '10': 'timing'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CIPD$json = {
  '1': 'CIPD',
  '2': [
    {'1': 'specs', '3': 2, '4': 3, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CIPD.PkgSpec', '10': 'specs'},
  ],
  '3': [ResolvedDataRef_CIPD_PkgSpec$json],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CIPD_PkgSpec$json = {
  '1': 'PkgSpec',
  '2': [
    {'1': 'skipped', '3': 1, '4': 1, '5': 8, '10': 'skipped'},
    {'1': 'package', '3': 2, '4': 1, '5': 9, '10': 'package'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    {'1': 'was_cached', '3': 4, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'wasCached'},
    {'1': 'timing', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.Timing', '10': 'timing'},
  ],
};

/// Descriptor for `ResolvedDataRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolvedDataRefDescriptor =
    $convert.base64Decode('Cg9SZXNvbHZlZERhdGFSZWYSNwoDY2FzGAEgASgLMiMuYnVpbGRidWNrZXQudjIuUmVzb2x2ZW'
        'REYXRhUmVmLkNBU0gAUgNjYXMSOgoEY2lwZBgCIAEoCzIkLmJ1aWxkYnVja2V0LnYyLlJlc29s'
        'dmVkRGF0YVJlZi5DSVBESABSBGNpcGQakAEKBlRpbWluZxJACg5mZXRjaF9kdXJhdGlvbhgBIA'
        'EoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINZmV0Y2hEdXJhdGlvbhJEChBpbnN0YWxs'
        'X2R1cmF0aW9uGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg9pbnN0YWxsRHVyYX'
        'Rpb24aRQoDQ0FTEj4KBnRpbWluZxgBIAEoCzImLmJ1aWxkYnVja2V0LnYyLlJlc29sdmVkRGF0'
        'YVJlZi5UaW1pbmdSBnRpbWluZxqcAgoEQ0lQRBJCCgVzcGVjcxgCIAMoCzIsLmJ1aWxkYnVja2'
        'V0LnYyLlJlc29sdmVkRGF0YVJlZi5DSVBELlBrZ1NwZWNSBXNwZWNzGs8BCgdQa2dTcGVjEhgK'
        'B3NraXBwZWQYASABKAhSB3NraXBwZWQSGAoHcGFja2FnZRgCIAEoCVIHcGFja2FnZRIYCgd2ZX'
        'JzaW9uGAMgASgJUgd2ZXJzaW9uEjYKCndhc19jYWNoZWQYBCABKA4yFy5idWlsZGJ1Y2tldC52'
        'Mi5UcmluYXJ5Ugl3YXNDYWNoZWQSPgoGdGltaW5nGAUgASgLMiYuYnVpbGRidWNrZXQudjIuUm'
        'Vzb2x2ZWREYXRhUmVmLlRpbWluZ1IGdGltaW5nQgsKCWRhdGFfdHlwZQ==');

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra$json = {
  '1': 'BuildInfra',
  '2': [
    {
      '1': 'buildbucket',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket',
      '8': {},
      '10': 'buildbucket'
    },
    {'1': 'swarming', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Swarming', '10': 'swarming'},
    {'1': 'logdog', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.LogDog', '8': {}, '10': 'logdog'},
    {'1': 'recipe', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Recipe', '10': 'recipe'},
    {'1': 'resultdb', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.ResultDB', '8': {}, '10': 'resultdb'},
    {'1': 'bbagent', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.BBAgent', '10': 'bbagent'},
    {'1': 'backend', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Backend', '10': 'backend'},
    {'1': 'led', '3': 8, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Led', '10': 'led'},
  ],
  '3': [
    BuildInfra_Buildbucket$json,
    BuildInfra_Swarming$json,
    BuildInfra_LogDog$json,
    BuildInfra_Recipe$json,
    BuildInfra_ResultDB$json,
    BuildInfra_Led$json,
    BuildInfra_BBAgent$json,
    BuildInfra_Backend$json
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket$json = {
  '1': 'Buildbucket',
  '2': [
    {'1': 'service_config_revision', '3': 2, '4': 1, '5': 9, '10': 'serviceConfigRevision'},
    {'1': 'requested_properties', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'requestedProperties'},
    {
      '1': 'requested_dimensions',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.RequestedDimension',
      '10': 'requestedDimensions'
    },
    {'1': 'hostname', '3': 7, '4': 1, '5': 9, '10': 'hostname'},
    {
      '1': 'experiment_reasons',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.ExperimentReasonsEntry',
      '10': 'experimentReasons'
    },
    {
      '1': 'agent_executable',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.AgentExecutableEntry',
      '8': {'3': true},
      '10': 'agentExecutable',
    },
    {
      '1': 'agent',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent',
      '8': {},
      '10': 'agent'
    },
    {'1': 'known_public_gerrit_hosts', '3': 11, '4': 3, '5': 9, '10': 'knownPublicGerritHosts'},
    {'1': 'build_number', '3': 12, '4': 1, '5': 8, '10': 'buildNumber'},
  ],
  '3': [
    BuildInfra_Buildbucket_Agent$json,
    BuildInfra_Buildbucket_ExperimentReasonsEntry$json,
    BuildInfra_Buildbucket_AgentExecutableEntry$json
  ],
  '4': [BuildInfra_Buildbucket_ExperimentReason$json],
  '9': [
    {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent$json = {
  '1': 'Agent',
  '2': [
    {
      '1': 'input',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Input',
      '8': {},
      '10': 'input'
    },
    {
      '1': 'output',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Output',
      '8': {},
      '10': 'output'
    },
    {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source',
      '8': {},
      '10': 'source'
    },
    {
      '1': 'purposes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.PurposesEntry',
      '10': 'purposes'
    },
    {'1': 'cipd_client_cache', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.v2.CacheEntry', '10': 'cipdClientCache'},
    {'1': 'cipd_packages_cache', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.v2.CacheEntry', '10': 'cipdPackagesCache'},
  ],
  '3': [
    BuildInfra_Buildbucket_Agent_Source$json,
    BuildInfra_Buildbucket_Agent_Input$json,
    BuildInfra_Buildbucket_Agent_Output$json,
    BuildInfra_Buildbucket_Agent_PurposesEntry$json
  ],
  '4': [BuildInfra_Buildbucket_Agent_Purpose$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source$json = {
  '1': 'Source',
  '2': [
    {
      '1': 'cipd',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source.CIPD',
      '9': 0,
      '10': 'cipd'
    },
  ],
  '3': [BuildInfra_Buildbucket_Agent_Source_CIPD$json],
  '8': [
    {'1': 'data_type'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source_CIPD$json = {
  '1': 'CIPD',
  '2': [
    {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'server', '3': 3, '4': 1, '5': 9, '10': 'server'},
    {
      '1': 'resolved_instances',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source.CIPD.ResolvedInstancesEntry',
      '8': {},
      '10': 'resolvedInstances'
    },
  ],
  '3': [BuildInfra_Buildbucket_Agent_Source_CIPD_ResolvedInstancesEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source_CIPD_ResolvedInstancesEntry$json = {
  '1': 'ResolvedInstancesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Input$json = {
  '1': 'Input',
  '2': [
    {
      '1': 'data',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Input.DataEntry',
      '10': 'data'
    },
    {
      '1': 'cipd_source',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Input.CipdSourceEntry',
      '10': 'cipdSource'
    },
  ],
  '3': [BuildInfra_Buildbucket_Agent_Input_DataEntry$json, BuildInfra_Buildbucket_Agent_Input_CipdSourceEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Input_DataEntry$json = {
  '1': 'DataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Input_CipdSourceEntry$json = {
  '1': 'CipdSourceEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Output$json = {
  '1': 'Output',
  '2': [
    {
      '1': 'resolved_data',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Output.ResolvedDataEntry',
      '10': 'resolvedData'
    },
    {'1': 'status', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    {'1': 'status_details', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    {
      '1': 'summary_html',
      '3': 4,
      '4': 1,
      '5': 9,
      '8': {'3': true},
      '10': 'summaryHtml',
    },
    {'1': 'agent_platform', '3': 5, '4': 1, '5': 9, '10': 'agentPlatform'},
    {'1': 'total_duration', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'totalDuration'},
    {'1': 'summary_markdown', '3': 7, '4': 1, '5': 9, '10': 'summaryMarkdown'},
  ],
  '3': [BuildInfra_Buildbucket_Agent_Output_ResolvedDataEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Output_ResolvedDataEntry$json = {
  '1': 'ResolvedDataEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_PurposesEntry$json = {
  '1': 'PurposesEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Purpose', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Purpose$json = {
  '1': 'Purpose',
  '2': [
    {'1': 'PURPOSE_UNSPECIFIED', '2': 0},
    {'1': 'PURPOSE_EXE_PAYLOAD', '2': 1},
    {'1': 'PURPOSE_BBAGENT_UTILITY', '2': 2},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_ExperimentReasonsEntry$json = {
  '1': 'ExperimentReasonsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.ExperimentReason',
      '10': 'value'
    },
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_AgentExecutableEntry$json = {
  '1': 'AgentExecutableEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef', '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_ExperimentReason$json = {
  '1': 'ExperimentReason',
  '2': [
    {'1': 'EXPERIMENT_REASON_UNSET', '2': 0},
    {'1': 'EXPERIMENT_REASON_GLOBAL_DEFAULT', '2': 1},
    {'1': 'EXPERIMENT_REASON_BUILDER_CONFIG', '2': 2},
    {'1': 'EXPERIMENT_REASON_GLOBAL_MINIMUM', '2': 3},
    {'1': 'EXPERIMENT_REASON_REQUESTED', '2': 4},
    {'1': 'EXPERIMENT_REASON_GLOBAL_INACTIVE', '2': 5},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Swarming$json = {
  '1': 'Swarming',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'hostname'},
    {'1': 'task_id', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'taskId'},
    {'1': 'parent_run_id', '3': 9, '4': 1, '5': 9, '10': 'parentRunId'},
    {'1': 'task_service_account', '3': 3, '4': 1, '5': 9, '10': 'taskServiceAccount'},
    {'1': 'priority', '3': 4, '4': 1, '5': 5, '10': 'priority'},
    {
      '1': 'task_dimensions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.RequestedDimension',
      '10': 'taskDimensions'
    },
    {'1': 'bot_dimensions', '3': 6, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'botDimensions'},
    {'1': 'caches', '3': 7, '4': 3, '5': 11, '6': '.buildbucket.v2.BuildInfra.Swarming.CacheEntry', '10': 'caches'},
  ],
  '3': [BuildInfra_Swarming_CacheEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Swarming_CacheEntry$json = {
  '1': 'CacheEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'wait_for_warm_cache', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'waitForWarmCache'},
    {'1': 'env_var', '3': 4, '4': 1, '5': 9, '10': 'envVar'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_LogDog$json = {
  '1': 'LogDog',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'hostname'},
    {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    {'1': 'prefix', '3': 3, '4': 1, '5': 9, '10': 'prefix'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Recipe$json = {
  '1': 'Recipe',
  '2': [
    {'1': 'cipd_package', '3': 1, '4': 1, '5': 9, '10': 'cipdPackage'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_ResultDB$json = {
  '1': 'ResultDB',
  '2': [
    {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': {}, '10': 'hostname'},
    {'1': 'invocation', '3': 2, '4': 1, '5': 9, '8': {}, '10': 'invocation'},
    {'1': 'enable', '3': 3, '4': 1, '5': 8, '10': 'enable'},
    {'1': 'bq_exports', '3': 4, '4': 3, '5': 11, '6': '.luci.resultdb.v1.BigQueryExport', '10': 'bqExports'},
    {'1': 'history_options', '3': 5, '4': 1, '5': 11, '6': '.luci.resultdb.v1.HistoryOptions', '10': 'historyOptions'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Led$json = {
  '1': 'Led',
  '2': [
    {'1': 'shadowed_bucket', '3': 1, '4': 1, '5': 9, '10': 'shadowedBucket'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent$json = {
  '1': 'BBAgent',
  '2': [
    {'1': 'payload_path', '3': 1, '4': 1, '5': 9, '10': 'payloadPath'},
    {'1': 'cache_dir', '3': 2, '4': 1, '5': 9, '10': 'cacheDir'},
    {
      '1': 'known_public_gerrit_hosts',
      '3': 3,
      '4': 3,
      '5': 9,
      '8': {'3': true},
      '10': 'knownPublicGerritHosts',
    },
    {
      '1': 'input',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.BBAgent.Input',
      '8': {'3': true},
      '10': 'input',
    },
  ],
  '3': [BuildInfra_BBAgent_Input$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent_Input$json = {
  '1': 'Input',
  '2': [
    {
      '1': 'cipd_packages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.BBAgent.Input.CIPDPackage',
      '10': 'cipdPackages'
    },
  ],
  '3': [BuildInfra_BBAgent_Input_CIPDPackage$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent_Input_CIPDPackage$json = {
  '1': 'CIPDPackage',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    {'1': 'server', '3': 3, '4': 1, '5': 9, '10': 'server'},
    {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Backend$json = {
  '1': 'Backend',
  '2': [
    {'1': 'config', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'config'},
    {'1': 'task', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.Task', '10': 'task'},
    {'1': 'caches', '3': 3, '4': 3, '5': 11, '6': '.buildbucket.v2.CacheEntry', '10': 'caches'},
    {
      '1': 'task_dimensions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.RequestedDimension',
      '10': 'taskDimensions'
    },
    {'1': 'hostname', '3': 6, '4': 1, '5': 9, '10': 'hostname'},
  ],
};

/// Descriptor for `BuildInfra`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildInfraDescriptor =
    $convert.base64Decode('CgpCdWlsZEluZnJhElAKC2J1aWxkYnVja2V0GAEgASgLMiYuYnVpbGRidWNrZXQudjIuQnVpbG'
        'RJbmZyYS5CdWlsZGJ1Y2tldEIGisMaAggCUgtidWlsZGJ1Y2tldBI/Cghzd2FybWluZxgCIAEo'
        'CzIjLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuU3dhcm1pbmdSCHN3YXJtaW5nEkEKBmxvZ2'
        'RvZxgDIAEoCzIhLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuTG9nRG9nQgaKwxoCCAJSBmxv'
        'Z2RvZxI5CgZyZWNpcGUYBCABKAsyIS5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLlJlY2lwZV'
        'IGcmVjaXBlEkYKCHJlc3VsdGRiGAUgASgLMiMuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5S'
        'ZXN1bHREQkIFuM68AwJSCHJlc3VsdGRiEjwKB2JiYWdlbnQYBiABKAsyIi5idWlsZGJ1Y2tldC'
        '52Mi5CdWlsZEluZnJhLkJCQWdlbnRSB2JiYWdlbnQSPAoHYmFja2VuZBgHIAEoCzIiLmJ1aWxk'
        'YnVja2V0LnYyLkJ1aWxkSW5mcmEuQmFja2VuZFIHYmFja2VuZBIwCgNsZWQYCCABKAsyHi5idW'
        'lsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkxlZFIDbGVkGqUYCgtCdWlsZGJ1Y2tldBI2ChdzZXJ2'
        'aWNlX2NvbmZpZ19yZXZpc2lvbhgCIAEoCVIVc2VydmljZUNvbmZpZ1JldmlzaW9uEkoKFHJlcX'
        'Vlc3RlZF9wcm9wZXJ0aWVzGAUgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFITcmVxdWVz'
        'dGVkUHJvcGVydGllcxJVChRyZXF1ZXN0ZWRfZGltZW5zaW9ucxgGIAMoCzIiLmJ1aWxkYnVja2'
        'V0LnYyLlJlcXVlc3RlZERpbWVuc2lvblITcmVxdWVzdGVkRGltZW5zaW9ucxIaCghob3N0bmFt'
        'ZRgHIAEoCVIIaG9zdG5hbWUSbAoSZXhwZXJpbWVudF9yZWFzb25zGAggAygLMj0uYnVpbGRidW'
        'NrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5FeHBlcmltZW50UmVhc29uc0VudHJ5UhFl'
        'eHBlcmltZW50UmVhc29ucxJqChBhZ2VudF9leGVjdXRhYmxlGAkgAygLMjsuYnVpbGRidWNrZX'
        'QudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5BZ2VudEV4ZWN1dGFibGVFbnRyeUICGAFSD2Fn'
        'ZW50RXhlY3V0YWJsZRJKCgVhZ2VudBgKIAEoCzIsLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcm'
        'EuQnVpbGRidWNrZXQuQWdlbnRCBorDGgIIAlIFYWdlbnQSOQoZa25vd25fcHVibGljX2dlcnJp'
        'dF9ob3N0cxgLIAMoCVIWa25vd25QdWJsaWNHZXJyaXRIb3N0cxIhCgxidWlsZF9udW1iZXIYDC'
        'ABKAhSC2J1aWxkTnVtYmVyGsQPCgVBZ2VudBJQCgVpbnB1dBgBIAEoCzIyLmJ1aWxkYnVja2V0'
        'LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuSW5wdXRCBorDGgIIAlIFaW5wdXQSUw'
        'oGb3V0cHV0GAIgASgLMjMuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5B'
        'Z2VudC5PdXRwdXRCBorDGgIIA1IGb3V0cHV0ElMKBnNvdXJjZRgDIAEoCzIzLmJ1aWxkYnVja2'
        'V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuU291cmNlQgaKwxoCCAJSBnNvdXJj'
        'ZRJWCghwdXJwb3NlcxgEIAMoCzI6LmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidW'
        'NrZXQuQWdlbnQuUHVycG9zZXNFbnRyeVIIcHVycG9zZXMSRgoRY2lwZF9jbGllbnRfY2FjaGUY'
        'BSABKAsyGi5idWlsZGJ1Y2tldC52Mi5DYWNoZUVudHJ5Ug9jaXBkQ2xpZW50Q2FjaGUSSgoTY2'
        'lwZF9wYWNrYWdlc19jYWNoZRgGIAEoCzIaLmJ1aWxkYnVja2V0LnYyLkNhY2hlRW50cnlSEWNp'
        'cGRQYWNrYWdlc0NhY2hlGoYDCgZTb3VyY2USTgoEY2lwZBgBIAEoCzI4LmJ1aWxkYnVja2V0Ln'
        'YyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuU291cmNlLkNJUERIAFIEY2lwZBqeAgoE'
        'Q0lQRBIYCgdwYWNrYWdlGAEgASgJUgdwYWNrYWdlEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb2'
        '4SFgoGc2VydmVyGAMgASgJUgZzZXJ2ZXISgwEKEnJlc29sdmVkX2luc3RhbmNlcxgEIAMoCzJP'
        'LmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuU291cmNlLkNJUE'
        'QuUmVzb2x2ZWRJbnN0YW5jZXNFbnRyeUID4EEDUhFyZXNvbHZlZEluc3RhbmNlcxpEChZSZXNv'
        'bHZlZEluc3RhbmNlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YW'
        'x1ZToCOAFCCwoJZGF0YV90eXBlGvICCgVJbnB1dBJQCgRkYXRhGAEgAygLMjwuYnVpbGRidWNr'
        'ZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5BZ2VudC5JbnB1dC5EYXRhRW50cnlSBGRhdG'
        'ESYwoLY2lwZF9zb3VyY2UYAiADKAsyQi5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJ1aWxk'
        'YnVja2V0LkFnZW50LklucHV0LkNpcGRTb3VyY2VFbnRyeVIKY2lwZFNvdXJjZRpVCglEYXRhRW'
        '50cnkSEAoDa2V5GAEgASgJUgNrZXkSMgoFdmFsdWUYAiABKAsyHC5idWlsZGJ1Y2tldC52Mi5J'
        'bnB1dERhdGFSZWZSBXZhbHVlOgI4ARpbCg9DaXBkU291cmNlRW50cnkSEAoDa2V5GAEgASgJUg'
        'NrZXkSMgoFdmFsdWUYAiABKAsyHC5idWlsZGJ1Y2tldC52Mi5JbnB1dERhdGFSZWZSBXZhbHVl'
        'OgI4ARqHBAoGT3V0cHV0EmoKDXJlc29sdmVkX2RhdGEYASADKAsyRS5idWlsZGJ1Y2tldC52Mi'
        '5CdWlsZEluZnJhLkJ1aWxkYnVja2V0LkFnZW50Lk91dHB1dC5SZXNvbHZlZERhdGFFbnRyeVIM'
        'cmVzb2x2ZWREYXRhEi4KBnN0YXR1cxgCIAEoDjIWLmJ1aWxkYnVja2V0LnYyLlN0YXR1c1IGc3'
        'RhdHVzEkQKDnN0YXR1c19kZXRhaWxzGAMgASgLMh0uYnVpbGRidWNrZXQudjIuU3RhdHVzRGV0'
        'YWlsc1INc3RhdHVzRGV0YWlscxIlCgxzdW1tYXJ5X2h0bWwYBCABKAlCAhgBUgtzdW1tYXJ5SH'
        'RtbBIlCg5hZ2VudF9wbGF0Zm9ybRgFIAEoCVINYWdlbnRQbGF0Zm9ybRJACg50b3RhbF9kdXJh'
        'dGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINdG90YWxEdXJhdGlvbhIpCh'
        'BzdW1tYXJ5X21hcmtkb3duGAcgASgJUg9zdW1tYXJ5TWFya2Rvd24aYAoRUmVzb2x2ZWREYXRh'
        'RW50cnkSEAoDa2V5GAEgASgJUgNrZXkSNQoFdmFsdWUYAiABKAsyHy5idWlsZGJ1Y2tldC52Mi'
        '5SZXNvbHZlZERhdGFSZWZSBXZhbHVlOgI4ARpxCg1QdXJwb3Nlc0VudHJ5EhAKA2tleRgBIAEo'
        'CVIDa2V5EkoKBXZhbHVlGAIgASgOMjQuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZG'
        'J1Y2tldC5BZ2VudC5QdXJwb3NlUgV2YWx1ZToCOAEiWAoHUHVycG9zZRIXChNQVVJQT1NFX1VO'
        'U1BFQ0lGSUVEEAASFwoTUFVSUE9TRV9FWEVfUEFZTE9BRBABEhsKF1BVUlBPU0VfQkJBR0VOVF'
        '9VVElMSVRZEAIafQoWRXhwZXJpbWVudFJlYXNvbnNFbnRyeRIQCgNrZXkYASABKAlSA2tleRJN'
        'CgV2YWx1ZRgCIAEoDjI3LmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuRX'
        'hwZXJpbWVudFJlYXNvblIFdmFsdWU6AjgBGmMKFEFnZW50RXhlY3V0YWJsZUVudHJ5EhAKA2tl'
        'eRgBIAEoCVIDa2V5EjUKBXZhbHVlGAIgASgLMh8uYnVpbGRidWNrZXQudjIuUmVzb2x2ZWREYX'
        'RhUmVmUgV2YWx1ZToCOAEi6QEKEEV4cGVyaW1lbnRSZWFzb24SGwoXRVhQRVJJTUVOVF9SRUFT'
        'T05fVU5TRVQQABIkCiBFWFBFUklNRU5UX1JFQVNPTl9HTE9CQUxfREVGQVVMVBABEiQKIEVYUE'
        'VSSU1FTlRfUkVBU09OX0JVSUxERVJfQ09ORklHEAISJAogRVhQRVJJTUVOVF9SRUFTT05fR0xP'
        'QkFMX01JTklNVU0QAxIfChtFWFBFUklNRU5UX1JFQVNPTl9SRVFVRVNURUQQBBIlCiFFWFBFUk'
        'lNRU5UX1JFQVNPTl9HTE9CQUxfSU5BQ1RJVkUQBUoECAQQBRqwBAoIU3dhcm1pbmcSIgoIaG9z'
        'dG5hbWUYASABKAlCBorDGgIIAlIIaG9zdG5hbWUSHAoHdGFza19pZBgCIAEoCUID4EEDUgZ0YX'
        'NrSWQSIgoNcGFyZW50X3J1bl9pZBgJIAEoCVILcGFyZW50UnVuSWQSMAoUdGFza19zZXJ2aWNl'
        'X2FjY291bnQYAyABKAlSEnRhc2tTZXJ2aWNlQWNjb3VudBIaCghwcmlvcml0eRgEIAEoBVIIcH'
        'Jpb3JpdHkSSwoPdGFza19kaW1lbnNpb25zGAUgAygLMiIuYnVpbGRidWNrZXQudjIuUmVxdWVz'
        'dGVkRGltZW5zaW9uUg50YXNrRGltZW5zaW9ucxJBCg5ib3RfZGltZW5zaW9ucxgGIAMoCzIaLm'
        'J1aWxkYnVja2V0LnYyLlN0cmluZ1BhaXJSDWJvdERpbWVuc2lvbnMSRgoGY2FjaGVzGAcgAygL'
        'Mi4uYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5Td2FybWluZy5DYWNoZUVudHJ5UgZjYWNoZX'
        'MalwEKCkNhY2hlRW50cnkSEgoEbmFtZRgBIAEoCVIEbmFtZRISCgRwYXRoGAIgASgJUgRwYXRo'
        'EkgKE3dhaXRfZm9yX3dhcm1fY2FjaGUYAyABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb2'
        '5SEHdhaXRGb3JXYXJtQ2FjaGUSFwoHZW52X3ZhchgEIAEoCVIGZW52VmFyGl4KBkxvZ0RvZxIi'
        'Cghob3N0bmFtZRgBIAEoCUIGisMaAggCUghob3N0bmFtZRIYCgdwcm9qZWN0GAIgASgJUgdwcm'
        '9qZWN0EhYKBnByZWZpeBgDIAEoCVIGcHJlZml4Gj8KBlJlY2lwZRIhCgxjaXBkX3BhY2thZ2UY'
        'ASABKAlSC2NpcGRQYWNrYWdlEhIKBG5hbWUYAiABKAlSBG5hbWUa9wEKCFJlc3VsdERCEiIKCG'
        'hvc3RuYW1lGAEgASgJQgaKwxoCCAJSCGhvc3RuYW1lEiMKCmludm9jYXRpb24YAiABKAlCA+BB'
        'A1IKaW52b2NhdGlvbhIWCgZlbmFibGUYAyABKAhSBmVuYWJsZRI/CgpicV9leHBvcnRzGAQgAy'
        'gLMiAubHVjaS5yZXN1bHRkYi52MS5CaWdRdWVyeUV4cG9ydFIJYnFFeHBvcnRzEkkKD2hpc3Rv'
        'cnlfb3B0aW9ucxgFIAEoCzIgLmx1Y2kucmVzdWx0ZGIudjEuSGlzdG9yeU9wdGlvbnNSDmhpc3'
        'RvcnlPcHRpb25zGi4KA0xlZBInCg9zaGFkb3dlZF9idWNrZXQYASABKAlSDnNoYWRvd2VkQnVj'
        'a2V0GpoDCgdCQkFnZW50EiEKDHBheWxvYWRfcGF0aBgBIAEoCVILcGF5bG9hZFBhdGgSGwoJY2'
        'FjaGVfZGlyGAIgASgJUghjYWNoZURpchI9Chlrbm93bl9wdWJsaWNfZ2Vycml0X2hvc3RzGAMg'
        'AygJQgIYAVIWa25vd25QdWJsaWNHZXJyaXRIb3N0cxJCCgVpbnB1dBgEIAEoCzIoLmJ1aWxkYn'
        'Vja2V0LnYyLkJ1aWxkSW5mcmEuQkJBZ2VudC5JbnB1dEICGAFSBWlucHV0GssBCgVJbnB1dBJZ'
        'Cg1jaXBkX3BhY2thZ2VzGAEgAygLMjQuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CQkFnZW'
        '50LklucHV0LkNJUERQYWNrYWdlUgxjaXBkUGFja2FnZXMaZwoLQ0lQRFBhY2thZ2USEgoEbmFt'
        'ZRgBIAEoCVIEbmFtZRIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uEhYKBnNlcnZlchgDIAEoCV'
        'IGc2VydmVyEhIKBHBhdGgYBCABKAlSBHBhdGgagQIKB0JhY2tlbmQSLwoGY29uZmlnGAEgASgL'
        'MhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFIGY29uZmlnEigKBHRhc2sYAiABKAsyFC5idWlsZG'
        'J1Y2tldC52Mi5UYXNrUgR0YXNrEjIKBmNhY2hlcxgDIAMoCzIaLmJ1aWxkYnVja2V0LnYyLkNh'
        'Y2hlRW50cnlSBmNhY2hlcxJLCg90YXNrX2RpbWVuc2lvbnMYBSADKAsyIi5idWlsZGJ1Y2tldC'
        '52Mi5SZXF1ZXN0ZWREaW1lbnNpb25SDnRhc2tEaW1lbnNpb25zEhoKCGhvc3RuYW1lGAYgASgJ'
        'Ughob3N0bmFtZQ==');
