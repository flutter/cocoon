// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'firestore.dart';
library;

import 'dart:io';

import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'access_client_provider.dart';
import 'google_auth_provider.dart';
import 'src/firestore_batch.dart';

export 'src/firestore_batch.dart' show BatchWriteOperation;

/// A lightweight typed wrapper on top of [g.FirestoreApi].
base class Firestore {
  /// Creates a [Firestore] using Google API authentication.
  static Future<Firestore> from(
    GoogleAuthProvider authProvider, {
    required String projectId,
    required String databaseId,
  }) async {
    final client = await authProvider.createClient(
      scopes: const [g.FirestoreApi.datastoreScope],
      baseClient: FirestoreBaseClient(
        projectId: projectId,
        databaseId: databaseId,
      ),
    );
    return Firestore.fromApi(
      g.FirestoreApi(client),
      projectId: projectId,
      databaseId: databaseId,
    );
  }

  /// Creates a [Firestore] instance that delegates to [g.FirestoreApi].
  Firestore.fromApi(
    this._api, {
    required String projectId,
    required String databaseId,
  }) : _databasePath = p.posix.join(
         'projects',
         projectId,
         'databases',
         databaseId,
       );

  final g.FirestoreApi _api;
  final String _databasePath;

  /// Returns the full database path to the `documents/` Firestore path.
  ///
  /// If [path] is provided, it is appended at the end.
  ///
  /// ## Example
  ///
  /// ```dart
  /// print(firestore.resolveDocumentsPath());
  /// // Outputs: projects/project-id/databases/database-id/documents
  ///
  /// print(firestore.resolveDocumentsPath('task/task-name'));
  /// // Outputs: projects/project-id/databases/database-id/documents/task/task-name
  /// ```
  String resolveDocumentsPath([String? path]) {
    return p.posix.join(_databasePath, 'documents', path);
  }

  /// Direct access to [g.FirestoreApi].
  ///
  /// This is used as a migration aid so that all (existing) calls to older
  /// implementations of [Firestore] within `app_dart` do not have to
  /// immediately start using `this`.
  g.FirestoreApi get apiDuringMigration => _api;

  /// Updates the [Document] at the _relative_ [path] to [document].
  ///
  /// If the document was found, it is updated, otherwise `null` is returned.
  ///
  /// If it is invalid within your app to update a document that does not exist,
  /// i.e. you would ignore the result, use [updateByPath].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryUpdateByPath('tasks/task-that-might-exist', document);
  /// ```
  @useResult
  Future<g.Document?> tryUpdateByPath(String path, g.Document document) async {
    try {
      return await _api.projects.databases.documents.patch(
        document,
        resolveDocumentsPath(path),
        currentDocument_exists: true,
      );
    } on g.DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        return null;
      }
      rethrow;
    }
  }

  /// Updates the [Document] at the _relative_ [path] to [document].
  ///
  /// If the document was found, it is updated, otherwise `null` is returned.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.updateByPath('tasks/task-that-might-exist', document);
  /// ```
  @nonVirtual
  Future<g.Document> updateByPath(String path, g.Document document) async {
    final inserted = await tryUpdateByPath(path, document);
    if (inserted == null) {
      throw StateError('No document found at "$path"');
    }
    return inserted;
  }

  /// Upserts the [Document] at the _relative_ [path] to [document].
  ///
  /// If the document already exists, it is updated, otherwise it is inserted.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.upsertByPath('tasks/task-that-might-exist', document);
  /// ```
  @useResult
  Future<g.Document> upsertByPath(String path, g.Document document) async {
    return await _api.projects.databases.documents.patch(
      document,
      resolveDocumentsPath(path),
    );
  }

  /// Returns the [Document] at the _relative_ [path] within Firestore.
  ///
  /// If the document was not found, returns `null`.
  ///
  /// If it is invalid within your app to access a document that doesn't exist,
  /// i.e. you would write `result!`, use [getByPath].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryGet('tasks/document-name-of-task`);
  /// ```
  @useResult
  Future<g.Document?> tryGetByPath(String path) async {
    try {
      return await _api.projects.databases.documents.get(
        resolveDocumentsPath(path),
      );
    } on g.DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.notFound) {
        return null;
      }
      rethrow;
    }
  }

  /// Returns the [Document] at the _relative_ [path] within Firestore.
  ///
  /// The document must already exist.
  ///
  /// If it is valid within your app to access a document that doesn't exist,
  /// use [tryGetByPath].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.getByPath('tasks/task-that-definitely-exists');
  /// ```
  @nonVirtual
  Future<g.Document> getByPath(String path) async {
    final document = await tryGetByPath(path);
    if (document == null) {
      throw StateError('No document found at "$path"');
    }
    return document;
  }

  /// Inserts the [Document] at the _relative_ [path] to [document].
  ///
  /// If the document already exists, returns `null`, otherwise returns the
  /// updated document.
  ///
  /// If it is invalid within your app to insert a document that already exists,
  /// i.e. you would ignore the result, use [insertByPath].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryInsertByPath('tasks/task-that-might-exist', document);
  /// ```
  @useResult
  Future<g.Document?> tryInsertByPath(String path, g.Document document) async {
    try {
      // TODO(matanlurey): Make this an error instead of stripping it off.
      // Document.name cannot be set on an inserted path, but some documents
      // use ".name" as a synthetic field (i.e. Task.attempts) where it would
      // be cumbersome and error-prone to remember to sometimes clear the name.
      //
      // See https://github.com/flutter/flutter/issues/166229.
      final clone = g.Document(fields: {...?document.fields});
      assert(clone.name == null, 'Name must be null for new documents');
      return await _api.projects.databases.documents.createDocument(
        clone,
        resolveDocumentsPath(),
        p.dirname(path),
        documentId: p.basename(path),
      );
    } on g.DetailedApiRequestError catch (e) {
      if (e.status == HttpStatus.conflict) {
        return null;
      }
      rethrow;
    }
  }

  /// Inserts the [Document] at the _relative_ [path] to [document].
  ///
  /// If the document already exists, returns `null`, otherwise returns the
  /// updated document.
  ///
  /// If it is invalid within your app to insert a document that already exists,
  /// i.e. you would ignore the result, use [insertByPath].
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryInsertByPath('tasks/task-that-might-exist', document);
  /// ```
  @nonVirtual
  Future<g.Document> insertByPath(String path, g.Document document) async {
    final inserted = await tryInsertByPath(path, document);
    if (inserted == null) {
      throw StateError('Existing document found at "$path"');
    }
    return inserted;
  }

  /// See <https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto>.
  static const _gRPC$Status$OK = 0;

  /// Batch writes (inserts or updates) _all_ [documents] into the database.
  ///
  /// Each key of [documents] is interpreted as the _path_ (similar to an
  /// operation like [insertByPath]), and each value is interpeted as the
  /// cooresponding document.
  ///
  /// Returns a list of boolean values indicating whether each individual
  /// document was successfully written, with a value of `true` indicating
  /// _yes_ and a value of `false` indicating _no_.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryBatchWrite({
  ///   'tasks/new-task-1': BatchWriteOperation.insert(taskDocument1),
  ///   'tasks/existing-task-2': BatchWriteOperation.update(taskDocument2),
  ///   'tasks/maybe-existing-task-3': BatchWriteOperation.upsert(taskDocument3),
  /// });
  /// ```
  Future<List<bool>> tryBatchWrite(
    Map<String, BatchWriteOperation> writes,
  ) async {
    final response = await _api.projects.databases.documents.batchWrite(
      g.BatchWriteRequest(
        writes: [
          for (final MapEntry(key: path, value: write) in writes.entries)
            internalToFirestoreWrite(
              write,
              documentPath: resolveDocumentsPath(path),
            ),
        ],
      ),
      _databasePath,
    );
    return [
      for (final status in response.status!) status.code == _gRPC$Status$OK,
    ];
  }
}
