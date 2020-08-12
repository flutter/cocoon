// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../model/appengine/task.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';

/// Cleans up any tasks that have been [Task.statusInProgress] for over an hour.
///
/// It is assumed that any tasks that are still recorded as being in progress
/// an hour after having been started are in fact stranded, perhaps because the
/// agent running the task crashed. In response, this handler looks for such
/// tasks and either:
///
///  * Marks them as [Task.statusFailed] if they've reached their retry limit
///  * Marks them as [Task.statusNew] if they've not reached their retry limit,
///    to allow an agent to pick the task up and try to run it again.
@immutable
class VacuumClean extends ApiRequestHandler<Body> {
  const VacuumClean(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting DatastoreServiceProvider datastoreProvider,
  })  : datastoreProvider = datastoreProvider ?? DatastoreService.defaultProvider,
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> get() async {
    final int maxRetries = config.maxTaskRetries;
    final DatastoreService datastore = datastoreProvider(config.db);
    final List<Task> tasks = await datastore
        .queryRecentTasksNoBranch(commitLimit: config.commitNumber)
        .map<Task>((FullTask fullTask) => fullTask.task)
        .where(shouldBeVacuumCleaned)
        .toList();
    log.debug('Found ${tasks.length} in progress tasks that have been stranded');
    for (Task task in tasks) {
      if (task.attempts >= maxRetries) {
        task.status = Task.statusFailed;
        task.reason = 'Task timed out after 1 hour';
      } else {
        // This will cause this task to be picked up by an agent again.
        task.status = Task.statusNew;
        task.startTimestamp = 0;
      }
    }

    await datastore.insert(tasks);
    return Body.empty;
  }

  bool shouldBeVacuumCleaned(Task task) {
    return _inProgress(task) && isOverAnHourOld(task);
  }

  /// Returns whether [task] is in progress.
  bool _inProgress(Task task) => task.status == Task.statusInProgress;

  /// Returns whether the specified [task] was started over an hour ago.
  bool isOverAnHourOld(Task task) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    const Duration oneHour = Duration(hours: 1);
    return task.startTimestamp < now - oneHour.inMilliseconds;
  }
}
