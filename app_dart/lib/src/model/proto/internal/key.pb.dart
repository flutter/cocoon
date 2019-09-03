///
//  Generated code. Do not modify.
//  source: lib/src/model/proto/internal/key.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

enum Key_Id {
  uid, 
  name, 
  notSet
}

class Key extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, Key_Id> _Key_IdByTag = {
    2 : Key_Id.uid,
    3 : Key_Id.name,
    0 : Key_Id.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('Key')
    ..oo(0, [2, 3])
    ..aOS(1, 'type')
    ..aInt64(2, 'uid')
    ..aOS(3, 'name')
    ..a<Key>(4, 'child', $pb.PbFieldType.OM, Key.getDefault, Key.create)
    ..hasRequiredFields = false
  ;

  Key._() : super();
  factory Key() => create();
  factory Key.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Key.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  Key clone() => Key()..mergeFromMessage(this);
  Key copyWith(void Function(Key) updates) => super.copyWith((message) => updates(message as Key));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static Key create() => Key._();
  Key createEmptyInstance() => create();
  static $pb.PbList<Key> createRepeated() => $pb.PbList<Key>();
  static Key getDefault() => _defaultInstance ??= create()..freeze();
  static Key _defaultInstance;

  Key_Id whichId() => _Key_IdByTag[$_whichOneof(0)];
  void clearId() => clearField($_whichOneof(0));

  $core.String get type => $_getS(0, '');
  set type($core.String v) { $_setString(0, v); }
  $core.bool hasType() => $_has(0);
  void clearType() => clearField(1);

  Int64 get uid => $_getI64(1);
  set uid(Int64 v) { $_setInt64(1, v); }
  $core.bool hasUid() => $_has(1);
  void clearUid() => clearField(2);

  $core.String get name => $_getS(2, '');
  set name($core.String v) { $_setString(2, v); }
  $core.bool hasName() => $_has(2);
  void clearName() => clearField(3);

  Key get child => $_getN(3);
  set child(Key v) { setField(4, v); }
  $core.bool hasChild() => $_has(3);
  void clearChild() => clearField(4);
}

class RootKey extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('RootKey')
    ..aOS(1, 'namespace')
    ..a<Key>(2, 'child', $pb.PbFieldType.OM, Key.getDefault, Key.create)
    ..hasRequiredFields = false
  ;

  RootKey._() : super();
  factory RootKey() => create();
  factory RootKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RootKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  RootKey clone() => RootKey()..mergeFromMessage(this);
  RootKey copyWith(void Function(RootKey) updates) => super.copyWith((message) => updates(message as RootKey));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static RootKey create() => RootKey._();
  RootKey createEmptyInstance() => create();
  static $pb.PbList<RootKey> createRepeated() => $pb.PbList<RootKey>();
  static RootKey getDefault() => _defaultInstance ??= create()..freeze();
  static RootKey _defaultInstance;

  $core.String get namespace => $_getS(0, '');
  set namespace($core.String v) { $_setString(0, v); }
  $core.bool hasNamespace() => $_has(0);
  void clearNamespace() => clearField(1);

  Key get child => $_getN(1);
  set child(Key v) { setField(2, v); }
  $core.bool hasChild() => $_has(1);
  void clearChild() => clearField(2);
}

