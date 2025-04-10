// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/build_status_provider.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  useTestLoggerPerTest();

  group('BuildStatusProvider', () {
    late FakeConfig config;
    late BuildStatusService buildStatusService;
    late MockFirestoreService mockFirestoreService;

    final slug = RepositorySlug('flutter', 'flutter');

    setUp(() {
      mockFirestoreService = MockFirestoreService();
      config = FakeConfig()..firestoreService = mockFirestoreService;
      buildStatusService = BuildStatusService(config);
    });

    group('calculateStatus', () {
      List<Commit> commits;
      List<Task> tasks1;
      List<Task> tasks2;
      late int row;
      setUp(() {
        row = 0;
        tasks1 = <Task>[];
        tasks2 = <Task>[];
        commits = <Commit>[];
        when(
          // ignore: discarded_futures
          mockFirestoreService.queryRecentCommits(
            limit: captureAnyNamed('limit'),
            slug: captureAnyNamed('slug'),
            branch: captureAnyNamed('branch'),
          ),
        ).thenAnswer((Invocation invocation) {
          return Future<List<Commit>>.value(commits);
        });

        // ignore: discarded_futures
        when(mockFirestoreService.queryCommitTasks(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          if (row == 0) {
            row++;
            return Future<List<Task>>.value(tasks1);
          } else {
            return Future<List<Task>>.value(tasks2);
          }
        });
      });
      test('returns failure if there are no commits', () async {
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const <String>[]));
      });

      test('returns success if top commit is all green', () async {
        commits = <Commit>[generateFirestoreCommit(1)];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusSucceeded),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      });

      test(
        'returns success if top commit is all green followed by red commit',
        () async {
          commits = <Commit>[
            generateFirestoreCommit(1),
            generateFirestoreCommit(2),
          ];
          tasks1 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusSucceeded),
          ];
          tasks2 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusFailed),
          ];
          final status = await buildStatusService.calculateCumulativeStatus(
            slug,
          );
          expect(status, BuildStatus.success());
        },
      );

      test('returns failure if last commit contains any red tasks', () async {
        commits = <Commit>[generateFirestoreCommit(1)];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusFailed),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test(
        'returns failure if last commit contains any canceled tasks',
        () async {
          commits = <Commit>[generateFirestoreCommit(1)];
          tasks1 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusCancelled),
          ];
          final status = await buildStatusService.calculateCumulativeStatus(
            slug,
          );
          expect(status, BuildStatus.failure(const <String>['task2']));
        },
      );

      test(
        'ensure failed task do not have duplicates when last consecutive commits contains red tasks',
        () async {
          commits = <Commit>[
            generateFirestoreCommit(1),
            generateFirestoreCommit(2),
          ];
          tasks1 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusFailed),
          ];
          tasks2 = tasks1;

          final status = await buildStatusService.calculateCumulativeStatus(
            slug,
          );
          expect(status, BuildStatus.failure(const <String>['task2']));
        },
      );

      test('ignores failures on flaky commits', () async {
        commits = <Commit>[generateFirestoreCommit(1)];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusFailed, bringup: true),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      });

      test(
        'returns success if partial green, and all unfinished tasks were last green',
        () async {
          commits = <Commit>[
            generateFirestoreCommit(1),
            generateFirestoreCommit(2),
          ];
          tasks1 = <Task>[
            generateFirestoreTask(1, status: Task.statusInProgress),
            generateFirestoreTask(2, status: Task.statusSucceeded),
          ];
          tasks2 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusSucceeded),
          ];
          final status = await buildStatusService.calculateCumulativeStatus(
            slug,
          );
          expect(status, BuildStatus.success());
        },
      );

      test(
        'returns failure if partial green, and any unfinished task was last red',
        () async {
          commits = <Commit>[
            generateFirestoreCommit(1),
            generateFirestoreCommit(2),
          ];
          tasks1 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusInProgress),
          ];
          tasks2 = <Task>[
            generateFirestoreTask(1, status: Task.statusSucceeded),
            generateFirestoreTask(2, status: Task.statusFailed),
          ];
          final status = await buildStatusService.calculateCumulativeStatus(
            slug,
          );
          expect(status, BuildStatus.failure(const <String>['task2']));
        },
      );

      test('returns failure when green but a task is rerunning', () async {
        commits = <Commit>[
          generateFirestoreCommit(1),
          generateFirestoreCommit(2),
        ];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusInProgress, attempts: 2),
        ];
        tasks2 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusSucceeded),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('returns failure when a task has an infra failure', () async {
        commits = <Commit>[
          generateFirestoreCommit(1),
          generateFirestoreCommit(2),
        ];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusInfraFailure),
        ];
        tasks2 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusSucceeded),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.failure(const <String>['task2']));
      });

      test('returns success when all green with a successful rerun', () async {
        commits = <Commit>[
          generateFirestoreCommit(1),
          generateFirestoreCommit(2),
        ];
        tasks1 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusSucceeded, attempts: 2),
        ];
        tasks2 = <Task>[
          generateFirestoreTask(1, status: Task.statusSucceeded),
          generateFirestoreTask(2, status: Task.statusFailed),
        ];
        final status = await buildStatusService.calculateCumulativeStatus(slug);
        expect(status, BuildStatus.success());
      });
    });
  });
}
