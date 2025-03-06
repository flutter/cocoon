///
//  Generated code. Do not modify.
//  source: lib/src/model/appengine/key_helper.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields,deprecated_member_use_from_same_package

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pathDescriptor instead')
const Path$json = {
  '1': 'Path',
  '2': [
    {
      '1': 'element',
      '3': 1,
      '4': 3,
      '5': 10,
      '6': '.Path.Element',
      '10': 'element'
    },
  ],
  '3': [Path_Element$json],
};

@$core.Deprecated('Use pathDescriptor instead')
const Path_Element$json = {
  '1': 'Element',
  '2': [
    {'1': 'type', '3': 2, '4': 2, '5': 9, '10': 'type'},
    {'1': 'id', '3': 3, '4': 1, '5': 3, '10': 'id'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `Path`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pathDescriptor = $convert.base64Decode(
    'CgRQYXRoEicKB2VsZW1lbnQYASADKAoyDS5QYXRoLkVsZW1lbnRSB2VsZW1lbnQaQQoHRWxlbWVudBISCgR0eXBlGAIgAigJUgR0eXBlEg4KAmlkGAMgASgDUgJpZBISCgRuYW1lGAQgASgJUgRuYW1l');
@$core.Deprecated('Use referenceDescriptor instead')
const Reference$json = {
  '1': 'Reference',
  '2': [
    {'1': 'app', '3': 13, '4': 2, '5': 9, '10': 'app'},
    {'1': 'name_space', '3': 20, '4': 1, '5': 9, '10': 'nameSpace'},
    {'1': 'path', '3': 14, '4': 2, '5': 11, '6': '.Path', '10': 'path'},
  ],
};

/// Descriptor for `Reference`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List referenceDescriptor = $convert.base64Decode(
    'CglSZWZlcmVuY2USEAoDYXBwGA0gAigJUgNhcHASHQoKbmFtZV9zcGFjZRgUIAEoCVIJbmFtZVNwYWNlEhkKBHBhdGgYDiACKAsyBS5QYXRoUgRwYXRo');
