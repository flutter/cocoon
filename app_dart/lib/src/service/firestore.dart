// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import '../model/firestore/commit.dart';
import '../model/firestore/github_gold_status.dart';
import '../model/firestore/task.dart';
import 'access_client_provider.dart';
import 'config.dart';

const String kDatabase = 'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}';
const String kDocumentParent = '$kDatabase/documents';
const String kFieldFilterOpEqual = 'EQUAL';
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
};

class FirestoreService {
  const FirestoreService(this.accessClientProvider);

  /// AccessClientProvider for OAuth 2.0 authenticated access client
  final AccessClientProvider accessClientProvider;

  /// Return a [ProjectsDatabasesDocumentsResource] with an authenticated [client]
  Future<ProjectsDatabasesDocumentsResource> documentResource() async {
    final Client client = await accessClientProvider.createAccessClient(
      scopes: const <String>[FirestoreApi.datastoreScope],
      baseClient: FirestoreBaseClient(
        projectId: Config.flutterGcpProjectId,
        databaseId: Config.flutterGcpFirestoreDatabase,
      ),
    );
    return FirestoreApi(client).projects.databases.documents;
  }

  /// Gets a document based on name.
  Future<Document> getDocument(
    String name,
  ) async {
    final ProjectsDatabasesDocumentsResource databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.get(name);
  }

  /// Batch writes documents to Firestore.
  ///
  /// It does not apply the write operations atomically and can apply them out of order.
  /// Each write succeeds or fails independently.
  ///
  /// https://firebase.google.com/docs/firestore/reference/rest/v1/projects.databases.documents/batchWrite
  Future<BatchWriteResponse> batchWriteDocuments(BatchWriteRequest request, String database) async {
    final ProjectsDatabasesDocumentsResource databasesDocumentsResource = await documentResource();
    return databasesDocumentsResource.batchWrite(request, database);
  }

  /// Writes [writes] to Firestore within a transaction.
  ///
  /// This is an atomic operation: either all writes succeed or all writes fail.
  Future<CommitResponse> writeViaTransaction(List<Write> writes) async {
    final ProjectsDatabasesDocumentsResource databasesDocumentsResource = await documentResource();
    final BeginTransactionRequest beginTransactionRequest =
        BeginTransactionRequest(options: TransactionOptions(readWrite: ReadWrite()));
    final BeginTransactionResponse beginTransactionResponse =
        await databasesDocumentsResource.beginTransaction(beginTransactionRequest, kDatabase);
    final CommitRequest commitRequest =
        CommitRequest(transaction: beginTransactionResponse.transaction, writes: writes);
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
    final Map<String, Object> filterMap = <String, Object>{
      '$kCommitBranchField =': branch,
      '$kCommitRepositoryPathField =': slug.fullName,
      '$kCommitCreateTimestampField <': timestamp,
    };
    final Map<String, String> orderMap = <String, String>{
      kCommitCreateTimestampField: kQueryOrderDescending,
    };
    final List<Document> documents = await query(kCommitCollectionId, filterMap, orderMap: orderMap, limit: limit);
    return documents.map((Document document) => Commit.fromDocument(commitDocument: document)).toList();
  }

  /// Queries for recent tasks that meet the specified criteria.
  ///
  /// Since each task belongs to a commit, this query implicitly includes a
  /// query of the most recent N commits (see [queryRecentCommits]). The
  /// [commitLimit] argument specifies how many commits to consider when
  /// retrieving the list of recent tasks.
  ///
  /// If [taskName] is specified, only tasks whose [Task.name] matches the
  /// specified value will be returned. By default, tasks will be returned
  /// regardless of their name.
  ///
  /// The returned tasks will be ordered by most recent [Commit.timestamp]
  /// first, then by most recent [Task.createTimestamp].
  Future<List<FullTask>> queryRecentTasks({
    String? taskName,
    int commitLimit = 20,
    String? branch,
    required RepositorySlug slug,
  }) async {
    final List<Commit> commits = await queryRecentCommits(limit: commitLimit, branch: branch, slug: slug); 
    final List<FullTask> allTasks = [];
    for (Commit commit in commits) {
      final String? sha = commit.sha;
      if(sha != null){
        final Map<String, String> orderMap = <String, String>{
          kCommitCreateTimestampField: kQueryOrderDescending,
        };
        final List<Task> tasks = await queryCommitTasks(sha, orderMap);
        List<FullTask> commitTasks = tasks.map((Task task) => FullTask(task, commit)).toList();
        
        // Filter by taskName if provided
        if (taskName != null) {
            commitTasks = commitTasks.where((fullTask) => fullTask.task.name == taskName).toList();
        }

        allTasks.addAll(commitTasks);
      }
    }
    return allTasks;
  }
  
  /// Returns all tasks running against the speificed [commitSha].
  Future<List<Task>> queryCommitTasks(String commitSha, Map<String, String>? filters) async {
    final Map<String, Object> filterMap = <String, Object>{
      '$kTaskCommitShaField =': commitSha,
    };

    if (filters != null) {
      filterMap.addAll(filters);
    }
    
    final List<Document> documents = await query(kTaskCollectionId, filterMap);
    return documents.map((Document document) => Task.fromDocument(taskDocument: document)).toList();
  }

  /// Queries the last updated Gold status for the [slug] and [prNumber].
  ///
  /// If not existing, returns a fresh new Gold status.
  Future<GithubGoldStatus> queryLastGoldStatus(RepositorySlug slug, int prNumber) async {
    final Map<String, Object> filterMap = <String, Object>{
      '$kGithubGoldStatusPrNumberField =': prNumber,
      '$kGithubGoldStatusRepositoryField =': slug.fullName,
    };
    final List<Document> documents = await query(kGithubGoldStatusCollectionId, filterMap);
    final List<GithubGoldStatus> githubGoldStatuses =
        documents.map((Document document) => GithubGoldStatus.fromDocument(githubGoldStatus: document)).toList();
    if (githubGoldStatuses.isEmpty) {
      return GithubGoldStatus.fromDocument(
        githubGoldStatus: Document(
          name: '$kDatabase/documents/$kGithubGoldStatusCollectionId/${slug.owner}_${slug.name}_$prNumber',
          fields: <String, Value>{
            kGithubGoldStatusPrNumberField: Value(integerValue: prNumber.toString()),
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
        throw StateError('GithubGoldStatusUpdate should have no more than one entry on '
            'repository ${slug.fullName}, pr $prNumber.');
      }
      return githubGoldStatuses.single;
    }
  }

  /// Returns Firestore [Value] based on corresponding object type.
  Value getValueFromFilter(Object comparisonOject) {
    if (comparisonOject is int) {
      return Value(integerValue: comparisonOject.toString());
    } else if (comparisonOject is bool) {
      return Value(booleanValue: comparisonOject);
    }
    return Value(stringValue: comparisonOject as String);
  }

  /// Generates Firestore query filter based on "human" read conditions.
  Filter generateFilter(Map<String, Object> filterMap, String compositeFilterOp) {
    final List<Filter> filters = <Filter>[];
    filterMap.forEach((filterString, comparisonOject) {
      final List<String> parts = filterString.split(' ');
      if (parts.length != kFilterStringSpaceSplitElements ||
          !kRelationMapping.containsKey(parts[kFilterStringSpaceSplitOpIndex])) {
        throw ArgumentError("Invalid filter string '$filterString'.");
      }
      final String name = parts[0];
      final String comparison = kRelationMapping[parts[1]]!;
      final Value value = getValueFromFilter(comparisonOject);

      filters.add(
        Filter(
          fieldFilter: FieldFilter(
            field: FieldReference(fieldPath: name),
            op: comparison,
            value: value,
          ),
        ),
      );
    });
    return Filter(
      compositeFilter: CompositeFilter(
        filters: filters,
        op: compositeFilterOp,
      ),
    );
  }

  List<Order>? generateOrders(Map<String, String>? orderMap) {
    if (orderMap == null || orderMap.isEmpty) {
      return null;
    }
    final List<Order> orders = <Order>[];
    orderMap.forEach((field, direction) {
      orders.add(Order(field: FieldReference(fieldPath: field), direction: direction));
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
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  }) async {
    final ProjectsDatabasesDocumentsResource databasesDocumentsResource = await documentResource();
    final List<CollectionSelector> from = <CollectionSelector>[
      CollectionSelector(collectionId: collectionId),
    ];
    final Filter filter = generateFilter(filterMap, compositeFilterOp);
    final List<Order>? orders = generateOrders(orderMap);
    final RunQueryRequest runQueryRequest = RunQueryRequest(
      structuredQuery: StructuredQuery(
        from: from,
        where: filter,
        orderBy: orders,
        limit: limit,
      ),
    );
    final List<RunQueryResponseElement> runQueryResponseElements =
        await databasesDocumentsResource.runQuery(runQueryRequest, kDocumentParent);
    return documentsFromQueryResponse(runQueryResponseElements);
  }

  /// Retrieve documents based on query response.
  List<Document> documentsFromQueryResponse(List<RunQueryResponseElement> runQueryResponseElements) {
    final List<Document> documents = <Document>[];
    for (RunQueryResponseElement runQueryResponseElement in runQueryResponseElements) {
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
