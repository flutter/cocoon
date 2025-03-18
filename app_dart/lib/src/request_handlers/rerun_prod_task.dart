// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/firestore/task.dart' as firestore;
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';
import '../service/luci_build_service.dart';
import '../service/luci_build_service/build_tags.dart';
import '../service/luci_build_service/user_data.dart';
import '../service/scheduler.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// Reruns a postsubmit LUCI build.
///
/// Expects either [taskKeyParam] or a set of params that give enough detail to lookup a task in datastore.
@immutable
class RerunProdTask extends ApiRequestHandler<Body> {
  const RerunProdTask({
    required super.config,
    required super.authenticationProvider,
    required this.luciBuildService,
    required this.scheduler,
    required this.ciYamlFetcher,
    @visibleForTesting DatastoreServiceProvider? datastoreProvider,
  }) : datastoreProvider =
           datastoreProvider ?? DatastoreService.defaultProvider;

  final DatastoreServiceProvider datastoreProvider;
  final LuciBuildService luciBuildService;
  final Scheduler scheduler;
  final CiYamlFetcher ciYamlFetcher;

  static const _paramBranch = 'branch';
  static const _paramRepo = 'repo';
  static const _paramCommitSha = 'commit';
  static const _paramTaskName = 'task';

  /// Name of the task to be retried.
  ///
  /// If "all" is given, all failed tasks will be retried. This enables
  /// oncalls to quickly recover a commit without the tedium of the UI.
  static const String taskParam = 'Task';

  @override
  Future<Body> post() async {
    final datastore = datastoreProvider(config.db);
    final firestoreService = await config.createFirestoreService();

    checkRequiredParameters([
      _paramBranch,
      _paramRepo,
      _paramCommitSha,
      _paramTaskName,
    ]);

    final {
      _paramBranch: String branch,
      _paramRepo: String repo,
      _paramCommitSha: String commitSha,
      _paramTaskName: String taskName,
    } = requestData!;

    final token = await tokenInfo(request!);
    final slug = RepositorySlug('flutter', repo);

    if (taskName == 'all') {
      log2.info(
        'Attempting to reset all failed prod tasks for $commitSha in $repo...',
      );
      final commitKey = Commit.createKey(
        db: datastore.db,
        slug: slug,
        gitBranch: branch,
        sha: commitSha,
      );
      final tasks = datastore.db.query<Task>(ancestorKey: commitKey).run();
      final futures = <Future<void>>[];
      await for (final task in tasks) {
        if (!Task.taskFailStatusSet.contains(task.status)) {
          continue;
        }
        log2.info('Resetting failed task ${task.name}');
        futures.add(
          _rerun(
            datastore: datastore,
            firestoreService: firestoreService,
            branch: branch,
            commitSha: commitSha,
            taskName: task.name!,
            slug: slug,
            email: token.email!,
          ),
        );
      }
      await Future.wait(futures);
    } else {
      log2.info(
        'Attempting to reset prod task "$taskName" for $commitSha in $repo...',
      );
      await _rerun(
        datastore: datastore,
        firestoreService: firestoreService,
        branch: branch,
        commitSha: commitSha,
        taskName: taskName,
        slug: slug,
        email: token.email!,
        ignoreChecks: true,
      );
    }

    log2.info('$taskName reset initiated successfully.');

    return Body.empty;
  }

  Future<void> _rerun({
    required DatastoreService datastore,
    required FirestoreService firestoreService,
    required String branch,
    required String commitSha,
    required String taskName,
    required RepositorySlug slug,
    required String email,
    bool ignoreChecks = false,
  }) async {
    // Prepares Datastore task.
    final task = await _getTaskFromNamedParams(
      datastore: datastore,
      branch: branch,
      name: taskName,
      sha: commitSha,
      slug: slug,
    );
    final commit = await _getCommitFromTask(datastore, task);
    final ciYaml = await ciYamlFetcher.getCiYamlByDatastoreCommit(commit);
    final targets = [
      ...ciYaml.postsubmitTargets(),
      if (ciYaml.isFusion)
        ...ciYaml.postsubmitTargets(type: CiType.fusionEngine),
    ];
    final target = targets.singleWhere(
      (Target target) => target.value.name == task.name,
    );

    // Prepares Firestore task.
    final documentName = FirestoreTaskDocumentName(
      commitSha: commitSha,
      taskName: taskName,
      currentAttempt: task.attempts!,
    );
    final taskDocument = await firestore.Task.fromFirestore(
      firestoreService: firestoreService,
      documentName: p.join(
        kDatabase,
        'documents',
        firestore.kTaskCollectionId,
        '$documentName',
      ),
    );

    final isRerunning = await luciBuildService.checkRerunBuilder(
      commit: commit,
      task: task,
      target: target,
      datastore: datastore,
      tags: [TriggerdByBuildTag(email: email)],
      ignoreChecks: ignoreChecks,
      firestoreService: firestoreService,
      taskDocument: taskDocument,
    );

    // For human retries from the dashboard, notify if a task failed to rerun.
    if (ignoreChecks && isRerunning == false) {
      throw InternalServerError('Failed to rerun $taskName');
    }
  }

  /// Retrieve [Task] from [DatastoreService] from a commit + task name info.
  static Future<Task> _getTaskFromNamedParams({
    required DatastoreService datastore,
    required String branch,
    required String name,
    required String sha,
    required RepositorySlug slug,
  }) async {
    final commitKey = Commit.createKey(
      db: datastore.db,
      slug: slug,
      gitBranch: branch,
      sha: sha,
    );
    return Task.fromDatastore(
      datastore: datastore,
      commitKey: commitKey,
      name: name,
    );
  }

  /// Returns the [Commit] associated with [Task].
  static Future<Commit> _getCommitFromTask(
    DatastoreService datastore,
    Task task,
  ) async {
    return (await datastore.lookupByKey<Commit>(<Key<dynamic>>[
      task.parentKey!,
    ])).single!;
  }
}
