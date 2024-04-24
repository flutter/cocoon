// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart' as gh;
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../model/appengine/task.dart';
import '../../model/firestore/task.dart' as firestore;
import '../../model/firestore/commit.dart' as firestore_commit;
import '../../service/datastore.dart';
import '../../service/logging.dart';

/// Vacuum stale tasks.
///
/// Occassionally, a build never gets processed by LUCI. To prevent tasks
/// being stuck as "In Progress," this will return tasks to "New" if they have
/// no updates after 3 hours.
@immutable
class VacuumStaleTasks extends RequestHandler<Body> {
  const VacuumStaleTasks({
    required super.config,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting this.nowValue,
  });

  final DatastoreServiceProvider datastoreProvider;

  /// For testing, can be used to inject a deterministic time.
  final DateTime? nowValue;

  /// Tasks that are in progress for this duration will be reset.
  static const Duration kTimeoutLimit = Duration(hours: 3);

  @override
  Future<Body> get() async {
    final List<Future<void>> futures = <Future<void>>[];
    for (gh.RepositorySlug slug in config.supportedRepos) {
      futures.add(_vacuumRepository(slug));
    }

    await Future.wait(futures);

    return Body.empty;
  }

  /// Scans [slug] for tasks that have reached the timeout limit, and sets
  /// them back to the new state.
  ///
  /// The expectation is the [BatchBackfiller] will be able to reschedule these.
  Future<void> _vacuumRepository(gh.RepositorySlug slug) async {
    final DatastoreService datastore = datastoreProvider(config.db);

    final FirestoreService firestoreService = await config.createFirestoreService();

    // Datastore logic to query for recent tasks and assign to commits
    final List<FullTask> tasks =
        await datastore.queryRecentTasks(slug: slug, commitLimit: config.backfillerTargetLimit).toList();
    final List<Task> tasksToBeReset = <Task>[];
    for (FullTask fullTask in tasks) {
      final Task task = fullTask.task;
      if (task.status == Task.statusInProgress && task.buildNumber == null) {
        task.status = Task.statusNew;
        task.createTimestamp = 0;
        tasksToBeReset.add(task);
      }
    }

    // Firestore logic to query for recent tasks and assign to commits
    final List<(firestore.Task, firestore_commit.Commit)> firestoreTasks =
        await firestoreService.queryRecentTasks(slug: slug, commitLimit: config.backfillerTargetLimit);
    final List<firestore.Task> firestoreTasksToBeReset = <firestore.Task>[];
    for (var taskRecord in firestoreTasks) {
      final firestore.Task task = taskRecord.$1; // extract Task
      if (task.status == Task.statusInProgress && task.buildNumber == null) {
        task.setStatus(Task.statusNew);
        task.setCreateTimestamp(0);
        firestoreTasksToBeReset.add(task);
      }
    }
    log.info('Vacuuming stale firestore tasks: $tasksToBeReset');
    await datastore.insert(tasksToBeReset);

    log.info('Vacuuming stale firestore tasks: $firestoreTasksToBeReset');
    await updateTaskDocuments(firestoreTasksToBeReset);
  }

  Future<void> updateTaskDocuments(List<firestore.Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }
    final List<Write> writes = documentsToWrites(tasks, exists: true);
    final FirestoreService firestoreService = await config.createFirestoreService();
    await firestoreService.writeViaTransaction(writes);
  }
}
