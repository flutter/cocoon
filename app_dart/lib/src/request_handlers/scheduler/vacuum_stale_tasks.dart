// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:github/github.dart' as gh;
import 'package:meta/meta.dart';

import '../../model/appengine/task.dart';
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

    final List<FullTask> tasks = await datastore.queryRecentTasks(slug: slug).toList();
    final Set<Task> tasksToBeReset = <Task>{};
    for (FullTask fullTask in tasks) {
      final Task task = fullTask.task;
      if (task.status != Task.statusInProgress) {
        continue;
      }

      if (task.createTimestamp == null) {
        log.fine('Vacuuming $task due to createTimestamp being null');
        tasksToBeReset.add(task);
        continue;
      }

      final DateTime now = nowValue ?? DateTime.now();
      final DateTime create = DateTime.fromMillisecondsSinceEpoch(task.createTimestamp!);
      final Duration queueTime = now.difference(create);

      if (queueTime > kTimeoutLimit) {
        log.fine('Vacuuming $task due to staleness');
        tasksToBeReset.add(task);
        continue;
      }
    }

    final Iterable<Task> inserts = tasksToBeReset
        .map((Task task) => task..status = Task.statusNew)
        .map((Task task) => task..createTimestamp = null);
    await datastore.insert(inserts.toList());
  }
}
