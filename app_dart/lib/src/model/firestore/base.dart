// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Metadata about an [AppDocument].
@immutable
final class AppDocumentMetadata<T extends AppDocument<T>> {
  const AppDocumentMetadata({
    required String collectionId,
    required String Function(T) documentName,
    required T Function(g.Document) fromDocument,
  }) : _collectionId = collectionId,
       _documentName = documentName,
       _fromDocument = fromDocument;

  /// Returns the relative path of [document] within Firestore.
  String relativePath(T document) {
    return p.posix.join(_collectionId, _documentName(document));
  }

  final String _collectionId;
  final String Function(T) _documentName;

  /// Whether [path] is a path to this type of document.
  bool isPathTo(String path) {
    return p.posix.basename(p.posix.dirname(path)) == _collectionId;
  }

  /// Creates a new instance of [T].
  ///
  /// If [cloneFrom] is provided, the state is copied, otherwise a default
  /// state is returned.
  T newInstance([T? cloneFrom]) => fromDocument(cloneFrom ?? g.Document());

  /// Creates a new instance of [T] from the provided [document].
  T fromDocument(g.Document document) => _fromDocument(document);
  final T Function(g.Document) _fromDocument;
}

/// Provides methods across [g.Document] sub-types in `model/firestore/*.dart`.
@internal
mixin AppDocument<T extends AppDocument<T>> on g.Document {
  Map<String, Object?> _fieldsToJson() {
    return fields!.map((k, v) => MapEntry(k, _valueToJson(v)));
  }

  /// Metadata that informs other parts of the app about how to use this entity.
  AppDocumentMetadata<T> get runtimeMetadata;

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
