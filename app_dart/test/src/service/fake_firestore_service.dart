// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/fake_firestore.dart';
import 'package:cocoon_service/src/model/firestore/base.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/model/firestore/github_build_status.dart';
import 'package:cocoon_service/src/model/firestore/github_gold_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

import '../utilities/mocks.dart';

/// A partial fake implementation of [FirestoreService].
///
/// For methods that are implemented by [FirestoreServiceMixin], operates as an
/// in-memory fake, with writes/reads flowing through [api], which is an
/// in-memory database simulation.
///
/// For other methods, they delegate to [mock], which can be manipulated at
/// test runtime similar to any other mock (i.e. `when(firestore.mock)`).
///
/// The awkwardness will be removed after
/// https://github.com/flutter/flutter/issues/165931.
final class FakeFirestoreService
    with FirestoreServiceMixin
    implements FirestoreService {
  /// The raw [FakeFirestore] implementation that operates in-memory.
  @override
  final FakeFirestore api = FakeFirestore(
    projectId: 'project-id',
    databaseId: 'datbase-id',
  );

  /// A mock [FirestoreService] for legacy methods that don't use [api].
  final mock = MockFirestoreService();

  @override
  Future<BatchWriteResponse> batchWriteDocuments(
    BatchWriteRequest request,
    String database,
  ) {
    return mock.batchWriteDocuments(request, database);
  }

  @override
  Future<ProjectsDatabasesDocumentsResource> documentResource() {
    return mock.documentResource();
  }

  @override
  List<Document> documentsFromQueryResponse(
    List<RunQueryResponseElement> runQueryResponseElements,
  ) {
    return mock.documentsFromQueryResponse(runQueryResponseElements);
  }

  @override
  Filter generateFilter(
    Map<String, Object> filterMap,
    String compositeFilterOp,
  ) {
    return mock.generateFilter(filterMap, compositeFilterOp);
  }

  @override
  List<Order>? generateOrders(Map<String, String>? orderMap) {
    return mock.generateOrders(orderMap);
  }

  @override
  Future<Document> getDocument(String name) {
    return mock.getDocument(name);
  }

  @override
  Value getValueFromFilter(Object comparisonOject) {
    return mock.getValueFromFilter(comparisonOject);
  }

  @override
  Future<List<Document>> query(
    String collectionId,
    Map<String, Object> filterMap, {
    int? limit,
    Map<String, String>? orderMap,
    String compositeFilterOp = kCompositeFilterOpAnd,
  }) {
    return mock.query(
      collectionId,
      filterMap,
      limit: limit,
      orderMap: orderMap,
      compositeFilterOp: compositeFilterOp,
    );
  }

  @override
  Future<List<Task>> queryCommitTasks(String commitSha) {
    return mock.queryCommitTasks(commitSha);
  }

  @override
  Future<GithubBuildStatus> queryLastBuildStatus(
    RepositorySlug slug,
    int prNumber,
    String head,
  ) {
    return mock.queryLastBuildStatus(slug, prNumber, head);
  }

  @override
  Future<GithubGoldStatus> queryLastGoldStatus(
    RepositorySlug slug,
    int prNumber,
  ) {
    return mock.queryLastGoldStatus(slug, prNumber);
  }

  @override
  Future<List<Commit>> queryRecentCommits({
    int limit = 100,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) {
    return mock.queryRecentCommits(
      limit: limit,
      timestamp: timestamp,
      branch: branch,
      slug: slug,
    );
  }

  @override
  Future<List<Task>> queryRecentTasksByName({
    int limit = 100,
    required String name,
  }) {
    return mock.queryRecentTasksByName(limit: limit, name: name);
  }

  @override
  Future<CommitResponse> writeViaTransaction(List<Write> writes) {
    return mock.writeViaTransaction(writes);
  }

  @override
  String toString() {
    return 'FakeFirestoreService ${const JsonEncoder.withIndent('  ').convert(api.documents)}';
  }
}

/// Checks that a task matching [matcher] exists in [FakeFirestoreService].
///
/// ## Example
///
/// ```dart
/// expect(
///   fakeFirestoreService,
///   hasModelOf(Task.metadata, (m) => m.having((t) => t.status, 'status', Task.statusSucceeded))
/// );
/// ```
Matcher hasModelOf<T extends AppDocument<T>>(
  AppDocumentMetadata<T> metadata,
  Matcher Function(TypeMatcher<T>) match,
) {
  return _HasModel(metadata, match);
}

final class _HasModel<T extends AppDocument<T>> extends Matcher {
  const _HasModel(this.metadata, this.match);
  final AppDocumentMetadata<T> metadata;
  final Matcher Function(TypeMatcher<T>) match;

  @override
  Description describe(Description description) {
    final match = this.match(isA<T>());
    description = description.add('has a $T where ');
    return match.describe(description);
  }

  @override
  bool matches(Object? item, _) {
    if (item is! FakeFirestoreService) {
      return false;
    }
    for (final document in item.api.documents) {
      final model = metadata.fromDocument(document);
      final match = this.match(isA<T>());
      if (match.matches(model, {})) {
        return true;
      }
    }
    return false;
  }
}
