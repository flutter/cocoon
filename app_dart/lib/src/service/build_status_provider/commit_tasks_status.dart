// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../../model/firestore/commit.dart';
import '../../model/firestore/task.dart';

/// Class that holds the status for all tasks corresponding to a particular
/// commit.
///
/// Tasks may still be running, and thus their status is subject to change.
/// Put another way, this class holds information that is a snapshot in time.
@immutable
final class CommitTasksStatus {
  /// Creates a new [CommitTasksStatus].
  const CommitTasksStatus(this.commit, this.tasks);

  /// The commit against which all the tasks are run.
  final Commit commit;

  /// Tasks running against the commit.
  final List<Task> tasks;

  /// Refactors task list to fullTask list.
  ///
  /// After migrated to Firestore, we are tracking each rerun as a separate Task entry.
  /// But from Frontend side, it is expecting a build list for all retries.
  ///
  /// Instead of adding burden to the frondend loading, a proactive preparation is
  /// added here to provide build list explicitly.
  ///
  /// Note we use the lastest run as the `task`, surfacing on the dashboard.
  List<FullTask> collateTasksByTaskName() {
    // First, create a Map<Builder, [Tasks from High Attempt > Low]>
    final tasksByBuilder = tasks.groupListsBy((t) => t.taskName);

    // Sort the tasks from MOST RECENT to LEAST RECENT.
    for (final tasks in tasksByBuilder.values) {
      tasks.sort((a, b) => b.currentAttempt.compareTo(a.currentAttempt));
    }

    return [
      for (final tasks in tasksByBuilder.values)
        FullTask(
          tasks.first,
          [...tasks.reversed.map((t) => t.buildNumber).nonNulls],
          didAtLeastOneFailureOccur: tasks.any(
            (t) => Task.taskFailStatusSet.contains(t.status),
          ),
          lastCompletedAttemptWasFailure: _lastCompletedAttemptWasFailure(
            tasks,
          ),
        ),
    ];
  }

  static bool _lastCompletedAttemptWasFailure(List<Task> tasks) {
    // Iterate through the tasks.
    // As soon as we find a PASSING or {FAILED, INFRA FAILURE, CANCELLED}, stop.
    for (final task in tasks) {
      if (task.status == Task.statusSucceeded) {
        return false;
      }
      if (Task.taskFailStatusSet.contains(task.status)) {
        return true;
      }
    }
    return false;
  }
}

/// Latest [task] entry and its re-run [buildList].
@immutable
final class FullTask {
  const FullTask(
    this.task,
    this.buildList, {
    required this.didAtLeastOneFailureOccur,
    required this.lastCompletedAttemptWasFailure,
  });

  /// Task representing a [Task.taskName] builder.
  final Task task;

  /// Every [Task.buildNumber] associated with [Task.taskName].
  final List<int> buildList;

  /// Whether at least one run was considered a failure.
  final bool didAtLeastOneFailureOccur;

  /// Whether the last _completed_ attempt was a failure.
  final bool lastCompletedAttemptWasFailure;
}
