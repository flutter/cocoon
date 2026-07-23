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
import 'package:path/path.dart' as p;

import '../../cocoon_service.dart';
import '../model/firestore/github_build_status.dart';
import '../model/firestore/github_gold_status.dart';

import 'firestore/commit_and_tasks.dart';
import 'firestore/task_cache_service.dart';

export '../model/common/firestore_extensions.dart';

const String kDatabase =
    'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}';
const String kDocumentParent = '$kDatabase/documents';
const String kFieldFilterOpEqual = 'EQUAL';
const String kFieldFilterOpNotEqual = 'NOT_EQUAL';
const String kCompositeFilterOpAnd = 'AND';
const String kCompositeFilterOpOr = 'OR';
const String kQueryOrderDescending = 'DESCENDING';
const String kQueryOrderAscending = 'ASCENDING';

const int kFilterStringSpaceSplitElements = 2;
const int kFilterStringSpaceSplitOpIndex = 1;

const Map<String, String> kRelationMapping = <String, String>{
  '=': 'EQUAL',
  '<': 'LESS_THAN',
  '<=': 'LESS_THAN_OR_EQUAL',
  '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL',
  '!=': 'NOT_EQUAL',
  '@>': 'ARRAY_CONTAINS',
};

final kFieldMapRegExp = RegExp(
  r'([a-zA-Z0-9_\t ]+)'
  '(${kRelationMapping.keys.join("|")})',
);

@visibleForTesting
/// Mixin that encapsulates Firestore query and caching operations across Cocoon.
///
/// Task caching orchestration is delegated to [TaskCacheService].
/// See [TaskCacheService] for full architectural documentation and caching invariant flowcharts.
mixin FirestoreQueries {
  CacheService? get cache => null;
  Config? get config => null;

  /// Lazy accessor for [TaskCacheService].
  TaskCacheService? get _taskCache {
    if (cache == null || !(config?.flags.taskCachingEnabled ?? true)) {
      return null;
    }
    return TaskCacheService(cache: cache!, config: config);
  }

  Future<Document> getDocument(String name, {Transaction? transaction});
  @protected
  @visibleForTesting
  Future<List<Document>> batchGetDocuments(
    List<String> names, {
    Transaction? transaction,
  });
  Future<Transaction> beginTransaction();
  Future<CommitResponse> commit(Transaction transaction, List<Write> writes);
  Future<BatchWriteResponse> batchWriteDocuments(
    BatchWriteRequest request,
    String database,
  );

  /// Queries all tasks for [commitSha] from Firestore, updates their individual cache entries,
  /// Retrieves a [Task] by its document ID, serving from versioned cache if available,
  /// or fetching from Firestore DB on cache miss and populating the cache.
  Future<Task> getTask(AppDocumentId<Task> id) async {
    final docId = id.documentId;
    if (_taskCache != null) {
      final result = await _taskCache!.getTaskPayloads([docId]);
      if (result.foundTasks.isNotEmpty) {
        return result.foundTasks.first;
      }
    }

    final docName = p.posix.join(
      kDatabase,
      'documents',
      kTaskCollectionId,
      docId,
    );
    final document = await getDocument(docName);
    final task = Task.fromDocument(document);

    await _taskCache?.cacheTaskPayloads([task]);
    return task;
  }

  /// Caches payloads for modified [Task] entities.
  Future<void> cacheTaskPayloads(Iterable<Task> tasks) async {
    await _taskCache?.cacheTaskPayloads(tasks);
  }

  /// Queries all tasks for [commitSha] from Firestore, updates their individual cache entries,
  /// and populates the `tasks_by_commit_ids` set.
  Future<List<Task>> _fetchAndCacheCommitTasks(String commitSha) async {
    final documents = await query(
      kTaskCollectionId,
      {'${Task.fieldCommitSha} =': commitSha},
      orderMap: {Task.fieldCreateTimestamp: kQueryOrderDescending},
    );
    final tasks = documents.map(Task.fromDocument).toList();
    if (_taskCache != null) {
      final docIds = {for (final t in tasks) p.basename(t.name!)};
      await [
        _taskCache!.cacheTaskPayloads(tasks),
        if (docIds.isNotEmpty)
          () async {
            final initialized = await _taskCache!.initializeCommitTaskSet(
              commitSha,
              docIds,
            );
            if (!initialized) {
              await _taskCache!.addTasksToCommitSet(commitSha, docIds);
            }
          }(),
      ].wait;
    }
    return tasks;
  }

  /// Explicitly updates the cache when new [Task]s are created.
  Future<void> updateCacheForCreatedTasks(List<Task> tasks) async {
    if (_taskCache == null || tasks.isEmpty) return;
    await _taskCache!.cacheTaskPayloads(tasks);

    final tasksByCommit = <String, Set<String>>{};
    for (final task in tasks) {
      if (task.commitSha.isNotEmpty) {
        final docId = p.basename(task.name!);
        tasksByCommit.putIfAbsent(task.commitSha, () => {}).add(docId);
      }
    }

    for (final entry in tasksByCommit.entries) {
      final commitSha = entry.key;
      final docIds = entry.value;
      final setExisted = await _taskCache!.addTasksToCommitSet(
        commitSha,
        docIds,
      );
      if (!setExisted) {
        // Set was missing in Redis: fall back to full database query to populate set
        await _fetchAndCacheCommitTasks(commitSha);
      }
    }
  }

  /// Saves or updates [Task] entities in Firestore and updates the versioned Redis cache.
  Future<void> updateTasks(List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final writes = documentsToWrites(tasks);
    await batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
    await _taskCache?.cacheTaskPayloads(tasks);
  }

  /// Updates the status of tasks identified by [taskStatusMap] within a single Firestore transaction
  /// and updates the versioned task cache.
  Future<void> updateTaskStatuses(Map<TaskId, TaskStatus> taskStatusMap) async {
    if (taskStatusMap.isEmpty) return;

    final docIds = taskStatusMap.keys
        .map(
          (id) => p.posix.join(
            kDatabase,
            'documents',
            kTaskCollectionId,
            id.documentId,
          ),
        )
        .toList();

    final transaction = await beginTransaction();
    final docs = await batchGetDocuments(docIds, transaction: transaction);
    final tasksToUpdate = <Task>[];

    for (final doc in docs) {
      final task = Task.fromDocument(doc);
      final id = TaskId(
        commitSha: task.commitSha,
        taskName: task.taskName,
        currentAttempt: task.currentAttempt,
      );
      final newStatus = taskStatusMap[id];
      if (newStatus != null) {
        task.setStatus(newStatus);
        tasksToUpdate.add(task);
      }
    }

    final writes = documentsToWrites(tasksToUpdate);
    await commit(transaction, writes);
    await _taskCache?.cacheTaskPayloads(tasksToUpdate);
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
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
    Transaction? transaction,
  });

  static Map<String, Object> _filterByTimeRange(
    String fieldName,
    TimeRange range,
  ) {
    return switch (range) {
      IndefiniteTimeRange() => const {},
      SpecificTimeRange(:final start, :final end, :final exclusive) => {
        if (start != null)
          '$fieldName ${exclusive ? '>' : '>='}': start.millisecondsSinceEpoch,
        if (end != null)
          '$fieldName ${exclusive ? '<' : '<='}': end.millisecondsSinceEpoch,
      },
    };
  }

  /// Queries for recent commits.
  ///
  /// If [limit] is `null`, all commits are returned.
  ///
  /// The returned commits will be ordered by most recent
  /// [Commit.createTimestamp].
  Future<List<Commit>> queryRecentCommits({
    required int? limit,
    required RepositorySlug slug,
    TimeRange? created,
    String? branch,
  }) async {
    created ??= TimeRange.indefinite;
    final filterMap = <String, Object>{
      '${Commit.fieldRepositoryPath} =': slug.fullName,
      '${Commit.fieldBranch} =': ?branch,
      ..._filterByTimeRange(Commit.fieldCreateTimestamp, created),
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

  /// Queries for a commit by its [sha] and [slug].
  ///
  /// Returns `null` if no matching commit is found.
  Future<Commit?> queryCommit({
    required String sha,
    required RepositorySlug slug,
  }) async {
    final filterMap = <String, Object>{
      '${Commit.fieldRepositoryPath} =': slug.fullName,
      '${Commit.fieldSha} =': sha,
    };
    final documents = await query(Commit.collectionId, filterMap, limit: 1);
    return documents.isEmpty ? null : Commit.fromDocument(documents.first);
  }

  Future<List<Task>> _queryTasksFromFirestore({
    int? limit,
    String? name,
    TaskStatus? status,
    String? commitSha,
    Transaction? transaction,
    bool cacheResults = true,
  }) async {
    final filterMap = <String, Object>{
      '${Task.fieldName} =': ?name,
      '${Task.fieldStatus} =': ?status?.value,
      '${Task.fieldCommitSha} =': ?commitSha,
    };

    if (limit == null && filterMap.isEmpty) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Cannot set limit to "null" without other fields',
      );
    }

    final orderMap = {Task.fieldCreateTimestamp: kQueryOrderDescending};
    final documents = await query(
      kTaskCollectionId,
      filterMap,
      orderMap: orderMap,
      limit: limit,
      transaction: transaction,
    );
    final tasks = documents.map(Task.fromDocument).toList();
    if (cacheResults && transaction == null && _taskCache != null) {
      await _taskCache!.cacheTaskPayloads(tasks);
    }
    return tasks;
  }

  Future<List<Task>> _queryTasksByCommit({
    required String commitSha,
    String? name,
    TaskStatus? status,
    int? limit,
    Transaction? transaction,
  }) async {
    if (transaction == null &&
        cache != null &&
        (config?.flags.taskCachingEnabled ?? true)) {
      return await _queryTasksByCommitCached(
        commitSha: commitSha,
        name: name,
        status: status,
        limit: limit,
      );
    }
    return await _queryTasksFromFirestore(
      commitSha: commitSha,
      name: name,
      status: status,
      limit: limit,
      transaction: transaction,
      cacheResults: false,
    );
  }

  Future<List<Task>> _queryTasksByCommitCached({
    required String commitSha,
    String? name,
    TaskStatus? status,
    int? limit,
  }) async {
    List<Task>? tasks;
    final docIds = await _taskCache!.getTaskIdsForCommit(commitSha);
    if (docIds != null && docIds.isNotEmpty) {
      final lookupResult = await _taskCache!.getTaskPayloads(docIds);
      final foundTasks = lookupResult.foundTasks;

      if (lookupResult.missingDocIds.isEmpty) {
        tasks = foundTasks;
      } else {
        final missingNames = lookupResult.missingDocIds
            .map(
              (String missingId) => p.posix.join(
                kDatabase,
                'documents',
                kTaskCollectionId,
                missingId,
              ),
            )
            .toList();
        final documents = await batchGetDocuments(missingNames);
        final fetchedMissingTasks = documents.map(Task.fromDocument).toList();
        if (fetchedMissingTasks.isNotEmpty) {
          await _taskCache!.cacheTaskPayloads(fetchedMissingTasks);
          foundTasks.addAll(fetchedMissingTasks);
        }
        tasks = foundTasks;
      }
    }

    tasks ??= await _fetchAndCacheCommitTasks(commitSha);

    var result = tasks.toList();
    if (name != null) {
      result = result.where((t) => t.taskName == name).toList();
    }
    if (status != null) {
      result = result.where((t) => t.status == status).toList();
    }
    result.sort((a, b) => b.createTimestamp.compareTo(a.createTimestamp));
    if (limit != null) {
      result = result.take(limit).toList();
    }
    return result;
  }

  /// Queries for recent [Task]s across commits matching [name].
  ///
  /// If [status] is provided, only tasks matching the status are returned.
  Future<List<Task>> queryRecentTasksByName({
    required String name,
    int limit = 100,
    TaskStatus? status,
  }) async {
    return await _queryTasksFromFirestore(
      limit: limit,
      name: name,
      status: status,
    );
  }

  /// Queries [Task]s running against the specified [commitSha].
  ///
  /// If [name] is provided, only tasks matching the task name are returned.
  /// If [status] is provided, only tasks matching the status are returned.
  /// If [limit] is provided, at most [limit] tasks are returned.
  Future<List<Task>> queryRecentTasksByCommit({
    required String commitSha,
    String? name,
    TaskStatus? status,
    int? limit,
  }) async {
    return await _queryTasksByCommit(
      commitSha: commitSha,
      name: name,
      status: status,
      limit: limit,
    );
  }

  /// Returns _all_ tasks running against the speificed [commitSha].
  Future<List<Task>> queryAllTasksForCommit({
    required String commitSha,
    TaskStatus? status,
    String? name,
    Transaction? transaction,
  }) async {
    return await _queryTasksByCommit(
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

    final tasksFutures = commits.map(
      (commit) => queryAllTasksForCommit(commitSha: commit.sha, status: status),
    );
    final tasksResults = await Future.wait(tasksFutures);

    return [
      for (final (index, commit) in commits.indexed)
        CommitAndTasks(
          commit.toRef(),
          tasksResults[index],
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
    final tasks = await _queryTasksByCommit(
      commitSha: commitSha,
      name: builderName,
      limit: 1,
    );
    return tasks.isEmpty ? null : tasks.first;
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
            kGithubBuildStatusUpdateTimeMillisField: DateTime.now()
                .millisecondsSinceEpoch
                .toValue(),
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
  static Future<FirestoreService> from(
    GoogleAuthProvider authProvider, {
    CacheService? cache,
    Config? config,
  }) async {
    final client = await authProvider.createClient(
      scopes: const [FirestoreApi.datastoreScope],
      baseClient: FirestoreBaseClient(
        projectId: Config.flutterGcpProjectId,
        databaseId: Config.flutterGcpFirestoreDatabase,
      ),
    );
    return FirestoreService._(
      FirestoreApi(client),
      cache: cache,
      config: config,
    );
  }

  const FirestoreService._(this._api, {this.cache, this.config});
  final FirestoreApi _api;

  @override
  final CacheService? cache;

  @override
  final Config? config;

  /// Gets a document based on name.
  @override
  Future<Document> getDocument(String name, {Transaction? transaction}) async {
    return _api.projects.databases.documents.get(
      name,
      transaction: transaction?.identifier,
    );
  }

  /// Gets multiple documents based on a list of names in a single batch request.
  @override
  Future<List<Document>> batchGetDocuments(
    List<String> names, {
    Transaction? transaction,
  }) async {
    if (names.isEmpty) return const [];
    final request = BatchGetDocumentsRequest(
      documents: names,
      transaction: transaction?.identifier,
    );
    final response = await _api.projects.databases.documents.batchGet(
      request,
      kDatabase,
    );
    return response
        .map((element) => element.found)
        .whereType<Document>()
        .toList();
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
    final result = await _api.projects.databases.documents.createDocument(
      document,
      '$kDatabase/documents',
      collectionId,
      documentId: documentId,
    );
    if (_taskCache != null && collectionId == kTaskCollectionId) {
      await updateCacheForCreatedTasks([Task.fromDocument(result)]);
    }
    return result;
  }

  /// Batch writes documents to Firestore.
  ///
  /// It does not apply the write operations atomically and can apply them out of order.
  /// Each write succeeds or fails independently.
  ///
  /// https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/batchWrite
  @override
  Future<BatchWriteResponse> batchWriteDocuments(
    BatchWriteRequest request,
    String database,
  ) async {
    return await _api.projects.databases.documents.batchWrite(
      request,
      database,
    );
  }

  /// Begins a read-write transaction.
  @override
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
  @override
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
    return await _api.projects.databases.documents.commit(
      commitRequest,
      kDatabase,
    );
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
        Order(
          field: FieldReference(fieldPath: field),
          direction: direction,
        ),
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
