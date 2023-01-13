// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/ci_yaml.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../../model/appengine/commit.dart';
import '../../model/appengine/task.dart';
import '../../model/luci/push_message.dart';
import '../../request_handling/body.dart';
import '../../request_handling/exceptions.dart';
import '../../request_handling/subscription_handler.dart';
import '../../service/datastore.dart';
import '../../service/logging.dart';
import '../../service/scheduler.dart';

// TODO(chillers): Create new subscription.
// TODO(chillers): Add this to bin/server.dart
// TODO(chillers): Write tests.
// TODO(chillers): Create a similar version of this for presubmit.
@immutable
class PostsubmitBuildTestSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PostsubmitBuildTestSubscription({
    required super.cache,
    required super.config,
    required this.scheduler,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    super.authProvider,
  }) : super(subscriptionName: 'postsubmit-build-test');

  final DatastoreServiceProvider datastoreProvider;
  final Scheduler scheduler;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildPushMessage buildPushMessage = BuildPushMessage.fromPushMessage(message);
    log.fine(buildPushMessage.userData);
    final String? rawTaskKey = buildPushMessage.userData['task_key'] as String?;
    final String? rawCommitKey = buildPushMessage.userData['commit_key'] as String?;
    if (rawCommitKey == null) {
      throw const BadRequestException('buildPushMessage.userData does not contain commit_key');
    }
    final Build? build = buildPushMessage.build;
    if (build == null) {
      log.warning('Build is null');
      return Body.empty;
    }
    final Key<String> commitKey = Key<String>(Key<dynamic>.emptyKey(Partition(null)), Commit, rawCommitKey);
    final Commit commit = await datastore.lookupByValue<Commit>(commitKey);
    final Task task = await Task.fromDatastore(
      datastore: datastore,
      commitKey: commitKey,
      name: build.buildParameters?['builder_name'] as String,
      id: rawTaskKey,
    );
    final CiYaml ciYaml = await scheduler.getCiYaml(commit);
    final Target target = ciYaml.postsubmitTargets.singleWhere((Target target) => target.value.name == task.name);
    final List<Target> dependencies = ciYaml.getDependentTargets(target, ciYaml.postsubmitTargets);
    if (dependencies.isEmpty) {
      return Body.empty;
    }
    log.fine('Scheduling dependent targets...');
    await scheduler.triggerPostsubmitDependencies(commit: commit, targets: dependencies);

    return Body.empty;
  }
}
