// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_service/src/model/luci/push_message.dart';
import 'package:cocoon_service/src/request_handling/subscription_handler.dart';
import 'package:gcloud/db.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../request_handling/exceptions.dart';
import '../service/cache_service.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

/// An endpoint for listening to build updates for task updates.
///
/// The PubSub subscription is set up here:
/// https://cloud.google.com/cloudpubsub/subscription/detail/luci-builds?project=flutter-dashboard&tab=overview
///
/// This endpoint is responsible for updating Datastore with the result of tasks from LUCI.
@immutable
class TaskStatusSubscription extends SubscriptionHandler {
  const TaskStatusSubscription(
    CacheService cache,
    Config config,
    AuthenticationProvider authProvider, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(cache: cache, config: config, authProvider: authProvider, topicName: 'luci-builds');

  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final String data = message.data!;
    final BuildPushMessage buildPushMessage =
        BuildPushMessage.fromJson(json.decode(String.fromCharCodes(base64.decode(data))) as Map<String, dynamic>);

    final Map<String, dynamic> userData = jsonDecode(buildPushMessage.userData!) as Map<String, dynamic>;
    final String? commitBranch = userData['commit_branch'] as String?;
    if (commitBranch == null) {
      throw const BadRequestException('userData does not contain commit_branch');
    }
    final String? commitSha = userData['commit_sha'] as String?;
    if (commitSha == null) {
      throw const BadRequestException('userData does not contain commit_sha');
    }
    final String? builderName = userData['builder_name'] as String?;
    if (builderName == null) {
      throw const BadRequestException('userData does not contain builder_name');
    }
    final String? newStatus = buildPushMessage.build?.status.toString();
    if (newStatus == null) {
      throw const BadRequestException('userData does not contain status');
    }

    final DatastoreService datastore = datastoreProvider(config.db);

    // if (newStatus != Task.statusSucceeded && newStatus != Task.statusFailed) {
    //   throw const BadRequestException('NewStatus can be one of "Succeeded", "Failed"');
    // }

    final Task task = await _getTaskFromNamedParams(datastore, builderName, commitBranch, commitSha);

    task.status = newStatus;
    task.endTimestamp = DateTime.now().millisecondsSinceEpoch;

    await datastore.insert(<Task>[task]);
    return Body.empty;
  }

  /// Retrieve [Task] from [DatastoreService] when given [commitSha], [commitBranch], and [builderName].
  ///
  /// This is used when the DeviceLab test runner is uploading results to Cocoon for runs on LUCI.
  /// LUCI does not know the [Key] assigned to task when scheduling the build, but Cocoon can
  /// lookup the task based on these key values.
  ///
  /// To lookup the value, we construct the ancestor key, which corresponds to the [Commit].
  /// Then we query the tasks with that ancestor key and search for the one that matches the builder name.
  Future<Task> _getTaskFromNamedParams(
      DatastoreService datastore, String builderName, String gitBranch, String gitSha) async {
    final Key<String> commitKey = await _constructCommitKey(datastore, gitBranch, gitSha);

    final Query<Task> query = datastore.db.query<Task>(ancestorKey: commitKey);
    final List<Task> initialTasks = await query.run().toList();
    log.fine('Found ${initialTasks.length} tasks for commit');
    final List<Task> tasks = <Task>[];
    log.fine('Searching for task with builderName=$builderName');
    for (Task task in initialTasks) {
      if (task.builderName == builderName || task.name == builderName) {
        tasks.add(task);
      }
    }

    if (tasks.length != 1) {
      log.severe('Found ${tasks.length} entries for builder $builderName');
      throw InternalServerError('Expected to find 1 task for $builderName, but found ${tasks.length}');
    }

    return tasks.first;
  }

  /// Construct the Datastore key for [Commit] that is the ancestor to this [Task].
  Future<Key<String>> _constructCommitKey(DatastoreService datastore, String commitBranch, String commitSha) async {
    final String id = 'flutter/flutter/$commitBranch/$commitSha';
    final Key<String> commitKey = datastore.db.emptyKey.append<String>(Commit, id: id);
    log.fine('Constructed commit key=$id');
    // Return the official key from Datastore for task lookups.
    final Commit commit = await config.db.lookupValue<Commit>(commitKey);
    return commit.key;
  }
}
