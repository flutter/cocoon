// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:cocoon_server/firestore.dart';
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

  /// Documents stored in memory.
  ///
  /// This list is unmodifiable.
  late final List<g.Document> documents = UnmodifiableListView(_documents);

  int? _getReferenceByPath(String path) {
    for (var i = 0; i < _documents.length; i++) {
      final document = _documents[i];
      if (document.name case final name? when name.endsWith(path)) {
        return i;
      }
    }
    return null;
  }

  @override
  Future<g.Document?> tryGetByPath(String path) async {
    final index = _getReferenceByPath(path);
    return index == null ? null : _clone(_documents[index]);
  }

  @override
  Future<g.Document?> tryInsertByPath(String path, g.Document document) async {
    final index = _getReferenceByPath(path);
    if (index != null) {
      return null;
    }

    final inserted = _clone(document);
    inserted.name = resolvePath(path);
    inserted.updateTime = inserted.updateTime = _now().toIso8601String();
    _documents.add(inserted);
    return _clone(inserted);
  }

  @override
  Future<g.Document?> tryUpdateByPath(String path, g.Document document) async {
    final index = _getReferenceByPath(path);
    if (index == null) {
      return null;
    }

    final updated = _clone(_documents[index]);
    updated.fields = {...?document.fields};
    updated.updateTime = _now().toIso8601String();
    _documents[index] = updated;
    return _clone(updated);
  }

  @override
  Future<g.Document> upsertByPath(String path, g.Document document) async {
    final index = _getReferenceByPath(path);
    if (index == null) {
      return insertByPath(path, document);
    } else {
      return updateByPath(path, document);
    }
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

  @override
  Future<List<bool>> tryUpsertAll(Map<String, g.Document> documents) async {
    final results = <bool>[];
    for (final MapEntry(key: path, value: document) in documents.entries) {
      final inserted = await tryInsertByPath(path, document);
      if (inserted == null) {
        final updated = await tryUpdateByPath(path, document);
        results.add(updated != null);
      } else {
        results.add(true);
      }
    }
    return results;
  }

  @override
  Future<List<bool>> tryUpdateAll(Map<String, g.Document> documents) async {
    final results = <bool>[];
    for (final MapEntry(key: path, value: document) in documents.entries) {
      final updated = await tryUpdateByPath(path, document);
      results.add(updated != null);
    }
    return results;
  }
}
