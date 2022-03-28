///
//  Generated code. Do not modify.
//  source: lib/model/branch.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use branchDescriptor instead')
const Branch$json = {
  '1': 'Branch',
  '2': [
    {'1': 'branch', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'branch', '17': true},
    {'1': 'repository', '3': 2, '4': 1, '5': 9, '9': 1, '10': 'repository', '17': true},
  ],
  '8': [
    {'1': '_branch'},
    {'1': '_repository'},
  ],
};

/// Descriptor for `Branch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List branchDescriptor = $convert.base64Decode(
    'CgZCcmFuY2gSGwoGYnJhbmNoGAEgASgJSABSBmJyYW5jaIgBARIjCgpyZXBvc2l0b3J5GAIgASgJSAFSCnJlcG9zaXRvcnmIAQFCCQoHX2JyYW5jaEINCgtfcmVwb3NpdG9yeQ==');
