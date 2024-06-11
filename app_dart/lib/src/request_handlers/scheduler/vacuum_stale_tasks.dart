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

  /// Tasks that are in progress without a build for this duration will be
  /// reset.
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

    // Use the same commit limit as the backfill scheduler, since the primary
    // purpose of fixing stuck tasks is to prevent the backfiller from being
    // stuck on one of these tasks.
    final List<FullTask> tasks =
        await datastore.queryRecentTasks(slug: slug, commitLimit: config.backfillerCommitLimit).toList();
    final List<Task> tasksToBeReset = <Task>[];
    final DateTime now = DateTime.now();
    for (FullTask fullTask in tasks) {
      final Task task = fullTask.task;
      if (task.status == Task.statusInProgress && task.buildNumber == null) {
        // If the task hasn't been assigned a build, see if it's been waiting
        // longer than the timeout, and if so reset it back to New as a
        // mitigation for https://github.com/flutter/flutter/issues/122117 until
        // the root cause is determined and fixed.
        final DateTime creationTime = DateTime.fromMillisecondsSinceEpoch(task.createTimestamp ?? 0);
        if (now.difference(creationTime) > kTimeoutLimit) {
          task.status = Task.statusNew;
          tasksToBeReset.add(task);
        }
      }
    }
    log.info('Vacuuming stale tasks: $tasksToBeReset');
    await datastore.insert(tasksToBeReset);

    await updateTaskDocuments(tasksToBeReset);
  }

  Future<void> updateTaskDocuments(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }
    final List<firestore.Task> taskDocuments = tasks.map((e) => firestore.taskToDocument(e)).toList();
    final List<Write> writes = documentsToWrites(taskDocuments, exists: true);
    final FirestoreService firestoreService = await config.createFirestoreService();
    await firestoreService.writeViaTransaction(writes);
  }
}
