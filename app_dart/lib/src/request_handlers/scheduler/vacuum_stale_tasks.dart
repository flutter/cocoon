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
import '../../service/datastore.dart';

/// Vacuum stale tasks.
///
/// Occassionally, a build never gets processed by LUCI. To prevent tasks
/// being stuck as "In Progress," this will return tasks to "New" if they have
/// no updates after 3 hours.
@immutable
class VacuumStaleTasks extends RequestHandler<Body> {
  const VacuumStaleTasks({
    required super.config,
    required LuciBuildService luciBuildService,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting this.nowValue,
  }) : _luciBuildService = luciBuildService;

  final DatastoreServiceProvider datastoreProvider;

  /// For testing, can be used to inject a deterministic time.
  final DateTime? nowValue;

  /// Tasks that are in progress without a build for this duration will be
  /// reset.
  static const Duration kTimeoutLimit = Duration(hours: 3);

  final LuciBuildService _luciBuildService;

  @override
  Future<Body> get() async {
    final futures = <Future<void>>[];
    for (var slug in config.supportedRepos) {
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
    final datastore = datastoreProvider(config.db);

    // Use the same commit limit as the backfill scheduler, since the primary
    // purpose of fixing stuck tasks is to prevent the backfiller from being
    // stuck on one of these tasks.
    final tasks =
        await datastore
            .queryRecentTasks(
              slug: slug,
              commitLimit: config.backfillerCommitLimit,
            )
            .toList();
    final tasksToBeReset = <Task>[];
    final now = DateTime.now();
    for (var fullTask in tasks) {
      final task = fullTask.task;
      if (task.status != Task.statusInProgress) {
        // TODO(matanlurey): Change the query instead of doing in-memory filtering.
        // This should probably wait until we migrate to Firestore.
        continue;
      }
      if (task.buildNumber case final buildNumber?) {
        final build = await _luciBuildService.getProdBuilds(
          builderName: task.builderName,
          sha: fullTask.commit.sha,
        );
        if (build.isEmpty) {
          log.warn(
            'Requested an update for build#$buildNumber (${task.builderName}, sha=${fullTask.commit.sha}), but no response.',
          );
          continue;
        }
        task.updateFromBuildbucketBuild(build.first);
      } else {
        // If the task hasn't been assigned a build, see if it's been waiting
        // longer than the timeout, and if so reset it back to New as a
        // mitigation for https://github.com/flutter/flutter/issues/122117 until
        // the root cause is determined and fixed.
        final creationTime = DateTime.fromMillisecondsSinceEpoch(
          task.createTimestamp ?? 0,
        );
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
    final writes = documentsToWrites([
      ...tasks.map(firestore.Task.fromDatastore),
    ], exists: true);
    final firestoreService = await config.createFirestoreService();
    await firestoreService.writeViaTransaction(writes);
  }
}
