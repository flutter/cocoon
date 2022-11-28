///
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/predicate.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

// ignore_for_file: UNDEFINED_SHOWN_NAME
import 'dart:core' as $core;
import 'package:protobuf/protobuf.dart' as $pb;

class TestResultPredicate_Expectancy extends $pb.ProtobufEnum {
  static const TestResultPredicate_Expectancy ALL = TestResultPredicate_Expectancy._(0, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'ALL');
  static const TestResultPredicate_Expectancy VARIANTS_WITH_UNEXPECTED_RESULTS = TestResultPredicate_Expectancy._(1, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VARIANTS_WITH_UNEXPECTED_RESULTS');
  static const TestResultPredicate_Expectancy VARIANTS_WITH_ONLY_UNEXPECTED_RESULTS = TestResultPredicate_Expectancy._(2, const $core.bool.fromEnvironment('protobuf.omit_enum_names') ? '' : 'VARIANTS_WITH_ONLY_UNEXPECTED_RESULTS');

  static const $core.List<TestResultPredicate_Expectancy> values = <TestResultPredicate_Expectancy> [
    ALL,
    VARIANTS_WITH_UNEXPECTED_RESULTS,
    VARIANTS_WITH_ONLY_UNEXPECTED_RESULTS,
  ];

  static final $core.Map<$core.int, TestResultPredicate_Expectancy> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TestResultPredicate_Expectancy? valueOf($core.int value) => _byValue[value];

  const TestResultPredicate_Expectancy._($core.int v, $core.String n) : super(v, n);
}

