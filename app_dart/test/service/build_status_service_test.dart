// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/build_status_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../src/service/fake_firestore_service.dart';
import '../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  final newerCommit = generateFirestoreCommit(
    1,
    sha: 'abc123',
    createTimestamp: DateTime(2025, 1, 1, 1, 1).millisecondsSinceEpoch,
  );
  final olderCommit = generateFirestoreCommit(
    2,
    sha: 'def456',
    createTimestamp: DateTime(2025, 1, 1, 1, 0).millisecondsSinceEpoch,
  );

  late BuildStatusService buildStatusService;
  late FakeFirestoreService firestore;

  final slug = RepositorySlug('flutter', 'flutter');

  setUp(() {
    firestore = FakeFirestoreService();
    buildStatusService = BuildStatusService(firestore: firestore);
  });

  group('calculateStatus', () {
    test('returns failure if there are no commits', () async {
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const []));
    });

    test('returns success if top commit is all green', () async {
      firestore.putDocuments([
        newerCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.success());
    });

    test(
      'returns success if top commit is all green followed by red commit',
      () async {
        firestore.putDocuments([
          newerCommit,
          olderCommit,
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.succeeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.failed,
            commitSha: olderCommit.sha,
          ),
        ]);
        firestore.putDocument(
          generateFirestoreTask(1, status: TaskStatus.succeeded),
        );
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      },
    );

    test('returns failure if last commit contains any red tasks', () async {
      firestore.putDocuments([
        newerCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.failed,
          commitSha: newerCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const ['task2']));
    });

    test(
      'returns failure if last commit contains any canceled tasks',
      () async {
        firestore.putDocuments([
          newerCommit,
          olderCommit,
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.failed,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.failed,
            commitSha: olderCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const ['task2']));
      },
    );

    test(
      'ensure failed task do not have duplicates when last consecutive commits contains red tasks',
      () async {
        firestore.putDocuments([
          newerCommit,
          olderCommit,
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.failed,
            commitSha: newerCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const ['task2']));
      },
    );

    test('ignores failures on flaky commits', () async {
      firestore.putDocuments([
        newerCommit,
        olderCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.failed,
          commitSha: newerCommit.sha,
          bringup: true,
        ),
      ]);

      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.success());
    });

    test(
      'returns success if partial green, and all unfinished tasks were last green',
      () async {
        firestore.putDocuments([
          newerCommit,
          olderCommit,
          generateFirestoreTask(
            1,
            status: TaskStatus.inProgress,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.succeeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      },
    );

    test(
      'returns failure if partial green, and any unfinished task was last red',
      () async {
        firestore.putDocuments([
          newerCommit,
          olderCommit,
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.inProgress,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: TaskStatus.succeeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: TaskStatus.failed,
            commitSha: olderCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const ['task2']));
      },
    );

    test('returns passing when green but a task is rerunning', () async {
      firestore.putDocuments([
        newerCommit,
        olderCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.inProgress,
          attempts: 2,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.succeeded,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.success());
    });

    test('returns failure when a task has an infra failure', () async {
      firestore.putDocuments([
        newerCommit,
        olderCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.infraFailure,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.succeeded,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const ['task2']));
    });

    test('returns success when all green with a successful rerun', () async {
      firestore.putDocuments([
        newerCommit,
        olderCommit,
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.succeeded,
          commitSha: newerCommit.sha,
          attempts: 2,
        ),
        generateFirestoreTask(
          1,
          status: TaskStatus.succeeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: TaskStatus.failed,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.success());
    });

    test('supports a non-default branch', () async {
      firestore.putDocuments([
        generateFirestoreCommit(1, branch: 'flutter-0.42-candidate.0'),
        generateFirestoreTask(1, commitSha: '1', status: TaskStatus.succeeded),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(
        slug,
        branch: 'flutter-0.42-candidate.0',
      );
      expect(status, BuildStatus.success());
    });
  });
}
