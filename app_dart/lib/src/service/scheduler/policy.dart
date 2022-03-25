// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/datastore.dart';

import '../../model/appengine/task.dart';
import '../logging.dart';
import '../luci_build_service.dart';

/// Interface for implementing various scheduling policies in the Cocoon scheduler.
abstract class SchedulerPolicy {
  /// Returns the priority of [Task].
  ///
  /// If null is returned, the task should not be scheduled.
  Future<int?> triggerPriority({
    required Task task,
    required DatastoreService datastore,
  });
}

/// Every [Task] is triggered to run.
class GuranteedPolicy implements SchedulerPolicy {
  @override
  Future<int?> triggerPriority({
    required Task task,
    required DatastoreService datastore,
  }) async =>
      LuciBuildService.kDefaultPriority;
}

class BatchPolicy implements SchedulerPolicy {
  static const int kBatchSize = 3;
  @override
  Future<int?> triggerPriority({
    required Task task,
    required DatastoreService datastore,
  }) async {
    final List<Task> recentTasks = await datastore.queryRecentTasksByName(name: task.name!).toList();
    // Ensure task isn't considered in recentTasks
    recentTasks.removeWhere((Task t) => t.commitKey == task.commitKey);
    if (recentTasks.length < kBatchSize - 1) {
      log.warning('${task.name} has less than $kBatchSize, triggerring all builds regardless of policy');
      return LuciBuildService.kDefaultPriority;
    }

    // Prioritize tasks that recently failed.
    if (_isFailed(recentTasks[0]) || _isFailed(recentTasks[1])) {
      return LuciBuildService.kRerunPriority;
    }

    if (recentTasks[0].status == Task.statusNew && recentTasks[1].status == Task.statusNew) {
      return LuciBuildService.kDefaultPriority;
    }

    return null;
  }

  bool _isFailed(Task task) {
    return task.status == Task.statusFailed || task.status == Task.statusInfraFailure;
  }
}

/// [Task] run outside of Cocoon are not triggered by the Cocoon scheduler.
class OmitPolicy implements SchedulerPolicy {
  @override
  Future<int?> triggerPriority({
    required Task task,
    required DatastoreService datastore,
  }) async =>
      null;
}
