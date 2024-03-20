//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/sink/proto/v1/test_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// A result file format.
class TestResultFile_Format extends $pb.ProtobufEnum {
  static const TestResultFile_Format LUCI = TestResultFile_Format._(0, _omitEnumNames ? '' : 'LUCI');
  static const TestResultFile_Format CHROMIUM_JSON_TEST_RESULTS = TestResultFile_Format._(1, _omitEnumNames ? '' : 'CHROMIUM_JSON_TEST_RESULTS');
  static const TestResultFile_Format GOOGLE_TEST = TestResultFile_Format._(2, _omitEnumNames ? '' : 'GOOGLE_TEST');

  static const $core.List<TestResultFile_Format> values = <TestResultFile_Format> [
    LUCI,
    CHROMIUM_JSON_TEST_RESULTS,
    GOOGLE_TEST,
  ];

  static final $core.Map<$core.int, TestResultFile_Format> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TestResultFile_Format? valueOf($core.int value) => _byValue[value];

  const TestResultFile_Format._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
