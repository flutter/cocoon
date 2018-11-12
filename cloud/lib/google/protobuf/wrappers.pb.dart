///
//  Generated code. Do not modify.
//  source: google/protobuf/wrappers.proto
///
// ignore_for_file: non_constant_identifier_names,library_prefixes,unused_import

// ignore: UNUSED_SHOWN_NAME
import 'dart:core' show int, bool, double, String, List, override;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class DoubleValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('DoubleValue',
      package: const $pb.PackageName('google.protobuf'))
    ..a<double>(1, 'value', $pb.PbFieldType.OD)
    ..hasRequiredFields = false;

  DoubleValue() : super();
  DoubleValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  DoubleValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  DoubleValue clone() => new DoubleValue()..mergeFromMessage(this);
  DoubleValue copyWith(void Function(DoubleValue) updates) =>
      super.copyWith((message) => updates(message as DoubleValue));
  $pb.BuilderInfo get info_ => _i;
  static DoubleValue create() => new DoubleValue();
  static $pb.PbList<DoubleValue> createRepeated() =>
      new $pb.PbList<DoubleValue>();
  static DoubleValue getDefault() => _defaultInstance ??= create()..freeze();
  static DoubleValue _defaultInstance;
  static void $checkItem(DoubleValue v) {
    if (v is! DoubleValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  double get value => $_getN(0);
  set value(double v) {
    $_setDouble(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class FloatValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('FloatValue',
      package: const $pb.PackageName('google.protobuf'))
    ..a<double>(1, 'value', $pb.PbFieldType.OF)
    ..hasRequiredFields = false;

  FloatValue() : super();
  FloatValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  FloatValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  FloatValue clone() => new FloatValue()..mergeFromMessage(this);
  FloatValue copyWith(void Function(FloatValue) updates) =>
      super.copyWith((message) => updates(message as FloatValue));
  $pb.BuilderInfo get info_ => _i;
  static FloatValue create() => new FloatValue();
  static $pb.PbList<FloatValue> createRepeated() =>
      new $pb.PbList<FloatValue>();
  static FloatValue getDefault() => _defaultInstance ??= create()..freeze();
  static FloatValue _defaultInstance;
  static void $checkItem(FloatValue v) {
    if (v is! FloatValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  double get value => $_getN(0);
  set value(double v) {
    $_setFloat(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class Int64Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Int64Value',
      package: const $pb.PackageName('google.protobuf'))
    ..aInt64(1, 'value')
    ..hasRequiredFields = false;

  Int64Value() : super();
  Int64Value.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Int64Value.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Int64Value clone() => new Int64Value()..mergeFromMessage(this);
  Int64Value copyWith(void Function(Int64Value) updates) =>
      super.copyWith((message) => updates(message as Int64Value));
  $pb.BuilderInfo get info_ => _i;
  static Int64Value create() => new Int64Value();
  static $pb.PbList<Int64Value> createRepeated() =>
      new $pb.PbList<Int64Value>();
  static Int64Value getDefault() => _defaultInstance ??= create()..freeze();
  static Int64Value _defaultInstance;
  static void $checkItem(Int64Value v) {
    if (v is! Int64Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  Int64 get value => $_getI64(0);
  set value(Int64 v) {
    $_setInt64(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class UInt64Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('UInt64Value',
      package: const $pb.PackageName('google.protobuf'))
    ..a<Int64>(1, 'value', $pb.PbFieldType.OU6, Int64.ZERO)
    ..hasRequiredFields = false;

  UInt64Value() : super();
  UInt64Value.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  UInt64Value.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  UInt64Value clone() => new UInt64Value()..mergeFromMessage(this);
  UInt64Value copyWith(void Function(UInt64Value) updates) =>
      super.copyWith((message) => updates(message as UInt64Value));
  $pb.BuilderInfo get info_ => _i;
  static UInt64Value create() => new UInt64Value();
  static $pb.PbList<UInt64Value> createRepeated() =>
      new $pb.PbList<UInt64Value>();
  static UInt64Value getDefault() => _defaultInstance ??= create()..freeze();
  static UInt64Value _defaultInstance;
  static void $checkItem(UInt64Value v) {
    if (v is! UInt64Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  Int64 get value => $_getI64(0);
  set value(Int64 v) {
    $_setInt64(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class Int32Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('Int32Value',
      package: const $pb.PackageName('google.protobuf'))
    ..a<int>(1, 'value', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  Int32Value() : super();
  Int32Value.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  Int32Value.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  Int32Value clone() => new Int32Value()..mergeFromMessage(this);
  Int32Value copyWith(void Function(Int32Value) updates) =>
      super.copyWith((message) => updates(message as Int32Value));
  $pb.BuilderInfo get info_ => _i;
  static Int32Value create() => new Int32Value();
  static $pb.PbList<Int32Value> createRepeated() =>
      new $pb.PbList<Int32Value>();
  static Int32Value getDefault() => _defaultInstance ??= create()..freeze();
  static Int32Value _defaultInstance;
  static void $checkItem(Int32Value v) {
    if (v is! Int32Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  int get value => $_get(0, 0);
  set value(int v) {
    $_setSignedInt32(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class UInt32Value extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('UInt32Value',
      package: const $pb.PackageName('google.protobuf'))
    ..a<int>(1, 'value', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  UInt32Value() : super();
  UInt32Value.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  UInt32Value.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  UInt32Value clone() => new UInt32Value()..mergeFromMessage(this);
  UInt32Value copyWith(void Function(UInt32Value) updates) =>
      super.copyWith((message) => updates(message as UInt32Value));
  $pb.BuilderInfo get info_ => _i;
  static UInt32Value create() => new UInt32Value();
  static $pb.PbList<UInt32Value> createRepeated() =>
      new $pb.PbList<UInt32Value>();
  static UInt32Value getDefault() => _defaultInstance ??= create()..freeze();
  static UInt32Value _defaultInstance;
  static void $checkItem(UInt32Value v) {
    if (v is! UInt32Value) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  int get value => $_get(0, 0);
  set value(int v) {
    $_setUnsignedInt32(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class BoolValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('BoolValue',
      package: const $pb.PackageName('google.protobuf'))
    ..aOB(1, 'value')
    ..hasRequiredFields = false;

  BoolValue() : super();
  BoolValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  BoolValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  BoolValue clone() => new BoolValue()..mergeFromMessage(this);
  BoolValue copyWith(void Function(BoolValue) updates) =>
      super.copyWith((message) => updates(message as BoolValue));
  $pb.BuilderInfo get info_ => _i;
  static BoolValue create() => new BoolValue();
  static $pb.PbList<BoolValue> createRepeated() => new $pb.PbList<BoolValue>();
  static BoolValue getDefault() => _defaultInstance ??= create()..freeze();
  static BoolValue _defaultInstance;
  static void $checkItem(BoolValue v) {
    if (v is! BoolValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  bool get value => $_get(0, false);
  set value(bool v) {
    $_setBool(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class StringValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('StringValue',
      package: const $pb.PackageName('google.protobuf'))
    ..aOS(1, 'value')
    ..hasRequiredFields = false;

  StringValue() : super();
  StringValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  StringValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  StringValue clone() => new StringValue()..mergeFromMessage(this);
  StringValue copyWith(void Function(StringValue) updates) =>
      super.copyWith((message) => updates(message as StringValue));
  $pb.BuilderInfo get info_ => _i;
  static StringValue create() => new StringValue();
  static $pb.PbList<StringValue> createRepeated() =>
      new $pb.PbList<StringValue>();
  static StringValue getDefault() => _defaultInstance ??= create()..freeze();
  static StringValue _defaultInstance;
  static void $checkItem(StringValue v) {
    if (v is! StringValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  String get value => $_getS(0, '');
  set value(String v) {
    $_setString(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}

class BytesValue extends $pb.GeneratedMessage {
  static final $pb.BuilderInfo _i = new $pb.BuilderInfo('BytesValue',
      package: const $pb.PackageName('google.protobuf'))
    ..a<List<int>>(1, 'value', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  BytesValue() : super();
  BytesValue.fromBuffer(List<int> i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromBuffer(i, r);
  BytesValue.fromJson(String i,
      [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY])
      : super.fromJson(i, r);
  BytesValue clone() => new BytesValue()..mergeFromMessage(this);
  BytesValue copyWith(void Function(BytesValue) updates) =>
      super.copyWith((message) => updates(message as BytesValue));
  $pb.BuilderInfo get info_ => _i;
  static BytesValue create() => new BytesValue();
  static $pb.PbList<BytesValue> createRepeated() =>
      new $pb.PbList<BytesValue>();
  static BytesValue getDefault() => _defaultInstance ??= create()..freeze();
  static BytesValue _defaultInstance;
  static void $checkItem(BytesValue v) {
    if (v is! BytesValue) $pb.checkItemFailed(v, _i.qualifiedMessageName);
  }

  List<int> get value => $_getN(0);
  set value(List<int> v) {
    $_setBytes(0, v);
  }

  bool hasValue() => $_has(0);
  void clearValue() => clearField(1);
}
