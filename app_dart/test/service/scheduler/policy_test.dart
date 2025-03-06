// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler/policy.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';

void main() {
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
      generateFirestoreTask(1, status: Task.statusSucceeded),
    ];

    final latestFinishedButRestPending = <Task>[
      generateFirestoreTask(6, status: Task.statusSucceeded),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3),
      generateFirestoreTask(2),
      generateFirestoreTask(1),
    ];

    final latestFailed = <Task>[
      generateFirestoreTask(6, status: Task.statusFailed),
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
      generateFirestoreTask(2, status: Task.statusSucceeded),
      generateFirestoreTask(1, status: Task.statusSucceeded),
    ];

    final failedWithRunning = <Task>[
      generateFirestoreTask(6),
      generateFirestoreTask(5),
      generateFirestoreTask(4),
      generateFirestoreTask(3, status: Task.statusFailed),
      generateFirestoreTask(2, status: Task.statusInProgress),
      generateFirestoreTask(1),
    ];

    test('triggers if less tasks than batch size', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(4).taskName!,
          recentTasks: allPending,
        ),
        isNull,
      );
    });

    test('triggers after batch size', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(7).taskName!,
          recentTasks: latestAllPending,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failures', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(7).taskName!,
          recentTasks: latestFailed,
        ),
        LuciBuildService.kRerunPriority,
      );
    });

    test(
      'does not trigger on recent failures if there is already a running task',
      () async {
        expect(
          await policy.triggerPriority(
            generateFirestoreTask(7).taskName!,
            recentTasks: failedWithRunning,
          ),
          isNull,
        );
      },
    );

    test('does not trigger when a test was recently scheduled', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(7).taskName!,
          recentTasks: latestFinishedButRestPending,
        ),
        isNull,
      );
    });

    test('does not trigger when pending queue is smaller than batch', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(7).taskName!,
          recentTasks: latestPending,
        ),
        isNull,
      );
    });

    test(
      'do not return rerun priority when tasks length is smaller than batch size',
      () {
        expect(shouldRerunPriority(allPending, 5), false);
      },
    );
  });

  group('GuaranteedPolicy', () {
    const policy = GuaranteedPolicy();

    final pending = <Task>[generateFirestoreTask(1)];
    final latestFailed = <Task>[
      generateFirestoreTask(1, status: Task.statusFailed),
    ];

    test('triggers every task', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(2).taskName!,
          recentTasks: pending,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failure', () async {
      expect(
        await policy.triggerPriority(
          generateFirestoreTask(2).taskName!,
          recentTasks: latestFailed,
        ),
        LuciBuildService.kRerunPriority,
      );
    });
  });
}
