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
import 'package:path/path.dart' as p;
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
      'batchWriteDocuments updates versioned task cache with full document and incremented revisionId',
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
        expect(initialTasks.first.revisionId, 1);
        expect(
          await cache.getSet('tasks_by_commit_ids', commitSha),
          isNotEmpty,
        );

        // Mutate task status and increment revisionId
        task1.setStatus(TaskStatus.succeeded);
        await firestore.batchWriteDocuments(
          BatchWriteRequest(writes: documentsToWrites([task1])),
          kDatabase,
        );

        // Verify that tasks_by_commit_ids remains intact
        expect(
          await cache.getSet('tasks_by_commit_ids', commitSha),
          isNotEmpty,
        );

        // Verify that single-task payload cache entry was updated in Redis with full document and rev 2
        final cachedBytes = await cache.get('tasks', p.basename(task1.name!));
        expect(cachedBytes, isNotNull);
        final cachedTask = Task.deserialize(cachedBytes!);
        expect(cachedTask.status, TaskStatus.succeeded);
        expect(cachedTask.revisionId, 2);
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

    test(
      'updateCacheForCreatedTasks groups tasks by commit SHA',
      () async {
        final task1 = generateFirestoreTask(1, commitSha: 'shaA', name: 'Linux A');
        final task2 = generateFirestoreTask(2, commitSha: 'shaA', name: 'Linux B');
        final task3 = generateFirestoreTask(3, commitSha: 'shaB', name: 'Linux C');

        await firestore.updateCacheForCreatedTasks([task1, task2, task3]);

        final cachedTask1 = await cache.get('tasks', p.basename(task1.name!));
        final cachedTask2 = await cache.get('tasks', p.basename(task2.name!));
        final cachedTask3 = await cache.get('tasks', p.basename(task3.name!));

        expect(cachedTask1, isNotNull);
        expect(cachedTask2, isNotNull);
        expect(cachedTask3, isNotNull);
      },
    );
  });
}
