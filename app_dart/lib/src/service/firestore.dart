// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/access_client_provider.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
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
mixin FirestoreQueries {
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
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  });

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
  Future<List<Task>> queryCommitTasks(
    String commitSha, {
    String? status,
  }) async {
    final filterMap = <String, Object>{
      '${Task.fieldCommitSha} =': commitSha,
      if (status != null) '${Task.fieldStatus} =': status,
    };
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

  /// Queries the last [commitLimit] commits, and returns the commit and tasks.
  ///
  /// For tasks with multiple attempts, only the most recent task is returned.
  ///
  /// If [status] is provided, only tasks matching the status are returned.
  Future<List<CommitAndTasks>> queryRecentCommitsAndTasks(
    RepositorySlug slug, {
    required int commitLimit,
    String? status,
  }) async {
    final commits = await queryRecentCommits(slug: slug, limit: commitLimit);
    return [
      for (final commit in commits)
        CommitAndTasks(
          commit,
          await queryCommitTasks(commit.sha, status: status),
        ).withMostRecentTaskOnly(),
    ];
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
        Document(
          name:
              '$kDatabase/documents/$kGithubGoldStatusCollectionId/${slug.owner}_${slug.name}_$prNumber',
          fields: <String, Value>{
            kGithubGoldStatusPrNumberField: Value(
              integerValue: prNumber.toString(),
            ),
            kGithubGoldStatusHeadField: Value(stringValue: ''),
            kGithubGoldStatusStatusField: Value(stringValue: ''),
            kGithubGoldStatusUpdatesField: Value(integerValue: '0'),
            kGithubGoldStatusDescriptionField: Value(stringValue: ''),
            kGithubGoldStatusRepositoryField: Value(stringValue: slug.fullName),
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

  /// Returns the latest [Task] for [commitSha] and [builderName].
  ///
  /// If no task exists, `null` is returned.
  Future<Task?> queryLatestTask({
    required String commitSha,
    required String builderName,
  }) async {
    final tasks = await query(
      kTaskCollectionId,
      {
        '${Task.fieldCommitSha} =': commitSha,
        '${Task.fieldName} =': builderName,
      },
      // Assumes the invariant where the newest task has the highest attempt #.
      orderMap: {Task.fieldCreateTimestamp: kQueryOrderDescending},
      limit: 1,
    );
    return tasks.isEmpty ? null : Task.fromDocument(tasks.first);
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
    final githubBuildStatuses = [
      ...documents.map(GithubBuildStatus.fromDocument),
    ];
    if (githubBuildStatuses.isEmpty) {
      return GithubBuildStatus.fromDocument(
        Document(
          name:
              '$kDatabase/documents/$kGithubBuildStatusCollectionId/${head}_$prNumber',
          fields: <String, Value>{
            kGithubBuildStatusPrNumberField: Value(
              integerValue: prNumber.toString(),
            ),
            kGithubBuildStatusHeadField: Value(stringValue: head),
            kGithubBuildStatusStatusField: Value(stringValue: ''),
            kGithubBuildStatusUpdatesField: Value(integerValue: '0'),
            kGithubBuildStatusUpdateTimeMillisField: Value(
              integerValue: DateTime.now().millisecondsSinceEpoch.toString(),
            ),
            kGithubBuildStatusRepositoryField: Value(
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
}

class FirestoreService with FirestoreQueries {
  /// Creates a [FirestoreService] using Google API authentication.
  static Future<FirestoreService> from(GoogleAuthProvider authProvider) async {
    final client = await authProvider.createClient(
      scopes: const [FirestoreApi.datastoreScope],
      baseClient: FirestoreBaseClient(
        projectId: Config.flutterGcpProjectId,
        databaseId: Config.flutterGcpFirestoreDatabase,
      ),
    );
    return FirestoreService._(client);
  }

  const FirestoreService._(this._client);
  final http.Client _client;

  /// Return a [ProjectsDatabasesDocumentsResource] with an authenticated [client]
  Future<ProjectsDatabasesDocumentsResource> documentResource() async {
    return FirestoreApi(_client).projects.databases.documents;
  }

  /// Gets a document based on name.
  Future<Document> getDocument(String name) async {
    final databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.get(name);
  }

  /// Creates a document.
  ///
  /// A document name is automatically generated.
  ///
  /// If the document already exists, a 409 [DetailedApiRequestError] is thrown.
  Future<Document> createDocument(
    Document document, {
    required String collectionId,
  }) async {
    final databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.createDocument(
      document,
      '$kDatabase/documents',
      collectionId,
    );
  }

  /// Batch writes documents to Firestore.
  ///
  /// It does not apply the write operations atomically and can apply them out of order.
  /// Each write succeeds or fails independently.
  ///
  /// https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/batchWrite
  Future<BatchWriteResponse> batchWriteDocuments(
    BatchWriteRequest request,
    String database,
  ) async {
    final databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.batchWrite(request, database);
  }

  /// Writes [writes] to Firestore within a transaction.
  ///
  /// This is an atomic operation: either all writes succeed or all writes fail.
  Future<CommitResponse> writeViaTransaction(List<Write> writes) async {
    final databasesDocumentsResource = await documentResource();
    final beginTransactionRequest = BeginTransactionRequest(
      options: TransactionOptions(readWrite: ReadWrite()),
    );
    final beginTransactionResponse = await databasesDocumentsResource
        .beginTransaction(beginTransactionRequest, kDatabase);
    final commitRequest = CommitRequest(
      transaction: beginTransactionResponse.transaction,
      writes: writes,
    );
    return databasesDocumentsResource.commit(commitRequest, kDatabase);
  }

  /// Returns Firestore [Value] based on corresponding object type.
  Value _getValueFromFilter(Object comparisonOject) {
    if (comparisonOject is int) {
      return Value(integerValue: comparisonOject.toString());
    } else if (comparisonOject is bool) {
      return Value(booleanValue: comparisonOject);
    }
    return Value(stringValue: comparisonOject as String);
  }

  /// Generates Firestore query filter based on "human" read conditions.
  Filter _generateFilter(
    Map<String, Object> filterMap,
    String compositeFilterOp,
  ) {
    final filters = <Filter>[];
    filterMap.forEach((filterString, comparisonOject) {
      final match = kFieldMapRegExp.firstMatch(filterString);
      if (match == null) {
        throw ArgumentError("Invalid filter string '$filterString'.");
      }
      final [name!, comparison!] = match.groups([1, 2]);
      if (!kRelationMapping.containsKey(comparison)) {
        throw ArgumentError("Invalid filter comparison in '$filterString'.");
      }

      final value = _getValueFromFilter(comparisonOject);
      filters.add(
        Filter(
          fieldFilter: FieldFilter(
            field: FieldReference(fieldPath: '`${name.trim()}`'),
            op: kRelationMapping[comparison],
            value: value,
          ),
        ),
      );
    });
    return Filter(
      compositeFilter: CompositeFilter(filters: filters, op: compositeFilterOp),
    );
  }

  List<Order>? _generateOrders(Map<String, String>? orderMap) {
    if (orderMap == null || orderMap.isEmpty) {
      return null;
    }
    final orders = <Order>[];
    orderMap.forEach((field, direction) {
      orders.add(
        Order(field: FieldReference(fieldPath: field), direction: direction),
      );
    });
    return orders;
  }

  @override
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  }) async {
    final databasesDocumentsResource = await documentResource();
    final from = <CollectionSelector>[
      CollectionSelector(collectionId: collectionId),
    ];
    final filter = _generateFilter(filterMap, compositeFilterOp);
    final orders = _generateOrders(orderMap);
    final runQueryRequest = RunQueryRequest(
      structuredQuery: StructuredQuery(
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
    return _documentsFromQueryResponse(runQueryResponseElements);
  }

  /// Retrieve documents based on query response.
  List<Document> _documentsFromQueryResponse(
    List<RunQueryResponseElement> runQueryResponseElements,
  ) {
    final documents = <Document>[];
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
List<Write> documentsToWrites(List<Document> documents, {bool? exists}) {
  return documents
      .map(
        (Document document) => Write(
          update: document,
          currentDocument: Precondition(exists: exists),
        ),
      )
      .toList();
}

/// A pairing of a [Commit] and [Task]s associated with that commit.
@immutable
final class CommitAndTasks {
  /// Creates a [CommitAndTasks] with the provided commit and tasks.
  CommitAndTasks(this.commit, Iterable<Task> tasks)
    : tasks = List.unmodifiable(tasks);

  /// Commit from Firestore.
  final Commit commit;

  /// Tasks where [Task.commitSha] is the same as [Commit.sha].
  ///
  /// This list is unmodifiable.`
  final List<Task> tasks;

  /// Returns a copy of `this` with only the most recent task per builder.
  ///
  /// For example, if a task `Linux foo` was run 3 times, only the most recent
  /// task (`Linux foo`, `attempt = 3`) is retained in the accompanying [tasks]
  /// list, and the rest of the tasks are removed.
  @useResult
  CommitAndTasks withMostRecentTaskOnly() {
    final mostRecent = <String, Task>{};
    for (final task in tasks) {
      mostRecent.update(task.taskName, (current) {
        return current.currentAttempt > task.createTimestamp ? current : task;
      }, ifAbsent: () => task);
    }
    return CommitAndTasks(commit, mostRecent.values);
  }
}
