// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import '../../model/firestore/commit.dart';
import '../../model/firestore/task.dart';

/// A pairing of a [Commit] and [Task]s associated with that commit.
@immutable
final class CommitAndTasks {
  /// Creates a [CommitAndTasks] with the provided commit and tasks.
  CommitAndTasks(this.commit, Iterable<Task> tasks)
    : tasks = List.unmodifiable(tasks);

  /// Commit from Firestore.
  final Commit commit;

  /// Tasks where [Task.commitSha] is the same as [Commit.sha].
  ///
  /// This list is unmodifiable.`
  final List<Task> tasks;

  /// Returns a copy of `this` with only the most recent task per builder.
  ///
  /// For example, if a task `Linux foo` was run 3 times, only the most recent
  /// task (`Linux foo`, `attempt = 3`) is retained in the accompanying [tasks]
  /// list, and the rest of the tasks are removed.
  @useResult
  CommitAndTasks withMostRecentTaskOnly() {
    final mostRecent = <String, Task>{};
    for (final task in tasks) {
      mostRecent.update(task.taskName, (current) {
        return current.currentAttempt > task.createTimestamp ? current : task;
      }, ifAbsent: () => task);
    }
    return CommitAndTasks(commit, mostRecent.values);
  }
}
