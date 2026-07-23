// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as p;

import '../../model/firestore/task.dart';
import '../cache_service.dart';
import '../config.dart';

/// Result container for task payload batch lookups.
final class TaskPayloadLookupResult {
  TaskPayloadLookupResult({
    required this.foundTasks,
    required this.missingDocIds,
  });

  /// Tasks successfully retrieved and deserialized from cache.
  final List<Task> foundTasks;

  /// Document IDs whose payload was expired or missing in cache.
  final List<String> missingDocIds;
}

/// Dedicated service encapsulating Redis caching logic for /tasks.
///
/// ## Two-Tier Lock-Free Task Caching Architecture
///
/// ### Invariant 1: Task Entity Payload Cache (`tasks/$docId`)
/// - **Monotonically Increasing Revision ID**: Database write transactions establish a strict total order
///   of document states, monotonically numbered by `revisionId`.
/// - **Optimistic Version Guarding**: Write-backs call `insertVersioned(tasks/$docId, payload, revisionId)`.
///   Redis atomically evaluates `newRev > existingRev` (or `EXISTS == 0`).
///
/// #### Scenario 1.1: Read Task Entry
/// ```mermaid
/// flowchart TD
///     A["Query tasks/$docId Payload"] --> B{"Key Exists in Redis?"}
///     B -- Cache Hit --> C["Return Serialized JSON Payload"]
///     B -- Cache Miss --> D["Fetch Task from DB"]
///     D --> E["cacheTaskPayloads"]
///     E -- "!existingEntry || task.revisionId > existingEntry.revisionId" --> F[Cache write]
///     E -- "task.revisionId <= existingEntry.revisionId" --> G[No cache write]
///     F --> C
///     G --> C
/// ```
///
/// #### Scenario 1.2: Write Task Entry
/// ```mermaid
/// flowchart TD
///     A["Write/create task"] --> B[Write task to database, increment revisionId]
///     B --> C[cacheTaskPayloads]
///     C -- "!existingEntry || task.revisionId > existingEntry.revisionId" --> D[Cache write]
///     C -- "task.revisionId <= existingEntry.revisionId" --> E[No cache write]
///     D --> F[Return task]
///     E --> F[Return task]
/// ```
///
/// ### Invariant 2: Commit Task Index Set Cache (`tasks_by_commit_ids/$commitSha`)
/// - **Monotonically Growing Set & Immutable Commit Association**: A task's `commitSha` is permanent
///   upon creation and never changes. Task status updates **never alter set membership** and **never touch
///   `tasks_by_commit_ids`**. We only ever modify `tasks_by_commit_ids` when new tasks are created.
///
/// #### Scenario 2.1: Read `taskIdsByCommitId`
/// ```mermaid
/// flowchart TD
///     A["getTaskIdsForCommit(commitSha)"] --> B["getTaskPayloads"]
///     B -- Cache hit --> C["Return Set of Task IDs (SMEMBERS)"]
///     B -- Cache miss --> D["initializeCommitTaskSet (setIfNotExists)"]
///     D -- "Success (Set Initialized)" --> E["Set Created with Task IDs"]
///     D -- "Failed (Intervening Initialization)" --> F[addTasksToCommitSet]
///     F --> C
///     E --> C
/// ```
///
/// #### Scenario 2.2: Create Task
/// ```mermaid
/// flowchart TD
///     A[Create task] --> B[addTasksToCommitSet]
///     B -- Cache entry exists, taskId added --> C[Return]
///     B -- Cache entry does not exist --> D[Fetch tasks for task.commitId]
///     D --> E[initializeCommitTaskSet]
///     E -- "Success (Set Initialized)" --> C
///     E -- "Failed (Intervening Initialization)" --> F[addTasksToCommitSet]
///     F --> C
/// ```
final class TaskCacheService {
  TaskCacheService({required this.cache, this.config});

  final CacheService cache;
  final Config? config;

  /// Returns whether caching is enabled in dynamic config.
  bool get isEnabled => config?.flags.taskCachingEnabled ?? true;

  /// Returns the default cache TTL based on dynamic configuration.
  Duration get defaultTtl =>
      Duration(hours: config?.flags.taskCacheTtlInHours ?? 12);

  // --------------------------------------------------------------------------
  // Invariant 1: Task Entity Payload Cache (`tasks/$docId`)
  // --------------------------------------------------------------------------

  /// Caches full [Task] document payloads using optimistic versioning (`revisionId`).
  ///
  /// The payload update only succeeds if `task.revisionId > existingRev` or the cache key is missing.
  Future<void> cacheTaskPayloads(Iterable<Task> tasks, {Duration? ttl}) async {
    if (tasks.isEmpty || !isEnabled) return;
    final effectiveTtl = ttl ?? defaultTtl;
    final entries = [
      for (final t in tasks)
        VersionedCacheEntry(
          key: p.basename(t.name!),
          value: Task.serialize(t),
          revisionId: t.revisionId,
          ttl: effectiveTtl,
        ),
    ];
    await cache.insertVersioned('tasks', entries);
  }

  /// Evicts a deleted task payload from Redis.
  Future<void> evictTaskPayload(String docId) async {
    if (!isEnabled) return;
    await cache.purge('tasks', docId);
  }

  /// Performs a batch lookup of task payloads by document IDs.
  Future<TaskPayloadLookupResult> getTaskPayloads(Iterable<String> docIds) async {
    final docIdList = docIds.toList();
    if (docIdList.isEmpty || !isEnabled) {
      return TaskPayloadLookupResult(foundTasks: [], missingDocIds: docIdList);
    }

    final cachedData = await cache.getMulti('tasks', docIdList);
    final foundTasks = <Task>[];
    final missingDocIds = <String>[];

    for (var i = 0; i < docIdList.length; i++) {
      final data = cachedData[i];
      if (data != null) {
        try {
          foundTasks.add(Task.deserialize(data));
        } catch (_) {
          missingDocIds.add(docIdList[i]);
        }
      } else {
        missingDocIds.add(docIdList[i]);
      }
    }

    return TaskPayloadLookupResult(
      foundTasks: foundTasks,
      missingDocIds: missingDocIds,
    );
  }

  // --------------------------------------------------------------------------
  // Invariant 2: Commit Task Index Set Cache (`tasks_by_commit_ids/$commitSha`)
  // --------------------------------------------------------------------------

  /// Retrieves the set of task document IDs associated with [commitSha].
  ///
  /// Returns `null` if the set key does not exist in Redis (cache miss).
  Future<Set<String>?> getTaskIdsForCommit(String commitSha) async {
    if (!isEnabled) return null;
    final set = await cache.getSet('tasks_by_commit_ids', commitSha);
    if (set.isEmpty) return null;
    return set;
  }

  /// Adds [taskIds] to the commit set if the set already exists in Redis (`addToSetIfExists`).
  ///
  /// Returns `true` if the set existed and task IDs were added; `false` if the set key is missing.
  Future<bool> addTasksToCommitSet(
    String commitSha,
    Iterable<String> taskIds, {
    Duration? ttl,
  }) async {
    if (taskIds.isEmpty || !isEnabled) return false;
    var allAdded = true;
    for (final taskId in taskIds) {
      final added = await cache.addToSetIfExists(
        'tasks_by_commit_ids',
        commitSha,
        taskId,
      );
      if (!added) {
        allAdded = false;
      }
    }
    return allAdded;
  }

  /// Initializes the commit task set if it does NOT already exist (`setIfNotExists`).
  ///
  /// Returns `true` if the set was successfully updated/initialized.
  Future<bool> initializeCommitTaskSet(
    String commitSha,
    Iterable<String> taskIds, {
    Duration? ttl,
  }) async {
    if (!isEnabled) return false;
    await cache.updateSet(
      'tasks_by_commit_ids',
      commitSha,
      taskIds.toSet(),
      ttl: ttl ?? defaultTtl,
    );
    return true;
  }
}
