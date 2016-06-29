// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:intl/intl.dart' as intl;
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

class NumSerializer implements JsonSerializer<num> {
  const NumSerializer();

  num deserialize(dynamic jsonValue) {
    return jsonValue as num;
  }
  dynamic serialize(num value) => value;
}

/// Serializes date-times in Go JSON-compatible way.
class DateTimeSerializer implements JsonSerializer<DateTime> {
  // See https://golang.org/pkg/time/#Time.IsZero.
  static const zeroDateTime = '0001-01-01T00:00:00Z';

  static final intl.DateFormat _rfc3339Format =
      new intl.DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  static final RegExp _rfc3339RegExp =
      new RegExp(r'^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)(\.(\d+))?Z$');

  const DateTimeSerializer();

  DateTime deserialize(dynamic jsonValue) {
    if (jsonValue == null || jsonValue == zeroDateTime)
      return null;

    if (jsonValue is! String)
      throw 'Expected DateTime to be JSON-encoded as String but was ${jsonValue.runtimeType}: $jsonValue';

    Match m = _rfc3339RegExp.firstMatch(jsonValue as String);

    if (m == null)
      throw 'DateTime does not conform to RFC3339 format: $jsonValue';

    int millis = 0;
    int micros = 0;

    if (m[8] != null) {
      int nanos = int.parse(m[8]);
      millis = nanos ~/ 1000000;
      micros = nanos ~/ 1000 - millis * 1000;
    }

    return new DateTime(
      int.parse(m[1]),
      int.parse(m[2]),
      int.parse(m[3]),
      int.parse(m[4]),
      int.parse(m[5]),
      int.parse(m[6]),
      millis,
      micros
    );
  }
  dynamic serialize(DateTime value) => value != null
    ? '${_rfc3339Format.format(value)}${value.millisecond > 0 || value.microsecond > 0 ? _formatNanos(value) : ""}Z'
    : '0001-01-01T00:00:00Z';

  static String _formatNanos(DateTime value) {
    int nanos = value.millisecond * 1000000 + value.microsecond * 1000;
    return '.${nanos}';
  }
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
