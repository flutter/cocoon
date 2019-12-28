///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/commit.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Commit extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Commit', createEmptyInstance: create)
    ..aOM<$0.RootKey>(1, 'key', subBuilder: $0.RootKey.create)
    ..aInt64(2, 'timestamp')
    ..aOS(3, 'sha')
    ..aOS(4, 'author')
    ..aOS(5, 'authorAvatarUrl', protoName: 'authorAvatarUrl')
    ..aOS(6, 'repository')
    ..hasRequiredFields = false
  ;

  Commit._() : super();
  factory Commit() => create();
  factory Commit.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Commit.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Commit clone() => Commit()..mergeFromMessage(this);
  Commit copyWith(void Function(Commit) updates) => super.copyWith((message) => updates(message as Commit));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Commit create() => Commit._();
  Commit createEmptyInstance() => create();
  static $pb.PbList<Commit> createRepeated() => $pb.PbList<Commit>();
  @$core.pragma('dart2js:noInline')
  static Commit getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Commit>(create);
  static Commit _defaultInstance;

  @$pb.TagNumber(1)
  $0.RootKey get key => $_getN(0);
  @$pb.TagNumber(1)
  set key($0.RootKey v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => clearField(1);
  @$pb.TagNumber(1)
  $0.RootKey ensureKey() => $_ensure(0);

  @$pb.TagNumber(2)
  $fixnum.Int64 get timestamp => $_getI64(1);
  @$pb.TagNumber(2)
  set timestamp($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTimestamp() => $_has(1);
  @$pb.TagNumber(2)
  void clearTimestamp() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sha => $_getSZ(2);
  @$pb.TagNumber(3)
  set sha($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSha() => $_has(2);
  @$pb.TagNumber(3)
  void clearSha() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get author => $_getSZ(3);
  @$pb.TagNumber(4)
  set author($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAuthor() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthor() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get authorAvatarUrl => $_getSZ(4);
  @$pb.TagNumber(5)
  set authorAvatarUrl($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAuthorAvatarUrl() => $_has(4);
  @$pb.TagNumber(5)
  void clearAuthorAvatarUrl() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get repository => $_getSZ(5);
  @$pb.TagNumber(6)
  set repository($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasRepository() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepository() => clearField(6);
}

