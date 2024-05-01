// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/luci/buildbucket.dart' as bb;
import '../model/luci/push_message.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/subscription_handler.dart';
import '../service/buildbucket.dart';
import '../service/config.dart';
import '../service/github_checks_service.dart';
import '../service/logging.dart';
import '../service/scheduler_v2.dart';

/// An endpoint for listening to LUCI status updates for scheduled builds.
///
/// [ScheduleBuildRequest.notify] property is set to tell LUCI to use this
/// PubSub topic. LUCI then publishes updates about build status to that topic,
/// which we listen to on the github-updater subscription. When new messages
/// arrive, they are posted to this web service.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/github-updater?project=flutter-dashboard
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
    required this.buildBucketClient,
    required this.githubChecksService,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'github-updater');

  final BuildBucketClient buildBucketClient;
  final GithubChecksService githubChecksService;
  final SchedulerV2 scheduler;

  @override
  Future<Body> post() async {
    RepositorySlug slug;
    final BuildPushMessage buildPushMessage = BuildPushMessage.fromPushMessage(message);
    final Build build = buildPushMessage.build!;
    final String builderName = build.tagsByName('builder').single;
    log.fine('Available tags: ${build.tags.toString()}');
    // Skip status update if we can not get the sha tag.
    if (build.tagsByName('buildset').isEmpty) {
      log.warning('Buildset tag not included, skipping Status Updates');
      return Body.empty;
    }
    log.fine('Setting status: ${buildPushMessage.toJson()} for $builderName');
    if (buildPushMessage.userData.containsKey('repo_owner') && buildPushMessage.userData.containsKey('repo_name')) {
      // Message is coming from a github checks api enabled repo. We need to
      // create the slug from the data in the message and send the check status
      // update.
      slug = RepositorySlug(
        buildPushMessage.userData['repo_owner'] as String,
        buildPushMessage.userData['repo_name'] as String,
      );
      bool rescheduled = false;
      if (githubChecksService.taskFailed(buildPushMessage)) {
        final int currentAttempt = githubChecksService.currentAttempt(build);
        final int maxAttempt = await _getMaxAttempt(buildPushMessage, slug, builderName);
        if (currentAttempt < maxAttempt) {
          rescheduled = true;
          log.fine('Rerun a failed task: $builderName');
          await _rescheduleBuild(
            builderName: builderName,
            buildPushMessage: buildPushMessage,
            rescheduleAttempt: currentAttempt + 1,
          );
        }
      }
      await githubChecksService.updateCheckStatus(
        buildPushMessage,
        buildBucketClient,
        slug,
        rescheduled: rescheduled,
      );
    } else {
      log.shout('This repo does not support checks API');
    }
    return Body.empty;
  }

  Future<int> _getMaxAttempt(
    BuildPushMessage buildPushMessage,
    RepositorySlug slug,
    String builderName,
  ) async {
    final Commit commit = Commit(
      branch: buildPushMessage.userData['commit_branch'] as String,
      repository: slug.fullName,
      sha: buildPushMessage.userData['commit_sha'] as String,
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

  /// Sends [ScheduleBuildRequest] using information from a given build's
  /// [BuildPushMessage].
  ///
  /// The buildset, user_agent, and github_link tags are applied to match the
  /// original build. The build properties and user data from the original build
  /// are also preserved.
  ///
  /// The [currentAttempt] is used to track the number of current build attempt.
  Future<bb.Build> _rescheduleBuild({
    required String builderName,
    required BuildPushMessage buildPushMessage,
    required int rescheduleAttempt,
  }) async {
    // Ensure we are using V2 bucket name istead of V1.
    // V1 bucket name  is "luci.flutter.prod" while the api
    // is expecting just the last part after "."(prod).
    final String bucketName = buildPushMessage.build!.bucket!.split('.').last;
    final Map<String, List<String>> tags = <String, List<String>>{
      'buildset': buildPushMessage.build!.tagsByName('buildset'),
      'user_agent': buildPushMessage.build!.tagsByName('user_agent'),
      'github_link': buildPushMessage.build!.tagsByName('github_link'),
      'cipd_version': buildPushMessage.build!.tagsByName('cipd_version'),
      'github_checkrun': buildPushMessage.build!.tagsByName('github_checkrun'),
      'current_attempt': <String>[rescheduleAttempt.toString()],
    };
    return buildBucketClient.scheduleBuild(
      bb.ScheduleBuildRequest(
        builderId: bb.BuilderId(
          project: buildPushMessage.build!.project,
          bucket: bucketName,
          builder: builderName,
        ),
        tags: tags,
        // We need to cast to <String, Object> to bypass json.encode error when scheduling builds.
        properties:
            (buildPushMessage.build!.buildParameters!['properties'] as Map<String, Object?>).cast<String, Object>(),
        notify: bb.NotificationConfig(
          pubsubTopic: 'projects/flutter-dashboard/topics/luci-builds',
          userData: base64Encode(json.encode(buildPushMessage.userData).codeUnits),
        ),
      ),
    );
  }
}
