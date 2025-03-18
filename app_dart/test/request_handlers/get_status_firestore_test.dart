// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/firestore/commit_tasks_status.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('GetStatusFirestore', () {
    late FakeConfig config;
    FakeClientContext clientContext;
    FakeKeyHelper keyHelper;
    FakeBuildStatusService buildStatusService;
    late RequestHandlerTester tester;
    late GetStatusFirestore handler;
    late MockFirestoreService mockFirestoreService;

    late Commit commit1;
    late Commit commit2;

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
      keyHelper = FakeKeyHelper(
        applicationContext: clientContext.applicationContext,
      );
      tester = RequestHandlerTester();
      config = FakeConfig(
        keyHelperValue: keyHelper,
        firestoreService: mockFirestoreService,
      );
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: <CommitTasksStatus>[],
      );
      handler = GetStatusFirestore(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );
      commit1 = Commit(
        key: config.db.emptyKey.append(
          Commit,
          id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829',
        ),
        repository: 'flutter/flutter',
        sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
        timestamp: 3,
        message: 'test message 1',
        branch: 'master',
      );
      commit2 = Commit(
        key: config.db.emptyKey.append(
          Commit,
          id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        ),
        repository: 'flutter/flutter',
        sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        timestamp: 1,
        message: 'test message 2',
        branch: 'master',
      );
    });

    test('no statuses', () async {
      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(result['Statuses'], isEmpty);
    });

    test('reports statuses without input commit key', () async {
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: <CommitTasksStatus>[
          CommitTasksStatus(generateFirestoreCommit(1), const <Task>[]),
          CommitTasksStatus(generateFirestoreCommit(2), const <Task>[]),
        ],
      );
      handler = GetStatusFirestore(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(result, containsPair('Statuses', hasLength(2)));
    });

    test('reports statuses with input commit key', () async {
      final commit1 = Commit(
        key: config.db.emptyKey.append(
          Commit,
          id: 'flutter/flutter/ea28a9c34dc701de891eaf74503ca4717019f829',
        ),
        repository: 'flutter/flutter',
        sha: 'ea28a9c34dc701de891eaf74503ca4717019f829',
        timestamp: 3,
        message: 'test message 1',
        branch: 'master',
      );
      final commit2 = Commit(
        key: config.db.emptyKey.append(
          Commit,
          id: 'flutter/flutter/d5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        ),
        repository: 'flutter/flutter',
        sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
        timestamp: 1,
        message: 'test message 2',
        branch: 'master',
      );
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: <CommitTasksStatus>[
          CommitTasksStatus(
            generateFirestoreCommit(
              1,
              sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
            ),
            const <Task>[],
          ),
          CommitTasksStatus(generateFirestoreCommit(2), const <Task>[]),
        ],
      );
      handler = GetStatusFirestore(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      const expectedLastCommitKeyEncoded =
          'ahNzfmZsdXR0ZXItZGFzaGJvYXJkckcLEglDaGVja2xpc3QiOGZsdXR0ZXIvZmx1dHRlci9lYTI4YTljMzRkYzcwMWRlODkxZWFmNzQ1MDNjYTQ3MTcwMTlmODI5DA';

      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          GetStatusFirestore.kLastCommitKeyParam: expectedLastCommitKeyEncoded,
        },
      );

      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(
        result,
        containsPair(
          'Statuses',
          contains(
            containsPair('Commit', <String, dynamic>{
              'DocumentName': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'RepositoryPath': 'flutter/flutter',
              'CreateTimestamp': 1,
              'Sha': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'Message': 'test message',
              'Author': 'author',
              'Avatar': 'avatar',
              'Branch': 'master',
            }),
          ),
        ),
      );
    });

    test('reports statuses with input branch', () async {
      commit2.branch = 'flutter-1.1-candidate.1';
      config.db.values[commit1.key] = commit1;
      config.db.values[commit2.key] = commit2;
      buildStatusService = FakeBuildStatusService(
        commitTasksStatuses: <CommitTasksStatus>[
          CommitTasksStatus(generateFirestoreCommit(1), const <Task>[]),
          CommitTasksStatus(
            generateFirestoreCommit(
              2,
              branch: 'flutter-1.1-candidate.1',
              sha: 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
            ),
            const <Task>[],
          ),
        ],
      );
      handler = GetStatusFirestore(
        config: config,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        buildStatusProvider: (_, _) => buildStatusService,
      );

      const branch = 'flutter-1.1-candidate.1';

      expect(config.db.values.length, 2);

      tester.request = FakeHttpRequest(
        queryParametersValue: <String, String>{
          GetStatusFirestore.kBranchParam: branch,
        },
      );

      final result = (await decodeHandlerBody<Map<String, Object?>>())!;
      expect(
        result,
        containsPair('Statuses', [
          <String, dynamic>{
            'Commit': <String, dynamic>{
              'DocumentName': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'RepositoryPath': 'flutter/flutter',
              'CreateTimestamp': 2,
              'Sha': 'd5b0b3c8d1c5fd89302089077ccabbcfaae045e4',
              'Message': 'test message',
              'Author': 'author',
              'Avatar': 'avatar',
              'Branch': 'flutter-1.1-candidate.1',
            },
            'Tasks': <Object?>[],
          },
        ]),
      );
    });
  });
}
