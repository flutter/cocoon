// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/model/firestore/commit_tasks_status.dart';
import 'package:cocoon_service/src/request_handlers/get_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group('GetStatus', () {
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;
    late RequestHandlerTester tester;
    late GetStatus handler;
    late MockFirestoreService mockFirestoreService;

    final commit1 = generateFirestoreCommit(1);
    final commit2 = generateFirestoreCommit(2);

    Future<T?> decodeHandlerBody<T>() async {
      final body = await tester.get(handler);
      return await utf8.decoder
              .bind(body.serialize() as Stream<List<int>>)
              .transform(json.decoder)
              .single
          as T?;
    }

    setUp(() {
      clientContext = FakeClientContext();
      mockFirestoreService = MockFirestoreService();

      // ignore: discarded_futures
      when(mockFirestoreService.getDocument(any)).thenAnswer((i) async {
        final name = i.positionalArguments.first as String;
        final sha = p.split(name).last;
        final Commit match;
        if (commit1.sha == sha) {
          match = commit1;
        } else if (commit2.sha == sha) {
          match = commit2;
        } else {
          throw StateError('No sha $sha');
        }
        return Document()
          ..name = match.name
          ..fields = match.fields;
      });

      keyHelper = FakeKeyHelper(
        applicationContext: clientContext.applicationContext,
      );
      tester = RequestHandlerTester();
      config = FakeConfig(
        keyHelperValue: keyHelper,
        firestoreService: mockFirestoreService,
      );
      buildStatusService = FakeBuildStatusService(commitTasksStatuses: []);
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );
    });

    test('no statuses', () async {
      tester.request = FakeHttpRequest(
        queryParametersValue: {GetStatus.kLastCommitShaParam: commit1.sha},
      );

      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(result, containsPair('Commits', isEmpty));
    });

    test('reports statuses without input commit key', () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(generateFirestoreCommit(1, sha: commit1.sha), []),
          CommitTasksStatus(generateFirestoreCommit(2, sha: commit2.sha), []),
        ],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      tester.request = FakeHttpRequest();
      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(result, containsPair('Commits', hasLength(2)));
    });

    test('reports statuses with input commit key', () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(generateFirestoreCommit(1, sha: commit1.sha), []),
          CommitTasksStatus(generateFirestoreCommit(2, sha: commit2.sha), []),
        ],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {GetStatus.kLastCommitShaParam: commit2.sha!},
      );

      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(
        result,
        containsPair('Commits', [
          {
            'Commit': {
              'FlutterRepositoryPath': 'flutter/flutter',
              'CreateTimestamp': 1,
              'Commit': {
                'Sha': '${commit1.sha}',
                'Message': 'test message',
                'Author': {'Login': 'author', 'avatar_url': 'avatar'},
              },
              'Branch': 'master',
            },
            'Tasks': <void>[],
            'Status': 'In Progress',
          },
        ]),
      );
    });

    test('reports statuses with input branch', () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: [
          CommitTasksStatus(generateFirestoreCommit(1, sha: commit1.sha), [
            generateFirestoreTask(1),
          ]),
          CommitTasksStatus(generateFirestoreCommit(2, sha: commit2.sha), [
            generateFirestoreTask(1),
          ]),
        ],
      );
      handler = GetStatus(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      tester.request = FakeHttpRequest(
        queryParametersValue: {GetStatus.kBranchParam: commit1.branch},
      );
      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(
        result,
        containsPair('Commits', [
          {
            'Commit': {
              'FlutterRepositoryPath': 'flutter/flutter',
              'CreateTimestamp': 1,
              'Commit': {
                'Sha': '1',
                'Message': 'test message',
                'Author': {'Login': 'author', 'avatar_url': 'avatar'},
              },
              'Branch': 'master',
            },
            'Tasks': <void>[],
            'Status': 'In Progress',
          },
          {
            'Commit': {
              'FlutterRepositoryPath': 'flutter/flutter',
              'CreateTimestamp': 2,
              'Commit': {
                'Sha': '2',
                'Message': 'test message',
                'Author': {'Login': 'author', 'avatar_url': 'avatar'},
              },
              'Branch': 'master',
            },
            'Tasks': <void>[],
            'Status': 'In Progress',
          },
        ]),
      );
    });
  });
}
