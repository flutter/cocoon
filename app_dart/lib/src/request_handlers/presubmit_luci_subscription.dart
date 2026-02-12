// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';

import '../model/bbv2_extension.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/commit_ref.dart';
import '../model/common/presubmit_completed_check.dart';
import '../request_handling/authentication.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../request_handling/subscription_handler.dart';
import '../service/github_checks_service.dart';
import '../service/luci_build_service.dart';
import '../service/luci_build_service/build_tags.dart';
import '../service/luci_build_service/user_data.dart';
import '../service/scheduler.dart';
import '../service/scheduler/ci_yaml_fetcher.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// [ScheduleBuildRequest.notify] property is set to tell LUCI to use this
/// PubSub topic. LUCI then publishes updates about build status to that topic,
/// which we listen to on the github-updater subscription. When new messages
/// arrive, they are posted to this web service.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/build-bucket-presubmit-sub?project=flutter-dashboard
///
/// This endpoint is responsible for updating GitHub with the status of
/// completed builds from LUCI.
final class PresubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitLuciSubscription({
    required super.cache,
    required super.config,
    required LuciBuildService luciBuildService,
    required GithubChecksService githubChecksService,
    required CiYamlFetcher ciYamlFetcher,
    required Scheduler scheduler,
    AuthenticationProvider? authProvider,
  }) : _ciYamlFetcher = ciYamlFetcher,
       _githubChecksService = githubChecksService,
       _luciBuildService = luciBuildService,
       _scheduler = scheduler,
       super(subscriptionName: 'build-bucket-presubmit-sub');

  final LuciBuildService _luciBuildService;
  final GithubChecksService _githubChecksService;
  final CiYamlFetcher _ciYamlFetcher;
  final Scheduler _scheduler;

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

    var build = buildsPubSub.build;

    // Add build fields that are stored in a separate compressed buffer.
    build.mergeFromBuffer(
      const ZLibDecoder().decodeBytes(buildsPubSub.buildLargeFields),
    );

    final builderName = build.builder.builder;
    final tagSet = BuildTags.fromStringPairs(build.tags);

    log.info('Available tags: $tagSet');

    // Skip status update if we can not get the sha tag.
    if (tagSet.buildTags.whereType<BuildSetBuildTag>().isEmpty) {
      log.warn('Buildset tag not included, skipping Status Updates');
      return Response.emptyOk;
    }

    log.info('Setting status (${build.status}) for $builderName');

    if (!pubSubCallBack.hasUserData()) {
      log.info('No user data was found in this request');
      return Response.emptyOk;
    }

    final userData = PresubmitUserData.fromBytes(pubSubCallBack.userData);
    var rescheduled = false;
    final isUnifiedCheckRun = userData.guardCheckRunId != null;
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
    if (!isUnifiedCheckRun) {
      await _githubChecksService.updateCheckStatus(
        checkRunId: userData.checkRunId!,
        build: build,
        luciBuildService: _luciBuildService,
        slug: userData.commit.slug,
        rescheduled: rescheduled,
      );
    }
    if (!rescheduled) {
      // Process to the check-run status in the merge queue document during
      // the LUCI callback.
      if (config.flags.closeMqGuardAfterPresubmit || isUnifiedCheckRun) {
        final check = PresubmitCompletedCheck.fromBuild(build, userData);
        await _scheduler.processCheckRunCompleted(check);
      }
    }

    return Response.emptyOk;
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
    return properties['presubmit_max_attempts'] as int;
  }
}
