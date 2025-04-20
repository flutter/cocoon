// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' hide json;
import 'dart:convert' as convert show json;

import 'package:json_annotation/json_annotation.dart';

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

/// A converter for "timestamp" fields encoded as seconds since epoch.
class SecondsSinceEpochConverter implements JsonConverter<DateTime?, Object?> {
  const SecondsSinceEpochConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json * 1000);
    }
    if (json is String) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(json) * 1000);
    }
    return null;
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
class BoolConverter implements JsonConverter<bool?, Object?> {
  const BoolConverter();

  @override
  bool? fromJson(Object? json) {
    if (json is bool) return json;
    if (json is String) {
      return json.toLowerCase() == 'true';
    }
    return null;
  }

  @override
  String? toJson(bool? value) {
    if (value == null) {
      return null;
    }
    return '$value';
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
