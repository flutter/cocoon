// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_release_branch.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as gh;
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/firestore/commit.dart' as fs;
import '../../model/firestore/task.dart' as fs;
import '../../service/firestore/commit_and_tasks.dart';

/// Vacuum stale tasks.
///
/// Occassionally, a build never gets processed by LUCI. To prevent tasks
/// being stuck as "In Progress," this will return tasks to "New" if they have
/// no updates after 3 hours.
@immutable
final class VacuumStaleTasks extends RequestHandler<Body> {
  const VacuumStaleTasks({
    required super.config,
    required LuciBuildService luciBuildService,
    required FirestoreService firestore,
    required BranchService branchService,
    Duration timeoutLimit = const Duration(hours: 3),
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _luciBuildService = luciBuildService,
       _timeoutLimit = timeoutLimit,
       _now = now,
       _firestore = firestore,
       _branchService = branchService;

  final DateTime Function() _now;
  final Duration _timeoutLimit;
  final LuciBuildService _luciBuildService;
  final FirestoreService _firestore;
  final BranchService _branchService;

  @override
  Future<Body> get() async {
    // Default branches.
    await Future.forEach(config.supportedRepos, _vaccumRepository);

    // Release candidates.
    for (final branch in await _branchService.getReleaseBranches(
      slug: Config.flutterSlug,
    )) {
      if (!isReleaseCandidateBranch(branchName: branch.reference)) {
        continue;
      }
      await _vaccumRepository(Config.flutterSlug, branch: branch.reference);
    }

    return Body.empty;
  }

  Future<void> _vaccumRepository(
    gh.RepositorySlug slug, {
    String? branch,
  }) async {
    final toUpdate = <_UpdateTaskIntent>[];

    final recentCommits = await _firestore.queryRecentCommitsAndTasks(
      slug,
      commitLimit: config.backfillerCommitLimit,
      status: fs.Task.statusInProgress,
      branch: branch,
    );
    for (final CommitAndTasks(:commit, :tasks) in recentCommits) {
      for (final task in tasks) {
        if (await _considerTaskReset(commit, task) case final shouldReset?) {
          toUpdate.add(shouldReset);
        }
      }
    }

    if (toUpdate.isEmpty) {
      log.info('No tasks to update for $slug/${branch ?? '<default branch>'}.');
      return;
    }

    log.info(
      'Updating ${toUpdate.length} tasks for $slug:\n'
      '${toUpdate.map((e) => '(${e.commit.sha}) $e').join('\n')}',
    );

    await _updateFirestore(toUpdate);
  }

  Future<_UpdateTaskIntent?> _considerTaskReset(
    fs.Commit commit,
    fs.Task task,
  ) async {
    // Check the timeout limit.
    final creationTime = DateTime.fromMillisecondsSinceEpoch(
      task.createTimestamp,
    );
    if (_now().difference(creationTime) < _timeoutLimit) {
      // Give the task more time to complete.
      return null;
    }

    // Check if the task is waiting for a LUCI build we might have dropped.
    if (task.buildNumber case final buildNumber?) {
      final build = await _luciBuildService.getProdBuilds(
        builderName: task.taskName,
        sha: task.commitSha,
      );
      if (build.isNotEmpty) {
        return _UpdateTaskFromLuciBuild(commit, task, build.first);
      }
      log.warn(
        'Requested an update for build#$buildNumber (${task.taskName}, '
        'sha=${task.commitSha}), but no response. Resetting task instead.',
      );
    }

    return _ResetTaskStatusToNew(commit, task);
  }

  Future<void> _updateFirestore(List<_UpdateTaskIntent> toUpdate) async {
    final tasks = <fs.Task>[];
    for (final intent in toUpdate) {
      final task = fs.Task.fromDocument(intent.task);
      switch (intent) {
        case _ResetTaskStatusToNew():
          task.setStatus(fs.Task.statusNew);
        case _UpdateTaskFromLuciBuild():
          task.updateFromBuild(intent.build);
      }
      tasks.add(task);
    }
    await _firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites(tasks)),
      kDatabase,
    );
  }
}

sealed class _UpdateTaskIntent {
  _UpdateTaskIntent(this.commit, this.task);
  final fs.Commit commit;
  final fs.Task task;

  @mustBeOverridden
  @override
  String toString();
}

final class _ResetTaskStatusToNew extends _UpdateTaskIntent {
  _ResetTaskStatusToNew(super.commit, super.task);

  @override
  String toString() {
    return 'Resetting task ${task.taskName} to new.';
  }
}

final class _UpdateTaskFromLuciBuild extends _UpdateTaskIntent {
  _UpdateTaskFromLuciBuild(super.commit, super.task, this.build);
  final bbv2.Build build;

  @override
  String toString() {
    return 'Updating task ${task.taskName} from build ${build.id} (${build.status.name}).';
  }
}
