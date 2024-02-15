// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/ci_yaml/ci_yaml.dart';
import '../model/ci_yaml/target.dart';
import '../model/luci/push_message.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/subscription_handler.dart';
import '../service/config.dart';
import '../service/github_checks_service.dart';
import '../service/logging.dart';
import '../service/luci_build_service.dart';
import '../service/scheduler.dart';

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
    required this.luciBuildService,
    required this.githubChecksService,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'github-updater');

  final LuciBuildService luciBuildService;
  final GithubChecksService githubChecksService;
  final Scheduler scheduler;

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
        final int currentAttempt = githubChecksService.currentAttempt(buildPushMessage);
        final int maxAttempt = await _getMaxAttempt(buildPushMessage, slug, builderName);
        if (currentAttempt < maxAttempt) {
          rescheduled = true;
          log.fine('Rerun a failed task: $builderName');
          await luciBuildService.rescheduleBuild(
            builderName: builderName,
            buildPushMessage: buildPushMessage,
            rescheduleAttempt: currentAttempt + 1,
          );
        }
      }
      await githubChecksService.updateCheckStatus(
        buildPushMessage,
        luciBuildService,
        slug,
        rescheduled: rescheduled,
      );
    } else {
      log.shout('This repo does not support checks API');
    }
    return Body.empty;
  }

  /// Gets target's allowed reschedule attempt.
  ///
  /// Each target can define their own allowed max number of reschedule attemp, and it
  /// is defined as a property `presubmit_max_attempts`.
  ///
  /// If not property is defined, the target doesn't allow a reschedule after failures.
  /// Typically the property will be used for targets that are likely flaky.
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
}
