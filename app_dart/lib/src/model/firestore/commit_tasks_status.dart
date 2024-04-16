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
}

class SerializableCommitTasksStatus {
  const SerializableCommitTasksStatus(this.status);

  final CommitTasksStatus status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Commit': status.commit.facade,
      'Tasks': status.tasks.map((task) => task.facade).toList(),
    };
  }
}
