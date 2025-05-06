// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';

import '../../model/firestore/task.dart';
import '../luci_build_service.dart';

/// Interface for implementing various scheduling policies in the Cocoon scheduler.
sealed class SchedulerPolicy {
  /// Returns the priority of [taskName], given [recentTasks] executing the same thing.
  ///
  /// If null is returned, the task should not be scheduled.
  Future<int?> triggerPriority({
    required String commitSha,
    required String taskName,
    required List<Task> recentTasks,
  });
}

/// Every [Task] is triggered to run.
final class GuaranteedPolicy implements SchedulerPolicy {
  const GuaranteedPolicy();

  @override
  Future<int?> triggerPriority({
    required String commitSha,
    required String taskName,
    required List<Task> recentTasks,
  }) async {
    // Ensure task isn't considered in recentTasks
    recentTasks.removeWhere(
      (Task t) => t.taskName == taskName && t.commitSha == commitSha,
    );
    if (recentTasks.isEmpty) {
      log.warn(
        '$taskName is newly added, triggerring builds regardless of policy',
      );
      return LuciBuildService.kDefaultPriority;
    }
    // Prioritize tasks that recently failed.
    if (_shouldRerunPriority(recentTasks, 1)) {
      return LuciBuildService.kRerunPriority;
    }
    return LuciBuildService.kDefaultPriority;
  }
}

/// [Task] is run at least every 6 commits.
///
/// If there is capacity, a backfiller cron triggers the latest task that was not run
/// to ensure ToT is always tested.
///
/// This is intended for targets that are run in an infra pool that has limited capacity,
/// such as the on device tests in the DeviceLab.
final class BatchPolicy implements SchedulerPolicy {
  static const int kBatchSize = 6;

  const BatchPolicy();

  @override
  Future<int?> triggerPriority({
    required String commitSha,
    required String taskName,
    required List<Task> recentTasks,
  }) async {
    // Skip scheduling if there is already a running task.
    if (recentTasks.any((Task task) => task.status == TaskStatus.inProgress)) {
      return null;
    }

    // Ensure task isn't considered in recentTasks
    recentTasks.removeWhere(
      (Task t) => t.taskName == taskName && t.commitSha == commitSha,
    );
    if (recentTasks.length < kBatchSize) {
      log.warn(
        '$taskName has less than $kBatchSize, skip scheduling to wait for '
        'ci.yaml roll.',
      );
      return null;
    }

    // Prioritize tasks that recently failed.
    if (_shouldRerunPriority(recentTasks, kBatchSize)) {
      return LuciBuildService.kRerunPriority;
    }

    if (_allWaitingOrSkipped(recentTasks.sublist(0, kBatchSize - 1))) {
      return LuciBuildService.kDefaultPriority;
    }

    return null;
  }
}

/// Checks if all tasks are with waiting for backfill or skipped.
bool _allWaitingOrSkipped(List<Task> tasks) {
  const newOrSkipped = {TaskStatus.waitingForBackfill, TaskStatus.skipped};
  return tasks.every((Task task) => newOrSkipped.contains(task.status));
}

/// Return true if there is an earlier failed build.
bool _shouldRerunPriority(List<Task> tasks, int pastTaskNumber) {
  // Prioritize tasks that recently failed.
  var hasRecentFailure = false;
  for (var i = 0; i < pastTaskNumber && i < tasks.length; i++) {
    if (tasks[i].status.isFailure) {
      hasRecentFailure = true;
      break;
    }
  }
  return hasRecentFailure;
}

/// [Task] run outside of Cocoon are not triggered by the Cocoon scheduler.
final class OmitPolicy implements SchedulerPolicy {
  const OmitPolicy();

  @override
  Future<int?> triggerPriority({
    required String commitSha,
    required String taskName,
    required List<Task> recentTasks,
  }) async => null;
}
