// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as gh;
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/appengine/task.dart';
import '../../model/firestore/task.dart' as firestore;

/// "Vacuums" stale tasks.
///
/// Occassionally, a build never gets processed by LUCI. To prevent tasks
/// being stuck as "In Progress," this will return tasks to "New" if they have
/// no updates after 3 hours.
///
/// For configuration options, see [VacuumStaleTasks.new].
@immutable
interface class VacuumStaleTasks extends RequestHandler<Body> {
  /// Creates a [VacuumStaleTasks] request handler.
  ///
  /// When [get] is invoked, it:
  /// - Looks for the last [Config.backfillerCommitLimit] commits;
  /// - Finds tasks associated with that task that are both:
  ///   - [Task.statusInProgress] and
  ///   - Do not have a [Task.buildNumber] assigned
  ///
  /// If a task was found that was created longer than [timeoutLimit] the
  /// status is "reset" (set back to [Task.new]).
  const VacuumStaleTasks({
    required super.config,
    @visibleForTesting DateTime Function() now = DateTime.now,
    @visibleForTesting Duration timeoutLimit = const Duration(hours: 3),
  }) : _now = now,
       _timeoutLimit = timeoutLimit;

  final DateTime Function() _now;
  final Duration _timeoutLimit;

  @override
  Future<Body> get() async {
    final futures = <Future<void>>[];
    for (final slug in config.supportedRepos) {
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
    // Use the same commit limit as the backfill scheduler, since the primary
    // purpose of fixing stuck tasks is to prevent the backfiller from being
    // stuck on one of these tasks.
    final commitLimit = config.backfillerCommitLimit;
    final firestoreService = await config.createFirestoreService();

    // For each recent commit, find each task associated with it.
    final tasksToBeReset = <firestore.Task>[];
    for (final recentCommit in await firestoreService.queryRecentCommits(
      slug: slug,
      limit: commitLimit,
    )) {
      for (final taskForCommit in await firestoreService.queryCommitTasks(
        recentCommit.sha!,
      )) {
        // For completed tasks, skip.
        if (taskForCommit.status != Task.statusInProgress) {
          continue;
        }

        // For tasks that are assigned a build, skip.
        if (taskForCommit.buildNumber != null) {
          continue;
        }

        // If the task hasn't been assigned a build, see if it's been waiting
        // longer than the timeout, and if so reset it back to New as a
        // mitigation for https://github.com/flutter/flutter/issues/122117 until
        // the root cause is determined and fixed.
        final creationTime = DateTime.fromMillisecondsSinceEpoch(
          taskForCommit.createTimestamp ?? 0,
        );
        if (_now().difference(creationTime) > _timeoutLimit) {
          taskForCommit.setStatus(Task.statusNew);
          tasksToBeReset.add(taskForCommit);
        }
      }
    }

    log.info('Vacuuming stale tasks: $tasksToBeReset');
    await _updateTaskDocuments(firestoreService, tasksToBeReset);
  }

  Future<void> _updateTaskDocuments(
    FirestoreService firestoreService,
    List<firestore.Task> tasks,
  ) async {
    if (tasks.isEmpty) {
      return;
    }
    final writes = documentsToWrites(tasks, exists: true);
    await firestoreService.writeViaTransaction(writes);
  }
}
