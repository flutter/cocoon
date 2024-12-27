//
//  Generated code. Do not modify.
//  source: internal/key.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

enum Key_Id { uid, name, notSet }

class Key extends $pb.GeneratedMessage {
  factory Key({
    $core.String? type,
    $fixnum.Int64? uid,
    $core.String? name,
    Key? child,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (uid != null) {
      $result.uid = uid;
    }
    if (name != null) {
      $result.name = name;
    }
    if (child != null) {
      $result.child = child;
    }
    return $result;
  }
  Key._() : super();
  factory Key.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory Key.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Key_Id> _Key_IdByTag = {2: Key_Id.uid, 3: Key_Id.name, 0: Key_Id.notSet};
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Key',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cocoon'), createEmptyInstance: create)
    ..oo(0, [2, 3])
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aInt64(2, _omitFieldNames ? '' : 'uid')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOM<Key>(4, _omitFieldNames ? '' : 'child', subBuilder: Key.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  Key clone() => Key()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  Key copyWith(void Function(Key) updates) => super.copyWith((message) => updates(message as Key)) as Key;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Key create() => Key._();
  Key createEmptyInstance() => create();
  static $pb.PbList<Key> createRepeated() => $pb.PbList<Key>();
  @$core.pragma('dart2js:noInline')
  static Key getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Key>(create);
  static Key? _defaultInstance;

  Key_Id whichId() => _Key_IdByTag[$_whichOneof(0)]!;
  void clearId() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get uid => $_getI64(1);
  @$pb.TagNumber(2)
  set uid($fixnum.Int64 v) {
    $_setInt64(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasUid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUid() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) {
    $_setString(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  @$pb.TagNumber(4)
  Key get child => $_getN(3);
  @$pb.TagNumber(4)
  set child(Key v) {
    setField(4, v);
  }

  @$pb.TagNumber(4)
  $core.bool hasChild() => $_has(3);
  @$pb.TagNumber(4)
  void clearChild() => clearField(4);
  @$pb.TagNumber(4)
  Key ensureChild() => $_ensure(3);
}

class RootKey extends $pb.GeneratedMessage {
  factory RootKey({
    $core.String? namespace,
    Key? child,
  }) {
    final $result = create();
    if (namespace != null) {
      $result.namespace = namespace;
    }
    if (child != null) {
      $result.child = child;
    }
    return $result;
  }
  RootKey._() : super();
  factory RootKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory RootKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RootKey',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'cocoon'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'namespace')
    ..aOM<Key>(2, _omitFieldNames ? '' : 'child', subBuilder: Key.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  RootKey clone() => RootKey()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  RootKey copyWith(void Function(RootKey) updates) =>
      super.copyWith((message) => updates(message as RootKey)) as RootKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RootKey create() => RootKey._();
  RootKey createEmptyInstance() => create();
  static $pb.PbList<RootKey> createRepeated() => $pb.PbList<RootKey>();
  @$core.pragma('dart2js:noInline')
  static RootKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RootKey>(create);
  static RootKey? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get namespace => $_getSZ(0);
  @$pb.TagNumber(1)
  set namespace($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasNamespace() => $_has(0);
  @$pb.TagNumber(1)
  void clearNamespace() => clearField(1);

  @$pb.TagNumber(2)
  Key get child => $_getN(1);
  @$pb.TagNumber(2)
  set child(Key v) {
    setField(2, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasChild() => $_has(1);
  @$pb.TagNumber(2)
  void clearChild() => clearField(2);
  @$pb.TagNumber(2)
  Key ensureChild() => $_ensure(1);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
