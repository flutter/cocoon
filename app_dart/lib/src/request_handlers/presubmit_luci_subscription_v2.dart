// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_service/src/model/luci/user_data.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler_v2.dart';
import 'package:cocoon_service/src/service/github_checks_service_v2.dart';
import 'package:cocoon_service/src/service/luci_build_service_v2.dart';
import 'package:cocoon_service/src/service/scheduler_v2.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/config.dart';
import '../service/logging.dart';

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
class PresubmitLuciSubscriptionV2 extends SubscriptionHandlerV2 {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitLuciSubscriptionV2({
    required super.cache,
    required super.config,
    required this.scheduler,
    required this.luciBuildService,
    required this.githubChecksService,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'build-bucket-presubmit-sub');

  final LuciBuildServiceV2 luciBuildService;
  final GithubChecksServiceV2 githubChecksService;
  final SchedulerV2 scheduler;

  @override
  Future<Body> post() async {
    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    final bbv2.PubSubCallBack pubSubCallBack = bbv2.PubSubCallBack();
    pubSubCallBack.mergeFromProto3Json(jsonDecode(message.data!) as Map<String, dynamic>);

    final bbv2.BuildsV2PubSub buildsV2PubSub = pubSubCallBack.buildPubsub;

    if (!buildsV2PubSub.hasBuild()) {
      log.info('no build information in message');
      return Body.empty;
    }

    final bbv2.Build build = buildsV2PubSub.build;

    final String builderName = build.builder.builder;

    final List<bbv2.StringPair> tags = build.tags;
    // final String builderName = tags.where((element) => element.key == 'builder_name').single.value;

    // final String builderName = build.tagsByName('builder').single;
    log.fine('Available tags: ${tags.toString()}');

    // Skip status update if we can not get the sha tag.
    if (tags.where((element) => element.key == 'buildset').isEmpty) {
      log.warning('Buildset tag not included, skipping Status Updates');
      return Body.empty;
    }

    log.fine('Setting status (${build.status.toString()}) for $builderName');

    if (pubSubCallBack.hasUserData()) {
      // Not sure if this is it has an automatic base64 decoder so we don't need to do that.
      final Map<String, dynamic> userDataMap = jsonDecode(String.fromCharCodes(pubSubCallBack.userData)) as Map<String, dynamic>;
      if (userDataMap.containsKey('repo_owner') && userDataMap.containsKey('repo_name')) {
        final RepositorySlug slug =
            RepositorySlug(userDataMap['repo_owner'] as String, userDataMap['repo_name'] as String);

        bool rescheduled = false;
        if (githubChecksService.taskFailed(build.status)) {
          final int currentAttempt = githubChecksService.currentAttempt(tags);
          final int maxAttempt = await _getMaxAttemptV2(
            userDataMap,
            slug,
            builderName,
          );
          if (currentAttempt < maxAttempt) {
            rescheduled = true;
            log.fine('Rerunning failed task: $builderName');
            await luciBuildService.rescheduleBuild(
              builderName: builderName,
              build: build,
              rescheduleAttempt: currentAttempt + 1,
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
    } else {
      log.info('No user data was found in this request');
    }

    return Body.empty;
  }

  Future<int> _getMaxAttemptV2(
    Map<String, dynamic> userData,
    RepositorySlug slug,
    String builderName,
  ) async {
    final Commit commit = Commit(
      branch: userData['commit_branch'] as String,
      repository: slug.fullName,
      sha: userData['commit_sha'] as String,
    );
    late CiYaml ciYaml;
    if (commit.branch == Config.defaultBranch(commit.slug)) {
      ciYaml = await scheduler.getCiYaml(commit, validate: true);
    } else {
      ciYaml = await scheduler.getCiYaml(commit);
    }

    // Do not block on the target not found.
    if (!ciYaml.presubmitTargets.any((element) => element.value.name == builderName)) {
      // do not reschedule
      log.warning('Did not find builder with name: $builderName in ciYaml for ${commit.sha}');
      final List<String> availableBuilderList = ciYaml.presubmitTargets.map((Target e) => e.value.name).toList();
      log.warning('ciYaml presubmit targets found: $availableBuilderList');
      return 1;
    }

    final Target target = ciYaml.presubmitTargets.where((element) => element.value.name == builderName).single;
    final Map<String, Object> properties = target.getProperties();
    if (!properties.containsKey('presubmit_max_attempts')) {
      return 1;
    }
    return properties['presubmit_max_attempts'] as int;
  }
}
