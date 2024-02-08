// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/target.dart';
import 'access_client_provider.dart';
import 'config.dart';

const String kDatabase = 'projects/${Config.flutterGcpProjectId}/databases/${Config.flutterGcpFirestoreDatabase}';

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
}

/// Generates task documents based on targets.
List<Document> targetsToTaskDocuments(Commit commit, List<Target> targets) {
  final Iterable<Document> iterableDocuments = targets.map(
    (Target target) => Document(
      name: '$kDatabase/documents/tasks/${commit.sha}_${target.value.name}_1',
      fields: <String, Value>{
        'builderNumber': Value(integerValue: null),
        'createTimestamp': Value(integerValue: commit.timestamp!.toString()),
        'endTimestamp': Value(integerValue: '0'),
        'bringup': Value(booleanValue: target.value.bringup),
        'name': Value(stringValue: target.value.name.toString()),
        'startTimestamp': Value(integerValue: '0'),
        'status': Value(stringValue: Task.statusNew),
        'testFlaky': Value(booleanValue: false),
        'commitSha': Value(stringValue: commit.sha),
      },
    ),
  );
  return iterableDocuments.toList();
}

/// Generates commit document based on datastore commit data model.
Document commitToCommitDocument(Commit commit) {
  return Document(
    name: '$kDatabase/documents/commits/${commit.sha}',
    fields: <String, Value>{
      'avatar': Value(stringValue: commit.authorAvatarUrl),
      'branch': Value(stringValue: commit.branch),
      'createTimestamp': Value(integerValue: commit.timestamp.toString()),
      'author': Value(stringValue: commit.author),
      'message': Value(stringValue: commit.message),
      'repositoryPath': Value(stringValue: commit.repository),
      'sha': Value(stringValue: commit.sha),
    },
  );
}

/// Creates a list of [Write] based on documents.
List<Write> documentsToWrites(List<Document> documents) {
  return documents
      .map(
        (Document document) => Write(
          update: document,
          currentDocument: Precondition(exists: false),
        ),
      )
      .toList();
}
