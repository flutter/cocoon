// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/firestore/v1.dart' hide Status;
import 'package:meta/meta.dart';

import '../../ci_yaml.dart';
import '../model/firestore/commit.dart' as fs;
import '../model/firestore/task.dart' as fs;
import '../request_handling/body.dart';
import '../request_handling/subscription_handler.dart';
import '../service/firestore.dart';
import '../service/github_checks_service.dart';
import '../service/luci_build_service.dart';
import '../service/luci_build_service/commit_task_ref.dart';
import '../service/luci_build_service/user_data.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// An endpoint for listening to build updates for postsubmit builds.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/build-bucket-postsubmit-sub?project=flutter-dashboard
///
/// This endpoint is responsible for updating Firestore with the result of builds from LUCI.
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
    required FirestoreService firestore,
  }) : _ciYamlFetcher = ciYamlFetcher,
       _luciBuildService = luciBuildService,
       _githubChecksService = githubChecksService,
       _firestore = firestore,
       super(subscriptionName: 'build-bucket-postsubmit-sub');

  final LuciBuildService _luciBuildService;
  final GithubChecksService _githubChecksService;
  final CiYamlFetcher _ciYamlFetcher;
  final FirestoreService _firestore;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

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

    final fsTask = await fs.Task.fromFirestore(_firestore, userData.taskId);
    log.info('Found $fsTask');

    if (_shouldUpdateTask(build, fsTask)) {
      final oldTaskStatus = fsTask.status;
      await _updateFirestore(fsTask, build);
      log.debug('Updated Firestore from $oldTaskStatus to ${fsTask.status}');
    } else {
      log.debug(
        'skip processing for build with status scheduled or task with status '
        'finished.',
      );
    }

    final fsCommit = await fs.Commit.fromFirestoreBySha(
      _firestore,
      sha: fsTask.commitSha,
    );

    final ciYaml = await _ciYamlFetcher.getCiYamlByFirestoreCommit(fsCommit);
    final postsubmitTargets = [
      ...ciYaml.postsubmitTargets(),
      if (ciYaml.isFusion)
        ...ciYaml.postsubmitTargets(type: CiType.fusionEngine),
    ];

    // Do not block on the target not found.
    if (!postsubmitTargets.any((element) => element.name == fsTask.taskName)) {
      log.warn(
        'Target ${fsTask.taskName} has been deleted from TOT. Skip '
        'updating.',
      );
      return Body.empty;
    }
    final target = postsubmitTargets.singleWhere(
      (Target target) => target.name == fsTask.taskName,
    );
    if (await _shouldAutomaticallyRerun(fsTask)) {
      log.debug('Trying to auto-retry...');
      final retried = await _luciBuildService.checkRerunBuilder(
        commit: CommitRef.fromFirestore(fsCommit),
        target: target,
        task: fsTask,
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

  Future<void> _updateFirestore(fs.Task fsTask, bbv2.Build build) async {
    fsTask.updateFromBuild(build);
    await _firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites([fsTask], exists: true)),
      kDatabase,
    );
  }

  // No need to update task in Firestore if
  // 1) the build is `scheduled`. Task is marked as `In Progress`
  //    whenever scheduled, either from scheduler/backfiller/rerun. We need to update
  //    task in Firestore only for
  //    a) `started`: update info like builder number.
  //    b) `completed`: update info like status.
  // 2) the task is already completed.
  //    The task may have been marked as completed from test framework via update-task-status API.
  static bool _shouldUpdateTask(bbv2.Build build, fs.Task task) {
    if (build.status == bbv2.Status.SCHEDULED) {
      return false;
    }
    return !fs.Task.finishedStatusValues.contains(task.status);
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

    final currentCommit = await fs.Commit.fromFirestoreBySha(
      _firestore,
      sha: task.commitSha,
    );
    final commitList = await _firestore.queryRecentCommits(
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
