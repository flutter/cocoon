//
//  Generated code. Do not modify.
//  source: task.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use taskDescriptor instead')
const Task$json = {
  '1': 'Task',
  '2': [
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
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor = $convert.base64Decode(
    'CgRUYXNrEikKEGNyZWF0ZV90aW1lc3RhbXAYAyABKANSD2NyZWF0ZVRpbWVzdGFtcBInCg9zdG'
    'FydF90aW1lc3RhbXAYBCABKANSDnN0YXJ0VGltZXN0YW1wEiMKDWVuZF90aW1lc3RhbXAYBSAB'
    'KANSDGVuZFRpbWVzdGFtcBISCgRuYW1lGAYgASgJUgRuYW1lEhoKCGF0dGVtcHRzGAcgASgFUg'
    'hhdHRlbXB0cxIZCghpc19mbGFreRgIIAEoCFIHaXNGbGFreRIsChJ0aW1lb3V0X2luX21pbnV0'
    'ZXMYCSABKAVSEHRpbWVvdXRJbk1pbnV0ZXMSFgoGcmVhc29uGAogASgJUgZyZWFzb24SMwoVcm'
    'VxdWlyZWRfY2FwYWJpbGl0aWVzGAsgAygJUhRyZXF1aXJlZENhcGFiaWxpdGllcxIwChRyZXNl'
    'cnZlZF9mb3JfYWdlbnRJZBgMIAEoCVIScmVzZXJ2ZWRGb3JBZ2VudElkEh0KCnN0YWdlX25hbW'
    'UYDSABKAlSCXN0YWdlTmFtZRIWCgZzdGF0dXMYDiABKAlSBnN0YXR1cxIgCgtidWlsZE51bWJl'
    'chgPIAEoBVILYnVpbGROdW1iZXISKAoPYnVpbGROdW1iZXJMaXN0GBAgASgJUg9idWlsZE51bW'
    'Jlckxpc3QSIAoLYnVpbGRlck5hbWUYESABKAlSC2J1aWxkZXJOYW1lEh4KCmx1Y2lCdWNrZXQY'
    'EiABKAlSCmx1Y2lCdWNrZXQSIgoNaXNfdGVzdF9mbGFreRgTIAEoCFILaXNUZXN0Rmxha3lKBA'
    'gBEAJKBAgCEAM=');
