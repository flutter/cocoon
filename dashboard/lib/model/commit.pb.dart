//
//  Generated code. Do not modify.
//  source: commit.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class Commit extends $pb.GeneratedMessage {
  factory Commit({
    $fixnum.Int64? timestamp,
    $core.String? sha,
    $core.String? author,
    $core.String? authorAvatarUrl,
    $core.String? repository,
    $core.String? branch,
    $core.String? message,
  }) {
    final $result = create();
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (sha != null) {
      $result.sha = sha;
    }
    if (author != null) {
      $result.author = author;
    }
    if (authorAvatarUrl != null) {
      $result.authorAvatarUrl = authorAvatarUrl;
    }
    if (repository != null) {
      $result.repository = repository;
    }
    if (branch != null) {
      $result.branch = branch;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  Commit._() : super();
  factory Commit.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Commit.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Commit',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'dashboard'),
      createEmptyInstance: create)
    ..aInt64(2, _omitFieldNames ? '' : 'timestamp')
    ..aOS(3, _omitFieldNames ? '' : 'sha')
    ..aOS(4, _omitFieldNames ? '' : 'author')
    ..aOS(5, _omitFieldNames ? '' : 'authorAvatarUrl',
        protoName: 'authorAvatarUrl')
    ..aOS(6, _omitFieldNames ? '' : 'repository')
    ..aOS(7, _omitFieldNames ? '' : 'branch')
    ..aOS(8, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Commit clone() => Commit()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Commit copyWith(void Function(Commit) updates) =>
      super.copyWith((message) => updates(message as Commit)) as Commit;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Commit create() => Commit._();
  Commit createEmptyInstance() => create();
  static $pb.PbList<Commit> createRepeated() => $pb.PbList<Commit>();
  @$core.pragma('dart2js:noInline')
  static Commit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Commit>(create);
  static Commit? _defaultInstance;

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(0);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(0, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(0);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sha => $_getSZ(1);
  @$pb.TagNumber(3)
  set sha($core.String v) {
    $_setString(1, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasSha() => $_has(1);
  @$pb.TagNumber(3)
  void clearSha() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(2);
  @$pb.TagNumber(4)
  set author($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(2);
  @$pb.TagNumber(4)
  void clearAuthor() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get authorAvatarUrl => $_getSZ(3);
  @$pb.TagNumber(5)
  set authorAvatarUrl($core.String v) {
    $_setString(3, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAuthorAvatarUrl() => $_has(3);
  @$pb.TagNumber(5)
  void clearAuthorAvatarUrl() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get repository => $_getSZ(4);
  @$pb.TagNumber(6)
  set repository($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRepository() => $_has(4);
  @$pb.TagNumber(6)
  void clearRepository() => clearField(6);

  @$pb.TagNumber(7)
  $core.String get branch => $_getSZ(5);
  @$pb.TagNumber(7)
  set branch($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(7)
  $core.bool hasBranch() => $_has(5);
  @$pb.TagNumber(7)
  void clearBranch() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get message => $_getSZ(6);
  @$pb.TagNumber(8)
  set message($core.String v) {
    $_setString(6, v);
  }

  @$pb.TagNumber(8)
  $core.bool hasMessage() => $_has(6);
  @$pb.TagNumber(8)
  void clearMessage() => clearField(8);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
