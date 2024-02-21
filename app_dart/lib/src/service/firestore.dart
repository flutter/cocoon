// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../model/ci_yaml/target.dart';
import 'access_client_provider.dart';
import 'config.dart';

const String kDatabase = 'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}';
const String kDocumentParent = '$kDatabase/documents';
const String kFieldFilterOpEqual = 'EQUAL';

const String kTaskCollectionId = 'tasks';
const String kTaskBringupField = 'bringup';
const String kTaskBuildNumberField = 'buildNumber';
const String kTaskCommitShaField = 'commitSha';
const String kTaskCreateTimestampField = 'createTimestamp';
const String kTaskEndTimestampField = 'endTimestamp';
const String kTaskNameField = 'name';
const String kTaskStartTimestampField = 'startTimestamp';
const String kTaskStatusField = 'status';
const String kTaskTestFlakyField = 'testFlaky';

const String kCommitCollectionId = 'commits';
const String kCommitAvatarField = 'avatar';
const String kCommitBranchField = 'branch';
const String kCommitCreateTimestampField = 'createTimestamp';
const String kCommitAuthorField = 'author';
const String kCommitMessageField = 'message';
const String kCommitRepositoryPathField = 'repositoryPath';
const String kCommitShaField = 'sha';

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

  Future<List<firestore.Task>> queryCommitTasks(String commitSha) async {
    final ProjectsDatabasesDocumentsResource databasesDocumentsResource = await documentResource();
    final List<CollectionSelector> from = <CollectionSelector>[CollectionSelector(collectionId: kTaskCollectionId)];
    final Filter filter = Filter(
      fieldFilter: FieldFilter(
        field: FieldReference(fieldPath: kTaskCommitShaField),
        op: kFieldFilterOpEqual,
        value: Value(stringValue: commitSha),
      ),
    );
    final RunQueryRequest runQueryRequest =
        RunQueryRequest(structuredQuery: StructuredQuery(from: from, where: filter));
    final List<RunQueryResponseElement> runQueryResponseElements =
        await databasesDocumentsResource.runQuery(runQueryRequest, kDocumentParent);
    final List<Document> documents = runQueryResponseElements.map((e) => e.document!).toList();
    return documents.map((Document document) => firestore.Task.fromDocument(taskDocument: document)).toList();
  }
}

/// Generates task documents based on targets.
List<Document> targetsToTaskDocuments(Commit commit, List<Target> targets) {
  final Iterable<Document> iterableDocuments = targets.map(
    (Target target) => Document(
      name: '$kDatabase/documents/$kTaskCollectionId/${commit.sha}_${target.value.name}_1',
      fields: <String, Value>{
        kTaskCreateTimestampField: Value(integerValue: commit.timestamp!.toString()),
        kTaskEndTimestampField: Value(integerValue: '0'),
        kTaskBringupField: Value(booleanValue: target.value.bringup),
        kTaskNameField: Value(stringValue: target.value.name.toString()),
        kTaskStartTimestampField: Value(integerValue: '0'),
        kTaskStatusField: Value(stringValue: Task.statusNew),
        kTaskTestFlakyField: Value(booleanValue: false),
        kTaskCommitShaField: Value(stringValue: commit.sha),
      },
    ),
  );
  return iterableDocuments.toList();
}

/// Generates commit document based on datastore commit data model.
Document commitToCommitDocument(Commit commit) {
  return Document(
    name: '$kDatabase/documents/$kCommitCollectionId/${commit.sha}',
    fields: <String, Value>{
      kCommitAvatarField: Value(stringValue: commit.authorAvatarUrl),
      kCommitBranchField: Value(stringValue: commit.branch),
      kCommitCreateTimestampField: Value(integerValue: commit.timestamp.toString()),
      kCommitAuthorField: Value(stringValue: commit.author),
      kCommitMessageField: Value(stringValue: commit.message),
      kCommitRepositoryPathField: Value(stringValue: commit.repository),
      kCommitShaField: Value(stringValue: commit.sha),
    },
  );
}

/// Creates a list of [Write] based on documents.
List<Write> documentsToWrites(List<Document> documents, {bool exists = false}) {
  return documents
      .map(
        (Document document) => Write(
          update: document,
          currentDocument: Precondition(exists: exists),
        ),
      )
      .toList();
}
