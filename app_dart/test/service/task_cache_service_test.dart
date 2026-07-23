// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_service/src/model/firestore/task.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/firestore/task_cache_service.dart';
import 'package:cocoon_service/src/service/flags/dynamic_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late InMemoryCacheService cache;
  late FakeConfig config;
  late TaskCacheService taskCache;

  Task generateTestTask(
    int attempt, {
    String name = 'Linux A',
    String commitSha = 'sha123',
    TaskStatus status = TaskStatus.inProgress,
  }) {
    return Task(
      builderName: name,
      currentAttempt: attempt,
      commitSha: commitSha,
      bringup: false,
      createTimestamp: 1000,
      startTimestamp: 1000,
      endTimestamp: 0,
      status: status,
      testFlaky: false,
      buildNumber: null,
    );
  }

  String docIdFor(Task task) => p.basename(task.name!);

  setUp(() {
    cache = InMemoryCacheService();
    config = FakeConfig(dynamicConfig: DynamicConfig(taskCachingEnabled: true));
    taskCache = TaskCacheService(cache: cache, config: config);
  });

  group('TaskCacheService Payload Caching', () {
    test('cacheTaskPayloads stores versioned payload and getTaskPayloads retrieves it', () async {
      final task = generateTestTask(1);
      await taskCache.cacheTaskPayloads([task]);

      final result = await taskCache.getTaskPayloads([docIdFor(task)]);
      expect(result.foundTasks.length, equals(1));
      expect(result.foundTasks.first.taskName, equals('Linux A'));
      expect(result.missingDocIds, isEmpty);
    });

    test('evictTaskPayload purges item from cache', () async {
      final task = generateTestTask(1);
      await taskCache.cacheTaskPayloads([task]);

      await taskCache.evictTaskPayload(docIdFor(task));
      final result = await taskCache.getTaskPayloads([docIdFor(task)]);
      expect(result.foundTasks, isEmpty);
      expect(result.missingDocIds, contains(docIdFor(task)));
    });

    test('getTaskPayloads correctly reports missing and found items', () async {
      final task1 = generateTestTask(1, name: 'Linux A');
      await taskCache.cacheTaskPayloads([task1]);

      final result = await taskCache.getTaskPayloads([docIdFor(task1), 'non_existent_doc']);
      expect(result.foundTasks.length, equals(1));
      expect(result.foundTasks.first.taskName, equals('Linux A'));
      expect(result.missingDocIds, equals(['non_existent_doc']));
    });

    test('cacheTaskPayloads respects taskCachingEnabled flag', () async {
      config.dynamicConfig = DynamicConfig(taskCachingEnabled: false);
      final task = generateTestTask(1);
      await taskCache.cacheTaskPayloads([task]);

      final result = await taskCache.getTaskPayloads([docIdFor(task)]);
      expect(result.foundTasks, isEmpty);
      expect(result.missingDocIds, contains(docIdFor(task)));
    });
  });

  group('TaskCacheService Commit Set Caching', () {
    test('getTaskIdsForCommit returns null on cache miss', () async {
      final taskIds = await taskCache.getTaskIdsForCommit('sha123');
      expect(taskIds, isNull);
    });

    test('initializeCommitTaskSet populates set and getTaskIdsForCommit retrieves it', () async {
      final created = await taskCache.initializeCommitTaskSet('sha123', ['doc1', 'doc2']);
      expect(created, isTrue);

      final taskIds = await taskCache.getTaskIdsForCommit('sha123');
      expect(taskIds, equals({'doc1', 'doc2'}));
    });

    test('addTasksToCommitSet adds items only if set exists', () async {
      // First attempt on missing set returns false
      final addedMissing = await taskCache.addTasksToCommitSet('sha123', ['doc1']);
      expect(addedMissing, isFalse);

      // Initialize set
      await taskCache.initializeCommitTaskSet('sha123', ['doc1']);

      // Second attempt on existing set returns true and updates set
      final addedExisting = await taskCache.addTasksToCommitSet('sha123', ['doc2']);
      expect(addedExisting, isTrue);

      final taskIds = await taskCache.getTaskIdsForCommit('sha123');
      expect(taskIds, equals({'doc1', 'doc2'}));
    });

    test('initializeCommitTaskSet returns false if set flag is disabled', () async {
      config.dynamicConfig = DynamicConfig(taskCachingEnabled: false);
      final first = await taskCache.initializeCommitTaskSet('sha123', ['doc1']);
      expect(first, isFalse);
    });
  });
}
