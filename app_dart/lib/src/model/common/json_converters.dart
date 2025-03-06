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
    implements JsonConverter<Map<String?, List<String?>>?, List<dynamic>?> {
  const TagsConverter();

  @override
  Map<String?, List<String?>>? fromJson(List<dynamic>? json) {
    if (json == null) {
      return null;
    }
    final result = <String?, List<String?>>{};
    for (var tag in json.cast<Map<String, dynamic>>()) {
      final key = tag['key'] as String?;
      result[key] ??= <String?>[];
      result[key]!.add(tag['value'] as String?);
    }
    return result;
  }

  @override
  List<Map<String, dynamic>>? toJson(Map<String?, List<String?>>? object) {
    if (object == null) {
      return null;
    }
    if (object.isEmpty) {
      return const <Map<String, List<String>>>[];
    }
    final result = <Map<String, String>>[];
    for (var key in object.keys) {
      if (key == null) {
        continue;
      }
      final values = object[key];
      if (values == null) {
        continue;
      }
      for (var value in values) {
        if (value == null) {
          continue;
        }
        result.add(<String, String>{'key': key, 'value': value});
      }
    }
    return result;
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

/// A converter for "timestamp" fields encoded as microseconds since epoch.
class MicrosecondsSinceEpochConverter
    implements JsonConverter<DateTime?, String?> {
  const MicrosecondsSinceEpochConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return DateTime.fromMicrosecondsSinceEpoch(int.parse(json));
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) {
      return null;
    }
    return object.microsecondsSinceEpoch.toString();
  }
}

/// A converter for "timestamp" fields encoded as seconds since epoch.
class SecondsSinceEpochConverter implements JsonConverter<DateTime?, String?> {
  const SecondsSinceEpochConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(int.parse(json) * 1000);
  }

  @override
  String? toJson(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    final secondsSinceEpoch = dateTime.millisecondsSinceEpoch ~/ 1000;
    return secondsSinceEpoch.toString();
  }
}

/// A converter for boolean fields encoded as strings.
class BoolConverter implements JsonConverter<bool?, String?> {
  const BoolConverter();

  @override
  bool? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return json.toLowerCase() == 'true';
  }

  @override
  String? toJson(bool? value) {
    if (value == null) {
      return null;
    }
    return '$value';
  }
}

/// A converter for fields with nested JSON objects in String format.
class NestedJsonConverter
    implements JsonConverter<Map<String, dynamic>?, String?> {
  const NestedJsonConverter();

  @override
  Map<String, dynamic>? fromJson(String? json) {
    if (json == null) {
      return null;
    }
    return convert.json.decode(json) as Map<String, dynamic>?;
  }

  @override
  String? toJson(Map<String, dynamic>? object) {
    if (object == null) {
      return null;
    }
    return convert.json.encode(object);
  }
}

const Map<String, int> _months = <String, int>{
  'Jan': 1,
  'Feb': 2,
  'Mar': 3,
  'Apr': 4,
  'May': 5,
  'Jun': 6,
  'Jul': 7,
  'Aug': 8,
  'Sep': 9,
  'Oct': 10,
  'Nov': 11,
  'Dec': 12,
};

/// Convert a DateTime format from Gerrit to [DateTime].
///
/// Example format is "Wed Jun 07 22:54:06 2023 +0000"
class GerritDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const GerritDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) {
      return null;
    }

    final date = DateTime.tryParse(json);
    if (date != null) {
      return date;
    }

    json = json.substring(4); // Trim day of the week
    final parts = json.split(' ');
    final month = _months[parts[0]]!;
    final year = int.parse(parts[3]);
    final day = int.parse(parts[1]);
    final time = parts[2].split(':');
    final hours = int.parse(time[0]);
    final minutes = int.parse(time[1]);
    final seconds = int.parse(time[2]);

    return DateTime(year, month, day, hours, minutes, seconds);
  }

  @override
  String? toJson(DateTime? object) {
    return object?.toIso8601String();
  }
}
