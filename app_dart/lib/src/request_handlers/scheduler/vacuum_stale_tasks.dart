// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart' as gh;
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../../cocoon_service.dart';
import '../../model/appengine/commit.dart' as ds;
import '../../model/appengine/task.dart' as ds;
import '../../model/firestore/commit.dart' as fs;
import '../../model/firestore/task.dart' as fs;
import '../../service/datastore.dart';
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
    Duration timeoutLimit = const Duration(hours: 3),
    @visibleForTesting DateTime Function() now = DateTime.now,
  }) : _luciBuildService = luciBuildService,
       _timeoutLimit = timeoutLimit,
       _now = now;

  final DateTime Function() _now;
  final Duration _timeoutLimit;
  final LuciBuildService _luciBuildService;

  @override
  Future<Body> get() async {
    await Future.wait([
      for (final slug in config.supportedRepos) _vaccumRepository(slug),
    ]);
    return Body.empty;
  }

  Future<void> _vaccumRepository(gh.RepositorySlug slug) async {
    final toUpdate = <_UpdateTaskIntent>[];
    final firestore = await config.createFirestoreService();

    final recentCommits = await firestore.queryRecentCommitsAndTasks(
      slug,
      commitLimit: config.backfillerCommitLimit,
      status: fs.Task.statusInProgress,
    );
    for (final CommitAndTasks(:commit, :tasks) in recentCommits) {
      for (final task in tasks) {
        if (await _considerTaskReset(commit, task) case final shouldReset?) {
          toUpdate.add(shouldReset);
        }
      }
    }

    if (toUpdate.isEmpty) {
      log.info('No tasks to update for $slug.');
      return;
    }

    log.info(
      'Updating ${toUpdate.length} tasks for $slug:\n'
      '${toUpdate.map((e) => '(${e.commit.sha}) $e').join('\n')}',
    );

    await Future.wait([
      _updateFirestore(toUpdate, firestore),
      _legacyUpdateDatastore(toUpdate),
    ]);
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

  Future<void> _updateFirestore(
    List<_UpdateTaskIntent> toUpdate,
    FirestoreService firestore,
  ) async {
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
    await firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites(tasks)),
      kDatabase,
    );
  }

  Future<void> _legacyUpdateDatastore(List<_UpdateTaskIntent> toUpdate) async {
    if (!await config.useLegacyDatastore) {
      return;
    }
    final datastore = DatastoreService.defaultProvider(config.db);
    final tasks = <ds.Task>[];
    for (final intent in toUpdate) {
      final commitKey = _toCommitKey(datastore.db, intent.commit);
      final task = await ds.Task.fromCommitKey(
        datastore: datastore,
        commitKey: commitKey,
        name: intent.task.taskName,
      );
      switch (intent) {
        case _ResetTaskStatusToNew():
          task.status = ds.Task.statusNew;
        case _UpdateTaskFromLuciBuild():
          task.updateFromBuildbucketBuild(intent.build);
      }
      tasks.add(task);
    }
    await datastore.insert(tasks);
  }

  static Key<String> _toCommitKey(DatastoreDB db, fs.Commit commit) {
    return db.emptyKey.append<String>(
      ds.Commit,
      id: '${commit.slug.fullName}/${commit.branch}/${commit.sha}',
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
