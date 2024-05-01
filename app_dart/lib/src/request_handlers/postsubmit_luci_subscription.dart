// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/ci_yaml.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';
import '../service/logging.dart';
import '../service/github_checks_service.dart';
import '../service/scheduler.dart';

/// An endpoint for listening to build updates for postsubmit builds.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/luci-postsubmit?project=flutter-dashboard&tab=overview
///
/// This endpoint is responsible for updating Datastore with the result of builds from LUCI.
@immutable
class PostsubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PostsubmitLuciSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    required this.scheduler,
    required this.githubChecksService,
  }) : super(subscriptionName: 'luci-postsubmit');

  final DatastoreServiceProvider datastoreProvider;
  final Scheduler scheduler;
  final GithubChecksService githubChecksService;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final FirestoreService firestoreService = await config.createFirestoreService();

    final BuildPushMessage buildPushMessage = BuildPushMessage.fromPushMessage(message);
    log.fine('userData=${buildPushMessage.userData}');
    log.fine('Updating buildId=${buildPushMessage.build?.id} for result=${buildPushMessage.build?.result}');
    if (buildPushMessage.userData.isEmpty) {
      log.fine('User data is empty');
      return Body.empty;
    }

    final String? rawTaskKey = buildPushMessage.userData['task_key'] as String?;
    final String? rawCommitKey = buildPushMessage.userData['commit_key'] as String?;
    final String? taskDocumentName = buildPushMessage.userData['firestore_task_document_name'] as String?;
    if (taskDocumentName == null) {
      throw const BadRequestException('userData does not contain firestore_task_document_name');
    }
    final Build? build = buildPushMessage.build;
    if (build == null) {
      log.warning('Build is null');
      return Body.empty;
    }
    final Key<String> commitKey = Key<String>(Key<dynamic>.emptyKey(Partition(null)), Commit, rawCommitKey);
    Task? task;
    firestore.Task? firestoreTask;
    log.fine('Looking up task document...');
    final int taskId = int.parse(rawTaskKey!);
    final Key<int> taskKey = Key<int>(commitKey, Task, taskId);
    task = await datastore.lookupByValue<Task>(taskKey);
    firestoreTask = await firestore.Task.fromFirestore(
      firestoreService: firestoreService,
      documentName: '$kDatabase/documents/${firestore.kTaskCollectionId}/$taskDocumentName',
    );
    log.fine('Found $firestoreTask');

    if (_shouldUpdateTask(build, firestoreTask)) {
      final String oldTaskStatus = firestoreTask.status;
      firestoreTask.updateFromBuild(build);
      task.updateFromBuild(build);
      await datastore.insert(<Task>[task]);
      final List<Write> writes = documentsToWrites([firestoreTask], exists: true);
      await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
      log.fine('Updated datastore from $oldTaskStatus to ${firestoreTask.status}');
    } else {
      log.fine('skip processing for build with status scheduled or task with status finished.');
    }

    final Commit commit = await datastore.lookupByValue<Commit>(commitKey);
    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final List<Target> postsubmitTargets = ciYaml.postsubmitTargets;
    if (!postsubmitTargets.any((element) => element.value.name == firestoreTask!.taskName)) {
      log.warning('Target ${firestoreTask.taskName} has been deleted from TOT. Skip updating.');
      return Body.empty;
    }
    final Target target =
        postsubmitTargets.singleWhere((Target target) => target.value.name == firestoreTask!.taskName);
    if (firestoreTask.status == firestore.Task.statusFailed ||
        firestoreTask.status == firestore.Task.statusInfraFailure ||
        firestoreTask.status == firestore.Task.statusCancelled) {
      log.fine('Trying to auto-retry...');
      final bool retried = await scheduler.luciBuildServiceV2.checkRerunBuilder(
        commit: commit,
        target: target,
        task: task,
        datastore: datastore,
        taskDocument: firestoreTask,
        firestoreService: firestoreService,
      );
      log.info('Retried: $retried');
    }

    // Only update GitHub checks if target is not bringup
    if (target.value.bringup == false && config.postsubmitSupportedRepos.contains(target.slug)) {
      log.info('Updating check status for ${target.getTestName}');
      await githubChecksService.updateCheckStatus(
        buildPushMessage,
        scheduler.luciBuildService,
        commit.slug,
      );
    }

    return Body.empty;
  }

  // No need to update task in datastore if
  // 1) the build is `scheduled`. Task is marked as `In Progress`
  //    whenever scheduled, either from scheduler/backfiller/rerun. We need to update
  //    task in datastore only for
  //    a) `started`: update info like builder number.
  //    b) `completed`: update info like status.
  // 2) the task is already completed.
  //    The task may have been marked as completed from test framework via update-task-status API.
  bool _shouldUpdateTask(Build build, firestore.Task task) {
    return build.status != Status.scheduled && !firestore.Task.finishedStatusValues.contains(task.status);
  }
}
