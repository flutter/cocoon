// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/request_handlers/get_status.dart';
import 'package:cocoon_service/src/service/build_status_provider/commit_tasks_status.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_build_status_provider.dart';
import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  late FakeBuildStatusService buildStatusService;
  late RequestHandlerTester tester;
  late GetStatus handler;
  late FakeFirestoreService firestore;

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
    firestore = FakeFirestoreService();

    firestore.putDocument(commit1);
    firestore.putDocument(commit2);

    tester = RequestHandlerTester();
    buildStatusService = FakeBuildStatusService(commitTasksStatuses: []);
    handler = GetStatus(
      config: FakeConfig(),
      buildStatusService: buildStatusService,
      firestore: firestore,
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
      config: FakeConfig(),
      buildStatusService: buildStatusService,
      firestore: firestore,
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
      config: FakeConfig(),
      buildStatusService: buildStatusService,
      firestore: firestore,
    );

    tester.request = FakeHttpRequest(
      queryParametersValue: {GetStatus.kLastCommitShaParam: commit2.sha},
    );

    final result = (await decodeHandlerBody<Map<String, Object?>>())!;
    expect(
      result,
      containsPair('Commits', [
        {
          'Commit': {
            'FlutterRepositoryPath': 'flutter/flutter',
            'CreateTimestamp': 1,
            'Sha': commit1.sha,
            'Message': 'test message',
            'Author': {'Login': 'author', 'avatar_url': 'avatar'},
            'Branch': 'master',
          },
          'Tasks': <void>[],
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
          generateFirestoreTask(1, bringup: true),
          generateFirestoreTask(
            2,
            bringup: true,
            status: 'Failed',
            attempts: 1,
            buildNumber: 123,
          ),
          generateFirestoreTask(
            2,
            bringup: true,
            status: 'In Progress',
            attempts: 2,
            buildNumber: 456,
          ),
        ]),
      ],
    );
    handler = GetStatus(
      config: FakeConfig(),
      buildStatusService: buildStatusService,
      firestore: firestore,
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
            'Sha': '1',
            'Message': 'test message',
            'Author': {'Login': 'author', 'avatar_url': 'avatar'},
            'Branch': 'master',
          },
          'Tasks': [
            {
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'Attempts': 1,
              'IsBringup': false,
              'IsFlaky': false,
              'Status': 'New',
              'BuildNumberList': <Object?>[],
              'BuilderName': 'task1',
            },
          ],
        },
        {
          'Commit': {
            'FlutterRepositoryPath': 'flutter/flutter',
            'CreateTimestamp': 2,
            'Sha': '2',
            'Message': 'test message',
            'Author': {'Login': 'author', 'avatar_url': 'avatar'},
            'Branch': 'master',
          },
          'Tasks': [
            {
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'Attempts': 1,
              'IsBringup': true,
              'IsFlaky': false,
              'Status': 'New',
              'BuildNumberList': <Object?>[],
              'BuilderName': 'task1',
            },
            {
              'CreateTimestamp': 0,
              'StartTimestamp': 0,
              'EndTimestamp': 0,
              'Attempts': 2,
              'IsBringup': true,
              'IsFlaky': true,
              'Status': 'In Progress',
              'BuildNumberList': <Object?>[123, 456],
              'BuilderName': 'task2',
            },
          ],
        },
      ]),
    );
  });
}
