// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:meta/meta.dart';

/// Function signature for a [TaskService] provider.
typedef TaskServiceProvider = TaskService Function(DatastoreService datastoreService);

class TaskService {
  TaskService(
    this.datastore,
  ) : assert(datastore != null);

  /// The backing datastore. Guaranteed to be non-null.
  final DatastoreService datastore;

  /// Creates and returns a [TaskService] using [datastore].
  static TaskService defaultProvider(DatastoreService datastore) {
    return TaskService(datastore);
  }

  Future<FullTask> findNextTask(Agent agent) async {
    await for (Commit commit in datastore.queryRecentCommitsNoBranch()) {
      final List<Stage> stages = await datastore.queryTasksGroupedByStage(commit);
      for (Stage stage in stages) {
        if (!stage.isManagedByDeviceLab) {
          continue;
        }
        for (Task task in List<Task>.from(stage.tasks)..sort(Task.byAttempts)) {
          if (task.requiredCapabilities.isEmpty) {
            throw InvalidTaskException('Task ${task.name} has no required capabilities');
          }
          if (task.status == Task.statusNew && agent.isCapableOfPerformingTask(task)) {
            return FullTask(task, commit);
          }
        }
      }
    }

    return null;
  }
}

@visibleForTesting
class InvalidTaskException implements Exception {
  const InvalidTaskException(this.message);

  final String message;

  @override
  String toString() => message;
}
