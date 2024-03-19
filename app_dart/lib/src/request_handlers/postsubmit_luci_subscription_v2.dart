// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:cocoon_service/ci_yaml.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
// import '../model/luci/push_message.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler_v2.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';
import '../service/logging.dart';
import '../service/github_checks_service_v2.dart';
import '../service/scheduler_v2.dart';

/// An endpoint for listening to build updates for postsubmit builds.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/luci-postsubmit?project=flutter-dashboard&tab=overview
///
/// This endpoint is responsible for updating Datastore with the result of builds from LUCI.
@immutable
class PostsubmitLuciSubscription extends SubscriptionHandlerV2 {
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
  final SchedulerV2 scheduler;
  final GithubChecksServiceV2 githubChecksService;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(jsonDecode(message.data!) as Map<String, dynamic>);
    final bbv2.BuildsV2PubSub buildsV2PubSub = pubSubCallBack.buildPubsub;

    if (!pubSubCallBack.hasUserData()) {
      log.info('User data is empty');
      return Body.empty;
    }

    final Map<String, dynamic> userDataMap = UserData.decodeUserDataBytes(pubSubCallBack.userData);
    log.fine('userData=$userDataMap');

    if (!buildsV2PubSub.hasBuild()) {
      log.fine('User data is empty');
      return Body.empty;
    }
    final bbv2.Build build = buildsV2PubSub.build;
    // Note that result is no longer present in the output.
    log.fine('Updating buildId=${build.id} for result=${build.status}');

    final String? rawTaskKey = userDataMap['task_key'] as String?;
    final String? rawCommitKey = userDataMap['commit_key'] as String?;

    if (rawCommitKey == null) {
      throw const BadRequestException('userData does not contain commit_key');
    }

    final Key<String> commitKey = Key<String>(Key<dynamic>.emptyKey(Partition(null)), Commit, rawCommitKey);

    final DatastoreService datastore = datastoreProvider(config.db);
    final FirestoreService firestoreService = await config.createFirestoreService();

    final bbv2.Struct propertiesStruct = build.input.properties;

    final String taskName = propertiesStruct.fields['builder_name']!.stringValue;
    Task? task;

    // final String? taskName = build.buildParameters?['builder_name'] as String?;
    if (rawTaskKey == null || rawTaskKey.isEmpty || rawTaskKey == 'null') {
      log.fine('Pulling builder name from parameters_json...');
      log.fine(propertiesStruct.toProto3Json());
      if (taskName.isEmpty) {
        throw const BadRequestException('task_key is null and parameters_json does not contain the builder name');
      }
      final List<Task> tasks = await datastore.queryRecentTasksByName(name: taskName).toList();
      task = tasks.singleWhere((Task task) => task.parentKey?.id == commitKey.id);
    } else {
      log.fine('Looking up key...');
      final int taskId = int.parse(rawTaskKey);
      final Key<int> taskKey = Key<int>(commitKey, Task, taskId);
      task = await datastore.lookupByValue<Task>(taskKey);
    }
    log.fine('Found $task');

    firestore.Task taskDocument = firestore.Task();

    if (_shouldUpdateTask(build, task)) {
      final String oldTaskStatus = task.status;
      task.updateFromBuildbucketV2Build(build);
      await datastore.insert(<Task>[task]);
      try {
        taskDocument = await updateFirestore(build, rawCommitKey, task.name!, firestoreService);
      } catch (error) {
        log.warning('Failed to update task in Firestore: $error');
      }
      log.fine('Updated datastore from $oldTaskStatus to ${task.status}');
    } else {
      log.fine('skip processing for build with status scheduled or task with status finished.');
    }

    final Commit commit = await datastore.lookupByValue<Commit>(commitKey);
    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final List<Target> postsubmitTargets = ciYaml.postsubmitTargets;
    if (!postsubmitTargets.any((element) => element.value.name == task!.name)) {
      log.warning('Target ${task.name} has been deleted from TOT. Skip updating.');
      return Body.empty;
    }
    final Target target = postsubmitTargets.singleWhere((Target target) => target.value.name == task!.name);
    if (task.status == Task.statusFailed ||
        task.status == Task.statusInfraFailure ||
        task.status == Task.statusCancelled) {
      log.fine('Trying to auto-retry...');
      final bool retried = await scheduler.luciBuildService.checkRerunBuilder(
        commit: commit,
        target: target,
        task: task,
        datastore: datastore,
        taskDocument: taskDocument,
        firestoreService: firestoreService,
      );
      log.info('Retried: $retried');
    }

    // Only update GitHub checks if target is not bringup
    if (target.value.bringup == false && config.postsubmitSupportedRepos.contains(target.slug)) {
      log.info('Updating check status for ${target.getTestName}');
      await githubChecksService.updateCheckStatus(
        build: build,
        userDataMap: userDataMap,
        luciBuildService: scheduler.luciBuildService,
        slug: commit.slug,
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
  bool _shouldUpdateTask(bbv2.Build build, Task task) {
    return build.status != bbv2.Status.SCHEDULED && !Task.finishedStatusValues.contains(task.status);
  }

  /// Queries the task document and updates based on the latest build data.
  Future<firestore.Task> updateFirestore(
    bbv2.Build build,
    String commitKeyId,
    String taskName,
    FirestoreService firestoreService,
  ) async {
    final List<bbv2.StringPair> buildTags = build.tags;
    final int currentAttempt = githubChecksService.currentAttempt(buildTags);
    final String sha = commitKeyId.split('/').last;
    final String documentName = '$kDatabase/documents/tasks/${sha}_${taskName}_$currentAttempt';
    log.info('getting firestore document: $documentName');
    final firestore.Task firestoreTask =
        await firestore.Task.fromFirestore(firestoreService: firestoreService, documentName: documentName);
    log.info('updating firestoreTask based on build');
    firestoreTask.updateFromBuildV2(build);
    log.info('finished updating firestoreTask based on builds');
    final List<Write> writes = documentsToWrites([firestoreTask], exists: true);
    await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
    return firestoreTask;
  }
}
