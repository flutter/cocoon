// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/github_build_status_update.dart';
import '../model/appengine/stage.dart';
import '../model/appengine/task.dart';

import 'datastore.dart';

/// Function signature for a [BuildStatusService] provider.
typedef BuildStatusServiceProvider = BuildStatusService Function(DatastoreService datastoreService);

/// Class that calculates the current build status.
class BuildStatusService {
  const BuildStatusService(this.datastoreService) : assert(datastoreService != null);

  final DatastoreService datastoreService;

  /// Creates and returns a [DatastoreService] using [db] and [maxEntityGroups].
  static BuildStatusService defaultProvider(DatastoreService datastoreService) {
    return BuildStatusService(datastoreService);
  }

  @visibleForTesting
  static const int numberOfCommitsToReferenceForTreeStatus = 20;

  BuildStatus _calculateOverallStatus(List<CommitStatus> statuses, [ List<String> failedTasks ]) {
    failedTasks?.clear();
    if (statuses.isEmpty) {
      return BuildStatus.failed;
    }

    final Map<String, bool> tasksInProgress = _findTasksRelevantToLatestStatus(statuses);
    if (tasksInProgress.isEmpty) {
      return BuildStatus.failed;
    }

    BuildStatus result = BuildStatus.succeeded;
    for (CommitStatus status in statuses) {
      for (Stage stage in status.stages) {
        for (Task task in stage.tasks) {
          /// If a task [isRelevantToLatestStatus] but has not run yet, we look
          /// for a previous run of the task from the previous commit.
          final bool isRelevantToLatestStatus = tasksInProgress.containsKey(task.name);

          /// Tasks that are not relevant to the latest status will have a
          /// null value in the map.
          final bool taskInProgress = tasksInProgress[task.name] ?? true;

          if (isRelevantToLatestStatus && taskInProgress) {
            if (task.isFlaky || _isSuccessful(task)) {
              /// This task no longer needs to be checked to see if it causing
              /// the build status to fail.
              tasksInProgress[task.name] = false;
            } else if (_isFailed(task) || _isRerunning(task)) {
              if (failedTasks != null) {
                // Don't fail fast if we are collecting failed tasks.
                failedTasks.add(task.name);
                result = BuildStatus.failed;
              } else {
                return BuildStatus.failed;
              }
            }
          }
        }
      }
    }
    return result;
  }

  /// Calculates and returns the "overall" status of the Flutter build.
  ///
  /// This calculation operates by looking for the most recent success or
  /// failure for every (non-flaky) task in the manifest.
  ///
  /// Take the example build dashboard below:
  /// ✔ = passed, ✖ = failed, ☐ = new, ░ = in progress, s = skipped
  /// +---+---+---+---+
  /// | A | B | C | D |
  /// +---+---+---+---+
  /// | ✔ | ☐ | ░ | s |
  /// +---+---+---+---+
  /// | ✔ | ░ | ✔ | ✖ |
  /// +---+---+---+---+
  /// | ✔ | ✖ | ✔ | ✔ |
  /// +---+---+---+---+
  /// This build will fail because of Task B only. Task D is not included in
  /// the latest commit status, so it does not impact the build status.
  /// Task B fails because its last known status was to be failing, even though
  /// there is currently a newer version that is in progress.
  Future<BuildStatus> calculateCumulativeStatus({String branch}) async {
    final List<CommitStatus> statuses = await retrieveCommitStatus(
      limit: numberOfCommitsToReferenceForTreeStatus,
      branch: branch,
    ).toList();
    return _calculateOverallStatus(statuses);
  }

  /// Calculates the list of tasks that are currently failing and causing the
  /// build to be broken.
  ///
  /// This uses the same algorithm as calculateCumulativeStatus, but
  Future<List<String>> getFailingTasks({String branch}) async {
    final List<CommitStatus> statuses = await retrieveCommitStatus(
      limit: numberOfCommitsToReferenceForTreeStatus,
      branch: branch,
    ).toList();
    final List<String> failedTasks = <String>[];
    if (_calculateOverallStatus(statuses, failedTasks) == BuildStatus.failed) {
      return failedTasks;
    }
    return <String>[];
  }

  /// Creates a map of the tasks that need to be checked for the build status.
  ///
  /// This is based on the most recent [CommitStatus] and all of its tasks.
  Map<String, bool> _findTasksRelevantToLatestStatus(List<CommitStatus> statuses) {
    final Map<String, bool> tasks = <String, bool>{};

    for (Stage stage in statuses.first.stages) {
      for (Task task in stage.tasks) {
        tasks[task.name] = true;
      }
    }

    return tasks;
  }

  /// Retrieves the comprehensive status of every task that runs per commit.
  ///
  /// The returned stream will be ordered by most recent commit first, then
  /// the next newest, and so on.
  Stream<CommitStatus> retrieveCommitStatus({int limit, int timestamp, String branch}) async* {
    await for (Commit commit
        in datastoreService.queryRecentCommits(limit: limit, timestamp: timestamp, branch: branch)) {
      final List<Stage> stages = await datastoreService.queryTasksGroupedByStage(commit);
      yield CommitStatus(commit, stages);
    }
  }

  bool _isFailed(Task task) {
    return task.status == Task.statusFailed || task.status == Task.statusInfraFailure;
  }

  bool _isSuccessful(Task task) {
    return task.status == Task.statusSucceeded;
  }

  bool _isRerunning(Task task) {
    return task.attempts > 1 && (task.status == Task.statusInProgress || task.status == Task.statusNew);
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

  static const BuildStatus succeeded = BuildStatus._(GithubBuildStatusUpdate.statusSuccess);
  static const BuildStatus failed = BuildStatus._(GithubBuildStatusUpdate.statusFailure);

  String get githubStatus => value;

  @override
  String toString() => value;
}
