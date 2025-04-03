// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport '../firestore.dart';
library;

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

import 'firestore_clone.dart';

/// Possible writes to make using [Firestore.tryBatchWrite].
@immutable
sealed class BatchWriteOperation {
  BatchWriteOperation(g.Document document)
    : _document = cloneFirestoreDocument(document);

  /// An operation to update an existing document.
  factory BatchWriteOperation.update(g.Document doc) = BatchUpdateOperation._;

  /// An operation to insert a new document.
  factory BatchWriteOperation.insert(g.Document doc) = BatchInsertOperation._;

  /// An operation to update an existing, _or_ insert a new document.
  factory BatchWriteOperation.upsert(g.Document doc) = BatchUpsertOperation._;

  final g.Document _document;
  g.Precondition get _precondition;
}

@internal
g.Write internalToFirestoreWrite(
  BatchWriteOperation operation, {
  required String documentPath,
}) {
  return g.Write(
    currentDocument: operation._precondition,
    update: cloneFirestoreDocument(operation._document, name: documentPath),
  );
}

/// Updates an _existing_ document.
@visibleForTesting
final class BatchUpdateOperation extends BatchWriteOperation {
  BatchUpdateOperation._(super._document);

  @override
  g.Precondition get _precondition => g.Precondition(exists: true);
}

/// Inserts a _non-existent_ document.
@visibleForTesting
final class BatchInsertOperation extends BatchWriteOperation {
  BatchInsertOperation._(super._document);

  @override
  g.Precondition get _precondition => g.Precondition(exists: false);
}

/// Updates an _existing_ document, or inserts it if it did not already exist.
@visibleForTesting
final class BatchUpsertOperation extends BatchWriteOperation {
  BatchUpsertOperation._(super._document);

  @override
  g.Precondition get _precondition => g.Precondition(exists: null);
}
