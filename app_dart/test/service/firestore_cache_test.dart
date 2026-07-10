// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/firestore.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('Task Firestore Cache', () {
    late FakeFirestoreService firestore;
    late CacheService cache;
    const commitSha = 'testSha';

    setUp(() {
      cache = CacheService.inMemory();
      firestore = FakeFirestoreService(cache: cache);
    });

    test(
      'Task.fromFirestore caches task and returns from cache on second call',
      () async {
        final task = generateFirestoreTask(
          1,
          name: 'Linux A',
          attempts: 1,
          status: TaskStatus.inProgress,
        );
        firestore.putDocument(task);

        final fetched1 = await Task.fromFirestore(
          firestore,
          TaskId(
            commitSha: commitSha,
            taskName: task.taskName,
            currentAttempt: task.currentAttempt,
          ),
        );
        expect(fetched1.status, TaskStatus.inProgress);
        expect(fetched1.revisionId, 1);

        // Directly update firestore without using a service write so we know if cache is used on second read
        final rawDoc = firestore.documents.firstWhere(
          (d) => d.name == task.name,
        );
        rawDoc.fields![Task.fieldStatus] = Value(
          stringValue: TaskStatus.succeeded.value,
        );

        final fetched2 = await Task.fromFirestore(
          firestore,
          TaskId(
            commitSha: commitSha,
            taskName: task.taskName,
            currentAttempt: task.currentAttempt,
          ),
        );
        // Because fetched2 comes from cache, it should still have status inProgress and rev 1
        expect(fetched2.status, TaskStatus.inProgress);
        expect(fetched2.revisionId, 1);
      },
    );

    test(
      'queryAllTasksForCommit caches commit task IDs and serves subsequent queries from versioned task cache',
      () async {
        final task1 = generateFirestoreTask(
          1,
          name: 'Linux A',
          attempts: 1,
          status: TaskStatus.inProgress,
        );
        final task2 = generateFirestoreTask(
          2,
          name: 'Mac B',
          attempts: 1,
          status: TaskStatus.succeeded,
        );
        firestore.putDocument(task1);
        firestore.putDocument(task2);

        final initialTasks = await firestore.queryAllTasksForCommit(
          commitSha: commitSha,
        );
        expect(initialTasks.length, 2);
        expect(
          await cache.getSet('tasks_by_commit_ids', commitSha),
          isNotEmpty,
        );

        // Verify cached task lookup without hitting firestore query
        firestore.reset();
        final cachedTasks = await firestore.queryAllTasksForCommit(
          commitSha: commitSha,
        );
        expect(cachedTasks.length, 2);
      },
    );

    test(
      'queryAllTasksForCommit recovers missing individual task entries via partial query when commit set is populated',
      () async {
        final task1 = generateFirestoreTask(
          1,
          name: 'Linux A',
          attempts: 1,
          status: TaskStatus.inProgress,
        );
        final task2 = generateFirestoreTask(
          2,
          name: 'Mac B',
          attempts: 1,
          status: TaskStatus.succeeded,
        );
        firestore.putDocument(task1);
        firestore.putDocument(task2);

        await firestore.queryAllTasksForCommit(commitSha: commitSha);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await cache.purge('tasks', '${commitSha}_Mac B_1');
        expect(await cache.get('tasks', '${commitSha}_Mac B_1'), isNull);

        final recoveredTasks = await firestore.queryAllTasksForCommit(
          commitSha: commitSha,
        );
        expect(recoveredTasks.length, 2);
        expect(await cache.get('tasks', '${commitSha}_Mac B_1'), isNotNull);
      },
    );

    test(
      'batchWriteDocuments updates versioned task cache in-place lock-free',
      () async {
        final task1 = generateFirestoreTask(
          1,
          name: 'Linux A',
          attempts: 1,
          status: TaskStatus.inProgress,
        );
        firestore.putDocument(task1);

        // Populate commit cache and task cache via queryAllTasksForCommit
        final initialTasks = await firestore.queryAllTasksForCommit(
          commitSha: commitSha,
        );
        expect(initialTasks.first.status, TaskStatus.inProgress);
        expect(
          await cache.getSet('tasks_by_commit_ids', commitSha),
          isNotEmpty,
        );

        // Patch task status via batchWriteDocuments
        final patchWrite = Task.patchStatus(
          TaskId(
            commitSha: commitSha,
            taskName: task1.taskName,
            currentAttempt: task1.currentAttempt,
          ),
          TaskStatus.succeeded,
        );
        await firestore.batchWriteDocuments(
          BatchWriteRequest(writes: [patchWrite]),
          kDatabase,
        );

        // Verify that tasks_by_commit_ids remains intact (no purge needed!)
        expect(
          await cache.getSet('tasks_by_commit_ids', commitSha),
          isNotEmpty,
        );

        // Verify that single-task fetch and commit query return the updated version right from cache
        final updatedTask = await Task.fromFirestore(
          firestore,
          TaskId(
            commitSha: commitSha,
            taskName: task1.taskName,
            currentAttempt: task1.currentAttempt,
          ),
        );
        expect(updatedTask.status, TaskStatus.succeeded);
        expect(updatedTask.revisionId, 2);
      },
    );

    test(
      'writeViaTransaction updates versioned task cache in-place lock-free',
      () async {
        final task = generateFirestoreTask(
          1,
          name: 'Linux B',
          attempts: 1,
          status: TaskStatus.inProgress,
        );
        firestore.putDocument(task);
        await firestore.queryAllTasksForCommit(commitSha: commitSha);

        task.setStatus(TaskStatus.succeeded);
        await firestore.writeViaTransaction([
          Write(
            update: Document(name: task.name, fields: task.fields),
          ),
        ]);

        final updatedTask = await Task.fromFirestore(
          firestore,
          TaskId(
            commitSha: commitSha,
            taskName: task.taskName,
            currentAttempt: task.currentAttempt,
          ),
        );
        expect(updatedTask.status, TaskStatus.succeeded);
        expect(updatedTask.revisionId, 2);
      },
    );
  });
}
