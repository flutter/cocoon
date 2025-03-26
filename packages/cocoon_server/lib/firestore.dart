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

  @protected
  String getFullPath(String path) => p.posix.join(_databasePath, path);

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
    final fullPath = getFullPath(path);
    try {
      return await _api.projects.databases.documents.get(fullPath);
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
      return await _api.projects.databases.documents.createDocument(
        document,
        getFullPath('documents'),
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

  /// Inserts _all_ [documents] into the database.
  ///
  /// Each key of [documents] is interpreted as the _path_ (similar to an
  /// operation like [insertByPath]), and each value is interpeted as the
  /// cooresponding document.
  ///
  /// If the document already exists no changes are made.
  ///
  /// Returns a list of boolean values indicating whether each individual
  /// document was successfully inserted, with a value of `true` indicating
  /// _yes_ and a value of `false` indicating _no_.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryInsertAll({
  ///   'tasks/new-task-1': taskDocument1,
  ///   'tasks/new-task-2': taskDocument2,
  /// });
  /// ```
  Future<List<bool>> tryInsertAll(Map<String, g.Document> documents) async {
    final flatDocs = [
      for (final MapEntry(key: path, value: doc) in documents.entries)
        g.Document(name: getFullPath(path), fields: {...?doc.fields}),
    ];
    final response = await _api.projects.databases.documents.batchWrite(
      g.BatchWriteRequest(
        writes: [
          for (final document in flatDocs)
            g.Write(
              update: document,
              currentDocument: g.Precondition(exists: false),
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
