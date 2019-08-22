// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'key_helper.dart';

/// A converter for [Key]s encoded as strings.
class KeyConverter implements JsonConverter<Key, String> {
  const KeyConverter();

  @override
  Key fromJson(String json) => json == null ? null : KeyHelper().decode(json);

  @override
  String toJson(Key key) => key == null ? null : KeyHelper().encode(key);
}
