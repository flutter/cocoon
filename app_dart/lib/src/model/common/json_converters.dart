// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' hide json;
import 'dart:convert' as convert show json;

import 'package:json_annotation/json_annotation.dart';

/// A converter for tags.
///
/// The JSON format is:
///
/// ```json
/// [
///   {
///     "key": "tag_key",
///     "value": "tag_value"
///   }
/// ]
/// ```
///
/// Which is flattened out as a `Map<String, List<String>>`.
class TagsConverter
    implements JsonConverter<Map<String, List<String>>, List<dynamic>> {
  const TagsConverter();

  @override
  Map<String, List<String>> fromJson(List<dynamic> json) {
    if (json == null) {
      return null;
    }
    final Map<String, List<String>> result = <String, List<String>>{};
    for (Map<String, dynamic> tag in json.cast<Map<String, dynamic>>()) {
      final String key = tag['key'] as String;
      result[key] ??= <String>[];
      result[key].add(tag['value'] as String);
    }
    return result;
  }

  @override
  List<Map<String, dynamic>> toJson(Map<String, List<String>> object) {
    if (object == null) {
      return null;
    }
    if (object.isEmpty) {
      return const <Map<String, List<String>>>[];
    }
    final List<Map<String, String>> result = <Map<String, String>>[];
    for (String key in object.keys) {
      for (String value in object[key]) {
        result.add(<String, String>{
          'key': key,
          'value': value,
        });
      }
    }
    return result;
  }
}

/// A convert for BuildBucket IDs.
///
/// These are int64s, which are not safely representable as JSON numbers.
///
/// In JSON format, they're converted to Strings, but they're always int64s,
/// which are safe to use in the Dart VM.
class Int64Converter implements JsonConverter<int, String> {
  const Int64Converter();

  @override
  int fromJson(String json) {
    return int.parse(json);
  }

  @override
  String toJson(int object) {
    return object.toString();
  }
}

/// A converter for a "binary" JSON field.
///
/// Encodes and decodes a String to and from base64.
class Base64Converter implements JsonConverter<String, String> {
  const Base64Converter();

  @override
  String fromJson(String json) {
    return utf8.decode(base64.decode(json));
  }

  @override
  String toJson(String object) {
    return base64.encode(utf8.encode(object));
  }
}

/// A converter for "timestamp" fields encoded as milliseconds since epoch.
class MillisecondsSinceEpochConverter
    implements JsonConverter<DateTime, String> {
  const MillisecondsSinceEpochConverter();

  @override
  DateTime fromJson(String json) {
    if (json == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(json));
  }

  @override
  String toJson(DateTime object) {
    if (object == null) {
      return null;
    }
    return object.millisecondsSinceEpoch.toString();
  }
}

/// A converter for "timestamp" fields encoded as seconds since epoch.
class SecondsSinceEpochConverter implements JsonConverter<DateTime, String> {
  const SecondsSinceEpochConverter();

  @override
  DateTime fromJson(String json) {
    if (json == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(json) * 1000);
  }

  @override
  String toJson(DateTime dateTime) {
    if (dateTime == null) {
      return null;
    }
    final int secondsSinceEpoch = dateTime.millisecondsSinceEpoch ~/ 1000;
    return secondsSinceEpoch.toString();
  }
}

/// A converter for boolean fields encoded as strings.
class BoolConverter implements JsonConverter<bool, String> {
  const BoolConverter();

  @override
  bool fromJson(String json) {
    if (json == null) {
      return null;
    }
    return json.toLowerCase() == 'true';
  }

  @override
  String toJson(bool value) {
    if (value == null) {
      return null;
    }
    return '$value';
  }
}

/// A converter for fields with nested JSON objects in String format.
class NestedJsonConverter
    implements JsonConverter<Map<String, dynamic>, String> {
  const NestedJsonConverter();

  @override
  Map<String, dynamic> fromJson(String json) {
    if (json == null) {
      return null;
    }
    return convert.json.decode(json) as Map<String, dynamic>;
  }

  @override
  String toJson(Map<String, dynamic> object) {
    if (object == null) {
      return null;
    }
    return convert.json.encode(object);
  }
}
