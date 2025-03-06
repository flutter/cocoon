// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'commit.dart';
import 'task.dart';

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
  List<FullTask> toFullTasks(List<Task> tasks) {
    final fullTasksMap = <String, FullTask>{};
    for (var task in tasks) {
      if (!fullTasksMap.containsKey(task.taskName)) {
        if (task.buildNumber == null) {
          fullTasksMap[task.taskName!] = FullTask(task, <int>[]);
        } else {
          fullTasksMap[task.taskName!] = FullTask(task, <int>[
            task.buildNumber!,
          ]);
        }
      } else if (fullTasksMap.containsKey(task.taskName)) {
        fullTasksMap[task.taskName]!.buildList.add(task.buildNumber!);
      }
    }
    return fullTasksMap.entries.map((entry) => entry.value).toList();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Commit': commit.facade,
      'Tasks': toFullTasks(tasks).map((e) => e.toJson()).toList(),
    };
  }
}

/// Latest task entry and its rerun build list.
class FullTask {
  const FullTask(this.task, this.buildList);

  final Task task;
  final List<int> buildList;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Task': task.facade,
      'BuildList': buildList.join(','),
    };
  }
}
