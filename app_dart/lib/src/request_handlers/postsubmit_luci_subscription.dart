// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/luci/push_message.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';
import '../service/cache_service.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

/// An endpoint for listening to build updates for postsubmit builds.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/luci-postsubmit?project=flutter-dashboard&tab=overview
///
/// This endpoint is responsible for updating Datastore with the result of builds from LUCI.
@immutable
class PostsubmitLuciSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening to LUCI status updates.
  const PostsubmitLuciSubscription(
    CacheService cache,
    Config config, {
    AuthenticationProvider? authProvider,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(
          cache: cache,
          config: config,
          authProvider: authProvider,
          topicName: 'luci-postsubmit',
        );

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    final String data = message.data!;
    final BuildPushMessage buildPushMessage =
        BuildPushMessage.fromJson(json.decode(String.fromCharCodes(base64.decode(data))) as Map<String, dynamic>);
    log.fine(buildPushMessage.userData);
    log.fine('Updating buildId=${buildPushMessage.build?.id} for result=${buildPushMessage.build?.result}');
    // Example user data:
    // {
    //   "task_key": "key123",
    // }
    if (buildPushMessage.userData == null) {
      log.fine('User data is empty');
      return Body.empty;
    }
    final Map<String, dynamic> userData = jsonDecode(buildPushMessage.userData!) as Map<String, dynamic>;
    final String? rawTaskKey = userData['task_key'] as String?;
    final String? rawCommitKey = userData['commit_key'] as String?;
    if (rawTaskKey == null || rawCommitKey == null) {
      throw const BadRequestException('userData does not contain task_key');
    }
    log.fine('Looking up key...');
    final int taskId = int.parse(rawTaskKey);
    final Key<String> commitKey = Key<String>(Key<dynamic>.emptyKey(Partition(null)), Commit, rawCommitKey);
    final Key<int> taskKey = Key<int>(commitKey, Task, taskId);
    final Task task = await datastore.lookupByValue<Task>(taskKey);
    log.fine('Found $task');

    final Build? build = buildPushMessage.build;
    if (build == null) {
      log.warning('Build is null');
      return Body.empty;
    }
    task.updateFromBuild(build);
    await datastore.insert(<Task>[task]);
    log.fine('Updated datastore');

    return Body.empty;
  }
}
