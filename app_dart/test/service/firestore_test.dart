// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/firestore/commit_and_tasks.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  test('creates writes correctly from documents', () async {
    final documents = <Document>[
      Document(name: 'd1', fields: <String, Value>{'key1': 'value1'.toValue()}),
      Document(name: 'd2', fields: <String, Value>{'key1': 'value2'.toValue()}),
    ];
    final writes = documentsToWrites(documents, exists: false);
    expect(writes.length, documents.length);
    expect(writes[0].update, documents[0]);
    expect(writes[0].currentDocument!.exists, false);
  });

  group('CommitAndTasks', () {
    test('withMostRecentTaskOnly returns the largest currentAttempt', () {
      final commit = CommitAndTasks(generateFirestoreCommit(1).toRef(), [
        generateFirestoreTask(1, name: 'Linux A', attempts: 2),
        generateFirestoreTask(1, name: 'Linux A', attempts: 1),
        generateFirestoreTask(1, name: 'Linux A', attempts: 3),
      ]);
      final recent = commit.withMostRecentTaskOnly();
      expect(recent.tasks, [
        isTask.hasTaskName('Linux A').hasCurrentAttempt(3),
      ]);
    });
  });

  group('FirestoreQueries', () {
    late FakeFirestoreService firestore;

    setUp(() {
      firestore = FakeFirestoreService();
    });

    test('queryCommit returns matching commit', () async {
      final commit1 = Commit(
        sha: 'sha1',
        repositoryPath: 'flutter/packages',
        author: 'gollum',
        avatar: 'https://avatar',
        branch: 'main',
        message: 'Precious',
        createTimestamp: 1000,
      );
      final commit2 = Commit(
        sha: 'sha2',
        repositoryPath: 'flutter/packages',
        author: 'frodo',
        avatar: 'https://avatar',
        branch: 'main',
        message: 'Ring',
        createTimestamp: 2000,
      );
      firestore.putDocuments([commit1, commit2]);

      final result = await firestore.queryCommit(
        sha: 'sha1',
        slug: RepositorySlug('flutter', 'packages'),
      );
      expect(result, isNotNull);
      expect(result!.author, 'gollum');

      final notFound = await firestore.queryCommit(
        sha: 'sha_not_exists',
        slug: RepositorySlug('flutter', 'packages'),
      );
      expect(notFound, isNull);
    });
  });
}
