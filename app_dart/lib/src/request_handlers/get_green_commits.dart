// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/firestore/task.dart' as fs;
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/build_status_provider/commit_tasks_status.dart';
import '../service/config.dart';

/// Returns [List<String>] of the commit shas that had all passing tests.
///
/// A [CommitStatus] that have all passing tests is used to help the release tooling find commits Flutter infrastructure has validated.
/// In order to qualify as a [CommitStatus] that have all passing tests, the rules are:
/// 1. The [Commit] inside [CommitStatus] had all its tests run (at least those that are not in bringup)
/// 2. all the blocking [Task] in [CommitStatus] should pass
/// A [List<String>] of commit shas of the qualified [CommitStatus]s are returned, in the order of [Commit] timestamp, i.e.,
/// A [Commit] with an earlier timestamp will apprear earlier in the result [List<String>], as compared to another [Commit]
/// with a later timestamp.
///
/// Parameters:
///   branch: defaults to the defaults branch for the repository.
///   repo: default: 'flutter'. Name of the repository.
///
/// GET: /api/public/get-green-commits?repo=$repo

@immutable
final class GetGreenCommits extends RequestHandler<Body> {
  const GetGreenCommits({
    required super.config,
    required BuildStatusService buildStatusService,
  }) : _buildStatusService = buildStatusService;

  final BuildStatusService _buildStatusService;

  @visibleForTesting
  static const kBranchParam = 'branch';

  @visibleForTesting
  static const kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final repoName =
        request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request!.uri.queryParameters[kBranchParam] ??
        Config.defaultBranch(slug);
    final commitNumber = config.commitNumber;

    final allCommits = await _buildStatusService.retrieveCommitStatusFirestore(
      limit: commitNumber,
      branch: branch,
      slug: slug,
    );
    return Body.forJson([
      for(final commit in allCommits.where(_isGreenCommit))
        commit.commit.sha
    ]);
  }

  bool _isGreenCommit(CommitTasksStatus status) {
    if (status.tasks.isEmpty) {
      // If there are no tasks, it can't possibly be (our definition of) green.
      return false;
    }

    for (final task in status.tasks) {
      if (task.bringup) {
        continue;
      }
      if (!const {
        fs.Task.statusSkipped,
        fs.Task.statusSucceeded,
      }.contains(task.status)) {
        return false;
      }
    }

    return true;
  }
}
