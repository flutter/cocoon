// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/firestore.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart' as g;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/base.dart';
import '../model/firestore/commit.dart';
import '../model/firestore/github_build_status.dart';
import '../model/firestore/github_gold_status.dart';
import '../model/firestore/task.dart';
import 'config.dart';

const String kDatabase =
    'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}';
const String kDocumentParent = '$kDatabase/documents';
const String kFieldFilterOpEqual = 'EQUAL';
const String kFieldFilterOpNotEqual = 'NOT_EQUAL';
const String kCompositeFilterOpAnd = 'AND';
const String kQueryOrderDescending = 'DESCENDING';

const int kFilterStringSpaceSplitElements = 2;
const int kFilterStringSpaceSplitOpIndex = 1;

const Map<String, String> kRelationMapping = <String, String>{
  '=': 'EQUAL',
  '<': 'LESS_THAN',
  '<=': 'LESS_THAN_OR_EQUAL',
  '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL',
  '!=': 'NOT_EQUAL',
};

final kFieldMapRegExp = RegExp(
  r'([a-zA-Z0-9_\t ]+)'
  '(${kRelationMapping.keys.join("|")})',
);

@visibleForTesting
mixin FirestoreServiceMixin {
  @protected
  Firestore get api;

  String _resolvePath<T extends AppDocument<T>>(T document) {
    return api.resolvePath(document.runtimeMetadata.relativePath(document));
  }

  /// Inserts a [document].
  ///
  /// If the document already exists, returns `null`, otherwise returns the
  /// updated document.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryInsert(task);
  /// ```
  @useResult
  Future<T?> tryInsert<T extends AppDocument<T>>(T document) async {
    final inserted = await api.tryInsertByPath(
      _resolvePath(document),
      document,
    );
    if (inserted == null) {
      return null;
    }
    return document.runtimeMetadata.fromDocument(inserted);
  }

  /// Inserts a [document].
  ///
  /// The document must not already exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.insert(task);
  /// ```
  Future<T> insert<T extends AppDocument<T>>(T document) async {
    final inserted = await api.insertByPath(_resolvePath(document), document);
    return document.runtimeMetadata.fromDocument(inserted);
  }

  /// Upserts a [document].
  ///
  /// If the document already exists, updates it, otherwise inserts it.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.upsert(task);
  /// ```
  Future<T> upsert<T extends AppDocument<T>>(T document) async {
    final upserted = await api.upsertByPath(_resolvePath(document), document);
    return document.runtimeMetadata.fromDocument(upserted);
  }

  /// Updates a [document].
  ///
  /// If the document does not exists, return `null`, otherwise returns the
  /// updated document.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.tryUpdate(task);
  /// ```
  @useResult
  Future<T?> tryUpdate<T extends AppDocument<T>>(T document) async {
    final updated = await api.tryUpdateByPath(_resolvePath(document), document);
    if (updated == null) {
      return null;
    }
    return document.runtimeMetadata.fromDocument(updated);
  }

  /// Inserts a [document].
  ///
  /// The document must already exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await firestore.update(task);
  /// ```
  Future<T> update<T extends AppDocument<T>>(T document) async {
    final inserted = await api.updateByPath(_resolvePath(document), document);
    return document.runtimeMetadata.fromDocument(inserted);
  }

  void _checkBatchResults(Iterable<String> paths, List<bool> results) {
    if (paths.length != results.length) {
      throw ArgumentError('The number of paths and results must be the same.');
    }
    final failedPaths = <String>[];
    var i = 0;
    for (final path in paths) {
      if (!results[i]) {
        failedPaths.add(path);
      }
      i++;
    }
    if (failedPaths.isNotEmpty) {
      throw BatchWriteException(failedPaths);
    }
  }

  /// Inserts a list of [documents].
  ///
  /// Each document must not already exist.
  Future<void> insertAll<T extends AppDocument<T>>(
    Iterable<T> documents,
  ) async {
    final paths = {
      for (final document in documents) _resolvePath(document): document,
    };
    _checkBatchResults(paths.keys, await api.tryInsertAll(paths));
  }

  /// Updates a list of [documents].
  ///
  /// Each document must already exist.
  Future<void> updateAll<T extends AppDocument<T>>(
    Iterable<T> documents,
  ) async {
    final paths = {
      for (final document in documents) _resolvePath(document): document,
    };
    _checkBatchResults(paths.keys, await api.tryUpdateAll(paths));
  }

  /// Upserts a list of [documents].
  ///
  /// Each document may or may not already exist.
  Future<void> upsertAll<T extends AppDocument<T>>(
    Iterable<T> documents,
  ) async {
    final paths = {
      for (final document in documents) _resolvePath(document): document,
    };
    _checkBatchResults(paths.keys, await api.tryUpsertAll(paths));
  }
}

final class BatchWriteException implements Exception {
  BatchWriteException(this.failedPaths);
  final List<String> failedPaths;

  @override
  String toString() {
    return 'BatchWriteException: $failedPaths';
  }
}

/// An application-specific storage API around Google Firestore.
///
/// This API is in a state of flux, where the non-app specific APIs are being
/// migrated to a common API (https://github.com/flutter/flutter/issues/165931).
class FirestoreService with FirestoreServiceMixin {
  /// Creates a [BigqueryService] using Google API authentication.
  static Future<FirestoreService> from(GoogleAuthProvider authProvider) async {
    return FirestoreService._(
      await Firestore.from(
        authProvider,
        projectId: Config.flutterGcpProjectId,
        databaseId: Config.flutterGcpFirestoreDatabase,
      ),
    );
  }

  const FirestoreService._(this.api);

  @override
  @protected
  final Firestore api;

  /// Return a [ProjectsDatabasesDocumentsResource] with an authenticated [client]
  Future<g.ProjectsDatabasesDocumentsResource> documentResource() async {
    return api.apiDuringMigration.projects.databases.documents;
  }

  /// Gets a document based on name.
  Future<g.Document> getDocument(String name) async {
    final databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.get(name);
  }

  /// Writes [writes] to Firestore within a transaction.
  ///
  /// This is an atomic operation: either all writes succeed or all writes fail.
  Future<g.CommitResponse> writeViaTransaction(List<g.Write> writes) async {
    final databasesDocumentsResource = await documentResource();
    final beginTransactionRequest = g.BeginTransactionRequest(
      options: g.TransactionOptions(readWrite: g.ReadWrite()),
    );
    final beginTransactionResponse = await databasesDocumentsResource
        .beginTransaction(beginTransactionRequest, kDatabase);
    final commitRequest = g.CommitRequest(
      transaction: beginTransactionResponse.transaction,
      writes: writes,
    );
    return databasesDocumentsResource.commit(commitRequest, kDatabase);
  }

  /// Queries for recent commits.
  ///
  /// The [limit] argument specifies the maximum number of commits to retrieve.
  ///
  /// The returned commits will be ordered by most recent [Commit.timestamp].
  Future<List<Commit>> queryRecentCommits({
    int limit = 100,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) async {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;
    branch ??= Config.defaultBranch(slug);
    final filterMap = <String, Object>{
      '${Commit.fieldBranch} =': branch,
      '${Commit.fieldRepositoryPath} =': slug.fullName,
      '${Commit.fieldCreateTimestamp} <': timestamp,
    };
    final orderMap = <String, String>{
      Commit.fieldCreateTimestamp: kQueryOrderDescending,
    };
    final documents = await query(
      Commit.collectionId,
      filterMap,
      orderMap: orderMap,
      limit: limit,
    );
    return [...documents.map(Commit.fromDocument)];
  }

  /// Queries for recent [Task] by [name].
  Future<List<Task>> queryRecentTasksByName({
    int limit = 100,
    required String name,
  }) async {
    final filterMap = {'${Task.fieldName} =': name};
    final orderMap = {Task.fieldCreateTimestamp: kQueryOrderDescending};
    final documents = await query(
      kTaskCollectionId,
      filterMap,
      orderMap: orderMap,
    );
    return [...documents.map(Task.fromDocument)];
  }

  /// Returns all tasks running against the speificed [commitSha].
  Future<List<Task>> queryCommitTasks(String commitSha) async {
    final filterMap = <String, Object>{'${Task.fieldCommitSha} =': commitSha};
    final orderMap = <String, String>{
      Task.fieldCreateTimestamp: kQueryOrderDescending,
    };
    final documents = await query(
      kTaskCollectionId,
      filterMap,
      orderMap: orderMap,
    );
    return [...documents.map(Task.fromDocument)];
  }

  /// Queries the last updated Gold status for the [slug] and [prNumber].
  ///
  /// If not existing, returns a fresh new Gold status.
  Future<GithubGoldStatus> queryLastGoldStatus(
    RepositorySlug slug,
    int prNumber,
  ) async {
    final filterMap = <String, Object>{
      '$kGithubGoldStatusPrNumberField =': prNumber,
      '$kGithubGoldStatusRepositoryField =': slug.fullName,
    };
    final documents = await query(kGithubGoldStatusCollectionId, filterMap);
    final githubGoldStatuses = [
      ...documents.map(GithubGoldStatus.fromDocument),
    ];
    if (githubGoldStatuses.isEmpty) {
      return GithubGoldStatus.fromDocument(
        g.Document(
          name:
              '$kDatabase/documents/$kGithubGoldStatusCollectionId/${slug.owner}_${slug.name}_$prNumber',
          fields: <String, g.Value>{
            kGithubGoldStatusPrNumberField: g.Value(
              integerValue: prNumber.toString(),
            ),
            kGithubGoldStatusHeadField: g.Value(stringValue: ''),
            kGithubGoldStatusStatusField: g.Value(stringValue: ''),
            kGithubGoldStatusUpdatesField: g.Value(integerValue: '0'),
            kGithubGoldStatusDescriptionField: g.Value(stringValue: ''),
            kGithubGoldStatusRepositoryField: g.Value(
              stringValue: slug.fullName,
            ),
          },
        ),
      );
    } else {
      if (githubGoldStatuses.length > 1) {
        throw StateError(
          'GithubGoldStatusUpdate should have no more than one entry on '
          'repository ${slug.fullName}, pr $prNumber.',
        );
      }
      return githubGoldStatuses.single;
    }
  }

  /// Queries the last updated build status for the [slug], [prNumber], and [head].
  ///
  /// If not existing, returns a fresh new Build status.
  Future<GithubBuildStatus> queryLastBuildStatus(
    RepositorySlug slug,
    int prNumber,
    String head,
  ) async {
    final filterMap = <String, Object>{
      '$kGithubBuildStatusPrNumberField =': prNumber,
      '$kGithubBuildStatusRepositoryField =': slug.fullName,
      '$kGithubBuildStatusHeadField =': head,
    };
    final documents = await query(kGithubBuildStatusCollectionId, filterMap);
    final githubBuildStatuses =
        documents.map(GithubBuildStatus.fromDocument).toList();
    if (githubBuildStatuses.isEmpty) {
      return GithubBuildStatus.fromDocument(
        g.Document(
          name:
              '$kDatabase/documents/$kGithubBuildStatusCollectionId/${head}_$prNumber',
          fields: <String, g.Value>{
            kGithubBuildStatusPrNumberField: g.Value(
              integerValue: prNumber.toString(),
            ),
            kGithubBuildStatusHeadField: g.Value(stringValue: head),
            kGithubBuildStatusStatusField: g.Value(stringValue: ''),
            kGithubBuildStatusUpdatesField: g.Value(integerValue: '0'),
            kGithubBuildStatusUpdateTimeMillisField: g.Value(
              integerValue: DateTime.now().millisecondsSinceEpoch.toString(),
            ),
            kGithubBuildStatusRepositoryField: g.Value(
              stringValue: slug.fullName,
            ),
          },
        ),
      );
    } else {
      if (githubBuildStatuses.length > 1) {
        throw StateError(
          'GithubBuildStatus should have no more than one entry on '
          'repository ${slug.fullName}, pr $prNumber, and head $head.',
        );
      }
      return githubBuildStatuses.single;
    }
  }

  /// Returns Firestore [Value] based on corresponding object type.
  g.Value getValueFromFilter(Object comparisonOject) {
    if (comparisonOject is int) {
      return g.Value(integerValue: comparisonOject.toString());
    } else if (comparisonOject is bool) {
      return g.Value(booleanValue: comparisonOject);
    }
    return g.Value(stringValue: comparisonOject as String);
  }

  /// Generates Firestore query filter based on "human" read conditions.
  g.Filter generateFilter(
    Map<String, Object> filterMap,
    String compositeFilterOp,
  ) {
    final filters = <g.Filter>[];
    filterMap.forEach((filterString, comparisonOject) {
      final match = kFieldMapRegExp.firstMatch(filterString);
      if (match == null) {
        throw ArgumentError("Invalid filter string '$filterString'.");
      }
      final [name!, comparison!] = match.groups([1, 2]);
      if (!kRelationMapping.containsKey(comparison)) {
        throw ArgumentError("Invalid filter comparison in '$filterString'.");
      }

      final value = getValueFromFilter(comparisonOject);
      filters.add(
        g.Filter(
          fieldFilter: g.FieldFilter(
            field: g.FieldReference(fieldPath: '`${name.trim()}`'),
            op: kRelationMapping[comparison],
            value: value,
          ),
        ),
      );
    });
    return g.Filter(
      compositeFilter: g.CompositeFilter(
        filters: filters,
        op: compositeFilterOp,
      ),
    );
  }

  List<g.Order>? generateOrders(Map<String, String>? orderMap) {
    if (orderMap == null || orderMap.isEmpty) {
      return null;
    }
    final orders = <g.Order>[];
    orderMap.forEach((field, direction) {
      orders.add(
        g.Order(
          field: g.FieldReference(fieldPath: field),
          direction: direction,
        ),
      );
    });
    return orders;
  }

  /// Wrapper to simplify Firestore query.
  ///
  /// The [filterMap] follows format:
  ///   {
  ///     'fieldInt =': 1,
  ///     'fieldString =': 'string',
  ///     'fieldBool =': true,
  ///   }
  /// Note
  ///   1. the space in the key, which will be used to retrieve the field name and operator.
  ///   2. the value could be any type, like int, string, bool, etc.
  Future<List<g.Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  }) async {
    final databasesDocumentsResource = await documentResource();
    final from = <g.CollectionSelector>[
      g.CollectionSelector(collectionId: collectionId),
    ];
    final filter = generateFilter(filterMap, compositeFilterOp);
    final orders = generateOrders(orderMap);
    final runQueryRequest = g.RunQueryRequest(
      structuredQuery: g.StructuredQuery(
        from: from,
        where: filter,
        orderBy: orders,
        limit: limit,
      ),
    );
    final runQueryResponseElements = await databasesDocumentsResource.runQuery(
      runQueryRequest,
      kDocumentParent,
    );
    return documentsFromQueryResponse(runQueryResponseElements);
  }

  /// Retrieve documents based on query response.
  List<g.Document> documentsFromQueryResponse(
    List<g.RunQueryResponseElement> runQueryResponseElements,
  ) {
    final documents = <g.Document>[];
    for (var runQueryResponseElement in runQueryResponseElements) {
      if (runQueryResponseElement.document != null) {
        documents.add(runQueryResponseElement.document!);
      }
    }
    return documents;
  }
}

/// Creates a list of [Write] based on documents.
///
/// Null `exists` means either update when a document exists or insert when a document doesn't.
/// `exists = false` means inserting a new document, assuming a document doesn't exist.
/// `exists = true` means updating an existing document, assuming it exisits.
List<g.Write> documentsToWrites(List<g.Document> documents, {bool? exists}) {
  return documents
      .map(
        (g.Document document) => g.Write(
          update: document,
          currentDocument: g.Precondition(exists: exists),
        ),
      )
      .toList();
}
