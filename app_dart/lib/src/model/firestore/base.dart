// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Defines the `documentId` for a given document [T].
///
/// The path to a document in Firestore follows the pattern:
/// ```txt
/// /projects/<project-id>/databases/<database-id>/documents/<collection-id>/<document-id>
/// ```
///
/// This type is the `<document-id>` for a particular collection type [T].
///
/// ## Implementing
///
/// There are two ways to use this type: (1) [fromDocumentId] or (2) `extends`.
///
/// For simple cases, or for creating an ID from an existing string:
/// ```dart
/// AppDocumentId<Commit>.fromDocumentId(commitSha);
/// ```
///
/// For more complex cases, or deriving the ID from multiple distinct fields:
/// ```dart
/// final class TaskId extends AppDocumentId<Task> {
///   // ... fields ...
///
///   @override
///   String get documentId => '$field1_$field2_$field3';
/// }
/// ```
@immutable
abstract base class AppDocumentId<T extends AppDocument<T>> {
  const AppDocumentId();

  /// Create an [AppDocumentId] from an existing [documentId].
  const factory AppDocumentId.fromDocumentId(String documentId) =
      _AppDocumentId;

  /// The `<document-id>` portion of a [g.Document.name].
  String get documentId;

  @override
  @nonVirtual
  bool operator ==(Object other) {
    return other is AppDocumentId<T> && documentId == other.documentId;
  }

  @override
  @nonVirtual
  int get hashCode => documentId.hashCode;

  @override
  @nonVirtual
  String toString() {
    return 'AppDocumentId<$T>: $documentId';
  }
}

final class _AppDocumentId<T extends AppDocument<T>> extends AppDocumentId<T> {
  const _AppDocumentId(this.documentId);

  @override
  final String documentId;
}

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
  AppDocumentMetadata<T> get metadata;

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
