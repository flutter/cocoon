// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../model/firestore/commit.dart';
import '../../model/firestore/task.dart';

/// Class that holds the status for all tasks corresponding to a particular
/// commit.
///
/// Tasks may still be running, and thus their status is subject to change.
/// Put another way, this class holds information that is a snapshot in time.
class CommitTasksStatus {
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
    // Create an initial map of { task-name -> FullTask(latestTask, []) }
    final fullTasksMap = <String, FullTask>{};
    for (final task in tasks) {
      final FullTask taskToAddBuildNumber;
      // If task.taskName already exists
      if (fullTasksMap[task.taskName] case final fullTask?) {
        // If this task is newer than the existing task, use the new task
        if (task.currentAttempt > fullTask.task.currentAttempt) {
          taskToAddBuildNumber = FullTask(task, fullTask.buildList);
        } else {
          // Otherwise, just reference the existing (newer) task
          taskToAddBuildNumber = fullTask;
        }
      } else {
        // Otherwise, use this task as the latest task (so far)
        taskToAddBuildNumber = FullTask(task, []);
      }

      // If the task has a build number, add it to the list
      if (task.buildNumber case final buildNumber?) {
        taskToAddBuildNumber.buildList.add(buildNumber);
      }

      // And store it for the next loop
      fullTasksMap[task.taskName] = taskToAddBuildNumber;
    }

    // Sort build numbers, and return.
    final fullTasks = [...fullTasksMap.values];
    for (final fullTask in fullTasks) {
      fullTask.buildList.sort();
    }
    return fullTasks;
  }
}

/// Latest task entry and its rerun build list.
class FullTask {
  const FullTask(this.task, this.buildList);

  final Task task;
  final List<int> buildList;

  Map<String, Object?> toJson() {
    return {
      'Task': {
        'DocumentName': task.name,
        'TaskName': task.taskName,
        'CommitSha': task.commitSha,
        'CreateTimestamp': task.createTimestamp,
        'StartTimestamp': task.startTimestamp,
        'EndTimestamp': task.endTimestamp,
        'Status': task.status,
        'Bringup': task.bringup,
        'TestFlaky': task.testFlaky,
      },
      'BuildList': buildList.join(','),
    };
  }
}
