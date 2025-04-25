// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/service/luci_build_service/commit_task_ref.dart';
import 'package:test/test.dart';

import '../../src/model/ci_yaml_matcher.dart';
import '../../src/utilities/entity_generators.dart';
import 'backfill_matcher.dart';

void main() {
  useTestLoggerPerTest();

  test('createBackfillTask', () async {
    final commit = CommitRef.fromFirestore(generateFirestoreCommit(1));
    final task = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: commit.sha),
    );
    final target = generateTarget(1, name: task.name);

    final grid = BackfillGrid.from(
      [
        (commit, [task]),
      ],
      tipOfTreeTargets: [target],
    );

    expect(
      grid.createBackfillTask(task, priority: 1001),
      isBackfillTask
          .hasTask(task)
          .hasTarget(target)
          .hasCommit(commit)
          .hasPriority(1001),
    );
  });

  test('targets', () {
    final c1 = CommitRef.fromFirestore(generateFirestoreCommit(1));
    final c2 = CommitRef.fromFirestore(generateFirestoreCommit(2));
    final t1c1 = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: c1.sha),
    );
    final t1c2 = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: c2.sha),
    );
    final t2c1 = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: c1.sha),
    );
    final t2c2 = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: c2.sha),
    );
    final tg1 = generateTarget(1, name: t1c1.name);
    final tg2 = generateTarget(2, name: t2c1.name);
    final grid = BackfillGrid.from(
      [
        (c1, [t1c1, t2c1]),
        (c2, [t1c2, t2c2]),
      ],
      tipOfTreeTargets: [tg1, tg2],
    );

    expect(
      grid,
      hasGridTargetsMatching([
        (
          isTarget.hasName(tg1.name),
          [isOpaqueTask.hasName(tg1.name), isOpaqueTask.hasName(tg1.name)],
        ),
        (
          isTarget.hasName(tg2.name),
          [isOpaqueTask.hasName(tg2.name), isOpaqueTask.hasName(tg2.name)],
        ),
      ]),
    );
  });

  test('skipped', () {
    final c1 = CommitRef.fromFirestore(generateFirestoreCommit(1));
    final c2 = CommitRef.fromFirestore(generateFirestoreCommit(2));
    final t1c1 = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: c1.sha),
    );
    final t1c2 = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: c2.sha),
    );
    final t2c1 = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: c1.sha),
    );
    final t2c2 = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: c2.sha),
    );
    final tg1 = generateTarget(1, name: t1c1.name, backfill: false);
    final tg2 = generateTarget(2, name: t2c1.name);
    final grid = BackfillGrid.from(
      [
        (c1, [t1c1, t2c1]),
        (c2, [t1c2, t2c2]),
      ],
      tipOfTreeTargets: [tg1, tg2],
    );

    expect(
      grid,
      hasGridTargetsMatching([
        (
          isTarget.hasName(tg2.name),
          [isOpaqueTask.hasName(tg2.name), isOpaqueTask.hasName(tg2.name)],
        ),
      ]),
      reason: 'Target 1 is marked backfill: false, so it is not eligible',
    );

    expect(
      grid.skippableTasks,
      [isSkippableTask.hasTask(t1c1), isSkippableTask.hasTask(t1c2)],
      reason: 'Target 1 is marked backfill: false, so it is skipped',
    );
  });

  test('filters out tasks that are missing from ToT', () {
    final commit = CommitRef.fromFirestore(generateFirestoreCommit(1));
    final taskExists = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: commit.sha),
    );
    final taskMissing = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: commit.sha),
    );
    final targetExists = generateTarget(1, name: taskExists.name);

    final grid = BackfillGrid.from(
      [
        (commit, [taskExists, taskMissing]),
      ],
      tipOfTreeTargets: [targetExists],
    );

    expect(
      grid,
      hasGridTargetsMatching([
        (
          isTarget.hasName(targetExists.name),
          [isOpaqueTask.hasName(targetExists.name)],
        ),
      ]),
    );
  });

  test('filters out targets that are not batch policy', () {
    final commit = CommitRef.fromFirestore(generateFirestoreCommit(1));
    final taskBatch = TaskRef.fromFirestore(
      generateFirestoreTask(1, commitSha: commit.sha),
    );
    final taskNonBatch = TaskRef.fromFirestore(
      generateFirestoreTask(2, commitSha: commit.sha),
    );
    final targetBatch = generateTarget(1, name: taskBatch.name);
    final targetNonBatch = generateTarget(
      2,
      name: taskNonBatch.name,
      schedulerSystem: SchedulerSystem.release,
    );

    final grid = BackfillGrid.from(
      [
        (commit, [taskBatch, taskNonBatch]),
      ],
      tipOfTreeTargets: [targetBatch, targetNonBatch],
    );

    expect(
      grid,
      hasGridTargetsMatching([
        (
          isTarget.hasName(targetBatch.name),
          [isOpaqueTask.hasName(targetBatch.name)],
        ),
      ]),
    );
  });
}
