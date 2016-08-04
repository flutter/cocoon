// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon/logging.dart';

/// Stores a data entity's data in a [Map] and serializes it to/from JSON.
class Entity {
  Entity(this._entitySerializer, [Map<String, dynamic> props])
    : _props = props != null
        ? props
        : <String, dynamic>{};

  final EntitySerializer _entitySerializer;
  final Map<String, dynamic> _props;

  operator[](String propName) => _props[propName];
  operator[]=(String propName, dynamic value) {
    _props[propName] = value;
  }

  dynamic toJson() => _entitySerializer.serialize(this);
}

abstract class JsonSerializer<T> {
  T deserialize(dynamic jsonValue);
  dynamic serialize(T value);
}

/// Serializes strings.
StringSerializer string() => const StringSerializer();

/// Serializes booleans.
BoolSerializer boolean() => const BoolSerializer();

/// Serializes ints and doubles.
NumSerializer number() => const NumSerializer();

/// Serializes between [DateTime] (Dart-side) and string (JSON-side).
DateTimeSerializer dateTime() => const DateTimeSerializer();

/// Serializes between [List] of elements serialized by [elementSerializer] and
/// JSON arrays.
ListSerializer listOf(JsonSerializer elementSerializer) {
  if (elementSerializer == null) {
    throw 'null elementSerializer is not allowed';
  }
  return new ListSerializer(elementSerializer);
}

class ListSerializer<E> implements JsonSerializer<List<E>> {
  const ListSerializer(this.elementSerializer);

  final JsonSerializer elementSerializer;

  List<E> deserialize(dynamic jsonValue) {
    if (jsonValue == null)
      return null;

    List<dynamic> jsonList = jsonValue as List;
    List<E> result = <E>[];
    for (int i = 0; i < jsonList.length; i++) {
      try {
        result.add(elementSerializer.deserialize(jsonList[i]));
      } catch (_) {
        logger.error('Failed to deserialize ${i}th element of JSON array: ${jsonList[i]}');
        rethrow;
      }
    }
    return result;
  }

  List<dynamic> serialize(List<E> value) {
    return value
      .map((E elem) => elementSerializer.serialize(elem))
      .toList();
  }
}

class StringSerializer implements JsonSerializer<String> {
  const StringSerializer();

  String deserialize(dynamic jsonValue) {
    return jsonValue as String;
  }
  dynamic serialize(String value) => value;
}

class BoolSerializer implements JsonSerializer<bool> {
  const BoolSerializer();

  bool deserialize(dynamic jsonValue) {
    return jsonValue as bool;
  }
  dynamic serialize(bool value) => value;
}

class NumSerializer implements JsonSerializer<num> {
  const NumSerializer();

  num deserialize(dynamic jsonValue) {
    return jsonValue as num;
  }
  dynamic serialize(num value) => value;
}

/// Serializes between [DateTime] and milliseconds with the epoch.
class DateTimeSerializer implements JsonSerializer<DateTime> {

  const DateTimeSerializer();

  @override
  DateTime deserialize(dynamic jsonValue) {
    if (jsonValue == null || jsonValue == 0)
      return null;

    if (jsonValue is! int)
      throw 'Expected DateTime to be JSON-encoded as int in milliseconds since the epoch but was ${jsonValue.runtimeType}: $jsonValue';

    return new DateTime.fromMillisecondsSinceEpoch(jsonValue);
  }

  @override
  dynamic serialize(DateTime value) => value != null
    ? value.millisecondsSinceEpoch
    : 0;
}

typedef T EntityFactory<T>(Map<String, dynamic> props);

/// Serializes between structured Dart classes and JSON [Map]s.
class EntitySerializer<T extends Entity> implements JsonSerializer<T> {
  EntitySerializer(this._entityFactory, this._propertyCodecs);

  final EntityFactory<T> _entityFactory;
  final Map<String, JsonSerializer> _propertyCodecs;

  T deserialize(dynamic jsonValue) {
    Map<String, dynamic> props = <String, dynamic>{};
    (jsonValue as Map).forEach((String propName, dynamic propJsonValue) {
      if (_propertyCodecs.containsKey(propName)) {
        try {
          props[propName] = _propertyCodecs[propName].deserialize(propJsonValue);
        } catch (_) {
          logger.error('Failed to deserialize property "${propName}" of JSON object: ${propJsonValue}');
          rethrow;
        }
      }
    });
    return _entityFactory(props);
  }

  dynamic serialize(T value) {
    Map<String, dynamic> json = <String, dynamic>{};
    value._props.forEach((String propName, dynamic propValue) {
      json[propName] = _propertyCodecs[propName].serialize(propValue);
    });
    return json;
  }
}
