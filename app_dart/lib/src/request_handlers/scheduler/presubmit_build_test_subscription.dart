// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../../ci_yaml.dart';
import '../../model/appengine/commit.dart';
import '../../model/luci/push_message.dart';
import '../../request_handling/authentication.dart';
import '../../request_handling/body.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/logging.dart';
import '../../service/scheduler.dart';

/// Processes presubmit LUCI build messages to trigger dependent builds.
@immutable
class PresubmitBuildTestSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitBuildTestSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'scheduler-presubmit-build-test');

  final Scheduler scheduler;

  @override
  Future<Body> post() async {
    final BuildPushMessage buildPushMessage = BuildPushMessage.fromPushMessage(message);
    if (buildPushMessage.build == null) {
      log.fine('No build given, acking');
      return Body.empty;
    }
    final Build build = buildPushMessage.build!;
    if (build.result != Result.success) {
      return Body.empty;
    }
    final String builderName = build.tagsByName('builder').first;
    log.fine('Available tags: ${build.tags.toString()}');
    final List<String> tags = build.tagsByName('buildset');
    final String? prNumberRaw = tags.firstWhereOrNull((String tag) => tag.contains('pr/git/'));
    if (prNumberRaw == null) {
      log.warning('Build does not contain buildset tag with pr/git/####');
      return Body.empty;
    }
    final int prNumber = int.parse(prNumberRaw.replaceAll('pr/git/', ''));
    final String sha = tags.singleWhere((String tag) => tag.contains('sha/git/')).replaceAll('sha/git/', '');
    if (!buildPushMessage.userData.containsKey('repo_owner') || !buildPushMessage.userData.containsKey('repo_name')) {
      log.warning('repo_owner or repo_name were not passed');
      return Body.empty;
    }

    final String branch = buildPushMessage.userData['commit_branch'];

    final RepositorySlug slug = RepositorySlug(
      buildPushMessage.userData['repo_owner'] as String,
      buildPushMessage.userData['repo_name'] as String,
    );

    final Commit commit = Commit(
      branch: branch,
      repository: slug.fullName,
      sha: sha,
    );
    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final Target target = ciYaml.presubmitTargets.singleWhere((Target target) => target.value.name == builderName);
    final List<Target> dependencies = ciYaml
        .getDependentTargets(target, ciYaml.presubmitTargets)
        .where((Target target) => target.value.bringup == false)
        .toList();
    // Recreate PullRequest from the PushMessage
    final PullRequest pullRequest = PullRequest(
      number: prNumber,
      head: PullRequestHead(sha: sha),
      base: PullRequestHead(
        ref: 'refs/heads/$branch',
        repo: Repository(owner: UserInformation(slug.owner, -1, '', ''), name: slug.name),
      ),
    );
    await scheduler.triggerPresubmit(
      targets: dependencies,
      pullRequest: pullRequest,
    );

    return Body.empty;
  }
}
