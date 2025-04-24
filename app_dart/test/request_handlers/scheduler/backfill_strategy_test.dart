// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_strategy.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/commit_task_ref.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import 'backfill_matcher.dart';

void main() {
  useTestLoggerPerTest();

  group('DefaultBackfillStrategy', () {
    // Pick a deterministic seed, because shuffling is involved.
    final random = Random(0);
    final strategy = DefaultBackfillStrategy(random);

    final commits = [
      for (var i = 0; i < 10; i++)
        CommitRef.fromFirestore(generateFirestoreCommit(i)),
    ];

    final targets = [
      for (var i = 0; i < 10; i++) generateTarget(i, name: 'Linux TASK_$i'),
    ];

    TaskRef taskSucceeded(int commit, int index) {
      return TaskRef.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusSucceeded,
          name: 'Linux TASK_$index',
        ),
      );
    }

    TaskRef taskNew(int commit, int index) {
      return TaskRef.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusNew,
          name: 'Linux TASK_$index',
        ),
      );
    }

    TaskRef taskFailed(int commit, int index) {
      return TaskRef.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusFailed,
          name: 'Linux TASK_$index',
        ),
      );
    }

    TaskRef taskInProgress(int commit, int index) {
      return TaskRef.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusInProgress,
          name: 'Linux TASK_$index',
        ),
      );
    }

    late BackfillGrid grid;

    tearDown(() {
      printOnFailure(
        'Grid contents on failure: ${grid.targets.toList().toString()}',
      );
    });

    // INPUT:
    // 🧑‍💼 ⬜ ⬜
    // 🧑‍💼 🟩 🟨
    //
    // OUTPUT:
    // 🧑‍💼 🟨 ⬜
    // 🧑‍💼 🟩 🟨
    test('skips tasks for targets where a task is already in progress', () {
      // dart format off
      grid = BackfillGrid.from([
        //           Linux TASK_0           Linux TASK_1
        (commits[0], [taskNew       (0, 0),        taskNew (0, 1)]),
        (commits[1], [taskSucceeded (1, 0), taskInProgress (1, 1)]),
      ], tipOfTreeTargets: [
        targets[0],
        targets[1],
      ]);
      // dart format on

      expect(strategy.determineBackfill(grid), [
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[0]),
      ]);
    });

    // INPUT:
    // 🧑‍💼 ⬜ ⬜
    // 🧑‍💼 ⬜ ⬜
    //
    // OUTPUT:
    // 🧑‍💼 🟨 🟨
    // 🧑‍💼 ⬜ ⬜
    test('only schedules one task per target', () {
      // dart format off
      grid = BackfillGrid.from([
        //           Linux TASK_0            Linux TASK_1
        (commits[0], [taskNew       (0, 0),  taskNew (0, 1)]),
        (commits[1], [taskNew       (1, 0),  taskNew (1, 1)]),
      ], tipOfTreeTargets: [
        targets[0],
        targets[1],
      ]);
      // dart format on

      expect(strategy.determineBackfill(grid), [
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[0]),
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[1]),
      ]);
    });

    // INPUT:
    // 🧑‍💼 ⬜ ⬜ ⬜ kBatchSize = 6
    // 🧑‍💼 ⬜ ⬜ ⬜ < 1
    // 🧑‍💼 ⬜ ⬜ ⬜ < 2
    // 🧑‍💼 ⬜ ⬜ ⬜ < 3
    // 🧑‍💼 ⬜ ⬜ ⬜ < 4
    // 🧑‍💼 ⬜ ⬜ 🟥 < 5
    // 🧑‍💼 ⬜ 🟥 ⬜ < 6
    // 🧑‍💼 🟥 ⬜ ⬜ < 7
    //
    // OUTPUT:
    // 🧑‍💼 3️⃣ 1️⃣ 2️⃣ kBatchSize = 6
    // 🧑‍💼 ⬜ ⬜ ⬜ < 1
    // 🧑‍💼 ⬜ ⬜ ⬜ < 2
    // 🧑‍💼 ⬜ ⬜ ⬜ < 3
    // 🧑‍💼 ⬜ ⬜ ⬜ < 4
    // 🧑‍💼 ⬜ ⬜ 🟥 < 5
    // 🧑‍💼 ⬜ 🟥 ⬜ < 6
    // 🧑‍💼 🟥 ⬜ ⬜ < 7
    test('places previously failing within kBatchSize as high priority', () {
      // dart format off
      grid = BackfillGrid.from([
        //           Linux TASK_0            Linux TASK_1          Linux TASK_2
        (commits[0], [taskNew       (0, 0),  taskNew    (0, 1),    taskNew    (0, 2)]), // kBatchSize = 6
        (commits[1], [taskNew       (1, 0),  taskNew    (1, 1),    taskNew    (1, 2)]), // < 1
        (commits[1], [taskNew       (2, 0),  taskNew    (2, 1),    taskNew    (2, 2)]), // < 2
        (commits[1], [taskNew       (3, 0),  taskNew    (3, 1),    taskNew    (3, 2)]), // < 4
        (commits[1], [taskNew       (4, 0),  taskNew    (4, 1),    taskNew    (4, 2)]), // < 4
        (commits[1], [taskNew       (5, 0),  taskNew    (5, 1),    taskFailed (5, 2)]), // < 5
        (commits[1], [taskNew       (6, 0),  taskFailed (6, 1),    taskNew    (6, 2)]), // < 6
        (commits[1], [taskFailed    (7, 0),  taskNew    (7, 1),    taskNew    (7, 2)]), // < 7
      ], tipOfTreeTargets: [
        targets[0],
        targets[1],
        targets[2],
      ]);
      // dart format on

      expect(strategy.determineBackfill(grid), [
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[1]), // 1️⃣
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[2]), // 2️⃣
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[0]), // 3️⃣
      ]);
    });

    test('any commit to a release candidate branch has high priority', () {
      final commit = CommitRef.fromFirestore(
        generateFirestoreCommit(
          1,
          branch: 'flutter-3.32-candidate.0',
          sha: '123',
        ),
      );
      // dart format off
      grid = BackfillGrid.from([
        (commit, [
          TaskRef.fromFirestore(generateFirestoreTask(1, commitSha: '123', name: targets[0].name))
        ])
      ], tipOfTreeTargets: [
        targets[0],
      ]);
      // dart format on

      expect(strategy.determineBackfill(grid), [
        isBackfillTask
            .hasCommit(commit)
            .hasTarget(targets[0])
            .hasPriority(LuciBuildService.kRerunPriority),
      ]);
    });
  });
}
