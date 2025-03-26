// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/firestore.dart';
import 'package:collection/collection.dart';
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

  final _documents = <g.Document>[];
  final DateTime Function() _now;

  static g.Document _clone(g.Document document) {
    return g.Document()
      ..name = document.name
      ..fields = document.fields
      ..createTime = document.createTime
      ..updateTime = document.updateTime;
  }

  g.Document? _getReferenceByPath(String path) {
    return _documents.firstWhereOrNull((d) {
      if (d.name case final name?) {
        return name.endsWith(path);
      }
      return false;
    });
  }

  @override
  Future<g.Document?> tryGetByPath(String path) async {
    final result = _getReferenceByPath(path);
    return result == null ? null : _clone(result);
  }

  @override
  Future<g.Document?> tryInsertByPath(String path, g.Document document) async {
    final existing = _getReferenceByPath(path);
    if (existing != null) {
      return null;
    }

    final inserted = _clone(document);
    inserted.name = resolvePath(path);
    inserted.updateTime = inserted.updateTime = _now().toIso8601String();
    _documents.add(inserted);
    return _clone(inserted);
  }

  @override
  Future<List<bool>> tryInsertAll(Map<String, g.Document> documents) async {
    final results = <bool>[];
    for (final MapEntry(key: path, value: document) in documents.entries) {
      final inserted = await tryInsertByPath(path, document);
      results.add(inserted != null);
    }
    return results;
  }
}
