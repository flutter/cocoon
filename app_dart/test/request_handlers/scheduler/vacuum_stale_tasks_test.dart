// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/firestore/commit.dart' as firestore;
import 'package:cocoon_service/src/model/firestore/task.dart' as firestore;
import 'package:collection/collection.dart';
import 'package:github/src/common/model/repos.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/request_handling/request_handler_tester.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  late RequestHandlerTester tester;

  setUp(() {
    tester = RequestHandlerTester();
  });

  group('precondition checks', () {
    late MockFirestoreService firestore;
    late FakeConfig config;
    late VacuumStaleTasks handler;

    setUp(() {
      firestore = MockFirestoreService();
      config = FakeConfig(firestoreService: firestore);
      handler = VacuumStaleTasks(config: config);
    });

    test('requests commits for each supported repository', () async {
      when(
        firestore.queryRecentCommits(
          slug: captureAnyNamed('slug'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async {
        // Intentionally do not return any results so we short-circuit.
        return [];
      });

      await tester.get(handler);

      expect(
        verify(
          firestore.queryRecentCommits(
            slug: captureAnyNamed('slug'),
            limit: anyNamed('limit'),
          ),
        ).captured,
        config.supportedRepos,
      );
    });

    test('requests commits equal to config.backfillerCommitLimit', () async {
      // Only make a single call
      config.supportedReposValue = {Config.flutterSlug};

      when(
        firestore.queryRecentCommits(
          slug: anyNamed('slug'),
          limit: captureAnyNamed('limit'),
        ),
      ).thenAnswer((_) async {
        // Intentionally do not return any results so we short-circuit.
        return [];
      });

      await tester.get(handler);

      expect(
        verify(
          firestore.queryRecentCommits(
            slug: anyNamed('slug'),
            limit: captureAnyNamed('limit'),
          ),
        ).captured,
        [config.backfillerCommitLimit],
      );
    });
  });

  group('logic checks', () {
    const timeoutLimit = Duration(hours: 1);

    late _FakeFirestoreService firestore;
    late FakeConfig config;
    late VacuumStaleTasks handler;
    late DateTime now;

    setUp(() {
      firestore = _FakeFirestoreService();
      config = FakeConfig(
        firestoreService: firestore,
        supportedReposValue: {Config.flutterSlug},
      );
      now = DateTime.now();
      handler = VacuumStaleTasks(
        config: config,
        now: () => now,
        timeoutLimit: timeoutLimit,
      );
    });

    test('resets tasks', () async {
      final resetEligible = firestore.createTask(
        firestore.createCommit(),
        status: Task.statusInProgress,
        buildNumber: null,
        createdAt: now.subtract(timeoutLimit),
      );

      await tester.get(handler);

      expect(
        firestore.fetchUpdatedTask(resetEligible).status,
        Task.statusNew,
        reason: 'Timed-out in-progress tasks without a build number',
      );
    });

    group('ignores tasks that are not in progress', () {
      for (final status in [
        Task.statusCancelled,
        Task.statusFailed,
        Task.statusInfraFailure,
        Task.statusNew,
        Task.statusSkipped,
        Task.statusSucceeded,
      ]) {
        test('status=$status', () async {
          final notInProgress = firestore.createTask(
            firestore.createCommit(),
            status: status,
          );

          await tester.get(handler);

          expect(
            firestore.fetchUpdatedTask(notInProgress).status,
            status,
            reason: 'Only Task.statusInProgress should be reset',
          );
        });
      }
    });

    test('ignores tasks with an assigned build number', () async {
      final inProgress = firestore.createTask(
        firestore.createCommit(),
        status: Task.statusInProgress,
        buildNumber: 1234,
      );

      await tester.get(handler);

      expect(
        firestore.fetchUpdatedTask(inProgress).status,
        Task.statusInProgress,
        reason: 'A task with .buildNumber set should not be reset',
      );
    });

    test(
      'ignores tasks where the task was created within the timeout limit',
      () async {
        final inProgress = firestore.createTask(
          firestore.createCommit(),
          status: Task.statusInProgress,
          createdAt: now.subtract(timeoutLimit - const Duration(minutes: 1)),
        );

        await tester.get(handler);

        expect(
          firestore.fetchUpdatedTask(inProgress).status,
          Task.statusInProgress,
          reason: 'A task within the timeoutlimit should not be reset',
        );
      },
    );
  });
}

final class _FakeFirestoreService extends Fake implements FirestoreService {
  _FakeFirestoreService();
  var _counter = 0;
  final _commits = <firestore.Commit>[];
  final _tasksByCommitSha = <String, Map<String, firestore.Task>>{};

  @useResult
  firestore.Commit createCommit() {
    final commit = generateFirestoreCommit(++_counter);
    _commits.add(commit);
    return commit;
  }

  @useResult
  firestore.Task createTask(
    firestore.Commit commit, {
    required String status,
    int? buildNumber,
    DateTime? createdAt,
  }) {
    final task = generateFirestoreTask(
      ++_counter,
      commitSha: commit.sha!,
      buildNumber: buildNumber,
      status: status,
    );
    _tasksByCommitSha.putIfAbsent(commit.sha!, () => {})[task.name!] = task;
    return task;
  }

  @useResult
  firestore.Task fetchUpdatedTask(firestore.Task task) {
    return _tasksByCommitSha[task.commitSha!]![task.name!]!;
  }

  @override
  Future<List<firestore.Commit>> queryRecentCommits({
    required RepositorySlug slug,
    int limit = 100,
    int? timestamp,
    String? branch,
  }) async {
    if (timestamp != null) {
      fail('Unexpected: queryRecentCommits(timestamp: ...)');
    }
    if (branch != null) {
      fail('Unexpected: queryRecentCommits(branch: ...)');
    }
    return _commits
        .where((c) => c.slug == slug)
        .sortedBy((c) => c.createTimestamp ?? 0)
        .take(limit)
        .toList();
  }

  @override
  Future<List<firestore.Task>> queryCommitTasks(String commitSha) async {
    return _tasksByCommitSha[commitSha]?.values.toList() ?? [];
  }

  @override
  Future<CommitResponse> writeViaTransaction(List<Write> writes) async {
    final updating = writes.map((w) => w.update).whereType<firestore.Task>();
    for (final task in updating) {
      final tasks = _tasksByCommitSha[task.commitSha]!;
      tasks[task.name!] = task;
    }
    return CommitResponse();
  }
}
