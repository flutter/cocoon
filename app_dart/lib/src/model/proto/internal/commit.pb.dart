///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/commit.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core
    show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import 'key.pb.dart' as $0;

class Commit extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Commit')
    ..a<$0.RootKey>(
        1, 'key', $pb.PbFieldType.OM, $0.RootKey.getDefault, $0.RootKey.create)
    ..aInt64(2, 'timestamp')
    ..aOS(3, 'sha')
    ..aOS(4, 'author')
    ..aOS(5, 'authorAvatarUrl')
    ..aOS(6, 'repository')
    ..hasRequiredFields = false;

  Commit._() : super();
  factory Commit() => create();
  factory Commit.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Commit.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);
  Commit clone() => Commit()..mergeFromMessage(this);
  Commit copyWith(void Function(Commit) updates) =>
      super.copyWith((message) => updates(message as Commit));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Commit create() => Commit._();
  Commit createEmptyInstance() => create();
  static $pb.PbList<Commit> createRepeated() => $pb.PbList<Commit>();
  static Commit getDefault() => _defaultInstance ??= create()..freeze();
  static Commit _defaultInstance;

  $0.RootKey get key => $_getN(0);
  set key($0.RootKey v) {
    setField(1, v);
  }

  $core.bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  Int64 get timestamp => $_getI64(1);
  set timestamp(Int64 v) {
    $_setInt64(1, v);
  }

  $core.bool hasTimestamp() => $_has(1);
  void clearTimestamp() => clearField(2);

  $core.String get sha => $_getS(2, '');
  set sha($core.String v) {
    $_setString(2, v);
  }

  $core.bool hasSha() => $_has(2);
  void clearSha() => clearField(3);

  $core.String get author => $_getS(3, '');
  set author($core.String v) {
    $_setString(3, v);
  }

  $core.bool hasAuthor() => $_has(3);
  void clearAuthor() => clearField(4);

  $core.String get authorAvatarUrl => $_getS(4, '');
  set authorAvatarUrl($core.String v) {
    $_setString(4, v);
  }

  $core.bool hasAuthorAvatarUrl() => $_has(4);
  void clearAuthorAvatarUrl() => clearField(5);

  $core.String get repository => $_getS(5, '');
  set repository($core.String v) {
    $_setString(5, v);
  }

  $core.bool hasRepository() => $_has(5);
  void clearRepository() => clearField(6);
}
