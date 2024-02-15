//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/buildbucket/proto/step.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use stepDescriptor instead')
const Step$json = {
  '1': 'Step',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'start_time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'startTime'},
    {'1': 'end_time', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'endTime'},
    {'1': 'status', '3': 4, '4': 1, '5': 14, '6': '.buildbucket.v2.Status', '10': 'status'},
    {'1': 'logs', '3': 5, '4': 3, '5': 11, '6': '.buildbucket.v2.Log', '10': 'logs'},
    {'1': 'merge_build', '3': 6, '4': 1, '5': 11, '6': '.buildbucket.v2.Step.MergeBuild', '10': 'mergeBuild'},
    {'1': 'summary_markdown', '3': 7, '4': 1, '5': 9, '10': 'summaryMarkdown'},
    {'1': 'tags', '3': 8, '4': 3, '5': 11, '6': '.buildbucket.v2.StringPair', '10': 'tags'},
  ],
  '3': [Step_MergeBuild$json],
};

@$core.Deprecated('Use stepDescriptor instead')
const Step_MergeBuild$json = {
  '1': 'MergeBuild',
  '2': [
    {'1': 'from_logdog_stream', '3': 1, '4': 1, '5': 9, '10': 'fromLogdogStream'},
    {'1': 'legacy_global_namespace', '3': 2, '4': 1, '5': 8, '10': 'legacyGlobalNamespace'},
  ],
};

/// Descriptor for `Step`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stepDescriptor = $convert.base64Decode(
    'CgRTdGVwEhIKBG5hbWUYASABKAlSBG5hbWUSOQoKc3RhcnRfdGltZRgCIAEoCzIaLmdvb2dsZS'
    '5wcm90b2J1Zi5UaW1lc3RhbXBSCXN0YXJ0VGltZRI1CghlbmRfdGltZRgDIAEoCzIaLmdvb2ds'
    'ZS5wcm90b2J1Zi5UaW1lc3RhbXBSB2VuZFRpbWUSLgoGc3RhdHVzGAQgASgOMhYuYnVpbGRidW'
    'NrZXQudjIuU3RhdHVzUgZzdGF0dXMSJwoEbG9ncxgFIAMoCzITLmJ1aWxkYnVja2V0LnYyLkxv'
    'Z1IEbG9ncxJACgttZXJnZV9idWlsZBgGIAEoCzIfLmJ1aWxkYnVja2V0LnYyLlN0ZXAuTWVyZ2'
    'VCdWlsZFIKbWVyZ2VCdWlsZBIpChBzdW1tYXJ5X21hcmtkb3duGAcgASgJUg9zdW1tYXJ5TWFy'
    'a2Rvd24SLgoEdGFncxgIIAMoCzIaLmJ1aWxkYnVja2V0LnYyLlN0cmluZ1BhaXJSBHRhZ3Macg'
    'oKTWVyZ2VCdWlsZBIsChJmcm9tX2xvZ2RvZ19zdHJlYW0YASABKAlSEGZyb21Mb2dkb2dTdHJl'
    'YW0SNgoXbGVnYWN5X2dsb2JhbF9uYW1lc3BhY2UYAiABKAhSFWxlZ2FjeUdsb2JhbE5hbWVzcG'
    'FjZQ==');

