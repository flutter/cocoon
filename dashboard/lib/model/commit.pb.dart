///
//  Generated code. Do not modify.
//  source: lib/model/commit.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,unnecessary_const,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type,unnecessary_this,prefer_final_fields

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Commit extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      const $core.bool.fromEnvironment('protobuf.omit_message_names')
          ? ''
          : 'Commit',
      createEmptyInstance: create)
    ..aOM<$0.RootKey>(
        1,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'key',
        subBuilder: $0.RootKey.create)
    ..aInt64(
        2,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'timestamp')
    ..aOS(
        3,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'sha')
    ..aOS(
        4,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'author')
    ..aOS(
        5,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'authorAvatarUrl',
        protoName: 'authorAvatarUrl')
    ..aOS(
        6,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'repository')
    ..aOS(
        7,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'branch')
    ..aOS(
        8,
        const $core.bool.fromEnvironment('protobuf.omit_field_names')
            ? ''
            : 'message')
    ..hasRequiredFields = false;

  Commit._() : super();
  factory Commit({
    $0.RootKey? key,
    $fixnum.Int64? timestamp,
    $core.String? sha,
    $core.String? author,
    $core.String? authorAvatarUrl,
    $core.String? repository,
    $core.String? branch,
    $core.String? message,
  }) {
    final _result = create();
    if (key != null) {
      _result.key = key;
    }
    if (timestamp != null) {
      _result.timestamp = timestamp;
    }
    if (sha != null) {
      _result.sha = sha;
    }
    if (author != null) {
      _result.author = author;
    }
    if (authorAvatarUrl != null) {
      _result.authorAvatarUrl = authorAvatarUrl;
    }
    if (repository != null) {
      _result.repository = repository;
    }
    if (branch != null) {
      _result.branch = branch;
    }
    if (message != null) {
      _result.message = message;
    }
    return _result;
  }
  factory Commit.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Commit.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Commit clone() => Commit()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Commit copyWith(void Function(Commit) updates) =>
      super.copyWith((message) => updates(message as Commit))
          as Commit; // ignore: deprecated_member_use
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Commit create() => Commit._();
  Commit createEmptyInstance() => create();
  static $pb.PbList<Commit> createRepeated() => $pb.PbList<Commit>();
  @$core.pragma('dart2js:noInline')
  static Commit getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Commit>(create);
  static Commit? _defaultInstance;

  @$pb.TagNumber(1)
  $0.RootKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($0.RootKey v) {
    setField(1, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
  @$pb.TagNumber(1)
  $0.RootKey ensureKey() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

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
  $core.String get authorAvatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set authorAvatarUrl($core.String v) {
    $_setString(4, v);
  }

  @$pb.TagNumber(5)
  $core.bool hasAuthorAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearAuthorAvatarUrl() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get repository => $_getSZ(5);
  @$pb.TagNumber(6)
  set repository($core.String v) {
    $_setString(5, v);
  }

  @$pb.TagNumber(6)
  $core.bool hasRepository() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepository() => clearField(6);

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
