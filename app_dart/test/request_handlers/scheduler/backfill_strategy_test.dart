// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart' as fs;
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_strategy.dart';
import 'package:cocoon_service/src/service/luci_build_service/opaque_commit.dart';
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
        OpaqueCommit.fromFirestore(generateFirestoreCommit(i)),
    ];

    final targets = [
      for (var i = 0; i < 10; i++) generateTarget(i, name: 'task$i'),
    ];

    OpaqueTask taskSucceeded(int commit, int index) {
      return OpaqueTask.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusSucceeded,
        ),
      );
    }

    OpaqueTask taskNew(int commit, int index) {
      return OpaqueTask.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusNew,
        ),
      );
    }

    OpaqueTask taskFailed(int commit, int index) {
      return OpaqueTask.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusFailed,
        ),
      );
    }

    OpaqueTask taskInProgress(int commit, int index) {
      return OpaqueTask.fromFirestore(
        generateFirestoreTask(
          index,
          commitSha: commits[commit].sha,
          status: fs.Task.statusInProgress,
        ),
      );
    }

    late BackfillGrid grid;

    tearDown(() {
      printOnFailure(
        'Grid contents on failure: ${grid.targets.toList().toString()}',
      );
    });

    test('skips tasks for targets where a task is already in progress', () {
      // dart format off
      grid = BackfillGrid.from([
        //           targets[0]             targets[1]
        (commits[0], [taskNew       (0, 0),        taskNew (0, 1)]),
        (commits[1], [taskSucceeded (0, 0), taskInProgress (0, 1)]),
      ], tipOfTreeTargets: [
        targets[0],
        targets[1],
      ]);
      // dart format on

      final results = strategy.determineBackfill(grid);
      expect(results, [
        isBackfillTask.hasCommit(commits[0]).hasTarget(targets[0]),
      ]);
    });

    test('only schedules one task per target', () {
      final grid = BackfillGrid.from([], tipOfTreeTargets: []);
    });

    test('places previously failing within kBatchSize as high priority', () {
      final grid = BackfillGrid.from([], tipOfTreeTargets: []);
    });
  });
}
