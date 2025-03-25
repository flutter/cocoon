// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/commit_tasks_status.dart';
import '../model/firestore/github_build_status.dart';
import '../model/firestore/task.dart';

/// Branches that are used to calculate the tree status.
const Set<String> defaultBranches = <String>{
  'refs/heads/main',
  'refs/heads/master',
};

/// Class that calculates the current build status.
interface class BuildStatusService {
  const BuildStatusService(this._config);
  final Config _config;

  @visibleForTesting
  static const int numberOfCommitsToReferenceForTreeStatus = 20;

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
  ///
  /// Tree status is only for [defaultBranches].
  Future<BuildStatus?> calculateCumulativeStatus(RepositorySlug slug) async {
    final statuses =
        await retrieveCommitStatusFirestore(
          limit: numberOfCommitsToReferenceForTreeStatus,
          slug: slug,
        ).toList();
    if (statuses.isEmpty) {
      return BuildStatus.failure();
    }

    final tasksInProgress = _findTasksRelevantToLatestStatus(statuses);
    if (tasksInProgress.isEmpty) {
      return BuildStatus.failure();
    }

    final failedTasks = <String>[];
    for (var status in statuses) {
      for (var task in status.tasks) {
        /// If a task [isRelevantToLatestStatus] but has not run yet, we look
        /// for a previous run of the task from the previous commit.
        final isRelevantToLatestStatus = tasksInProgress.containsKey(
          task.taskName,
        );

        /// Tasks that are not relevant to the latest status will have a
        /// null value in the map.
        final taskInProgress = tasksInProgress[task.taskName] ?? true;

        if (isRelevantToLatestStatus && taskInProgress) {
          if (task.bringup! || _isSuccessful(task)) {
            /// This task no longer needs to be checked to see if it causing
            /// the build status to fail.
            tasksInProgress[task.taskName!] = false;
          } else if (_isFailed(task) || _isRerunning(task)) {
            failedTasks.add(task.taskName!);

            /// This task no longer needs to be checked to see if its causing
            /// the build status to fail since its been
            /// added to the failedTasks list.
            tasksInProgress[task.taskName!] = false;
          }
        }
      }
    }
    return failedTasks.isNotEmpty
        ? BuildStatus.failure(failedTasks)
        : BuildStatus.success();
  }

  /// Creates a map of the tasks that need to be checked for the build status.
  ///
  /// This is based on the most recent [CommitStatus] and all of its tasks.
  Map<String, bool> _findTasksRelevantToLatestStatus(
    List<CommitTasksStatus> statuses,
  ) {
    final tasks = <String, bool>{};

    for (var task in statuses.first.tasks) {
      tasks[task.taskName!] = true;
    }
    return tasks;
  }

  /// Retrieves the comprehensive status of every task that runs per commit.
  ///
  /// The returned stream will be ordered by most recent commit first, then
  /// the next newest, and so on.
  Stream<CommitTasksStatus> retrieveCommitStatusFirestore({
    required int limit,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) async* {
    final firestore = await _config.createFirestoreService();
    final commits = await firestore.queryRecentCommits(
      limit: limit,
      timestamp: timestamp,
      branch: branch,
      slug: slug,
    );
    for (var commit in commits) {
      final tasks = await firestore.queryCommitTasks(commit.sha);
      yield CommitTasksStatus(commit, tasks);
    }
  }

  bool _isFailed(Task task) {
    return task.status == Task.statusFailed ||
        task.status == Task.statusInfraFailure ||
        task.status == Task.statusCancelled;
  }

  bool _isSuccessful(Task task) {
    return task.status == Task.statusSucceeded;
  }

  bool _isRerunning(Task task) {
    return task.attempts! > 1 &&
        (task.status == Task.statusInProgress || task.status == Task.statusNew);
  }
}

@immutable
final class BuildStatus {
  const BuildStatus._(this.value, [this.failedTasks = const <String>[]])
    : assert(
        value == GithubBuildStatus.statusSuccess ||
            value == GithubBuildStatus.statusFailure ||
            value == GithubBuildStatus.statusNeutral,
      );
  factory BuildStatus.success() =>
      const BuildStatus._(GithubBuildStatus.statusSuccess);
  factory BuildStatus.failure([List<String> failedTasks = const <String>[]]) =>
      BuildStatus._(GithubBuildStatus.statusFailure, failedTasks);
  factory BuildStatus.neutral() =>
      const BuildStatus._(GithubBuildStatus.statusNeutral);

  final String value;
  final List<String> failedTasks;

  bool get succeeded {
    return value == GithubBuildStatus.statusSuccess;
  }

  String get githubStatus => value;

  @override
  int get hashCode {
    var hash = 17;
    hash = hash * 31 + value.hashCode;
    hash = hash * 31 + failedTasks.hashCode;
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is BuildStatus) {
      if (value != other.value) {
        return false;
      }
      if (other.failedTasks.length != failedTasks.length) {
        return false;
      }
      for (var i = 0; i < failedTasks.length; ++i) {
        if (failedTasks[i] != other.failedTasks[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() => '$value $failedTasks';
}
