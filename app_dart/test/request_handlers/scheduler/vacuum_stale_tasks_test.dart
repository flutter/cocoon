// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/rpc_model.dart' as rpc;
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/service/fake_firestore_service.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group(VacuumStaleTasks, () {
    late RequestHandlerTester tester;
    late VacuumStaleTasks handler;
    late FakeFirestoreService firestore;
    late MockLuciBuildService luciBuildService;
    late List<rpc.Branch> branchServiceResponse;

    final fsCommit = generateFirestoreCommit(1);

    setUp(() {
      luciBuildService = MockLuciBuildService();
      firestore = FakeFirestoreService();

      // Insert into Firestore:
      firestore.putDocument(fsCommit);

      branchServiceResponse = [];
      final branchService = MockBranchService();
      when(
        branchService.getReleaseBranches(slug: anyNamed('slug')),
      ).thenAnswer((_) async => branchServiceResponse);

      tester = RequestHandlerTester();
      handler = VacuumStaleTasks(
        config: FakeConfig(),
        luciBuildService: luciBuildService,
        firestore: firestore,
        branchService: branchService,
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
      firestore.putDocument(fsTask);

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
        firestore,
        existsInStorage(fs.Task.metadata, [
          isTask.hasStatus(fs.Task.statusSucceeded).hasBuildNumber(123),
        ]),
      );
    });

    test(
      'skips when tasks are not yet old enough to be considered stale',
      () async {
        firestore.putDocument(
          generateFirestoreTask(
            1,
            status: Task.statusInProgress,
            commitSha: fsCommit.sha,
            created: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );

        await tester.get(handler);

        expect(
          firestore,
          existsInStorage(fs.Task.metadata, [
            isTask.hasStatus(fs.Task.statusInProgress),
          ]),
        );
      },
    );

    test('resets stale task', () async {
      // Insert Task into Firestore:
      firestore.putDocument(
        generateFirestoreTask(
          1,
          status: Task.statusInProgress,
          commitSha: fsCommit.sha,
        ),
      );
      firestore.putDocument(
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
          commitSha: fsCommit.sha,
        ),
      );
      firestore.putDocument(
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
        firestore,
        existsInStorage(fs.Task.metadata, [
          isTask.hasStatus(fs.Task.statusNew),
          isTask.hasStatus(fs.Task.statusSucceeded),
          isTask.hasStatus(fs.Task.statusNew),
        ]),
      );
    });

    test('resets stale tasks on a release candidate branch', () async {
      branchServiceResponse = [
        rpc.Branch(channel: 'beta', reference: 'flutter-3.32-candidate.0'),
      ];

      // Insert into Firestore:
      final rcCommit = generateFirestoreCommit(
        2,
        sha: 'abc123',
        branch: 'flutter-3.32-candidate.0',
      );
      firestore.putDocuments([
        rcCommit,
        generateFirestoreTask(
          1,
          status: Task.statusInProgress,
          commitSha: 'abc123',
          created: DateTime.now().subtract(const Duration(hours: 4)),
        ),
      ]);

      await tester.get(handler);

      // Check Firestore:
      expect(
        firestore,
        existsInStorage(fs.Task.metadata, [
          isTask.hasStatus(fs.Task.statusNew),
        ]),
      );
    });
  });
}
