//
//  Generated code. Do not modify.
//  source: lib/model/task_firestore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class TaskDocument extends $pb.GeneratedMessage {
  factory TaskDocument({
    $core.String? documentName,
    $fixnum.Int64? createTimestamp,
    $fixnum.Int64? startTimestamp,
    $fixnum.Int64? endTimestamp,
    $core.String? taskName,
    $core.int? attempts,
    $core.bool? bringup,
    $core.bool? testFlaky,
    $core.int? buildNumber,
    $core.String? status,
    $core.String? buildList,
    $core.String? commitSha,
  }) {
    final $result = create();
    if (documentName != null) {
      $result.documentName = documentName;
    }
    if (createTimestamp != null) {
      $result.createTimestamp = createTimestamp;
    }
    if (startTimestamp != null) {
      $result.startTimestamp = startTimestamp;
    }
    if (endTimestamp != null) {
      $result.endTimestamp = endTimestamp;
    }
    if (taskName != null) {
      $result.taskName = taskName;
    }
    if (attempts != null) {
      $result.attempts = attempts;
    }
    if (bringup != null) {
      $result.bringup = bringup;
    }
    if (testFlaky != null) {
      $result.testFlaky = testFlaky;
    }
    if (buildNumber != null) {
      $result.buildNumber = buildNumber;
    }
    if (status != null) {
      $result.status = status;
    }
    if (buildList != null) {
      $result.buildList = buildList;
    }
    if (commitSha != null) {
      $result.commitSha = commitSha;
    }
    return $result;
  }
  TaskDocument._() : super();
  factory TaskDocument.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TaskDocument.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TaskDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'documentName')
    ..aInt64(2, _omitFieldNames ? '' : 'createTimestamp')
    ..aInt64(3, _omitFieldNames ? '' : 'startTimestamp')
    ..aInt64(4, _omitFieldNames ? '' : 'endTimestamp')
    ..aOS(5, _omitFieldNames ? '' : 'taskName')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'attempts', $pb.PbFieldType.O3)
    ..aOB(7, _omitFieldNames ? '' : 'bringup')
    ..aOB(8, _omitFieldNames ? '' : 'testFlaky')
    ..a<$core.int>(9, _omitFieldNames ? '' : 'buildNumber', $pb.PbFieldType.O3)
    ..aOS(10, _omitFieldNames ? '' : 'status')
    ..aOS(11, _omitFieldNames ? '' : 'buildList')
    ..aOS(12, _omitFieldNames ? '' : 'commitSha')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TaskDocument clone() => TaskDocument()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TaskDocument copyWith(void Function(TaskDocument) updates) =>
      super.copyWith((message) => updates(message as TaskDocument))
          as TaskDocument;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TaskDocument create() => TaskDocument._();
  TaskDocument createEmptyInstance() => create();
  static $pb.PbList<TaskDocument> createRepeated() =>
      $pb.PbList<TaskDocument>();
  @$core.pragma('dart2js:noInline')
  static TaskDocument getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TaskDocument>(create);
  static TaskDocument? _defaultInstance;

  /// Next ID: 13
  @$pb.TagNumber(1)
  $core.String get documentName => $_getSZ(0);
  @$pb.TagNumber(1)
  set documentName($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasDocumentName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDocumentName() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get createTimestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set createTimestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasCreateTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearCreateTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get startTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set startTimestamp($fixnum.Int64 v) {
    $_setInt64(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasStartTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearStartTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get endTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set endTimestamp($fixnum.Int64 v) {
    $_setInt64(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasEndTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearEndTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get taskName => $_getSZ(4);
  @$pb.TagNumber(5)
  set taskName($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasTaskName() => $_has(4);
  @$pb.TagNumber(5)
  void clearTaskName() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get attempts => $_getIZ(5);
  @$pb.TagNumber(6)
  set attempts($core.int v) {
    $_setSignedInt32(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasAttempts() => $_has(5);
  @$pb.TagNumber(6)
  void clearAttempts() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get bringup => $_getBF(6);
  @$pb.TagNumber(7)
  set bringup($core.bool v) {
    $_setBool(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBringup() => $_has(6);
  @$pb.TagNumber(7)
  void clearBringup() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get testFlaky => $_getBF(7);
  @$pb.TagNumber(8)
  set testFlaky($core.bool v) {
    $_setBool(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasTestFlaky() => $_has(7);
  @$pb.TagNumber(8)
  void clearTestFlaky() => clearField(8);

  @$pb.TagNumber(9)
  $core.int get buildNumber => $_getIZ(8);
  @$pb.TagNumber(9)
  set buildNumber($core.int v) {
    $_setSignedInt32(8, v);
  }

  @$pb.TagNumber(9)
  $core.bool hasBuildNumber() => $_has(8);
  @$pb.TagNumber(9)
  void clearBuildNumber() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get status => $_getSZ(9);
  @$pb.TagNumber(10)
  set status($core.String v) {
    $_setString(9, v);
  }

  @$pb.TagNumber(10)
  $core.bool hasStatus() => $_has(9);
  @$pb.TagNumber(10)
  void clearStatus() => clearField(10);

  @$pb.TagNumber(11)
  $core.String get buildList => $_getSZ(10);
  @$pb.TagNumber(11)
  set buildList($core.String v) {
    $_setString(10, v);
  }

  @$pb.TagNumber(11)
  $core.bool hasBuildList() => $_has(10);
  @$pb.TagNumber(11)
  void clearBuildList() => clearField(11);

  @$pb.TagNumber(12)
  $core.String get commitSha => $_getSZ(11);
  @$pb.TagNumber(12)
  set commitSha($core.String v) {
    $_setString(11, v);
  }

  @$pb.TagNumber(12)
  $core.bool hasCommitSha() => $_has(11);
  @$pb.TagNumber(12)
  void clearCommitSha() => clearField(12);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
