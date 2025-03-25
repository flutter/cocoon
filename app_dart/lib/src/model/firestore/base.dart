// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

/// Provides methods across [g.Document] sub-types in `model/firestore/*.dart`.
@internal
mixin BaseDocumentMixin on g.Document {
  Map<String, Object?> _fieldsToJson() {
    return fields!.map((k, v) => MapEntry(k, _valueToJson(v)));
  }

  static Object? _valueToJson(g.Value value) {
    // Listen, I don't like this, you don't like this, but it's only used to
    // give beautiful toString() representations for logs and testing, so you'll
    // let it slide.
    //
    // Basically, toJson() does: {
    //   if (isString) 'stringValue': stringValue,
    //   if (isDouble) 'doubleValue': doubleValue,
    // }
    //
    // So instead of copying that, we'll just use what they do.
    return value.toJson().values.firstOrNull;
  }

  @override
  @nonVirtual
  String toString() {
    return '$runtimeType ${const JsonEncoder.withIndent('  ').convert(_fieldsToJson())}';
  }
}
