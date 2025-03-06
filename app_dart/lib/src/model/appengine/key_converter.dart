// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'key_helper.dart';

/// A converter for [Key]s encoded as strings.
class StringKeyConverter implements JsonConverter<Key<String>?, String> {
  const StringKeyConverter();

  @override
  Key<String>? fromJson(String? json) =>
      (json == null || json.isEmpty)
          ? null
          : KeyHelper().decode(json) as Key<String>;

  @override
  String toJson(Key<String>? key) => key == null ? '' : KeyHelper().encode(key);
}

/// A converter for [Key]s encoded as strings.
class IntKeyConverter implements JsonConverter<Key<int>, String> {
  const IntKeyConverter();

  @override
  Key<int> fromJson(String json) => KeyHelper().decode(json) as Key<int>;

  @override
  String toJson(Key<int?> key) => KeyHelper().encode(key);
}
