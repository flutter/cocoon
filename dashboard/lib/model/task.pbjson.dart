//
//  Generated code. Do not modify.
//  source: lib/model/task.proto
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
    {'1': 'key', '3': 1, '4': 1, '5': 11, '6': '.dashboard.RootKey', '10': 'key'},
    {'1': 'commit_key', '3': 2, '4': 1, '5': 11, '6': '.dashboard.RootKey', '10': 'commitKey'},
    {'1': 'create_timestamp', '3': 3, '4': 1, '5': 3, '10': 'createTimestamp'},
    {'1': 'start_timestamp', '3': 4, '4': 1, '5': 3, '10': 'startTimestamp'},
    {'1': 'end_timestamp', '3': 5, '4': 1, '5': 3, '10': 'endTimestamp'},
    {'1': 'name', '3': 6, '4': 1, '5': 9, '10': 'name'},
    {'1': 'attempts', '3': 7, '4': 1, '5': 5, '10': 'attempts'},
    {'1': 'is_flaky', '3': 8, '4': 1, '5': 8, '10': 'isFlaky'},
    {'1': 'timeout_in_minutes', '3': 9, '4': 1, '5': 5, '10': 'timeoutInMinutes'},
    {'1': 'reason', '3': 10, '4': 1, '5': 9, '10': 'reason'},
    {'1': 'stage_name', '3': 13, '4': 1, '5': 9, '10': 'stageName'},
    {'1': 'status', '3': 14, '4': 1, '5': 9, '10': 'status'},
    {'1': 'buildNumber', '3': 15, '4': 1, '5': 5, '10': 'buildNumber'},
    {'1': 'buildNumberList', '3': 16, '4': 1, '5': 9, '10': 'buildNumberList'},
    {'1': 'luciBucket', '3': 18, '4': 1, '5': 9, '10': 'luciBucket'},
    {'1': 'is_test_flaky', '3': 19, '4': 1, '5': 8, '10': 'isTestFlaky'},
  ],
  '9': [
    {'1': 11, '2': 12},
    {'1': 12, '2': 13},
    {'1': 17, '2': 18},
  ],
};

/// Descriptor for `Task`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List taskDescriptor =
    $convert.base64Decode('CgRUYXNrEiQKA2tleRgBIAEoCzISLmRhc2hib2FyZC5Sb290S2V5UgNrZXkSMQoKY29tbWl0X2'
        'tleRgCIAEoCzISLmRhc2hib2FyZC5Sb290S2V5Ugljb21taXRLZXkSKQoQY3JlYXRlX3RpbWVz'
        'dGFtcBgDIAEoA1IPY3JlYXRlVGltZXN0YW1wEicKD3N0YXJ0X3RpbWVzdGFtcBgEIAEoA1IOc3'
        'RhcnRUaW1lc3RhbXASIwoNZW5kX3RpbWVzdGFtcBgFIAEoA1IMZW5kVGltZXN0YW1wEhIKBG5h'
        'bWUYBiABKAlSBG5hbWUSGgoIYXR0ZW1wdHMYByABKAVSCGF0dGVtcHRzEhkKCGlzX2ZsYWt5GA'
        'ggASgIUgdpc0ZsYWt5EiwKEnRpbWVvdXRfaW5fbWludXRlcxgJIAEoBVIQdGltZW91dEluTWlu'
        'dXRlcxIWCgZyZWFzb24YCiABKAlSBnJlYXNvbhIdCgpzdGFnZV9uYW1lGA0gASgJUglzdGFnZU'
        '5hbWUSFgoGc3RhdHVzGA4gASgJUgZzdGF0dXMSIAoLYnVpbGROdW1iZXIYDyABKAVSC2J1aWxk'
        'TnVtYmVyEigKD2J1aWxkTnVtYmVyTGlzdBgQIAEoCVIPYnVpbGROdW1iZXJMaXN0Eh4KCmx1Y2'
        'lCdWNrZXQYEiABKAlSCmx1Y2lCdWNrZXQSIgoNaXNfdGVzdF9mbGFreRgTIAEoCFILaXNUZXN0'
        'Rmxha3lKBAgLEAxKBAgMEA1KBAgREBI=');
