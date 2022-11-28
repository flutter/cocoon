///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/build.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use buildDescriptor instead')
const Build$json = const {
  '1': 'Build',
  '2': const [
    const {'1': 'id', '3': 1, '4': 1, '5': 3, '8': const {}, '10': 'id'},
    const {'1': 'builder', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.BuilderID', '8': const {}, '10': 'builder'},
    const {'1': 'number', '3': 3, '4': 1, '5': 5, '8': const {}, '10': 'number'},
    const {'1': 'created_by', '3': 4, '4': 1, '5': 9, '8': const {}, '10': 'createdBy'},
    const {'1': 'canceled_by', '3': 23, '4': 1, '5': 9, '8': const {}, '10': 'canceledBy'},
    const {
      '1': 'create_time',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'createTime'
    },
    const {
      '1': 'start_time',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'startTime'
    },
    const {'1': 'end_time', '3': 8, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '8': const {}, '10': 'endTime'},
    const {
      '1': 'update_time',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'updateTime'
    },
    const {
      '1': 'cancel_time',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '8': const {},
      '10': 'cancelTime'
    },
    const {'1': 'status', '3': 12, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '8': const {}, '10': 'status'},
    const {'1': 'summary_markdown', '3': 20, '4': 1, '5': 9, '8': const {}, '10': 'summaryMarkdown'},
    const {'1': 'critical', '3': 21, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '8': const {}, '10': 'critical'},
    const {
      '1': 'status_details',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.StatusDetails',
      '8': const {},
      '10': 'statusDetails'
    },
    const {'1': 'input', '3': 15, '4': 1, '5': 11, '6': '.buildbucket.v2.Build.Input', '8': const {}, '10': 'input'},
    const {'1': 'output', '3': 16, '4': 1, '5': 11, '6': '.buildbucket.v2.Build.Output', '8': const {}, '10': 'output'},
    const {'1': 'steps', '3': 17, '4': 3, '5': 11, '6': '.buildbucket.v2.Step', '8': const {}, '10': 'steps'},
    const {'1': 'infra', '3': 18, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra', '8': const {}, '10': 'infra'},
    const {'1': 'tags', '3': 19, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'tags'},
    const {'1': 'exe', '3': 24, '4': 1, '5': 11, '6': '.buildbucket.v2.Executable', '8': const {}, '10': 'exe'},
    const {'1': 'canary', '3': 25, '4': 1, '5': 8, '10': 'canary'},
    const {
      '1': 'scheduling_timeout',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'schedulingTimeout'
    },
    const {
      '1': 'execution_timeout',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'executionTimeout'
    },
    const {'1': 'grace_period', '3': 29, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'gracePeriod'},
    const {'1': 'wait_for_capacity', '3': 28, '4': 1, '5': 8, '10': 'waitForCapacity'},
    const {'1': 'can_outlive_parent', '3': 30, '4': 1, '5': 8, '8': const {}, '10': 'canOutliveParent'},
    const {'1': 'ancestor_ids', '3': 31, '4': 3, '5': 3, '8': const {}, '10': 'ancestorIds'},
  ],
  '3': const [Build_Input$json, Build_Output$json],
  '9': const [
    const {'1': 5, '2': 6},
    const {'1': 13, '2': 14},
    const {'1': 14, '2': 15},
  ],
};

@$core.Deprecated('Use buildDescriptor instead')
const Build_Input$json = const {
  '1': 'Input',
  '2': const [
    const {'1': 'properties', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'properties'},
    const {
      '1': 'gitiles_commit',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.GitilesCommit',
      '8': const {},
      '10': 'gitilesCommit'
    },
    const {
      '1': 'gerrit_changes',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.GerritChange',
      '8': const {},
      '10': 'gerritChanges'
    },
    const {'1': 'experimental', '3': 5, '4': 1, '5': 8, '10': 'experimental'},
    const {'1': 'experiments', '3': 6, '4': 3, '5': 9, '10': 'experiments'},
  ],
};

@$core.Deprecated('Use buildDescriptor instead')
const Build_Output$json = const {
  '1': 'Output',
  '2': const [
    const {'1': 'properties', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'properties'},
    const {'1': 'gitiles_commit', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.GitilesCommit', '10': 'gitilesCommit'},
    const {'1': 'logs', '3': 5, '4': 3, '5': 11, '6': '.buildbucket.v2.Log', '10': 'logs'},
  ],
  '9': const [
    const {'1': 2, '2': 3},
    const {'1': 4, '2': 5},
  ],
};

/// Descriptor for `Build`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildDescriptor = $convert.base64Decode(
    'CgVCdWlsZBIYCgJpZBgBIAEoA0II4EEDuM68AwNSAmlkEkAKB2J1aWxkZXIYAiABKAsyGS5idWlsZGJ1Y2tldC52Mi5CdWlsZGVySURCC4rDGgIIArjOvAMCUgdidWlsZGVyEiAKBm51bWJlchgDIAEoBUII4EEDuM68AwJSBm51bWJlchIiCgpjcmVhdGVkX2J5GAQgASgJQgPgQQNSCWNyZWF0ZWRCeRIkCgtjYW5jZWxlZF9ieRgXIAEoCUID4EEDUgpjYW5jZWxlZEJ5EkUKC2NyZWF0ZV90aW1lGAYgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEII4EEDuM68AwJSCmNyZWF0ZVRpbWUSQwoKc3RhcnRfdGltZRgHIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCCOBBA7jOvAMCUglzdGFydFRpbWUSPwoIZW5kX3RpbWUYCCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wQgjgQQO4zrwDAlIHZW5kVGltZRJFCgt1cGRhdGVfdGltZRgJIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBCCOBBA7jOvAMCUgp1cGRhdGVUaW1lEkUKC2NhbmNlbF90aW1lGCAgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcEII4EEDuM68AwJSCmNhbmNlbFRpbWUSOwoGc3RhdHVzGAwgASgOMhYuYnVpbGRidWNrZXQudjIuU3RhdHVzQguKwxoCCAO4zrwDA1IGc3RhdHVzEjEKEHN1bW1hcnlfbWFya2Rvd24YFCABKAlCBorDGgIIA1IPc3VtbWFyeU1hcmtkb3duEjoKCGNyaXRpY2FsGBUgASgOMhcuYnVpbGRidWNrZXQudjIuVHJpbmFyeUIFuM68AwJSCGNyaXRpY2FsElEKDnN0YXR1c19kZXRhaWxzGBYgASgLMh0uYnVpbGRidWNrZXQudjIuU3RhdHVzRGV0YWlsc0ILisMaAggDuM68AwNSDXN0YXR1c0RldGFpbHMSOQoFaW5wdXQYDyABKAsyGy5idWlsZGJ1Y2tldC52Mi5CdWlsZC5JbnB1dEIGisMaAggCUgVpbnB1dBI8CgZvdXRwdXQYECABKAsyHC5idWlsZGJ1Y2tldC52Mi5CdWlsZC5PdXRwdXRCBorDGgIIA1IGb3V0cHV0EjIKBXN0ZXBzGBEgAygLMhQuYnVpbGRidWNrZXQudjIuU3RlcEIGisMaAggDUgVzdGVwcxI4CgVpbmZyYRgSIAEoCzIaLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmFCBorDGgIIAlIFaW5mcmESLgoEdGFncxgTIAMoCzIaLmJ1aWxkYnVja2V0LnYyLlN0cmluZ1BhaXJSBHRhZ3MSNAoDZXhlGBggASgLMhouYnVpbGRidWNrZXQudjIuRXhlY3V0YWJsZUIGisMaAggCUgNleGUSFgoGY2FuYXJ5GBkgASgIUgZjYW5hcnkSSAoSc2NoZWR1bGluZ190aW1lb3V0GBogASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUhFzY2hlZHVsaW5nVGltZW91dBJGChFleGVjdXRpb25fdGltZW91dBgbIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIQZXhlY3V0aW9uVGltZW91dBI8CgxncmFjZV9wZXJpb2QYHSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SC2dyYWNlUGVyaW9kEioKEXdhaXRfZm9yX2NhcGFjaXR5GBwgASgIUg93YWl0Rm9yQ2FwYWNpdHkSMwoSY2FuX291dGxpdmVfcGFyZW50GB4gASgIQgW4zrwDA1IQY2FuT3V0bGl2ZVBhcmVudBIrCgxhbmNlc3Rvcl9pZHMYHyADKANCCOBBA7jOvAMDUgthbmNlc3RvcklkcxqfAgoFSW5wdXQSNwoKcHJvcGVydGllcxgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnByb3BlcnRpZXMSSwoOZ2l0aWxlc19jb21taXQYAiABKAsyHS5idWlsZGJ1Y2tldC52Mi5HaXRpbGVzQ29tbWl0QgW4zrwDAlINZ2l0aWxlc0NvbW1pdBJKCg5nZXJyaXRfY2hhbmdlcxgDIAMoCzIcLmJ1aWxkYnVja2V0LnYyLkdlcnJpdENoYW5nZUIFuM68AwJSDWdlcnJpdENoYW5nZXMSIgoMZXhwZXJpbWVudGFsGAUgASgIUgxleHBlcmltZW50YWwSIAoLZXhwZXJpbWVudHMYBiADKAlSC2V4cGVyaW1lbnRzGrwBCgZPdXRwdXQSNwoKcHJvcGVydGllcxgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSCnByb3BlcnRpZXMSRAoOZ2l0aWxlc19jb21taXQYAyABKAsyHS5idWlsZGJ1Y2tldC52Mi5HaXRpbGVzQ29tbWl0Ug1naXRpbGVzQ29tbWl0EicKBGxvZ3MYBSADKAsyEy5idWlsZGJ1Y2tldC52Mi5Mb2dSBGxvZ3NKBAgCEANKBAgEEAVKBAgFEAZKBAgNEA5KBAgOEA8=');
@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef$json = const {
  '1': 'InputDataRef',
  '2': const [
    const {'1': 'cas', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CAS', '9': 0, '10': 'cas'},
    const {'1': 'cipd', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CIPD', '9': 0, '10': 'cipd'},
    const {'1': 'on_path', '3': 3, '4': 3, '5': 9, '10': 'onPath'},
  ],
  '3': const [InputDataRef_CAS$json, InputDataRef_CIPD$json],
  '8': const [
    const {'1': 'data_type'},
  ],
  '9': const [
    const {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CAS$json = const {
  '1': 'CAS',
  '2': const [
    const {'1': 'cas_instance', '3': 1, '4': 1, '5': 9, '10': 'casInstance'},
    const {'1': 'digest', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef.CAS.Digest', '10': 'digest'},
  ],
  '3': const [InputDataRef_CAS_Digest$json],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CAS_Digest$json = const {
  '1': 'Digest',
  '2': const [
    const {'1': 'hash', '3': 1, '4': 1, '5': 9, '10': 'hash'},
    const {'1': 'size_bytes', '3': 2, '4': 1, '5': 3, '10': 'sizeBytes'},
  ],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CIPD$json = const {
  '1': 'CIPD',
  '2': const [
    const {'1': 'server', '3': 1, '4': 1, '5': 9, '10': 'server'},
    const {'1': 'specs', '3': 2, '4': 3, '5': 11, '6': '.buildbucket.v2.InputDataRef.CIPD.PkgSpec', '10': 'specs'},
  ],
  '3': const [InputDataRef_CIPD_PkgSpec$json],
};

@$core.Deprecated('Use inputDataRefDescriptor instead')
const InputDataRef_CIPD_PkgSpec$json = const {
  '1': 'PkgSpec',
  '2': const [
    const {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    const {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `InputDataRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List inputDataRefDescriptor = $convert.base64Decode(
    'CgxJbnB1dERhdGFSZWYSNAoDY2FzGAEgASgLMiAuYnVpbGRidWNrZXQudjIuSW5wdXREYXRhUmVmLkNBU0gAUgNjYXMSNwoEY2lwZBgCIAEoCzIhLmJ1aWxkYnVja2V0LnYyLklucHV0RGF0YVJlZi5DSVBESABSBGNpcGQSFwoHb25fcGF0aBgDIAMoCVIGb25QYXRoGqYBCgNDQVMSIQoMY2FzX2luc3RhbmNlGAEgASgJUgtjYXNJbnN0YW5jZRI/CgZkaWdlc3QYAiABKAsyJy5idWlsZGJ1Y2tldC52Mi5JbnB1dERhdGFSZWYuQ0FTLkRpZ2VzdFIGZGlnZXN0GjsKBkRpZ2VzdBISCgRoYXNoGAEgASgJUgRoYXNoEh0KCnNpemVfYnl0ZXMYAiABKANSCXNpemVCeXRlcxqeAQoEQ0lQRBIWCgZzZXJ2ZXIYASABKAlSBnNlcnZlchI/CgVzcGVjcxgCIAMoCzIpLmJ1aWxkYnVja2V0LnYyLklucHV0RGF0YVJlZi5DSVBELlBrZ1NwZWNSBXNwZWNzGj0KB1BrZ1NwZWMSGAoHcGFja2FnZRgBIAEoCVIHcGFja2FnZRIYCgd2ZXJzaW9uGAIgASgJUgd2ZXJzaW9uQgsKCWRhdGFfdHlwZUoECAQQBQ==');
@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef$json = const {
  '1': 'ResolvedDataRef',
  '2': const [
    const {'1': 'cas', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CAS', '9': 0, '10': 'cas'},
    const {'1': 'cipd', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CIPD', '9': 0, '10': 'cipd'},
  ],
  '3': const [ResolvedDataRef_Timing$json, ResolvedDataRef_CAS$json, ResolvedDataRef_CIPD$json],
  '8': const [
    const {'1': 'data_type'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_Timing$json = const {
  '1': 'Timing',
  '2': const [
    const {'1': 'fetch_duration', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'fetchDuration'},
    const {'1': 'install_duration', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'installDuration'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CAS$json = const {
  '1': 'CAS',
  '2': const [
    const {'1': 'timing', '3': 1, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.Timing', '10': 'timing'},
  ],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CIPD$json = const {
  '1': 'CIPD',
  '2': const [
    const {'1': 'specs', '3': 2, '4': 3, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.CIPD.PkgSpec', '10': 'specs'},
  ],
  '3': const [ResolvedDataRef_CIPD_PkgSpec$json],
};

@$core.Deprecated('Use resolvedDataRefDescriptor instead')
const ResolvedDataRef_CIPD_PkgSpec$json = const {
  '1': 'PkgSpec',
  '2': const [
    const {'1': 'skipped', '3': 1, '4': 1, '5': 8, '10': 'skipped'},
    const {'1': 'package', '3': 2, '4': 1, '5': 9, '10': 'package'},
    const {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'was_cached', '3': 4, '4': 1, '5': 14, '6': '.buildbucket.v2.Trinary', '10': 'wasCached'},
    const {'1': 'timing', '3': 5, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef.Timing', '10': 'timing'},
  ],
};

/// Descriptor for `ResolvedDataRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resolvedDataRefDescriptor = $convert.base64Decode(
    'Cg9SZXNvbHZlZERhdGFSZWYSNwoDY2FzGAEgASgLMiMuYnVpbGRidWNrZXQudjIuUmVzb2x2ZWREYXRhUmVmLkNBU0gAUgNjYXMSOgoEY2lwZBgCIAEoCzIkLmJ1aWxkYnVja2V0LnYyLlJlc29sdmVkRGF0YVJlZi5DSVBESABSBGNpcGQakAEKBlRpbWluZxJACg5mZXRjaF9kdXJhdGlvbhgBIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINZmV0Y2hEdXJhdGlvbhJEChBpbnN0YWxsX2R1cmF0aW9uGAIgASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg9pbnN0YWxsRHVyYXRpb24aRQoDQ0FTEj4KBnRpbWluZxgBIAEoCzImLmJ1aWxkYnVja2V0LnYyLlJlc29sdmVkRGF0YVJlZi5UaW1pbmdSBnRpbWluZxqcAgoEQ0lQRBJCCgVzcGVjcxgCIAMoCzIsLmJ1aWxkYnVja2V0LnYyLlJlc29sdmVkRGF0YVJlZi5DSVBELlBrZ1NwZWNSBXNwZWNzGs8BCgdQa2dTcGVjEhgKB3NraXBwZWQYASABKAhSB3NraXBwZWQSGAoHcGFja2FnZRgCIAEoCVIHcGFja2FnZRIYCgd2ZXJzaW9uGAMgASgJUgd2ZXJzaW9uEjYKCndhc19jYWNoZWQYBCABKA4yFy5idWlsZGJ1Y2tldC52Mi5UcmluYXJ5Ugl3YXNDYWNoZWQSPgoGdGltaW5nGAUgASgLMiYuYnVpbGRidWNrZXQudjIuUmVzb2x2ZWREYXRhUmVmLlRpbWluZ1IGdGltaW5nQgsKCWRhdGFfdHlwZQ==');
@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra$json = const {
  '1': 'BuildInfra',
  '2': const [
    const {
      '1': 'buildbucket',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket',
      '8': const {},
      '10': 'buildbucket'
    },
    const {
      '1': 'swarming',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Swarming',
      '8': const {},
      '10': 'swarming'
    },
    const {
      '1': 'logdog',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.LogDog',
      '8': const {},
      '10': 'logdog'
    },
    const {'1': 'recipe', '3': 4, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Recipe', '10': 'recipe'},
    const {
      '1': 'resultdb',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.ResultDB',
      '8': const {},
      '10': 'resultdb'
    },
    const {'1': 'bbagent', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.BBAgent', '10': 'bbagent'},
    const {'1': 'backend', '3': 7, '4': 1, '5': 11, '6': '.buildbucket.v2.BuildInfra.Backend', '10': 'backend'},
  ],
  '3': const [
    BuildInfra_Buildbucket$json,
    BuildInfra_Swarming$json,
    BuildInfra_LogDog$json,
    BuildInfra_Recipe$json,
    BuildInfra_ResultDB$json,
    BuildInfra_BBAgent$json,
    BuildInfra_Backend$json
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket$json = const {
  '1': 'Buildbucket',
  '2': const [
    const {'1': 'service_config_revision', '3': 2, '4': 1, '5': 9, '10': 'serviceConfigRevision'},
    const {
      '1': 'requested_properties',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Struct',
      '10': 'requestedProperties'
    },
    const {
      '1': 'requested_dimensions',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.RequestedDimension',
      '10': 'requestedDimensions'
    },
    const {'1': 'hostname', '3': 7, '4': 1, '5': 9, '10': 'hostname'},
    const {
      '1': 'experiment_reasons',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.ExperimentReasonsEntry',
      '10': 'experimentReasons'
    },
    const {
      '1': 'agent_executable',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.AgentExecutableEntry',
      '8': const {'3': true},
      '10': 'agentExecutable',
    },
    const {
      '1': 'agent',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent',
      '8': const {},
      '10': 'agent'
    },
    const {'1': 'known_public_gerrit_hosts', '3': 11, '4': 3, '5': 9, '10': 'knownPublicGerritHosts'},
  ],
  '3': const [
    BuildInfra_Buildbucket_Agent$json,
    BuildInfra_Buildbucket_ExperimentReasonsEntry$json,
    BuildInfra_Buildbucket_AgentExecutableEntry$json
  ],
  '4': const [BuildInfra_Buildbucket_ExperimentReason$json],
  '9': const [
    const {'1': 4, '2': 5},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent$json = const {
  '1': 'Agent',
  '2': const [
    const {
      '1': 'input',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Input',
      '8': const {},
      '10': 'input'
    },
    const {
      '1': 'output',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Output',
      '8': const {},
      '10': 'output'
    },
    const {
      '1': 'source',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source',
      '8': const {},
      '10': 'source'
    },
    const {
      '1': 'purposes',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.PurposesEntry',
      '10': 'purposes'
    },
  ],
  '3': const [
    BuildInfra_Buildbucket_Agent_Source$json,
    BuildInfra_Buildbucket_Agent_Input$json,
    BuildInfra_Buildbucket_Agent_Output$json,
    BuildInfra_Buildbucket_Agent_PurposesEntry$json
  ],
  '4': const [BuildInfra_Buildbucket_Agent_Purpose$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source$json = const {
  '1': 'Source',
  '2': const [
    const {
      '1': 'cipd',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source.CIPD',
      '9': 0,
      '10': 'cipd'
    },
  ],
  '3': const [BuildInfra_Buildbucket_Agent_Source_CIPD$json],
  '8': const [
    const {'1': 'data_type'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source_CIPD$json = const {
  '1': 'CIPD',
  '2': const [
    const {'1': 'package', '3': 1, '4': 1, '5': 9, '10': 'package'},
    const {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'server', '3': 3, '4': 1, '5': 9, '10': 'server'},
    const {
      '1': 'resolved_instances',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Source.CIPD.ResolvedInstancesEntry',
      '8': const {},
      '10': 'resolvedInstances'
    },
  ],
  '3': const [BuildInfra_Buildbucket_Agent_Source_CIPD_ResolvedInstancesEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Source_CIPD_ResolvedInstancesEntry$json = const {
  '1': 'ResolvedInstancesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Input$json = const {
  '1': 'Input',
  '2': const [
    const {
      '1': 'data',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Input.DataEntry',
      '10': 'data'
    },
  ],
  '3': const [BuildInfra_Buildbucket_Agent_Input_DataEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Input_DataEntry$json = const {
  '1': 'DataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.InputDataRef', '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Output$json = const {
  '1': 'Output',
  '2': const [
    const {
      '1': 'resolved_data',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Output.ResolvedDataEntry',
      '10': 'resolvedData'
    },
    const {'1': 'status', '3': 2, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    const {'1': 'status_details', '3': 3, '4': 1, '5': 11, '6': '.buildbucket.v2.StatusDetails', '10': 'statusDetails'},
    const {'1': 'summary_html', '3': 4, '4': 1, '5': 9, '10': 'summaryHtml'},
    const {'1': 'agent_platform', '3': 5, '4': 1, '5': 9, '10': 'agentPlatform'},
    const {'1': 'total_duration', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'totalDuration'},
  ],
  '3': const [BuildInfra_Buildbucket_Agent_Output_ResolvedDataEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Output_ResolvedDataEntry$json = const {
  '1': 'ResolvedDataEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef', '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_PurposesEntry$json = const {
  '1': 'PurposesEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.Agent.Purpose',
      '10': 'value'
    },
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_Agent_Purpose$json = const {
  '1': 'Purpose',
  '2': const [
    const {'1': 'PURPOSE_UNSPECIFIED', '2': 0},
    const {'1': 'PURPOSE_EXE_PAYLOAD', '2': 1},
    const {'1': 'PURPOSE_BBAGENT_UTILITY', '2': 2},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_ExperimentReasonsEntry$json = const {
  '1': 'ExperimentReasonsEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {
      '1': 'value',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.buildbucket.v2.BuildInfra.Buildbucket.ExperimentReason',
      '10': 'value'
    },
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_AgentExecutableEntry$json = const {
  '1': 'AgentExecutableEntry',
  '2': const [
    const {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    const {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.ResolvedDataRef', '10': 'value'},
  ],
  '7': const {'7': true},
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Buildbucket_ExperimentReason$json = const {
  '1': 'ExperimentReason',
  '2': const [
    const {'1': 'EXPERIMENT_REASON_UNSET', '2': 0},
    const {'1': 'EXPERIMENT_REASON_GLOBAL_DEFAULT', '2': 1},
    const {'1': 'EXPERIMENT_REASON_BUILDER_CONFIG', '2': 2},
    const {'1': 'EXPERIMENT_REASON_GLOBAL_MINIMUM', '2': 3},
    const {'1': 'EXPERIMENT_REASON_REQUESTED', '2': 4},
    const {'1': 'EXPERIMENT_REASON_GLOBAL_INACTIVE', '2': 5},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Swarming$json = const {
  '1': 'Swarming',
  '2': const [
    const {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': const {}, '10': 'hostname'},
    const {'1': 'task_id', '3': 2, '4': 1, '5': 9, '8': const {}, '10': 'taskId'},
    const {'1': 'parent_run_id', '3': 9, '4': 1, '5': 9, '10': 'parentRunId'},
    const {'1': 'task_service_account', '3': 3, '4': 1, '5': 9, '10': 'taskServiceAccount'},
    const {'1': 'priority', '3': 4, '4': 1, '5': 5, '10': 'priority'},
    const {
      '1': 'task_dimensions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.RequestedDimension',
      '10': 'taskDimensions'
    },
    const {'1': 'bot_dimensions', '3': 6, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'botDimensions'},
    const {
      '1': 'caches',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.Swarming.CacheEntry',
      '10': 'caches'
    },
  ],
  '3': const [BuildInfra_Swarming_CacheEntry$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Swarming_CacheEntry$json = const {
  '1': 'CacheEntry',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    const {
      '1': 'wait_for_warm_cache',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Duration',
      '10': 'waitForWarmCache'
    },
    const {'1': 'env_var', '3': 4, '4': 1, '5': 9, '10': 'envVar'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_LogDog$json = const {
  '1': 'LogDog',
  '2': const [
    const {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': const {}, '10': 'hostname'},
    const {'1': 'project', '3': 2, '4': 1, '5': 9, '10': 'project'},
    const {'1': 'prefix', '3': 3, '4': 1, '5': 9, '10': 'prefix'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Recipe$json = const {
  '1': 'Recipe',
  '2': const [
    const {'1': 'cipd_package', '3': 1, '4': 1, '5': 9, '10': 'cipdPackage'},
    const {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_ResultDB$json = const {
  '1': 'ResultDB',
  '2': const [
    const {'1': 'hostname', '3': 1, '4': 1, '5': 9, '8': const {}, '10': 'hostname'},
    const {'1': 'invocation', '3': 2, '4': 1, '5': 9, '8': const {}, '10': 'invocation'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent$json = const {
  '1': 'BBAgent',
  '2': const [
    const {'1': 'payload_path', '3': 1, '4': 1, '5': 9, '10': 'payloadPath'},
    const {'1': 'cache_dir', '3': 2, '4': 1, '5': 9, '10': 'cacheDir'},
    const {
      '1': 'known_public_gerrit_hosts',
      '3': 3,
      '4': 3,
      '5': 9,
      '8': const {'3': true},
      '10': 'knownPublicGerritHosts',
    },
    const {
      '1': 'input',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.BBAgent.Input',
      '8': const {'3': true},
      '10': 'input',
    },
  ],
  '3': const [BuildInfra_BBAgent_Input$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent_Input$json = const {
  '1': 'Input',
  '2': const [
    const {
      '1': 'cipd_packages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.buildbucket.v2.BuildInfra.BBAgent.Input.CIPDPackage',
      '10': 'cipdPackages'
    },
  ],
  '3': const [BuildInfra_BBAgent_Input_CIPDPackage$json],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_BBAgent_Input_CIPDPackage$json = const {
  '1': 'CIPDPackage',
  '2': const [
    const {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    const {'1': 'version', '3': 2, '4': 1, '5': 9, '10': 'version'},
    const {'1': 'server', '3': 3, '4': 1, '5': 9, '10': 'server'},
    const {'1': 'path', '3': 4, '4': 1, '5': 9, '10': 'path'},
  ],
};

@$core.Deprecated('Use buildInfraDescriptor instead')
const BuildInfra_Backend$json = const {
  '1': 'Backend',
  '2': const [
    const {'1': 'config', '3': 1, '4': 1, '5': 11, '6': '.google.protobuf.Struct', '10': 'config'},
    const {'1': 'task', '3': 2, '4': 1, '5': 11, '6': '.buildbucket.v2.Task', '10': 'task'},
  ],
};

/// Descriptor for `BuildInfra`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List buildInfraDescriptor = $convert.base64Decode(
    'CgpCdWlsZEluZnJhElAKC2J1aWxkYnVja2V0GAEgASgLMiYuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldEIGisMaAggCUgtidWlsZGJ1Y2tldBJHCghzd2FybWluZxgCIAEoCzIjLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuU3dhcm1pbmdCBorDGgIIAlIIc3dhcm1pbmcSQQoGbG9nZG9nGAMgASgLMiEuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5Mb2dEb2dCBorDGgIIAlIGbG9nZG9nEjkKBnJlY2lwZRgEIAEoCzIhLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuUmVjaXBlUgZyZWNpcGUSRgoIcmVzdWx0ZGIYBSABKAsyIy5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLlJlc3VsdERCQgW4zrwDAlIIcmVzdWx0ZGISPAoHYmJhZ2VudBgGIAEoCzIiLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQkJBZ2VudFIHYmJhZ2VudBI8CgdiYWNrZW5kGAcgASgLMiIuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CYWNrZW5kUgdiYWNrZW5kGv0UCgtCdWlsZGJ1Y2tldBI2ChdzZXJ2aWNlX2NvbmZpZ19yZXZpc2lvbhgCIAEoCVIVc2VydmljZUNvbmZpZ1JldmlzaW9uEkoKFHJlcXVlc3RlZF9wcm9wZXJ0aWVzGAUgASgLMhcuZ29vZ2xlLnByb3RvYnVmLlN0cnVjdFITcmVxdWVzdGVkUHJvcGVydGllcxJVChRyZXF1ZXN0ZWRfZGltZW5zaW9ucxgGIAMoCzIiLmJ1aWxkYnVja2V0LnYyLlJlcXVlc3RlZERpbWVuc2lvblITcmVxdWVzdGVkRGltZW5zaW9ucxIaCghob3N0bmFtZRgHIAEoCVIIaG9zdG5hbWUSbAoSZXhwZXJpbWVudF9yZWFzb25zGAggAygLMj0uYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5FeHBlcmltZW50UmVhc29uc0VudHJ5UhFleHBlcmltZW50UmVhc29ucxJqChBhZ2VudF9leGVjdXRhYmxlGAkgAygLMjsuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5BZ2VudEV4ZWN1dGFibGVFbnRyeUICGAFSD2FnZW50RXhlY3V0YWJsZRJKCgVhZ2VudBgKIAEoCzIsLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnRCBorDGgIIAlIFYWdlbnQSOQoZa25vd25fcHVibGljX2dlcnJpdF9ob3N0cxgLIAMoCVIWa25vd25QdWJsaWNHZXJyaXRIb3N0cxq/DAoFQWdlbnQSUAoFaW5wdXQYASABKAsyMi5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJ1aWxkYnVja2V0LkFnZW50LklucHV0QgaKwxoCCAJSBWlucHV0ElMKBm91dHB1dBgCIAEoCzIzLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuT3V0cHV0QgaKwxoCCANSBm91dHB1dBJTCgZzb3VyY2UYAyABKAsyMy5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJ1aWxkYnVja2V0LkFnZW50LlNvdXJjZUIGisMaAggCUgZzb3VyY2USVgoIcHVycG9zZXMYBCADKAsyOi5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJ1aWxkYnVja2V0LkFnZW50LlB1cnBvc2VzRW50cnlSCHB1cnBvc2VzGoYDCgZTb3VyY2USTgoEY2lwZBgBIAEoCzI4LmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuU291cmNlLkNJUERIAFIEY2lwZBqeAgoEQ0lQRBIYCgdwYWNrYWdlGAEgASgJUgdwYWNrYWdlEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24SFgoGc2VydmVyGAMgASgJUgZzZXJ2ZXISgwEKEnJlc29sdmVkX2luc3RhbmNlcxgEIAMoCzJPLmJ1aWxkYnVja2V0LnYyLkJ1aWxkSW5mcmEuQnVpbGRidWNrZXQuQWdlbnQuU291cmNlLkNJUEQuUmVzb2x2ZWRJbnN0YW5jZXNFbnRyeUID4EEDUhFyZXNvbHZlZEluc3RhbmNlcxpEChZSZXNvbHZlZEluc3RhbmNlc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIgASgJUgV2YWx1ZToCOAFCCwoJZGF0YV90eXBlGrABCgVJbnB1dBJQCgRkYXRhGAEgAygLMjwuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5BZ2VudC5JbnB1dC5EYXRhRW50cnlSBGRhdGEaVQoJRGF0YUVudHJ5EhAKA2tleRgBIAEoCVIDa2V5EjIKBXZhbHVlGAIgASgLMhwuYnVpbGRidWNrZXQudjIuSW5wdXREYXRhUmVmUgV2YWx1ZToCOAEa2AMKBk91dHB1dBJqCg1yZXNvbHZlZF9kYXRhGAEgAygLMkUuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5BZ2VudC5PdXRwdXQuUmVzb2x2ZWREYXRhRW50cnlSDHJlc29sdmVkRGF0YRIuCgZzdGF0dXMYAiABKA4yFi5idWlsZGJ1Y2tldC52Mi5TdGF0dXNSBnN0YXR1cxJECg5zdGF0dXNfZGV0YWlscxgDIAEoCzIdLmJ1aWxkYnVja2V0LnYyLlN0YXR1c0RldGFpbHNSDXN0YXR1c0RldGFpbHMSIQoMc3VtbWFyeV9odG1sGAQgASgJUgtzdW1tYXJ5SHRtbBIlCg5hZ2VudF9wbGF0Zm9ybRgFIAEoCVINYWdlbnRQbGF0Zm9ybRJACg50b3RhbF9kdXJhdGlvbhgGIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblINdG90YWxEdXJhdGlvbhpgChFSZXNvbHZlZERhdGFFbnRyeRIQCgNrZXkYASABKAlSA2tleRI1CgV2YWx1ZRgCIAEoCzIfLmJ1aWxkYnVja2V0LnYyLlJlc29sdmVkRGF0YVJlZlIFdmFsdWU6AjgBGnEKDVB1cnBvc2VzRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSSgoFdmFsdWUYAiABKA4yNC5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJ1aWxkYnVja2V0LkFnZW50LlB1cnBvc2VSBXZhbHVlOgI4ASJYCgdQdXJwb3NlEhcKE1BVUlBPU0VfVU5TUEVDSUZJRUQQABIXChNQVVJQT1NFX0VYRV9QQVlMT0FEEAESGwoXUFVSUE9TRV9CQkFHRU5UX1VUSUxJVFkQAhp9ChZFeHBlcmltZW50UmVhc29uc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5Ek0KBXZhbHVlGAIgASgOMjcuYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CdWlsZGJ1Y2tldC5FeHBlcmltZW50UmVhc29uUgV2YWx1ZToCOAEaYwoUQWdlbnRFeGVjdXRhYmxlRW50cnkSEAoDa2V5GAEgASgJUgNrZXkSNQoFdmFsdWUYAiABKAsyHy5idWlsZGJ1Y2tldC52Mi5SZXNvbHZlZERhdGFSZWZSBXZhbHVlOgI4ASLpAQoQRXhwZXJpbWVudFJlYXNvbhIbChdFWFBFUklNRU5UX1JFQVNPTl9VTlNFVBAAEiQKIEVYUEVSSU1FTlRfUkVBU09OX0dMT0JBTF9ERUZBVUxUEAESJAogRVhQRVJJTUVOVF9SRUFTT05fQlVJTERFUl9DT05GSUcQAhIkCiBFWFBFUklNRU5UX1JFQVNPTl9HTE9CQUxfTUlOSU1VTRADEh8KG0VYUEVSSU1FTlRfUkVBU09OX1JFUVVFU1RFRBAEEiUKIUVYUEVSSU1FTlRfUkVBU09OX0dMT0JBTF9JTkFDVElWRRAFSgQIBBAFGrAECghTd2FybWluZxIiCghob3N0bmFtZRgBIAEoCUIGisMaAggCUghob3N0bmFtZRIcCgd0YXNrX2lkGAIgASgJQgPgQQNSBnRhc2tJZBIiCg1wYXJlbnRfcnVuX2lkGAkgASgJUgtwYXJlbnRSdW5JZBIwChR0YXNrX3NlcnZpY2VfYWNjb3VudBgDIAEoCVISdGFza1NlcnZpY2VBY2NvdW50EhoKCHByaW9yaXR5GAQgASgFUghwcmlvcml0eRJLCg90YXNrX2RpbWVuc2lvbnMYBSADKAsyIi5idWlsZGJ1Y2tldC52Mi5SZXF1ZXN0ZWREaW1lbnNpb25SDnRhc2tEaW1lbnNpb25zEkEKDmJvdF9kaW1lbnNpb25zGAYgAygLMhouYnVpbGRidWNrZXQudjIuU3RyaW5nUGFpclINYm90RGltZW5zaW9ucxJGCgZjYWNoZXMYByADKAsyLi5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLlN3YXJtaW5nLkNhY2hlRW50cnlSBmNhY2hlcxqXAQoKQ2FjaGVFbnRyeRISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHBhdGgYAiABKAlSBHBhdGgSSAoTd2FpdF9mb3Jfd2FybV9jYWNoZRgDIAEoCzIZLmdvb2dsZS5wcm90b2J1Zi5EdXJhdGlvblIQd2FpdEZvcldhcm1DYWNoZRIXCgdlbnZfdmFyGAQgASgJUgZlbnZWYXIaXgoGTG9nRG9nEiIKCGhvc3RuYW1lGAEgASgJQgaKwxoCCAJSCGhvc3RuYW1lEhgKB3Byb2plY3QYAiABKAlSB3Byb2plY3QSFgoGcHJlZml4GAMgASgJUgZwcmVmaXgaPwoGUmVjaXBlEiEKDGNpcGRfcGFja2FnZRgBIAEoCVILY2lwZFBhY2thZ2USEgoEbmFtZRgCIAEoCVIEbmFtZRpTCghSZXN1bHREQhIiCghob3N0bmFtZRgBIAEoCUIGisMaAggCUghob3N0bmFtZRIjCgppbnZvY2F0aW9uGAIgASgJQgPgQQNSCmludm9jYXRpb24amgMKB0JCQWdlbnQSIQoMcGF5bG9hZF9wYXRoGAEgASgJUgtwYXlsb2FkUGF0aBIbCgljYWNoZV9kaXIYAiABKAlSCGNhY2hlRGlyEj0KGWtub3duX3B1YmxpY19nZXJyaXRfaG9zdHMYAyADKAlCAhgBUhZrbm93blB1YmxpY0dlcnJpdEhvc3RzEkIKBWlucHV0GAQgASgLMiguYnVpbGRidWNrZXQudjIuQnVpbGRJbmZyYS5CQkFnZW50LklucHV0QgIYAVIFaW5wdXQaywEKBUlucHV0ElkKDWNpcGRfcGFja2FnZXMYASADKAsyNC5idWlsZGJ1Y2tldC52Mi5CdWlsZEluZnJhLkJCQWdlbnQuSW5wdXQuQ0lQRFBhY2thZ2VSDGNpcGRQYWNrYWdlcxpnCgtDSVBEUGFja2FnZRISCgRuYW1lGAEgASgJUgRuYW1lEhgKB3ZlcnNpb24YAiABKAlSB3ZlcnNpb24SFgoGc2VydmVyGAMgASgJUgZzZXJ2ZXISEgoEcGF0aBgEIAEoCVIEcGF0aBpkCgdCYWNrZW5kEi8KBmNvbmZpZxgBIAEoCzIXLmdvb2dsZS5wcm90b2J1Zi5TdHJ1Y3RSBmNvbmZpZxIoCgR0YXNrGAIgASgLMhQuYnVpbGRidWNrZXQudjIuVGFza1IEdGFzaw==');
