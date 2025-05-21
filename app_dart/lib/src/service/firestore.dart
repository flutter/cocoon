// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/access_client_provider.dart';
import 'package:cocoon_server/google_auth_provider.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/commit.dart';
import '../model/firestore/github_build_status.dart';
import '../model/firestore/github_gold_status.dart';
import '../model/firestore/task.dart';
import 'firestore/commit_and_tasks.dart';

export '../model/common/firestore_extensions.dart';

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
    Transaction? transaction,
  });

  static Map<String, String> _filterByTimeRAnge(
    String fieldName,
    TimeRange range,
  ) {
    return switch (range) {
      IndefiniteTimeRange() => const {},
      SpecificTimeRange(:final start, :final end, :final exclusive) => {
        if (start != null)
          '$fieldName ${exclusive ? '>' : '>='}':
              '${start.millisecondsSinceEpoch}',
        if (end != null)
          '$fieldName ${exclusive ? '<' : '<='}':
              '${end.millisecondsSinceEpoch}',
      },
    };
  }

  /// Queries for recent commits.
  ///
  /// The [limit] argument specifies the maximum number of commits to retrieve.
  ///
  /// The returned commits will be ordered by most recent [Commit.timestamp].
  Future<List<Commit>> queryRecentCommits({
    int limit = 100,
    TimeRange? created,
    String? branch,
    required RepositorySlug slug,
  }) async {
    branch ??= Config.defaultBranch(slug);
    created ??= TimeRange.indefinite;
    final filterMap = <String, Object>{
      '${Commit.fieldBranch} =': branch,
      '${Commit.fieldRepositoryPath} =': slug.fullName,
      ..._filterByTimeRAnge(Commit.fieldCreateTimestamp, created),
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

  Future<List<Task>> _queryTasks({
    required int? limit,
    String? name,
    TaskStatus? status,
    String? commitSha,
    Transaction? transaction,
  }) async {
    final filterMap = {
      if (name != null) '${Task.fieldName} =': name,
      if (status != null) '${Task.fieldStatus} =': status.value,
      if (commitSha != null) '${Task.fieldCommitSha} =': commitSha,
    };

    // Avoid a full table-scan.
    // TODO(matanlurey): Debatably this should be in the root query method.
    if (limit == null && filterMap.isEmpty) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Cannot set limit to "null" without other fields',
      );
    }

    // For tasks, therer is no reason to _not_ order this way.
    final orderMap = {Task.fieldCreateTimestamp: kQueryOrderDescending};
    final documents = await query(
      kTaskCollectionId,
      filterMap,
      orderMap: orderMap,
      transaction: transaction,
    );
    return [...documents.map(Task.fromDocument)];
  }

  /// Queries for recent [Task]s.
  ///
  /// If other named arguments are provided, they are used as a query filter.
  Future<List<Task>> queryRecentTasks({
    int limit = 100,
    String? name,
    TaskStatus? status,
    String? commitSha,
  }) async {
    return await _queryTasks(
      limit: limit,
      name: name,
      status: status,
      commitSha: commitSha,
    );
  }

  /// Returns _all_ tasks running against the speificed [commitSha].
  Future<List<Task>> queryAllTasksForCommit({
    required String commitSha,
    TaskStatus? status,
    String? name,
    Transaction? transaction,
  }) async {
    return await _queryTasks(
      limit: null,
      commitSha: commitSha,
      status: status,
      name: name,
      transaction: transaction,
    );
  }

  /// Queries the last [commitLimit] commits, and returns the commit and tasks.
  ///
  /// For tasks with multiple attempts, only the most recent task is returned.
  ///
  /// If [status] is provided, only tasks matching the status are returned.
  Future<List<CommitAndTasks>> queryRecentCommitsAndTasks(
    RepositorySlug slug, {
    required int commitLimit,
    TaskStatus? status,
    String? branch,
  }) async {
    final commits = await queryRecentCommits(
      slug: slug,
      limit: commitLimit,
      branch: branch,
    );
    return [
      for (final commit in commits)
        CommitAndTasks(
          commit.toRef(),
          await queryAllTasksForCommit(commitSha: commit.sha, status: status),
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
      return GithubGoldStatus(
        prNumber: prNumber,
        head: '',
        status: '',
        description: '',
        updates: 0,
        repository: slug.fullName,
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
            kGithubBuildStatusPrNumberField: prNumber.toValue(),
            kGithubBuildStatusHeadField: head.toValue(),
            kGithubBuildStatusStatusField: ''.toValue(),
            kGithubBuildStatusUpdatesField: 0.toValue(),
            kGithubBuildStatusUpdateTimeMillisField:
                DateTime.now().millisecondsSinceEpoch.toValue(),
            kGithubBuildStatusRepositoryField: slug.fullName.toValue(),
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
    return FirestoreService._(FirestoreApi(client));
  }

  const FirestoreService._(this._api);
  final FirestoreApi _api;

  /// Gets a document based on name.
  Future<Document> getDocument(String name, {Transaction? transaction}) async {
    return _api.projects.databases.documents.get(
      name,
      transaction: transaction?.identifier,
    );
  }

  /// Creates a document.
  ///
  /// A document name is automatically generated if [documentId] is omitted.
  ///
  /// If the document already exists, a 409 [DetailedApiRequestError] is thrown.
  Future<Document> createDocument(
    Document document, {
    required String collectionId,
    String? documentId,
  }) async {
    return _api.projects.databases.documents.createDocument(
      document,
      '$kDatabase/documents',
      collectionId,
      documentId: documentId,
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
    return _api.projects.databases.documents.batchWrite(request, database);
  }

  /// Begins a read-write transaction.
  Future<Transaction> beginTransaction() async {
    final request = BeginTransactionRequest(
      options: TransactionOptions(readWrite: ReadWrite()),
    );
    final response = await _api.projects.databases.documents.beginTransaction(
      request,
      kDatabase,
    );
    return Transaction._unwrap(response);
  }

  /// Commits a transaction.
  Future<CommitResponse> commit(
    Transaction transaction,
    List<Write> writes,
  ) async {
    final request = CommitRequest(
      transaction: transaction.identifier,
      writes: writes,
    );
    return await _api.projects.databases.documents.commit(request, kDatabase);
  }

  /// Rolls back a transaction.
  Future<void> rollback(Transaction transaction) async {
    final request = RollbackRequest(transaction: transaction.identifier);
    await _api.projects.databases.documents.rollback(request, kDatabase);
  }

  /// Writes [writes] to Firestore within a transaction.
  ///
  /// This is an atomic operation: either all writes succeed or all writes fail.
  Future<CommitResponse> writeViaTransaction(List<Write> writes) async {
    final beginTransactionRequest = BeginTransactionRequest(
      options: TransactionOptions(readWrite: ReadWrite()),
    );
    final beginTransactionResponse = await _api.projects.databases.documents
        .beginTransaction(beginTransactionRequest, kDatabase);
    final commitRequest = CommitRequest(
      transaction: beginTransactionResponse.transaction,
      writes: writes,
    );
    return _api.projects.databases.documents.commit(commitRequest, kDatabase);
  }

  /// Returns Firestore [Value] based on corresponding object type.
  Value _getValueFromFilter(Object comparisonOject) {
    if (comparisonOject is int) {
      return comparisonOject.toValue();
    } else if (comparisonOject is bool) {
      return comparisonOject.toValue();
    }
    return (comparisonOject as String).toValue();
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
    Transaction? transaction,
  }) async {
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
      transaction: transaction?.identifier,
    );
    final runQueryResponseElements = await _api.projects.databases.documents
        .runQuery(runQueryRequest, kDocumentParent);
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

/// An opaque object that represents a Firestore transaction.
@immutable
final class Transaction {
  factory Transaction._unwrap(BeginTransactionResponse response) {
    if (response.transaction case final tx?) {
      return Transaction.fromIdentifier(tx);
    }
    throw StateError('Unable to begin transaction');
  }

  @visibleForTesting
  const Transaction.fromIdentifier(this.identifier);

  /// The value that originates from [BeginTransactionResponse.transaction].
  @visibleForTesting
  final String identifier;

  @override
  bool operator ==(Object other) {
    return other is Transaction && identifier == other.identifier;
  }

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() {
    return 'Transaction <$identifier>';
  }
}
