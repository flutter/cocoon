// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/scheduler/policy_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';

void main() {
  group('BatchPolicy', () {
    late MockFirestoreService mockFirestoreService;
    List<Task> tasks = <Task>[];

    final BatchPolicy policy = BatchPolicy();

    setUp(() {
      tasks.clear();
      mockFirestoreService = MockFirestoreService();
      when(
        mockFirestoreService.queryRecentTasksByName(
          name: captureAnyNamed('name'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<Task>>.value(
          tasks,
        );
      });
    });

    test('triggers if less tasks than batch size', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1'),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(4),
          firestoreService: mockFirestoreService,
        ),
        null,
      );
    });

    test('triggers after batch size', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1'),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
        generateFirestoreTask(4, name: 'task1', commitSha: 'sha4'),
        generateFirestoreTask(5, name: 'task1', commitSha: 'sha5'),
        generateFirestoreTask(6, name: 'task1', commitSha: 'sha6', status: Task.statusSucceeded),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(7, name: 'task1', commitSha: 'sha7'),
          firestoreService: mockFirestoreService,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with higher priority on recent failures', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1', status: Task.statusFailed),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
        generateFirestoreTask(4, name: 'task1', commitSha: 'sha4'),
        generateFirestoreTask(5, name: 'task1', commitSha: 'sha5'),
        generateFirestoreTask(6, name: 'task1', commitSha: 'sha6'),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(7, name: 'task1', commitSha: 'sha7'),
          firestoreService: mockFirestoreService,
        ),
        LuciBuildService.kRerunPriority,
      );
    });

    test('does not trigger on recent failures if there is already a running task', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1'),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
        generateFirestoreTask(4, name: 'task1', commitSha: 'sha4', status: Task.statusFailed),
        generateFirestoreTask(5, name: 'task1', commitSha: 'sha5', status: Task.statusInProgress),
        generateFirestoreTask(6, name: 'task1', commitSha: 'sha6'),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(7, name: 'task1', commitSha: 'sha7'),
          firestoreService: mockFirestoreService,
        ),
        isNull,
      );
    });

    test('does not trigger when a test was recently scheduled', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1', status: Task.statusSucceeded),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
        generateFirestoreTask(4, name: 'task1', commitSha: 'sha4'),
        generateFirestoreTask(5, name: 'task1', commitSha: 'sha5'),
        generateFirestoreTask(6, name: 'task1', commitSha: 'sha6'),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(7, name: 'task1', commitSha: 'sha7'),
          firestoreService: mockFirestoreService,
        ),
        isNull,
      );
    });

    test('does not trigger when pending queue is smaller than batch', () async {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1'),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
        generateFirestoreTask(4, name: 'task1', commitSha: 'sha4'),
        generateFirestoreTask(5, name: 'task1', commitSha: 'sha5', status: Task.statusSucceeded),
        generateFirestoreTask(6, name: 'task1', commitSha: 'sha6', status: Task.statusSucceeded),
      ];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(7, name: 'task1', commitSha: 'sha7'),
          firestoreService: mockFirestoreService,
        ),
        isNull,
      );
    });

    test('do not return rerun priority when no task failed', () {
      tasks = [
        generateFirestoreTask(1, name: 'task1', commitSha: 'sha1'),
        generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
        generateFirestoreTask(3, name: 'task1', commitSha: 'sha3'),
      ];
      expect(shouldRerunPriority(tasks, 5), false);
    });
  });

  group('GuaranteedPolicy', () {
    late MockFirestoreService mockFirestoreService;
    List<Task> tasks = <Task>[];

    final GuaranteedPolicy policy = GuaranteedPolicy();

    setUp(() {
      tasks.clear();
      mockFirestoreService = MockFirestoreService();
      when(
        mockFirestoreService.queryRecentTasksByName(
          name: captureAnyNamed('name'),
        ),
      ).thenAnswer((Invocation invocation) {
        return Future<List<Task>>.value(
          tasks,
        );
      });
    });

    //   final List<Task> pending = <Task>[
    //     generateTask(1),
    //   ];

    //   final List<Task> latestFailed = <Task>[generateTask(1, status: Task.statusFailed)];

    test('triggers every task', () async {
      tasks = [generateFirestoreTask(1, name: 'task1', commitSha: 'sha1')];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(
            2,
            name: 'task1',
            commitSha: 'sha2',
          ),
          firestoreService: mockFirestoreService,
        ),
        LuciBuildService.kDefaultPriority,
      );
    });

    test('triggers with a higher priority on recent failure', () async {
      tasks = [generateFirestoreTask(1, name: 'task1', commitSha: 'sha1', status: Task.statusFailed)];
      expect(
        await policy.triggerPriority(
          task: generateFirestoreTask(2, name: 'task1', commitSha: 'sha2'),
          firestoreService: mockFirestoreService,
        ),
        LuciBuildService.kRerunPriority,
      );
    });
  });
}
