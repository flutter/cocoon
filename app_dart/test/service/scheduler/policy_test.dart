// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
  useTestLoggerPerTest();

  group('BatchPolicy', () {
    const policy = BatchPolicy();

    final allPending = <Task>[
      generateFirestoreTask(3),
      generateFirestoreTask(2),
      generateFirestoreTask(1),
    ];

    final latestAllPending = <Task>[
      generateFirestoreTask(6),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3),
      generateFirestoreTask(2),
      generateFirestoreTask(1, status: TaskStatus.succeeded),
    ];

    final latestAllPendingOrSkipped = <Task>[
      generateFirestoreTask(6),
      generateFirestoreTask(5, status: TaskStatus.skipped),
      generateFirestoreTask(4, status: TaskStatus.skipped),
      generateFirestoreTask(3, status: TaskStatus.skipped),
      generateFirestoreTask(2, status: TaskStatus.skipped),
      generateFirestoreTask(1, status: TaskStatus.succeeded),
    ];

    final latestFinishedButRestPending = <Task>[
      generateFirestoreTask(6, status: TaskStatus.succeeded),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3),
      generateFirestoreTask(2),
      generateFirestoreTask(1),
    ];

    final latestFailed = <Task>[
      generateFirestoreTask(6, status: TaskStatus.failed),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3),
      generateFirestoreTask(2),
      generateFirestoreTask(1),
    ];

    final latestPending = <Task>[
      generateFirestoreTask(6),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3),
      generateFirestoreTask(2, status: TaskStatus.succeeded),
      generateFirestoreTask(1, status: TaskStatus.succeeded),
    ];

    final failedWithRunning = <Task>[
      generateFirestoreTask(6),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3, status: TaskStatus.failed),
      generateFirestoreTask(2, status: TaskStatus.inProgress),
      generateFirestoreTask(1),
    ];

    test('triggers if less tasks than batch size', () async {
      final task = generateFirestoreTask(4);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: allPending,
        ),
        isNull,
      );
    });

    test('triggers after new tasks of batch size', () async {
      final task = generateFirestoreTask(7);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestAllPending,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers after skipped tasks of batch size', () async {
      final task = generateFirestoreTask(7);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestAllPendingOrSkipped,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failures', () async {
      final task = generateFirestoreTask(7);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestFailed,
        ),
        LuciBuildService.kRerunPriority,
      );
    });

    test(
      'does not trigger on recent failures if there is already a running task',
      () async {
        final task = generateFirestoreTask(7);
        expect(
          await policy.triggerPriority(
            taskName: task.taskName,
            commitSha: task.commitSha,
            recentTasks: failedWithRunning,
          ),
          isNull,
        );
      },
    );

    test('does not trigger when a test was recently scheduled', () async {
      final task = generateFirestoreTask(7);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestFinishedButRestPending,
        ),
        isNull,
      );
    });

    test('does not trigger when pending queue is smaller than batch', () async {
      final task = generateFirestoreTask(7);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestPending,
        ),
        isNull,
      );
    });
  });

  group('GuaranteedPolicy', () {
    const policy = GuaranteedPolicy();

    final pending = <Task>[generateFirestoreTask(1)];
    final latestFailed = <Task>[
      generateFirestoreTask(1, status: TaskStatus.failed),
    ];

    test('triggers every task', () async {
      final task = generateFirestoreTask(2);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: pending,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failure', () async {
      final task = generateFirestoreTask(2);
      expect(
        await policy.triggerPriority(
          taskName: task.taskName,
          commitSha: task.commitSha,
          recentTasks: latestFailed,
        ),
        LuciBuildService.kRerunPriority,
      );
    });
  });
}
