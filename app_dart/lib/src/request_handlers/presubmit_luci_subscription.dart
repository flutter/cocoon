// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/subscription_handler.dart';
import '../service/config.dart';
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
@immutable
class PresubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitLuciSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    required this.luciBuildService,
    required this.githubChecksService,
    required this.ciYamlFetcher,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'build-bucket-presubmit-sub');

  final LuciBuildService luciBuildService;
  final GithubChecksService githubChecksService;
  final Scheduler scheduler;
  final CiYamlFetcher ciYamlFetcher;

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

    if (!buildsPubSub.hasBuild()) {
      log.info('no build information in message');
      return Body.empty;
    }

    final build = buildsPubSub.build;

    // Add build fields that are stored in a separate compressed buffer.
    build.mergeFromBuffer(ZLibCodec().decode(buildsPubSub.buildLargeFields));

    final builderName = build.builder.builder;
    final tagSet = BuildTags.fromStringPairs(build.tags);

    log.info('Available tags: $tagSet');

    // Skip status update if we can not get the sha tag.
    if (tagSet.buildTags.whereType<BuildSetBuildTag>().isEmpty) {
      log.warn('Buildset tag not included, skipping Status Updates');
      return Body.empty;
    }

    log.info('Setting status (${build.status}) for $builderName');

    if (!pubSubCallBack.hasUserData()) {
      log.info('No user data was found in this request');
      return Body.empty;
    }

    final userData = PresubmitUserData.fromBytes(pubSubCallBack.userData);
    final slug = RepositorySlug(userData.repoOwner, userData.repoName);
    var rescheduled = false;
    if (githubChecksService.taskFailed(build.status)) {
      final currentAttempt = _nextAttempt(tagSet);
      final maxAttempt = await _getMaxAttempt(
        slug,
        builderName,
        tagSet,
        commitBranch: userData.commitBranch,
        commitSha: userData.commitSha,
      );
      if (currentAttempt < maxAttempt) {
        rescheduled = true;
        log.info('Rerunning failed task: $builderName');
        await luciBuildService.reschedulePresubmitBuild(
          builderName: builderName,
          build: build,
          nextAttempt: currentAttempt + 1,
          userData: userData,
        );
      }
    }
    await githubChecksService.updateCheckStatus(
      checkRunId: userData.checkRunId,
      build: build,
      luciBuildService: luciBuildService,
      slug: slug,
      rescheduled: rescheduled,
    );
    return Body.empty;
  }

  /// Returns the current reschedule attempt.
  ///
  /// It returns 1 if this is the first run.
  static int _nextAttempt(BuildTags buildTags) {
    final attempt = buildTags.getTagOfType<CurrentAttemptBuildTag>();
    if (attempt == null) {
      return 1;
    }
    return attempt.attemptNumber;
  }

  Future<int> _getMaxAttempt(
    RepositorySlug slug,
    String builderName,
    BuildTags tags, {
    required String commitBranch,
    required String commitSha,
  }) async {
    final CiYamlSet ciYaml;
    try {
      ciYaml = await ciYamlFetcher.getCiYaml(
        commitSha: commitSha,
        commitBranch: commitBranch,
        slug: slug,
        validate: commitSha == Config.defaultBranch(slug),
      );
    } on FormatException {
      // If ci.yaml no longer passes validation (for example, because a builder
      // has been removed), ensure no retries.
      return 0;
    }

    final targets = [
      ...ciYaml.presubmitTargets(),
      if (ciYaml.isFusion)
        ...ciYaml.presubmitTargets(type: CiType.fusionEngine),
    ];
    // Do not block on the target not found.
    if (!targets.any((element) => element.value.name == builderName)) {
      // do not reschedule
      log.warn(
        'Did not find builder with name: $builderName in ciYaml for $commitSha',
      );
      final availableBuilderList =
          ciYaml.presubmitTargets().map((Target e) => e.value.name).toList();
      log.warn('ciYaml presubmit targets found: $availableBuilderList');
      return 1;
    }

    final target = targets.singleWhere(
      (element) => element.value.name == builderName,
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
