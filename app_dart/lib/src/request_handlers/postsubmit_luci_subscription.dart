// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';

import '../../ci_yaml.dart';
import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/commit.dart' as fs;
import '../model/firestore/task.dart' as fs;
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';
import '../service/firestore.dart';
import '../service/github_checks_service.dart';
import '../service/luci_build_service.dart';
import '../service/luci_build_service/opaque_commit.dart';
import '../service/luci_build_service/user_data.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// An endpoint for listening to build updates for postsubmit builds.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/build-bucket-postsubmit-sub?project=flutter-dashboard
///
/// This endpoint is responsible for updating Datastore with the result of builds from LUCI.
@immutable
final class PostsubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PostsubmitLuciSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
    required LuciBuildService luciBuildService,
    required GithubChecksService githubChecksService,
    required CiYamlFetcher ciYamlFetcher,
  }) : _ciYamlFetcher = ciYamlFetcher,
       _luciBuildService = luciBuildService,
       _githubChecksService = githubChecksService,
       super(subscriptionName: 'build-bucket-postsubmit-sub');

  final LuciBuildService _luciBuildService;
  final GithubChecksService _githubChecksService;
  final CiYamlFetcher _ciYamlFetcher;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    final datastore = DatastoreService.defaultProvider(config.db);
    final firestoreService = await config.createFirestoreService();

    final pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(
      jsonDecode(message.data!) as Map<String, dynamic>,
    );
    final buildsPubSub = pubSubCallBack.buildPubsub;
    final userData = PostsubmitUserData.fromBytes(pubSubCallBack.userData);

    log.debug('userData=$userData');

    if (!buildsPubSub.hasBuild()) {
      log.warn('No build was found in message.');
      return Body.empty;
    }

    final build = buildsPubSub.build;

    // Note that result is no longer present in the output.
    log.debug('Updating buildId=${build.id} for result=${build.status}');

    // Add build fields that are stored in a separate compressed buffer.
    build.mergeFromBuffer(ZLibCodec().decode(buildsPubSub.buildLargeFields));

    log.info('build ${build.toProto3Json()}');

    // TODO(matanlurey): Figure out why (sometimes) these fields are invalid.
    // See https://github.com/flutter/flutter/issues/16.
    if (int.tryParse(userData.taskKey) == null) {
      throw BadRequestException('Invalid userData: $userData');
    }

    final commitKey = Key<String>(
      Key<dynamic>.emptyKey(Partition(null)),
      Commit,
      userData.commitKey,
    );
    log.info('Looking up task document: ${userData.firestoreTaskDocumentName}');
    final taskKey = Key<int>(commitKey, Task, int.parse(userData.taskKey));
    final task = await datastore.lookupByValue<Task>(taskKey);
    final firestoreTask = await fs.Task.fromFirestore(
      firestoreService,
      userData.firestoreTaskDocumentName,
    );
    log.info('Found $firestoreTask');

    if (_shouldUpdateTask(build, firestoreTask)) {
      final oldTaskStatus = firestoreTask.status;
      firestoreTask.updateFromBuild(build);

      log.info('Updated firestore task $firestoreTask');

      task.updateFromBuildbucketBuild(build);
      await datastore.insert(<Task>[task]);
      final writes = documentsToWrites([firestoreTask], exists: true);
      await firestoreService.batchWriteDocuments(
        BatchWriteRequest(writes: writes),
        kDatabase,
      );
      log.debug(
        'Updated datastore from $oldTaskStatus to ${firestoreTask.status}',
      );
    } else {
      log.debug(
        'skip processing for build with status scheduled or task with status '
        'finished.',
      );
    }

    final fsCommit = await fs.Commit.fromFirestoreBySha(
      firestoreService,
      sha: firestoreTask.commitSha,
    );
    final ciYaml = await _ciYamlFetcher.getCiYamlByFirestoreCommit(fsCommit);
    final postsubmitTargets = [
      ...ciYaml.postsubmitTargets(),
      if (ciYaml.isFusion)
        ...ciYaml.postsubmitTargets(type: CiType.fusionEngine),
    ];

    // Do not block on the target not found.
    if (!postsubmitTargets.any(
      (element) => element.name == firestoreTask.taskName,
    )) {
      log.warn(
        'Target ${firestoreTask.taskName} has been deleted from TOT. Skip '
        'updating.',
      );
      return Body.empty;
    }
    final target = postsubmitTargets.singleWhere(
      (Target target) => target.name == firestoreTask.taskName,
    );
    if (await _shouldAutomaticallyRerun(firestoreTask)) {
      log.debug('Trying to auto-retry...');
      final retried = await _luciBuildService.checkRerunBuilder(
        commit: OpaqueCommit.fromFirestore(fsCommit),
        target: target,
        task: task,
        taskDocument: firestoreTask,
      );
      log.info('Retried: $retried');
    }

    // Only update GitHub checks if target is not bringup
    if (target.isBringup == false &&
        config.postsubmitSupportedRepos.contains(target.slug)) {
      log.info('Updating check status for ${target.name}');
      await _githubChecksService.updateCheckStatus(
        build: build,
        checkRunId: userData.checkRunId!,
        luciBuildService: _luciBuildService,
        slug: fsCommit.slug,
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
  bool _shouldUpdateTask(bbv2.Build build, fs.Task task) {
    return build.status != bbv2.Status.SCHEDULED &&
        !fs.Task.finishedStatusValues.contains(task.status);
  }

  /// Check if a builder should be rerun.
  ///
  /// A rerun happens when a build fails, the retry number hasn't reached the limit, and the build is on TOT.
  Future<bool> _shouldAutomaticallyRerun(fs.Task task) async {
    if (!fs.Task.taskFailStatusSet.contains(task.status)) {
      log.debug('${task.taskName} is not failing. No rerun needed.');
      return false;
    }
    final retries = task.currentAttempt;
    if (retries > config.maxLuciTaskRetries) {
      log.info('Max retries reached for ${task.taskName}');
      return false;
    }

    final firestoreService = await config.createFirestoreService();
    final currentCommit = await fs.Commit.fromFirestoreBySha(
      firestoreService,
      sha: task.commitSha,
    );
    final commitList = await firestoreService.queryRecentCommits(
      limit: 1,
      slug: currentCommit.slug,
      branch: currentCommit.branch,
    );
    final latestCommit = commitList.single;

    // Merge queue uses PresubmitLuciSubscription, so this is safe.
    if (latestCommit.sha != currentCommit.sha) {
      log.info('Not tip of tree: ${currentCommit.sha}');
      return false;
    }
    return true;
  }
}
