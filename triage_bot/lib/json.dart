// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The whole point of this file is to wrap dynamic calls in a pretense of type safety, so we use dynamic calls a lot.
// Also the code uses a lot of one-line flow control so we don't bother wrapping them all in blocks.
// ignore_for_file: avoid_dynamic_calls, curly_braces_in_flow_control_structures

import 'dart:convert' as dart show json;
import 'package:meta/meta.dart';

@immutable
class Json {
  factory Json(dynamic input) {
    if (input is Json)
      return Json._wrap(input._value);
    return Json._wrap(input);
  }

  factory Json.list(List<dynamic> input) {
    return Json._raw(input.map<Json>(Json._wrap).toList());
  }

  // (This differs from "real" JSON in that we don't allow duplicate keys.)
  factory Json.map(Map<dynamic, dynamic> input) {
    final Map<String, Json> values = <String, Json>{};
    input.forEach((dynamic key, dynamic value) {
      final String name = key.toString();
      assert(!values.containsKey(name), 'Json.map keys must be unique strings');
      values[name] = Json._wrap(value);
    });
    return Json._raw(values);
  }

  factory Json.parse(String value) {
    return Json(dart.json.decode(value));
  }

  const Json._raw(this._value);

  factory Json._wrap(dynamic value) {
    if (value == null)
      return const Json._raw(null);
    if (value is num)
      return Json._raw(value.toDouble());
    if (value is List)
      return Json.list(value);
    if (value is Map)
      return Json.map(value);
    if (value == true)
      return const Json._raw(true);
    if (value == false)
      return const Json._raw(false);
    if (value is Json)
      return value;
    return Json._raw(value.toString());
  }

  final dynamic _value;

  dynamic unwrap() {
    if (_value is Map)
      return toMap();
    if (_value is List)
      return toList();
    return _value;
  }

  bool get isMap => _value is Map;
  bool get isList => _value is List;
  bool get isScalar => _value == null || _value is num || _value is bool || _value is String;
  Type get valueType => _value.runtimeType;

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> values = <String, dynamic>{};
    if (_value is Map) {
      _value.forEach((String key, Json value) {
        values[key] = value.unwrap();
      });
    } else if (_value is List) {
      for (int index = 0; index < (_value as List<dynamic>).length; index += 1)
        values[index.toString()] = _value[index].unwrap();
    } else {
      values['0'] = unwrap();
    }
    return values;
  }

  List<dynamic> toList() {
    if (_value is Map)
      return (_value as Map<String, Json>).values.map<dynamic>((Json value) => value.unwrap()).toList();
    if (_value is List)
      return (_value as List<Json>).map<dynamic>((Json value) => value.unwrap()).toList();
    return <dynamic>[unwrap()];
  }

  dynamic toScalar() {
    assert(isScalar, 'toScalar called on non-scalar. Check "isScalar" first.');
    return _value;
  }

  Iterable<Json> asIterable() {
    if (_value is Map)
      return (_value as Map<String, Json>).values.toList();
    if (_value is List)
      return _value as List<Json>;
    return const <Json>[];
  }

  double toDouble() => _value as double;

  int toInt() => (_value as double).toInt();

  bool toBoolean() => _value as bool;

  @override
  String toString() => _value.toString();

  String toJson() {
    return dart.json.encode(unwrap());
  }

  dynamic operator [](dynamic key) {
    return _value[key];
  }

  void operator []=(dynamic key, dynamic value) {
    _value[key] = Json._wrap(value);
  }

  bool hasKey(String key) {
    return _value is Map && (_value as Map<String, Json>).containsKey(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      final String name = _symbolName(invocation.memberName);
      if (_value is Map) {
        if ((_value as Map<String, Json>).containsKey(name))
          return this[name];
        return const Json._raw(null);
      }
    }
    if (invocation.isSetter)
      return this[_symbolName(invocation.memberName, stripEquals: true)] = invocation.positionalArguments[0];
    return super.noSuchMethod(invocation);
  }

  // Workaround for https://github.com/dart-lang/sdk/issues/28372
  String _symbolName(Symbol symbol, { bool stripEquals = false }) {
    // WARNING: Assumes a fixed format for Symbol.toString which is *not*
    // guaranteed anywhere.
    final String s = '$symbol';
    return s.substring(8, s.length - (2 + (stripEquals ? 1 : 0)));
  }

  bool operator <(Object other) {
    if (other is Json)
      return _value < other._value as bool;
    return _value < other as bool;
  }

  bool operator <=(Object other) {
    if (other is Json)
      return _value <= other._value as bool;
    return _value <= other as bool;
  }

  bool operator >(Object other) {
    if (other is Json)
      return _value > other._value as bool;
    return _value > other as bool;
  }

  bool operator >=(Object other) {
    if (other is Json)
      return _value >= other._value as bool;
    return _value >= other as bool;
  }

  dynamic operator -(Object other) {
    if (other is Json)
      return _value - other._value;
    return _value - other;
  }

  dynamic operator +(Object other) {
    if (other is Json)
      return _value + other._value;
    return _value + other;
  }

  dynamic operator /(Object other) {
    if (other is Json)
      return _value / other._value;
    return _value / other;
  }

  dynamic operator ~/(Object other) {
    if (other is Json)
      return _value ~/ other._value;
    return _value ~/ other;
  }

  dynamic operator *(Object other) {
    if (other is Json)
      return _value * other._value;
    return _value * other;
  }

  dynamic operator %(Object other) {
    if (other is Json)
      return _value % other._value;
    return _value % other;
  }

  dynamic operator |(Object other) {
    if (other is Json)
      return _value.toInt() | other._value.toInt();
    return _value.toInt() | other;
  }

  dynamic operator ^(Object other) {
    if (other is Json)
      return _value.toInt() ^ other._value.toInt();
    return _value.toInt() ^ other;
  }

  dynamic operator &(Object other) {
    if (other is Json)
      return _value.toInt() & other._value.toInt();
    return _value.toInt() & other;
  }

  dynamic operator <<(Object other) {
    if (other is Json)
      return _value.toInt() << other._value.toInt();
    return _value.toInt() << other;
  }

  dynamic operator >>(Object other) {
    if (other is Json)
      return _value.toInt() >> other._value.toInt();
    return _value.toInt() >> other;
  }

  @override
  bool operator ==(Object other) {
    if (other is Json)
      return _value == other._value;
    return _value == other;
  }

  @override
  int get hashCode => _value.hashCode;
}
