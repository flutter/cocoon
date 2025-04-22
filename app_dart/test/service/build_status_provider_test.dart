// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
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

    firestore.putDocuments([olderCommit, newerCommit]);
  });

  group('calculateStatus', () {
    test('returns failure if there are no commits', () async {
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const []));
    });

    test('returns success if top commit is all green', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
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
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusSucceeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusFailed,
            commitSha: olderCommit.sha,
          ),
        ]);
        firestore.putDocument(
          generateFirestoreTask(1, status: Task.statusSucceeded),
        );
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      },
    );

    test('returns failure if last commit contains any red tasks', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusFailed,
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
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusFailed,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusFailed,
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
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusFailed,
            commitSha: newerCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const ['task2']));
      },
    );

    test('ignores failures on flaky commits', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusFailed,
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
          generateFirestoreTask(
            1,
            status: Task.statusInProgress,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusSucceeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusSucceeded,
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
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusInProgress,
            commitSha: newerCommit.sha,
          ),
          generateFirestoreTask(
            1,
            status: Task.statusSucceeded,
            commitSha: olderCommit.sha,
          ),
          generateFirestoreTask(
            2,
            status: Task.statusFailed,
            commitSha: olderCommit.sha,
          ),
        ]);

        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const ['task2']));
      },
    );

    test('returns failure when green but a task is rerunning', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusInProgress,
          attempts: 2,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const ['task2']));
    });

    test('returns failure when a task has an infra failure', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusInfraFailure,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.failure(const ['task2']));
    });

    test('returns success when all green with a successful rerun', () async {
      firestore.putDocuments([
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusSucceeded,
          commitSha: newerCommit.sha,
          attempts: 2,
        ),
        generateFirestoreTask(
          1,
          status: Task.statusSucceeded,
          commitSha: olderCommit.sha,
        ),
        generateFirestoreTask(
          2,
          status: Task.statusFailed,
          commitSha: olderCommit.sha,
        ),
      ]);
      final status = await buildStatusService.calculateCumulativeStatus(slug);
      expect(status, BuildStatus.success());
    });
  });
}
