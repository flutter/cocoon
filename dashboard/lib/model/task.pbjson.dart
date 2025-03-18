///
//  Generated code. Do not modify.
//  source: lib/model/task.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 11, '6': '.RootKey', '10': 'key'},
    {
      '1': 'commit_key',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.RootKey',
      '10': 'commitKey'
    },
    {'1': 'create_timestamp', '3': 3, '4': 1, '5': 3, '10': 'createTimestamp'},
    {'1': 'start_timestamp', '3': 4, '4': 1, '5': 3, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 5, '4': 1, '5': 3, '10': 'endTimestamp'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'attempts', '3': 7, '4': 1, '5': 5, '10': 'attempts'},
    {'1': 'is_flaky', '3': 8, '4': 1, '5': 8, '10': 'isFlaky'},
    {
      '1': 'timeout_in_minutes',
      '3': 9,
      '4': 1,
      '5': 5,
      '10': 'timeoutInMinutes'
    },
    {'1': 'reason', '3': 10, '4': 1, '5': 9, '10': 'reason'},
    {
      '1': 'required_capabilities',
      '3': 11,
      '4': 3,
      '5': 9,
      '10': 'requiredCapabilities'
    },
    {
      '1': 'reserved_for_agentId',
      '3': 12,
      '4': 1,
      '5': 9,
      '10': 'reservedForAgentId'
    },
    {'1': 'stage_name', '3': 13, '4': 1, '5': 9, '10': 'stageName'},
    {'1': 'status', '3': 14, '4': 1, '5': 9, '10': 'status'},
    {'1': 'buildNumber', '3': 15, '4': 1, '5': 5, '10': 'buildNumber'},
    {'1': 'buildNumberList', '3': 16, '4': 1, '5': 9, '10': 'buildNumberList'},
    {'1': 'builderName', '3': 17, '4': 1, '5': 9, '10': 'builderName'},
    {'1': 'luciBucket', '3': 18, '4': 1, '5': 9, '10': 'luciBucket'},
    {'1': 'is_test_flaky', '3': 19, '4': 1, '5': 8, '10': 'isTestFlaky'},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEhoKA2tleRgBIAEoCzIILlJvb3RLZXlSA2tleRInCgpjb21taXRfa2V5GAIgASgLMgguUm9vdEtleVIJY29tbWl0S2V5EikKEGNyZWF0ZV90aW1lc3RhbXAYAyABKANSD2NyZWF0ZVRpbWVzdGFtcBInCg9zdGFydF90aW1lc3RhbXAYBCABKANSDnN0YXJ0VGltZXN0YW1wEiMKDWVuZF90aW1lc3RhbXAYBSABKANSDGVuZFRpbWVzdGFtcBISCgRuYW1lGAYgASgJUgRuYW1lEhoKCGF0dGVtcHRzGAcgASgFUghhdHRlbXB0cxIZCghpc19mbGFreRgIIAEoCFIHaXNGbGFreRIsChJ0aW1lb3V0X2luX21pbnV0ZXMYCSABKAVSEHRpbWVvdXRJbk1pbnV0ZXMSFgoGcmVhc29uGAogASgJUgZyZWFzb24SMwoVcmVxdWlyZWRfY2FwYWJpbGl0aWVzGAsgAygJUhRyZXF1aXJlZENhcGFiaWxpdGllcxIwChRyZXNlcnZlZF9mb3JfYWdlbnRJZBgMIAEoCVIScmVzZXJ2ZWRGb3JBZ2VudElkEh0KCnN0YWdlX25hbWUYDSABKAlSCXN0YWdlTmFtZRIWCgZzdGF0dXMYDiABKAlSBnN0YXR1cxIgCgtidWlsZE51bWJlchgPIAEoBVILYnVpbGROdW1iZXISKAoPYnVpbGROdW1iZXJMaXN0GBAgASgJUg9idWlsZE51bWJlckxpc3QSIAoLYnVpbGRlck5hbWUYESABKAlSC2J1aWxkZXJOYW1lEh4KCmx1Y2lCdWNrZXQYEiABKAlSCmx1Y2lCdWNrZXQSIgoNaXNfdGVzdF9mbGFreRgTIAEoCFILaXNUZXN0Rmxha3k=');
