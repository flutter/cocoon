//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/test_result.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Machine-readable status of a test result.
class TestStatus extends $pb.ProtobufEnum {
  static const TestStatus STATUS_UNSPECIFIED =
      TestStatus._(0, _omitEnumNames ? '' : 'STATUS_UNSPECIFIED');
  static const TestStatus PASS = TestStatus._(1, _omitEnumNames ? '' : 'PASS');
  static const TestStatus FAIL = TestStatus._(2, _omitEnumNames ? '' : 'FAIL');
  static const TestStatus CRASH =
      TestStatus._(3, _omitEnumNames ? '' : 'CRASH');
  static const TestStatus ABORT =
      TestStatus._(4, _omitEnumNames ? '' : 'ABORT');
  static const TestStatus SKIP = TestStatus._(5, _omitEnumNames ? '' : 'SKIP');

  static const $core.List<TestStatus> values = <TestStatus>[
    STATUS_UNSPECIFIED,
    PASS,
    FAIL,
    CRASH,
    ABORT,
    SKIP,
  ];

  static final $core.Map<$core.int, TestStatus> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static TestStatus? valueOf($core.int value) => _byValue[value];

  const TestStatus._($core.int v, $core.String n) : super(v, n);
}

/// Machine-readable reason that a test execution was skipped.
/// Only reasons actually used are listed here, if you need a new reason
/// please add it here and send a CL to the OWNERS.
class SkipReason extends $pb.ProtobufEnum {
  static const SkipReason SKIP_REASON_UNSPECIFIED =
      SkipReason._(0, _omitEnumNames ? '' : 'SKIP_REASON_UNSPECIFIED');
  static const SkipReason AUTOMATICALLY_DISABLED_FOR_FLAKINESS = SkipReason._(
      1, _omitEnumNames ? '' : 'AUTOMATICALLY_DISABLED_FOR_FLAKINESS');

  static const $core.List<SkipReason> values = <SkipReason>[
    SKIP_REASON_UNSPECIFIED,
    AUTOMATICALLY_DISABLED_FOR_FLAKINESS,
  ];

  static final $core.Map<$core.int, SkipReason> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static SkipReason? valueOf($core.int value) => _byValue[value];

  const SkipReason._($core.int v, $core.String n) : super(v, n);
}

/// Reason why a test variant was exonerated.
class ExonerationReason extends $pb.ProtobufEnum {
  static const ExonerationReason EXONERATION_REASON_UNSPECIFIED =
      ExonerationReason._(
          0, _omitEnumNames ? '' : 'EXONERATION_REASON_UNSPECIFIED');
  static const ExonerationReason OCCURS_ON_MAINLINE =
      ExonerationReason._(1, _omitEnumNames ? '' : 'OCCURS_ON_MAINLINE');
  static const ExonerationReason OCCURS_ON_OTHER_CLS =
      ExonerationReason._(2, _omitEnumNames ? '' : 'OCCURS_ON_OTHER_CLS');
  static const ExonerationReason NOT_CRITICAL =
      ExonerationReason._(3, _omitEnumNames ? '' : 'NOT_CRITICAL');
  static const ExonerationReason UNEXPECTED_PASS =
      ExonerationReason._(4, _omitEnumNames ? '' : 'UNEXPECTED_PASS');

  static const $core.List<ExonerationReason> values = <ExonerationReason>[
    EXONERATION_REASON_UNSPECIFIED,
    OCCURS_ON_MAINLINE,
    OCCURS_ON_OTHER_CLS,
    NOT_CRITICAL,
    UNEXPECTED_PASS,
  ];

  static final $core.Map<$core.int, ExonerationReason> _byValue =
      $pb.ProtobufEnum.initByValue(values);
  static ExonerationReason? valueOf($core.int value) => _byValue[value];

  const ExonerationReason._($core.int v, $core.String n) : super(v, n);
}

const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
