//
//  Generated code. Do not modify.
//  source: lib/model/branch.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use branchDescriptor instead')
const Branch$json = {
  '1': 'Branch',
  '2': [
    {'1': 'branch', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'branch', '17': true},
    {'1': 'repository', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'repository', '17': true},
    {'1': 'channel', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'channel', '17': true},
    {'1': 'lastActivity', '3': 4, '4': 1, '5': 3, '9': 3, '10': 'lastActivity', '17': true},
  ],
  '8': [
    {'1': '_branch'},
    {'1': '_repository'},
    {'1': '_channel'},
    {'1': '_lastActivity'},
  ],
};

/// Descriptor for `Branch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List branchDescriptor =
    $convert.base64Decode('CgZCcmFuY2gSGwoGYnJhbmNoGAEgASgJSABSBmJyYW5jaIgBARIjCgpyZXBvc2l0b3J5GAIgAS'
        'gJSAFSCnJlcG9zaXRvcnmIAQESHQoHY2hhbm5lbBgDIAEoCUgCUgdjaGFubmVsiAEBEicKDGxh'
        'c3RBY3Rpdml0eRgEIAEoA0gDUgxsYXN0QWN0aXZpdHmIAQFCCQoHX2JyYW5jaEINCgtfcmVwb3'
        'NpdG9yeUIKCghfY2hhbm5lbEIPCg1fbGFzdEFjdGl2aXR5');
