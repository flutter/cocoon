// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/firestore/github_build_status.dart';
import '../model/firestore/task.dart';
import 'build_status_provider/commit_tasks_status.dart';

/// Class that calculates the current build status.
interface class BuildStatusService {
  const BuildStatusService({required FirestoreService firestore})
    : _firestore = firestore;
  final FirestoreService _firestore;

  @visibleForTesting
  static const int numberOfCommitsToReferenceForTreeStatus = 20;

  /// Calculates and returns the "overall" status of the Flutter build.
  ///
  /// This calculation operates by looking for the most recent success or
  /// failure for every (non-flaky) task in the manifest.
  ///
  /// Take the example build dashboard below:
  /// ```txt
  ///    A   B   C   D
  /// 🧑‍💼 🟩  ⬜  🟨
  /// 🧑‍💼 🟩  🟨  🟩  🟥
  /// 🧑‍💼 🟩  🟥  🟩  🟩
  /// ```
  ///
  /// This build will fail because of Task `B` only:
  ///
  /// - Task `D` is not included in tip of tree (removed or marked `bringup`);
  /// - Task `B` fails becuse its last known _completed_ status was failing
  Future<BuildStatus> calculateCumulativeStatus(
    RepositorySlug slug, {
    String? branch,
  }) async {
    final commits = await retrieveCommitStatusFirestore(
      limit: numberOfCommitsToReferenceForTreeStatus,
      slug: slug,
      branch: branch,
    );
    if (commits.isEmpty) {
      log.info('Tree status of failure for $slug: no commits found');
      return BuildStatus.failure();
    }

    // First, create a list of every ToT task we want to see non-failing.
    final toBePassing = {
      for (final t in commits.first.tasks)
        if (!t.bringup) t.taskName,
    };
    final failingTasks = <String>{};

    // Then, iterate through commit by commit.
    // If we see a task fail, mark as failing.
    // If we see a task pass, mark as passing and no longer look for it.
    for (final commit in commits) {
      for (final collatedTask in commit.collateTasksByTaskName()) {
        if (!toBePassing.contains(collatedTask.task.taskName)) {
          continue;
        }
        if (collatedTask.lastCompletedAttemptWasFailure) {
          failingTasks.add(collatedTask.task.taskName);
        } else if (collatedTask.task.status == Task.statusSucceeded) {
          toBePassing.remove(collatedTask.task.taskName);
        }
      }
    }

    if (failingTasks.isEmpty) {
      return BuildStatus.success();
    } else {
      return BuildStatus.failure([...failingTasks]);
    }
  }

  /// Retrieves the comprehensive status of every task that runs per commit.
  ///
  /// The returned stream will be ordered by most recent commit first, then
  /// the next newest, and so on.
  Future<List<CommitTasksStatus>> retrieveCommitStatusFirestore({
    required int limit,
    int? timestamp,
    String? branch,
    required RepositorySlug slug,
  }) async {
    final commits = await _firestore.queryRecentCommits(
      limit: limit,
      timestamp: timestamp,
      branch: branch,
      slug: slug,
    );
    return [
      for (final commit in commits)
        // It's not obvious, but this is ordered by task creation time, descending.
        CommitTasksStatus(
          commit,
          await _firestore.queryAllTasksForCommit(commitSha: commit.sha),
        ),
    ];
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
