// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:cocoon_server/firestore.dart';
// ignore: implementation_imports
import 'package:cocoon_server/src/firestore_batch.dart';
// ignore: implementation_imports
import 'package:cocoon_server/src/firestore_clone.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:http/testing.dart';

final class FakeFirestore extends Firestore {
  /// Creates a fake Firestore instance with the given [projectId]/[databaseId].
  ///
  /// All operations are simulated in memory.
  FakeFirestore({
    required super.projectId,
    required super.databaseId,
    DateTime Function() now = DateTime.now,
  }) : _now = now,
       super.fromApi(
         g.FirestoreApi(MockClient((_) => throw UnimplementedError())),
       );

  /// Documents stored in memory.
  ///
  /// This list is unmodifiable.
  late final List<g.Document> documents = UnmodifiableListView(_documents);

  final _documents = <g.Document>[];
  final DateTime Function() _now;

  static g.Document _clone(g.Document document) {
    // ignore: invalid_use_of_internal_member
    return cloneFirestoreDocument(document);
  }

  int? _getDocumentIndexbyPath(String path) {
    for (var i = 0; i < _documents.length; i++) {
      if (_documents[i].name case final name? when name.endsWith(path)) {
        return i;
      }
    }
    return null;
  }

  @override
  Future<g.Document?> tryGetByPath(String path) async {
    final index = _getDocumentIndexbyPath(path);
    return index == null ? null : _clone(_documents[index]);
  }

  @override
  Future<g.Document?> tryInsertByPath(String path, g.Document document) async {
    if (_getDocumentIndexbyPath(path) != null) {
      return null;
    }

    final inserted = _clone(document);
    inserted.name = resolveDocumentsPath(path);
    inserted.updateTime = inserted.updateTime = _now().toIso8601String();
    _documents.add(inserted);
    return _clone(inserted);
  }

  @override
  Future<g.Document?> tryUpdateByPath(String path, g.Document document) async {
    final index = _getDocumentIndexbyPath(path);
    if (index == null) {
      return null;
    }

    final updates = _clone(_documents[index]);
    updates.fields = {...?document.fields};
    updates.updateTime = _now().toIso8601String();
    _documents[index] = updates;
    return _clone(updates);
  }

  @override
  Future<g.Document> upsertByPath(String path, g.Document document) {
    final index = _getDocumentIndexbyPath(path);
    if (index == null) {
      return insertByPath(path, document);
    } else {
      return updateByPath(path, document);
    }
  }

  @override
  Future<List<bool>> tryBatchWrite(
    Map<String, BatchWriteOperation> writes,
  ) async {
    final results = List.filled(writes.length, false);

    var i = 0;
    for (final MapEntry(key: path, value: write) in writes.entries) {
      // ignore: invalid_use_of_internal_member
      final op = internalToFirestoreWrite(
        write,
        documentPath: resolveDocumentsPath(path),
      );
      switch (write) {
        // ignore: invalid_use_of_visible_for_testing_member
        case BatchInsertOperation():
          results[i] = (await tryInsertByPath(path, op.update!)) != null;
        // ignore: invalid_use_of_visible_for_testing_member
        case BatchUpdateOperation():
          results[i] = (await tryUpdateByPath(path, op.update!)) != null;
        // ignore: invalid_use_of_visible_for_testing_member
        case BatchUpsertOperation():
          await upsertByPath(path, op.update!);
          results[i] = true;
      }

      i++;
    }

    return results;
  }
}
