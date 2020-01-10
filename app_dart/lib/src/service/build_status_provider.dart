// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';

import 'datastore.dart';

/// Class that calculates the current build status.
class BuildStatusProvider {
  const BuildStatusProvider({
    DatastoreServiceProvider datastoreProvider,
  }) : datastoreProvider =
            datastoreProvider ?? DatastoreService.defaultProvider;

  final DatastoreServiceProvider datastoreProvider;

  @visibleForTesting

  /// This is how far back this will reference to calculate the build status.
  static const int numberOfCommitsToReference = 20;

  /// Calculates and returns the "overall" status of the Flutter build.
  ///
  /// This calculation operates by looking for the most recent success or
  /// failure for every (non-flaky) task in the manifest.
  Future<BuildStatus> calculateCumulativeStatus() async {
    final Map<String, bool> checkedTasks = <String, bool>{};
    bool isLatestCommitStatus = true;

    await for (CommitStatus status in retrieveCommitStatus()) {
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          if (isLatestCommitStatus) {
            // We only care about tasks defined in the latest commit. If a task
            // is removed from CI, we no longer care about its status.
            checkedTasks[task.name] = false;
          }

          final bool isRelevantToLatestStatus =
              checkedTasks.containsKey(task.name);

          /// This task may be in progress. However, the same task for a prior
          /// commit may be done that we can base off of.
          final bool checked = checkedTasks[task.name] ?? false;

          if (isRelevantToLatestStatus && task.isFlaky) {
            checkedTasks[task.name] = true;
          } else if (isRelevantToLatestStatus && !checked) {
            if (_isSuccessful(task)) {
              checkedTasks[task.name] = true;
            } else if (_isFailed(task) || _isRerunning(task)) {
              return BuildStatus.failed;
            }
          }
        }
      }
      isLatestCommitStatus = false;
    }

    if (checkedTasks.isEmpty) {
      return BuildStatus.failed;
    }

    return BuildStatus.succeeded;
  }

  /// Retrieves the comprehensive status of every task that runs per commit.
  ///
  /// The returned stream will be ordered by most recent commit first, then
  /// the next newest, and so on.
  Stream<CommitStatus> retrieveCommitStatus() async* {
    final DatastoreService datastore = datastoreProvider();
    await for (Commit commit
        in datastore.queryRecentCommits(limit: numberOfCommitsToReference)) {
      final List<Stage> stages =
          await datastore.queryTasksGroupedByStage(commit);
      yield CommitStatus(commit, stages);
    }
  }

  bool _isFailed(Task task) {
    return task.status == Task.statusFailed;
  }

  bool _isSuccessful(Task task) {
    return task.status == Task.statusSucceeded;
  }

  bool _isRerunning(Task task) {
    return task.attempts > 1 &&
        (task.status == Task.statusInProgress || task.status == Task.statusNew);
  }
}

/// Class that holds the status for all tasks corresponding to a particular
/// commit.
///
/// Tasks may still be running, and thus their status is subject to change.
/// Put another way, this class holds information that is a snapshot in time.
@immutable
class CommitStatus {
  /// Creates a new [CommitStatus].
  const CommitStatus(this.commit, this.stages);

  /// The commit against which all the tasks in [stages] are run.
  final Commit commit;

  /// The partitioned stages, each of which holds a bucket of tasks that
  /// belong in the stage.
  final List<Stage> stages;
}

@immutable
class BuildStatus {
  const BuildStatus._(this.value);

  final String value;

  static const BuildStatus succeeded =
      BuildStatus._(GithubBuildStatusUpdate.statusSuccess);
  static const BuildStatus failed =
      BuildStatus._(GithubBuildStatusUpdate.statusFailure);

  String get githubStatus => value;

  @override
  String toString() => value;
}
