// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/bbv2_extension.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/commit_ref.dart';
import '../model/common/presubmit_completed_check.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';
import '../service/extensions/cache_service_test_suppression.dart';
import '../service/luci_build_service/build_tags.dart';
import '../service/luci_build_service/user_data.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// Base subscription handler for processing LUCI presubmit build status updates.
///
/// Subclasses inherit this logic to process completed or failing presubmit
/// try builds received via PubSub subscriptions.
///
/// This class is responsible for:
/// * Checking remaining build attempts and rescheduling failed builds.
/// * Suppressing failing conclusions if a test is marked as suppressed.
/// * Updating GitHub Check Run statuses for individual presubmit builds.
/// * Calling [Scheduler.processCheckRunCompleted] to progress CI stages or merge queues.
base class PresubmitSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitSubscription({
    required super.cache,
    required super.config,
    required LuciBuildService luciBuildService,
    required GithubChecksService githubChecksService,
    required CiYamlFetcher ciYamlFetcher,
    required Scheduler scheduler,
    required FirestoreService firestore,
    required super.subscriptionName,
    super.authProvider,
  }) : _ciYamlFetcher = ciYamlFetcher,
       _githubChecksService = githubChecksService,
       _luciBuildService = luciBuildService,
       _scheduler = scheduler,
       _firestore = firestore;

  final LuciBuildService _luciBuildService;
  final GithubChecksService _githubChecksService;
  final CiYamlFetcher _ciYamlFetcher;
  final Scheduler _scheduler;
  final FirestoreService _firestore;

  @override
  Future<Response> post(Request request) async {
    if (message.data == null) {
      log.info('no data in message');
      return Response.emptyOk;
    }

    final pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(
      jsonDecode(message.data!) as Map<String, dynamic>,
    );

    final buildsPubSub = pubSubCallBack.buildPubsub;

    if (!buildsPubSub.hasBuild()) {
      log.info('no build information in message');
      return Response.emptyOk;
    }

    final build = buildsPubSub.build;

    // Add build fields that are stored in a separate compressed buffer.
    // Add build fields that are stored in a separate compressed buffer if present.
    if (buildsPubSub.buildLargeFields.isNotEmpty) {
      build.mergeFromBuffer(
        const ZLibDecoder().decodeBytes(buildsPubSub.buildLargeFields),
      );
    } else {
      log.info('Build large fields not found, relying on direct build fields');
    }

    final builderName = build.builder.builder;
    final tagSet = BuildTags.fromStringPairs(build.tags);

    log.info('Available tags: ${build.tags}');

    // Skip status update if we can not get the sha tag.
    if (tagSet.buildTags.whereType<BuildSetBuildTag>().isEmpty) {
      log.warn('Buildset tag not included, skipping Status Updates');
      return Response.emptyOk;
    }

    log.info(
      'Setting status (${build.status}) for build id: ${build.id} named: $builderName',
    );

    if (!pubSubCallBack.hasUserData()) {
      log.info('No user data was found in this request');
      return Response.emptyOk;
    }

    final userData = PresubmitUserData.fromBytes(pubSubCallBack.userData);
    log.info('User Data Json: ${userData.toJson()}');

    if (await interceptBuild(tagSet)) {
      return Response.emptyOk;
    }

    await _processBuild(build: build, userData: userData, tagSet: tagSet);
    return Response.emptyOk;
  }

  /// Hook allowing subclasses to intercept and pre-process a presubmit build
  /// before standard build status processing ([_processBuild]) occurs.
  ///
  /// Returns `true` if the build was intercepted and fully handled (skipping
  /// default build processing), or `false` to proceed with default processing.
  @protected
  Future<bool> interceptBuild(BuildTags tags) async {
    return false;
  }

  /// Processes a completed or failing presubmit [build] using [userData].
  ///
  /// Evaluates whether a failing task should be automatically retried up to
  /// [_getMaxAttempt]. If the build is not rescheduled, updates GitHub check
  /// run status and notifies [Scheduler.processCheckRunCompleted].
  Future<void> _processBuild({
    required bbv2.Build build,
    required PresubmitUserData userData,
    BuildTags? tagSet,
  }) async {
    tagSet ??= BuildTags.fromStringPairs(build.tags);
    final builderName = build.builder.builder;
    var rescheduled = false;
    final isUnifiedCheckRun = userData.guardCheckRunId != null;
    log.info('Unified Check Run ${isUnifiedCheckRun ? 'Enabled' : 'Disabled'}');
    if (build.status.isTaskFailed()) {
      if (isUnifiedCheckRun) {
        // If failed we need summaryMarkdown. For github check run flow this
        // called in [GithubChecksService.updateCheckStatus(...)]
        build = await _luciBuildService.getBuildById(
          build.id,
          buildMask: bbv2.BuildMask(
            // Need to use allFields as there is a bug with fieldMask and summaryMarkdown.
            allFields: true,
          ),
        );
      }
      final maxAttempt = await _getMaxAttempt(
        userData.commit,
        builderName,
        tagSet,
      );
      if (tagSet.currentAttempt < maxAttempt) {
        rescheduled = true;
        log.info('Rerunning failed task: $builderName');
        await _luciBuildService.reschedulePresubmitBuild(
          builderName: builderName,
          build: build,
          nextAttempt: tagSet.currentAttempt + 1,
          userData: userData,
        );
      }
    }
    CheckRunConclusion? override;
    if (!isUnifiedCheckRun) {
      String? suppressedMessage;
      if (build.status.isTaskFailed() && !rescheduled) {
        // If a test is suppressed; we avoid setting a failing status.
        final isSuppressed = await cache.isTestSuppressed(
          testName: builderName,
          repository: userData.commit.slug,
          firestore: _firestore,
        );
        if (isSuppressed) {
          override = CheckRunConclusion.neutral;
          suppressedMessage =
              '### ⚠️ Test failed but marked as suppressed on dashboard';
        }
      }
      if (userData.checkRunId == null) {
        log.error('checkRunId is null for non-unified check run');
        return;
      }
      await _githubChecksService.updateCheckStatus(
        checkRunId: userData.checkRunId!,
        build: build,
        luciBuildService: _luciBuildService,
        slug: userData.commit.slug,
        rescheduled: rescheduled,
        conclusionOverride: override,
        summaryPrepend: suppressedMessage,
      );
    }
    if (!rescheduled) {
      final check = PresubmitCompletedJob.fromBuild(
        build,
        userData,
        status: override == CheckRunConclusion.neutral
            ? TaskStatus.neutral
            : null,
      );
      await _scheduler.processCheckRunCompleted(check);
    }
  }

  Future<int> _getMaxAttempt(
    CommitRef commit,
    String builderName,
    BuildTags tags,
  ) async {
    final CiYamlSet ciYaml;
    try {
      ciYaml = await _ciYamlFetcher.getCiYamlByCommit(commit);
    } on FormatException {
      // If ci.yaml no longer passes validation (for example, because a builder
      // has been removed), ensure no retries.
      return 0;
    }

    final List<Target> targets;
    try {
      targets = [
        ...ciYaml.presubmitTargets(),
        if (ciYaml.isFusion)
          ...ciYaml.presubmitTargets(type: CiType.fusionEngine),
      ];
    } on BranchNotEnabledForThisCiYamlException catch (e) {
      throw BadRequestException('Cannot handle request: $e');
    }
    // Do not block on the target not found.
    if (!targets.any((element) => element.name == builderName)) {
      // do not reschedule
      log.warn(
        'Did not find builder with name: $builderName in ciYaml for $commit',
      );
      final availableBuilderList = ciYaml
          .presubmitTargets()
          .map((Target e) => e..name)
          .toList();
      log.warn('ciYaml presubmit targets found: $availableBuilderList');
      return 1;
    }

    final target = targets.singleWhere(
      (element) => element.name == builderName,
    );
    final properties = target.getProperties();
    if (!properties.containsKey('presubmit_max_attempts')) {
      // Give any test in the merge queue another try... its expensive otherwise.
      return tags.containsType<InMergeQueueBuildTag>()
          ? LuciBuildService.kMergeQueueMaxRetries
          : 1;
    }
    final maxAttemptsValue = properties['presubmit_max_attempts'];
    if (maxAttemptsValue is int) {
      return maxAttemptsValue;
    } else if (maxAttemptsValue is String) {
      return int.tryParse(maxAttemptsValue) ?? 1;
    }
    return 1;
  }
}
