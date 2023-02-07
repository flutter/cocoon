// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

// TODO(chillers): Document this.
@immutable
class PresubmitBuildTestSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PresubmitBuildTestSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    AuthenticationProvider? authProvider,
  }) : super(subscriptionName: 'presubmit-build-test');

  final Scheduler scheduler;

  @override
  Future<Body> post() async {
    final BuildPushMessage buildPushMessage = BuildPushMessage.fromPushMessage(message);
    final Build build = buildPushMessage.build!;
    final String builderName = build.tagsByName('builder').first;
    log.fine('Available tags: ${build.tags.toString()}');
    //     processedTags['buildset'] = <String>['pr/git/$pullRequestNumber', 'sha/git/$sha'];
    final int? prNumber = int.tryParse(
      build.tagsByName('buildset').singleWhere((String tag) => tag.contains('pr/git/')).replaceAll('pr/git', ''),
    );
    final String sha = build
        .tagsByName('buildset')
        .singleWhere((String tag) => tag.contains('refs/heads/'))
        .replaceAll('refs/heads/', '');
    if (prNumber == null) {
      log.warning('Build does not contain buildset tag with pr number');
      return Body.empty;
    }
    // TODO(chill)
    if (!buildPushMessage.userData.containsKey('repo_owner') || !buildPushMessage.userData.containsKey('repo_name')) {
      log.warning('repo_owner or repo_name we not passed');
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
    final List<Target> dependencies = ciYaml.getDependentTargets(target, ciYaml.presubmitTargets);
    // TODO(chillers): Re-enable.
    // await scheduler.triggerPresubmitDependencies(
    //   dependencies: dependencies,
    //   pullRequest: pullRequest,
    // );

    return Body.empty;
  }
}
