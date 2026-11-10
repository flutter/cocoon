// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:cocoon_service/src/service/firestore/commit_and_tasks.dart';
import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    test('batchGetDocuments returns found and missing documents', () async {
      final doc1 = Document(
        name: firestore.resolveDocumentName('tasks', 'task1'),
        fields: {'key': 'val1'.toValue()},
      );
      firestore.putDocument(doc1);

      final missingName = firestore.resolveDocumentName('tasks', 'task2');
      final response = await firestore.batchGetDocuments([
        doc1.name!,
        missingName,
      ]);

      expect(response, hasLength(2));
      expect(response[0].found, isNotNull);
      expect(response[0].found!.name, doc1.name);
      expect(response[1].missing, missingName);
      expect(response[1].found, isNull);
    });

    test(
      'getDocumentOrNull returns document when exists, null otherwise',
      () async {
        final doc1 = Document(
          name: firestore.resolveDocumentName('tasks', 'task1'),
          fields: {'key': 'val1'.toValue()},
        );
        firestore.putDocument(doc1);

        final result = await firestore.getDocumentOrNull(doc1.name!);
        expect(result, isNotNull);
        expect(result!.name, doc1.name);

        final notFound = await firestore.getDocumentOrNull(
          firestore.resolveDocumentName('tasks', 'does_not_exist'),
        );
        expect(notFound, isNull);
      },
    );

    test(
      'FirestoreService.query serializes not-in as NOT_IN ArrayValue filter',
      () async {
        Map<String, Object?>? capturedBody;
        final mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, Object?>;
          return http.Response(
            jsonEncode([<String, Object?>{}]),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final realService = FirestoreService.forTesting(
          FirestoreApi(mockClient),
        );

        await realService.query('wantLgtmStates', {
          'check_run_status =': 'in_progress',
          'slug not-in': ['flutter/cocoon', 'flutter/packages'],
        });

        expect(capturedBody, isNotNull);
        final structuredQuery =
            capturedBody!['structuredQuery'] as Map<String, Object?>;
        final where = structuredQuery['where'] as Map<String, Object?>;
        final composite = where['compositeFilter'] as Map<String, Object?>;
        final filters = composite['filters'] as List<Object?>;
        expect(filters, hasLength(2));
        final notInFilter =
            (filters[1] as Map<String, Object?>)['fieldFilter']
                as Map<String, Object?>;
        expect(notInFilter['op'], 'NOT_IN');
        expect(notInFilter['field'], {'fieldPath': '`slug`'});
        expect(notInFilter['value'], {
          'arrayValue': {
            'values': [
              {'stringValue': 'flutter/cocoon'},
              {'stringValue': 'flutter/packages'},
            ],
          },
        });
      },
    );

    test(
      'FirestoreService.query rejects empty or >10 element not-in lists',
      () {
        final mockClient = MockClient((_) async => http.Response('[]', 200));
        final realService = FirestoreService.forTesting(
          FirestoreApi(mockClient),
        );

        expect(
          () =>
              realService.query('wantLgtmStates', {'slug not-in': <String>[]}),
          throwsArgumentError,
        );
        expect(
          () => realService.query('wantLgtmStates', {
            'slug not-in': List.generate(11, (i) => 'flutter/repo_$i'),
          }),
          throwsArgumentError,
        );
      },
    );
  });
}
