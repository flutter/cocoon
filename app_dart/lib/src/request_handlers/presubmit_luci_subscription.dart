// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:cocoon_service/src/service/github_checks_service.dart';
import 'package:cocoon_service/src/service/luci_build_service.dart';
import 'package:cocoon_service/src/service/luci_build_service/build_tags.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/config.dart';

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
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'build-bucket-presubmit-sub');

  final LuciBuildService luciBuildService;
  final GithubChecksService githubChecksService;
  final Scheduler scheduler;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(jsonDecode(message.data!) as Map<String, dynamic>);

    final bbv2.BuildsV2PubSub buildsPubSub = pubSubCallBack.buildPubsub;

    if (!buildsPubSub.hasBuild()) {
      log.info('no build information in message');
      return Body.empty;
    }

    final bbv2.Build build = buildsPubSub.build;

    // Add build fields that are stored in a separate compressed buffer.
    build.mergeFromBuffer(ZLibCodec().decode(buildsPubSub.buildLargeFields));

    final String builderName = build.builder.builder;
    final tagSet = BuildTags.fromStringPairs(build.tags);

    log.info('Available tags: $tagSet');

    // Skip status update if we can not get the sha tag.
    if (tagSet.buildTags.whereType<BuildSetBuildTag>().isEmpty) {
      log.warning('Buildset tag not included, skipping Status Updates');
      return Body.empty;
    }

    log.info('Setting status (${build.status}) for $builderName');

    if (!pubSubCallBack.hasUserData()) {
      log.info('No user data was found in this request');
      return Body.empty;
    }

    Map<String, dynamic> userDataMap = <String, dynamic>{};
    try {
      userDataMap = json.decode(String.fromCharCodes(pubSubCallBack.userData));
      log.info('User data was not base64 encoded.');
    } on FormatException {
      userDataMap = UserData.decodeUserDataBytes(pubSubCallBack.userData);
      log.info('Decoding base64 encoded user data.');
    }

    if (userDataMap.containsKey('repo_owner') && userDataMap.containsKey('repo_name')) {
      final RepositorySlug slug =
          RepositorySlug(userDataMap['repo_owner'] as String, userDataMap['repo_name'] as String);

      bool rescheduled = false;
      if (githubChecksService.taskFailed(build.status)) {
        final int currentAttempt = _nextAttempt(tagSet);
        final int maxAttempt = await _getMaxAttempt(
          userDataMap,
          slug,
          builderName,
          tagSet,
        );
        if (currentAttempt < maxAttempt) {
          rescheduled = true;
          log.info('Rerunning failed task: $builderName');
          await luciBuildService.rescheduleBuild(
            builderName: builderName,
            build: build,
            nextAttempt: currentAttempt + 1,
            userDataMap: userDataMap,
          );
        }
      }
      await githubChecksService.updateCheckStatus(
        build: build,
        userDataMap: userDataMap,
        luciBuildService: luciBuildService,
        slug: slug,
        rescheduled: rescheduled,
      );
    } else {
      log.info('This repo does not support checks API');
    }
    return Body.empty;
  }

  /// Returns the current reschedule attempt.
  ///
  /// It returns 1 if this is the first run.
  static int _nextAttempt(BuildTags buildTags) {
    final attempt = buildTags.getTagOf<CurrentAttemptBuildTag>();
    if (attempt == null) {
      return 1;
    }
    return attempt.attemptNumber;
  }

  Future<int> _getMaxAttempt(
    Map<String, dynamic> userData,
    RepositorySlug slug,
    String builderName,
    BuildTags tags,
  ) async {
    final Commit commit = Commit(
      branch: userData['commit_branch'] as String,
      repository: slug.fullName,
      sha: userData['commit_sha'] as String,
    );
    late CiYamlSet ciYaml;
    try {
      if (commit.branch == Config.defaultBranch(commit.slug)) {
        ciYaml = await scheduler.getCiYaml(commit, validate: true);
      } else {
        ciYaml = await scheduler.getCiYaml(commit);
      }
    } on FormatException {
      // If ci.yaml no longer passes validation (for example, because a builder
      // has been removed), ensure no retries.
      return 0;
    }

    final targets = [
      ...ciYaml.presubmitTargets(),
      if (ciYaml.isFusion) ...ciYaml.presubmitTargets(type: CiType.fusionEngine),
    ];
    // Do not block on the target not found.
    if (!targets.any((element) => element.value.name == builderName)) {
      // do not reschedule
      log.warning('Did not find builder with name: $builderName in ciYaml for ${commit.sha}');
      final List<String> availableBuilderList = ciYaml.presubmitTargets().map((Target e) => e.value.name).toList();
      log.warning('ciYaml presubmit targets found: $availableBuilderList');
      return 1;
    }

    final target = targets.singleWhere((element) => element.value.name == builderName);
    final Map<String, Object> properties = target.getProperties();
    if (!properties.containsKey('presubmit_max_attempts')) {
      // Give any test in the merge queue another try... its expensive otherwise.
      return tags.contains<InMergeQueueBuildTag>() ? LuciBuildService.kMergeQueueMaxRetries : 1;
    }
    return properties['presubmit_max_attempts'] as int;
  }
}
