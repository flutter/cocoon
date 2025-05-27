// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/protos.dart';
import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:test/test.dart';

import '../../src/model/ci_yaml_matcher.dart';
import '../../src/utilities/entity_generators.dart';
import 'backfill_matcher.dart';

void main() {
  useTestLoggerPerTest();

  test('createBackfillTask', () async {
    final commit = generateFirestoreCommit(1).toRef();
    final task = generateFirestoreTask(2, commitSha: commit.sha).toRef();
    final target = generateTarget(1, name: task.name);

    final grid = BackfillGrid.from(
      [
        (commit, [task]),
      ],
      postsubmitTargets: [target],
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
    final c1 = generateFirestoreCommit(1).toRef();
    final c2 = generateFirestoreCommit(2).toRef();
    final t1c1 = generateFirestoreTask(1, commitSha: c1.sha).toRef();
    final t1c2 = generateFirestoreTask(1, commitSha: c2.sha).toRef();
    final t2c1 = generateFirestoreTask(2, commitSha: c1.sha).toRef();
    final t2c2 = generateFirestoreTask(2, commitSha: c2.sha).toRef();
    final tg1 = generateTarget(1, name: t1c1.name);
    final tg2 = generateTarget(2, name: t2c1.name);
    final grid = BackfillGrid.from(
      [
        (c1, [t1c1, t2c1]),
        (c2, [t1c2, t2c2]),
      ],
      postsubmitTargets: [tg1, tg2],
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
    final c1 = generateFirestoreCommit(1).toRef();
    final c2 = generateFirestoreCommit(2).toRef();
    final t1c1 =
        generateFirestoreTask(
          1,
          commitSha: c1.sha,
          status: TaskStatus.inProgress,
        ).toRef();
    final t1c2 = generateFirestoreTask(1, commitSha: c2.sha).toRef();
    final t2c1 = generateFirestoreTask(2, commitSha: c1.sha).toRef();
    final t2c2 = generateFirestoreTask(2, commitSha: c2.sha).toRef();
    final tg1 = generateTarget(1, name: t1c1.name, backfill: false);
    final tg2 = generateTarget(2, name: t2c1.name);
    final grid = BackfillGrid.from(
      [
        (c1, [t1c1, t2c1]),
        (c2, [t1c2, t2c2]),
      ],
      postsubmitTargets: [tg1, tg2],
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
      [isSkippableTask.hasTask(t1c2)],
      reason: 'Target 1 is marked backfill: false, so it is skipped',
    );
  });

  test('filters out tasks that are missing from ToT', () {
    final commit = generateFirestoreCommit(1).toRef();
    final taskExists = generateFirestoreTask(1, commitSha: commit.sha).toRef();
    final taskMissing = generateFirestoreTask(2, commitSha: commit.sha).toRef();
    final targetExists = generateTarget(1, name: taskExists.name);

    final grid = BackfillGrid.from(
      [
        (commit, [taskExists, taskMissing]),
      ],
      postsubmitTargets: [targetExists],
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
    final commit = generateFirestoreCommit(1).toRef();
    final taskBatch = generateFirestoreTask(1, commitSha: commit.sha).toRef();
    final taskNonBatch =
        generateFirestoreTask(2, commitSha: commit.sha).toRef();
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
      postsubmitTargets: [targetBatch, targetNonBatch],
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

  test('can override BackfillTask priority after creation', () {
    final commit = generateFirestoreCommit(1).toRef();
    final task = generateFirestoreTask(2, commitSha: commit.sha).toRef();
    final target = generateTarget(1, name: task.name);

    final grid = BackfillGrid.from(
      [
        (commit, [task]),
      ],
      postsubmitTargets: [target],
    );

    expect(
      grid.createBackfillTask(task, priority: 1001).copyWith(priority: 1002),
      isBackfillTask
          .hasTask(task)
          .hasTarget(target)
          .hasCommit(commit)
          .hasPriority(1002),
    );
  });
}
