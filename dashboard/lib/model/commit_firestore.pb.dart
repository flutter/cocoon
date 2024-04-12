//
//  Generated code. Do not modify.
//  source: lib/model/commit_firestore.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class CommitDocument extends $pb.GeneratedMessage {
  factory CommitDocument({
    $core.String? documentName,
    $fixnum.Int64? createTimestamp,
    $core.String? sha,
    $core.String? author,
    $core.String? avatar,
    $core.String? repositoryPath,
    $core.String? branch,
    $core.String? message,
  }) {
    final $result = create();
    if (documentName != null) {
      $result.documentName = documentName;
    }
    if (createTimestamp != null) {
      $result.createTimestamp = createTimestamp;
    }
    if (sha != null) {
      $result.sha = sha;
    }
    if (author != null) {
      $result.author = author;
    }
    if (avatar != null) {
      $result.avatar = avatar;
    }
    if (repositoryPath != null) {
      $result.repositoryPath = repositoryPath;
    }
    if (branch != null) {
      $result.branch = branch;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  CommitDocument._() : super();
  factory CommitDocument.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory CommitDocument.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CommitDocument',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'documentName', protoName: 'documentName')
    ..aInt64(2, _omitFieldNames ? '' : 'createTimestamp', protoName: 'createTimestamp')
    ..aOS(3, _omitFieldNames ? '' : 'sha')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOS(5, _omitFieldNames ? '' : 'avatar')
    ..aOS(6, _omitFieldNames ? '' : 'repositoryPath', protoName: 'repositoryPath')
    ..aOS(7, _omitFieldNames ? '' : 'branch')
    ..aOS(8, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  CommitDocument clone() => CommitDocument()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  CommitDocument copyWith(void Function(CommitDocument) updates) =>
      super.copyWith((message) => updates(message as CommitDocument)) as CommitDocument;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CommitDocument create() => CommitDocument._();
  CommitDocument createEmptyInstance() => create();
  static $pb.PbList<CommitDocument> createRepeated() => $pb.PbList<CommitDocument>();
  @$core.pragma('dart2js:noInline')
  static CommitDocument getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CommitDocument>(create);
  static CommitDocument? _defaultInstance;

  /// Next ID: 9
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
  $core.String get sha => $_getSZ(2);
  @$pb.TagNumber(3)
  set sha($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSha() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get avatar => $_getSZ(4);
  @$pb.TagNumber(5)
  set avatar($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAvatar() => $_has(4);
  @$pb.TagNumber(5)
  void clearAvatar() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get repositoryPath => $_getSZ(5);
  @$pb.TagNumber(6)
  set repositoryPath($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRepositoryPath() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepositoryPath() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get branch => $_getSZ(6);
  @$pb.TagNumber(7)
  set branch($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBranch() => $_has(6);
  @$pb.TagNumber(7)
  void clearBranch() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get message => $_getSZ(7);
  @$pb.TagNumber(8)
  set message($core.String v) {
    $_setString(7, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasMessage() => $_has(7);
  @$pb.TagNumber(8)
  void clearMessage() => clearField(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
