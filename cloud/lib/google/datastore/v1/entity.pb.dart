///
//  Generated code. Do not modify.
//  source: google/datastore/v1/entity.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

import '../../type/latlng.pb.dart' as $0;
import '../../protobuf/timestamp.pb.dart' as $1;

import '../../protobuf/struct.pbenum.dart' as $2;

class PartitionId extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('PartitionId',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(2, 'projectId')
    ..aOS(4, 'namespaceId')
    ..hasRequiredFields = false;

  PartitionId() : super();
  PartitionId.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  PartitionId.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  PartitionId clone() => new PartitionId()..mergeFromMessage(this);
  PartitionId copyWith(void Function(PartitionId) updates) =>
      super.copyWith((message) => updates(message as PartitionId));
  $pb.BuilderInfo get info_ => _i;
  static PartitionId create() => new PartitionId();
  static $pb.PbList<PartitionId> createRepeated() =>
      new $pb.PbList<PartitionId>();
  static PartitionId getDefault() => _defaultInstance ??= create()..freeze();
  static PartitionId _defaultInstance;
  static void $checkItem(PartitionId v) {
    if (v is! PartitionId) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get projectId => $_getS(0, '');
  set projectId(String v) {
    $_setString(0, v);
  }

  bool hasProjectId() => $_has(0);
  void clearProjectId() => clearField(2);

  String get namespaceId => $_getS(1, '');
  set namespaceId(String v) {
    $_setString(1, v);
  }

  bool hasNamespaceId() => $_has(1);
  void clearNamespaceId() => clearField(4);
}

class Key_PathElement extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Key.PathElement',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(1, 'kind')
    ..aInt64(2, 'id')
    ..aOS(3, 'name')
    ..hasRequiredFields = false;

  Key_PathElement() : super();
  Key_PathElement.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Key_PathElement.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Key_PathElement clone() => new Key_PathElement()..mergeFromMessage(this);
  Key_PathElement copyWith(void Function(Key_PathElement) updates) =>
      super.copyWith((message) => updates(message as Key_PathElement));
  $pb.BuilderInfo get info_ => _i;
  static Key_PathElement create() => new Key_PathElement();
  static $pb.PbList<Key_PathElement> createRepeated() =>
      new $pb.PbList<Key_PathElement>();
  static Key_PathElement getDefault() =>
      _defaultInstance ??= create()..freeze();
  static Key_PathElement _defaultInstance;
  static void $checkItem(Key_PathElement v) {
    if (v is! Key_PathElement) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get kind => $_getS(0, '');
  set kind(String v) {
    $_setString(0, v);
  }

  bool hasKind() => $_has(0);
  void clearKind() => clearField(1);

  Int64 get id => $_getI64(1);
  set id(Int64 v) {
    $_setInt64(1, v);
  }

  bool hasId() => $_has(1);
  void clearId() => clearField(2);

  String get name => $_getS(2, '');
  set name(String v) {
    $_setString(2, v);
  }

  bool hasName() => $_has(2);
  void clearName() => clearField(3);
}

class Key extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Key',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<PartitionId>(1, 'partitionId', $pb.PbFieldType.OM,
        PartitionId.getDefault, PartitionId.create)
    ..pp<Key_PathElement>(2, 'path', $pb.PbFieldType.PM,
        Key_PathElement.$checkItem, Key_PathElement.create)
    ..hasRequiredFields = false;

  Key() : super();
  Key.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Key.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Key clone() => new Key()..mergeFromMessage(this);
  Key copyWith(void Function(Key) updates) =>
      super.copyWith((message) => updates(message as Key));
  $pb.BuilderInfo get info_ => _i;
  static Key create() => new Key();
  static $pb.PbList<Key> createRepeated() => new $pb.PbList<Key>();
  static Key getDefault() => _defaultInstance ??= create()..freeze();
  static Key _defaultInstance;
  static void $checkItem(Key v) {
    if (v is! Key) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  PartitionId get partitionId => $_getN(0);
  set partitionId(PartitionId v) {
    setField(1, v);
  }

  bool hasPartitionId() => $_has(0);
  void clearPartitionId() => clearField(1);

  List<Key_PathElement> get path => $_getList(1);
}

class ArrayValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('ArrayValue',
      package: const $pb.PackageName('google.datastore.v1'))
    ..pp<Value>(1, 'values', $pb.PbFieldType.PM, Value.$checkItem, Value.create)
    ..hasRequiredFields = false;

  ArrayValue() : super();
  ArrayValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  ArrayValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  ArrayValue clone() => new ArrayValue()..mergeFromMessage(this);
  ArrayValue copyWith(void Function(ArrayValue) updates) =>
      super.copyWith((message) => updates(message as ArrayValue));
  $pb.BuilderInfo get info_ => _i;
  static ArrayValue create() => new ArrayValue();
  static $pb.PbList<ArrayValue> createRepeated() =>
      new $pb.PbList<ArrayValue>();
  static ArrayValue getDefault() => _defaultInstance ??= create()..freeze();
  static ArrayValue _defaultInstance;
  static void $checkItem(ArrayValue v) {
    if (v is! ArrayValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<Value> get values => $_getList(0);
}

class Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Value',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOB(1, 'booleanValue')
    ..aInt64(2, 'integerValue')
    ..a<double>(3, 'doubleValue', $pb.PbFieldType.OD)
    ..a<Key>(5, 'keyValue', $pb.PbFieldType.OM, Key.getDefault, Key.create)
    ..a<Entity>(
        6, 'entityValue', $pb.PbFieldType.OM, Entity.getDefault, Entity.create)
    ..a<$0.LatLng>(8, 'geoPointValue', $pb.PbFieldType.OM, $0.LatLng.getDefault,
        $0.LatLng.create)
    ..a<ArrayValue>(9, 'arrayValue', $pb.PbFieldType.OM, ArrayValue.getDefault,
        ArrayValue.create)
    ..a<$1.Timestamp>(10, 'timestampValue', $pb.PbFieldType.OM,
        $1.Timestamp.getDefault, $1.Timestamp.create)
    ..e<$2.NullValue>(11, 'nullValue', $pb.PbFieldType.OE,
        $2.NullValue.NULL_VALUE, $2.NullValue.valueOf, $2.NullValue.values)
    ..a<int>(14, 'meaning', $pb.PbFieldType.O3)
    ..aOS(17, 'stringValue')
    ..a<List<int>>(18, 'blobValue', $pb.PbFieldType.OY)
    ..aOB(19, 'excludeFromIndexes')
    ..hasRequiredFields = false;

  Value() : super();
  Value.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Value.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Value clone() => new Value()..mergeFromMessage(this);
  Value copyWith(void Function(Value) updates) =>
      super.copyWith((message) => updates(message as Value));
  $pb.BuilderInfo get info_ => _i;
  static Value create() => new Value();
  static $pb.PbList<Value> createRepeated() => new $pb.PbList<Value>();
  static Value getDefault() => _defaultInstance ??= create()..freeze();
  static Value _defaultInstance;
  static void $checkItem(Value v) {
    if (v is! Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  bool get booleanValue => $_get(0, false);
  set booleanValue(bool v) {
    $_setBool(0, v);
  }

  bool hasBooleanValue() => $_has(0);
  void clearBooleanValue() => clearField(1);

  Int64 get integerValue => $_getI64(1);
  set integerValue(Int64 v) {
    $_setInt64(1, v);
  }

  bool hasIntegerValue() => $_has(1);
  void clearIntegerValue() => clearField(2);

  double get doubleValue => $_getN(2);
  set doubleValue(double v) {
    $_setDouble(2, v);
  }

  bool hasDoubleValue() => $_has(2);
  void clearDoubleValue() => clearField(3);

  Key get keyValue => $_getN(3);
  set keyValue(Key v) {
    setField(5, v);
  }

  bool hasKeyValue() => $_has(3);
  void clearKeyValue() => clearField(5);

  Entity get entityValue => $_getN(4);
  set entityValue(Entity v) {
    setField(6, v);
  }

  bool hasEntityValue() => $_has(4);
  void clearEntityValue() => clearField(6);

  $0.LatLng get geoPointValue => $_getN(5);
  set geoPointValue($0.LatLng v) {
    setField(8, v);
  }

  bool hasGeoPointValue() => $_has(5);
  void clearGeoPointValue() => clearField(8);

  ArrayValue get arrayValue => $_getN(6);
  set arrayValue(ArrayValue v) {
    setField(9, v);
  }

  bool hasArrayValue() => $_has(6);
  void clearArrayValue() => clearField(9);

  $1.Timestamp get timestampValue => $_getN(7);
  set timestampValue($1.Timestamp v) {
    setField(10, v);
  }

  bool hasTimestampValue() => $_has(7);
  void clearTimestampValue() => clearField(10);

  $2.NullValue get nullValue => $_getN(8);
  set nullValue($2.NullValue v) {
    setField(11, v);
  }

  bool hasNullValue() => $_has(8);
  void clearNullValue() => clearField(11);

  int get meaning => $_get(9, 0);
  set meaning(int v) {
    $_setSignedInt32(9, v);
  }

  bool hasMeaning() => $_has(9);
  void clearMeaning() => clearField(14);

  String get stringValue => $_getS(10, '');
  set stringValue(String v) {
    $_setString(10, v);
  }

  bool hasStringValue() => $_has(10);
  void clearStringValue() => clearField(17);

  List<int> get blobValue => $_getN(11);
  set blobValue(List<int> v) {
    $_setBytes(11, v);
  }

  bool hasBlobValue() => $_has(11);
  void clearBlobValue() => clearField(18);

  bool get excludeFromIndexes => $_get(12, false);
  set excludeFromIndexes(bool v) {
    $_setBool(12, v);
  }

  bool hasExcludeFromIndexes() => $_has(12);
  void clearExcludeFromIndexes() => clearField(19);
}

class Entity_PropertiesEntry extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo(
      'Entity.PropertiesEntry',
      package: const $pb.PackageName('google.datastore.v1'))
    ..aOS(1, 'key')
    ..a<Value>(2, 'value', $pb.PbFieldType.OM, Value.getDefault, Value.create)
    ..hasRequiredFields = false;

  Entity_PropertiesEntry() : super();
  Entity_PropertiesEntry.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Entity_PropertiesEntry.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Entity_PropertiesEntry clone() =>
      new Entity_PropertiesEntry()..mergeFromMessage(this);
  Entity_PropertiesEntry copyWith(
          void Function(Entity_PropertiesEntry) updates) =>
      super.copyWith((message) => updates(message as Entity_PropertiesEntry));
  $pb.BuilderInfo get info_ => _i;
  static Entity_PropertiesEntry create() => new Entity_PropertiesEntry();
  static $pb.PbList<Entity_PropertiesEntry> createRepeated() =>
      new $pb.PbList<Entity_PropertiesEntry>();
  static Entity_PropertiesEntry getDefault() =>
      _defaultInstance ??= create()..freeze();
  static Entity_PropertiesEntry _defaultInstance;
  static void $checkItem(Entity_PropertiesEntry v) {
    if (v is! Entity_PropertiesEntry)
      $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get key => $_getS(0, '');
  set key(String v) {
    $_setString(0, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  Value get value => $_getN(1);
  set value(Value v) {
    setField(2, v);
  }

  bool hasValue() => $_has(1);
  void clearValue() => clearField(2);
}

class Entity extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Entity',
      package: const $pb.PackageName('google.datastore.v1'))
    ..a<Key>(1, 'key', $pb.PbFieldType.OM, Key.getDefault, Key.create)
    ..pp<Entity_PropertiesEntry>(3, 'properties', $pb.PbFieldType.PM,
        Entity_PropertiesEntry.$checkItem, Entity_PropertiesEntry.create)
    ..hasRequiredFields = false;

  Entity() : super();
  Entity.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Entity.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Entity clone() => new Entity()..mergeFromMessage(this);
  Entity copyWith(void Function(Entity) updates) =>
      super.copyWith((message) => updates(message as Entity));
  $pb.BuilderInfo get info_ => _i;
  static Entity create() => new Entity();
  static $pb.PbList<Entity> createRepeated() => new $pb.PbList<Entity>();
  static Entity getDefault() => _defaultInstance ??= create()..freeze();
  static Entity _defaultInstance;
  static void $checkItem(Entity v) {
    if (v is! Entity) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  Key get key => $_getN(0);
  set key(Key v) {
    setField(1, v);
  }

  bool hasKey() => $_has(0);
  void clearKey() => clearField(1);

  List<Entity_PropertiesEntry> get properties => $_getList(1);
}
