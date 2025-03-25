// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late RequestHandlerTester tester;
  late GetBuildStatus handler;
  late MockFirestoreService mockFirestoreService;

  Future<T> decodeHandlerBody<T>() async {
    final body = await tester.get(handler);
    return await utf8.decoder
            .bind(body.serialize() as Stream<List<int>>)
            .transform(json.decoder)
            .single
        as T;
  }

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    final config = FakeConfig();
    config.firestoreService = mockFirestoreService;

    tester = RequestHandlerTester();
    handler = GetBuildStatus(
      config: config,
      buildStatusService: BuildStatusService(config),
    );
  });

  test('passing status', () async {
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final task = generateFirestoreTask(1, status: Task.statusSucceeded);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [task]);

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {'buildStatus': 'success'});
  });

  test('failing status', () async {
    final commit = generateFirestoreCommit(1);
    when(
      mockFirestoreService.queryRecentCommits(
        slug: anyNamed('slug'),
        branch: anyNamed('branch'),
        limit: anyNamed('limit'),
        timestamp: anyNamed('timestamp'),
      ),
    ).thenAnswer((_) async => [commit]);

    final taskPass = generateFirestoreTask(1, status: Task.statusSucceeded);
    final taskFail = generateFirestoreTask(2, status: Task.statusFailed);
    when(
      mockFirestoreService.queryCommitTasks(commit.sha),
    ).thenAnswer((_) async => [taskPass, taskFail]);

    final response = await decodeHandlerBody<Map<String, Object?>>();
    expect(response, {
      'buildStatus': 'failure',
      'failingTasks': [taskFail.taskName],
    });
  });
}
