//
//  Generated code. Do not modify.
//  source: go.chromium.org/luci/resultdb/proto/v1/failure_reason.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// Error represents a problem that caused a test to fail, such as a crash
/// or expectation failure.
class FailureReason_Error extends $pb.GeneratedMessage {
  factory FailureReason_Error({
    $core.String? message,
  }) {
    final $result = create();
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  FailureReason_Error._() : super();
  factory FailureReason_Error.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FailureReason_Error.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FailureReason.Error',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FailureReason_Error clone() => FailureReason_Error()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FailureReason_Error copyWith(void Function(FailureReason_Error) updates) =>
      super.copyWith((message) => updates(message as FailureReason_Error)) as FailureReason_Error;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FailureReason_Error create() => FailureReason_Error._();
  FailureReason_Error createEmptyInstance() => create();
  static $pb.PbList<FailureReason_Error> createRepeated() => $pb.PbList<FailureReason_Error>();
  @$core.pragma('dart2js:noInline')
  static FailureReason_Error getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FailureReason_Error>(create);
  static FailureReason_Error? _defaultInstance;

  ///  The error message. This should only be the error message and
  ///  should not include any stack traces. An example would be the
  ///  message from an Exception in a Java test.
  ///
  ///  This message may be used to cluster related failures together.
  ///
  ///  The size of the message must be equal to or smaller than 1024 bytes in
  ///  UTF-8.
  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => clearField(1);
}

/// Information about why a test failed. This information may be displayed
/// to developers in result viewing UIs and will also be used to cluster
/// similar failures together.
/// For example, this will contain assertion failure messages and stack traces.
class FailureReason extends $pb.GeneratedMessage {
  factory FailureReason({
    $core.String? primaryErrorMessage,
    $core.Iterable<FailureReason_Error>? errors,
    $core.int? truncatedErrorsCount,
  }) {
    final $result = create();
    if (primaryErrorMessage != null) {
      $result.primaryErrorMessage = primaryErrorMessage;
    }
    if (errors != null) {
      $result.errors.addAll(errors);
    }
    if (truncatedErrorsCount != null) {
      $result.truncatedErrorsCount = truncatedErrorsCount;
    }
    return $result;
  }
  FailureReason._() : super();
  factory FailureReason.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory FailureReason.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FailureReason',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'luci.resultdb.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'primaryErrorMessage')
    ..pc<FailureReason_Error>(2, _omitFieldNames ? '' : 'errors', $pb.PbFieldType.PM,
        subBuilder: FailureReason_Error.create)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'truncatedErrorsCount', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  FailureReason clone() => FailureReason()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  FailureReason copyWith(void Function(FailureReason) updates) =>
      super.copyWith((message) => updates(message as FailureReason)) as FailureReason;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FailureReason create() => FailureReason._();
  FailureReason createEmptyInstance() => create();
  static $pb.PbList<FailureReason> createRepeated() => $pb.PbList<FailureReason>();
  @$core.pragma('dart2js:noInline')
  static FailureReason getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FailureReason>(create);
  static FailureReason? _defaultInstance;

  ///  The error message that ultimately caused the test to fail. This should
  ///  only be the error message and should not include any stack traces.
  ///  An example would be the message from an Exception in a Java test.
  ///  In the case that a test failed due to multiple expectation failures, any
  ///  immediately fatal failure should be chosen, or otherwise the first
  ///  expectation failure.
  ///  If this field is empty, other fields (including those from the TestResult)
  ///  may be used to cluster the failure instead.
  ///
  ///  The size of the message must be equal to or smaller than 1024 bytes in
  ///  UTF-8.
  @$pb.TagNumber(1)
  $core.String get primaryErrorMessage => $_getSZ(0);
  @$pb.TagNumber(1)
  set primaryErrorMessage($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasPrimaryErrorMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrimaryErrorMessage() => clearField(1);

  ///  The error(s) that caused the test to fail.
  ///
  ///  If there is more than one error (e.g. due to multiple expectation failures),
  ///  a stable sorting should be used. A recommended form of stable sorting is:
  ///  - Fatal errors (errors that cause the test to terminate immediately first,
  ///    then
  ///  - Within fatal/non-fatal errors, sort by chronological order
  ///    (earliest error first).
  ///
  ///  Where this field is populated, errors[0].message shall match
  ///  primary_error_message.
  ///
  ///  The total combined size of all errors (as measured by proto.Size()) must
  ///  not exceed 3,172 bytes.
  @$pb.TagNumber(2)
  $core.List<FailureReason_Error> get errors => $_getList(1);

  /// The number of errors that are truncated from the errors list above due to
  /// the size limits.
  @$pb.TagNumber(3)
  $core.int get truncatedErrorsCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set truncatedErrorsCount($core.int v) {
    $_setSignedInt32(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasTruncatedErrorsCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearTruncatedErrorsCount() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
