// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group(VacuumStaleTasks, () {
    late FakeConfig config;
    late RequestHandlerTester tester;
    late VacuumStaleTasks handler;
    late FakeFirestoreService firestoreService;
    late MockLuciBuildService luciBuildService;

    final fsCommit = generateFirestoreCommit(1);

    setUp(() {
      luciBuildService = MockLuciBuildService();
      firestoreService = FakeFirestoreService();
      config = FakeConfig(firestoreService: firestoreService);

      // Insert into Firestore:
      firestoreService.putDocument(fsCommit);

      tester = RequestHandlerTester();
      handler = VacuumStaleTasks(
        config: config,
        luciBuildService: luciBuildService,
      );
    });

    test('queries LUCI when tasks have a build number', () async {
      // Insert Task into Firestore:
      final fsTask = generateFirestoreTask(
        1,
        status: Task.statusInProgress,
        name: 'Linux gosh_darnit',
        buildNumber: 123,
        commitSha: fsCommit.sha,
      );
      firestoreService.putDocument(fsTask);

      when(
        luciBuildService.getProdBuilds(
          builderName: argThat(equals(fsTask.taskName), named: 'builderName'),
          sha: argThat(equals(fsCommit.sha), named: 'sha'),
        ),
      ).thenAnswer((_) async {
        return [
          generateBbv2Build(
            Int64(123456789),
            buildNumber: 123,
            name: fsTask.taskName,
            status: bbv2.Status.SUCCESS,
          ),
        ];
      });

      await tester.get(handler);

      // Verify Firestore Update:
      expect(
        firestoreService,
        existsInStorage(fs.Task.metadata, [
          isTask.hasStatus(fs.Task.statusSucceeded).hasBuildNumber(123),
        ]),
      );
    });

    test(
      'skips when tasks are not yet old enough to be considered stale',
      () async {
        firestoreService.putDocument(
          generateFirestoreTask(
            1,
            status: Task.statusInProgress,
            commitSha: fsCommit.sha,
            created: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );

        await tester.get(handler);

        expect(
          firestoreService,
          existsInStorage(fs.Task.metadata, [
            isTask.hasStatus(fs.Task.statusInProgress),
          ]),
        );
      },
    );

    test('resets stale task', () async {
      // Insert Task into Firestore:
      firestoreService.putDocument(
        generateFirestoreTask(
          1,
          status: Task.statusInProgress,
          commitSha: fsCommit.sha,
        ),
      );
      firestoreService.putDocument(
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
          commitSha: fsCommit.sha,
        ),
      );
      firestoreService.putDocument(
        generateFirestoreTask(
          3,
          status: Task.statusInProgress,
          created: DateTime.now().subtract(const Duration(hours: 4)),
          commitSha: fsCommit.sha,
        ),
      );

      await tester.get(handler);

      // Check Firestore:
      expect(
        firestoreService,
        existsInStorage(fs.Task.metadata, [
          isTask.hasStatus(fs.Task.statusNew),
          isTask.hasStatus(fs.Task.statusSucceeded),
          isTask.hasStatus(fs.Task.statusNew),
        ]),
      );
    });
  });
}
