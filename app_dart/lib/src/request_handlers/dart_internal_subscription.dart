// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/model/luci/push_message.dart' as pm;
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

/// TODO(drewroengoogle): Make this subscription generic so we can accept more
/// than just dart-internal builds.
///
/// An endpoint for listening to build updates for dart-internal builds and
/// saving the results to the datastore.
///
/// The PubSub subscription is set up here:
/// https://console.cloud.google.com/cloudpubsub/subscription/detail/dart-internal-build-results-sub?project=flutter-dashboard
@immutable
class DartInternalSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening for dart-internal build results.
  /// The message should contain a single buildbucket id
  const DartInternalSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
    required this.buildBucketClient,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
    this.retryOptions = Config.buildbucketRetry,
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketClient buildBucketClient;
  final DatastoreServiceProvider datastoreProvider;
  final RetryOptions retryOptions;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    final pm.Build? buildFromMessage =
        pm.BuildPushMessage.fromPushMessage(message).build;
    log.info(buildFromMessage);

    if (buildFromMessage == null) {
      log.info("Build is null");
      return Body.empty;
    }
    // All dart-internal builds reach here, so if it isn't part of the flutter
    // bucket, there's no need to process it.
    if (buildFromMessage.bucket != 'flutter') {
      log.info("Ignoring build not from flutter bucket");
      return Body.empty;
    }

    // TODO(drewroengoogle): Determine which builds we want to save to the datastore
    return Body.empty;

    final String? buildbucketId = buildFromMessage.id;
    log.info("Creating build request object");
    final GetBuildRequest request = GetBuildRequest(
      id: buildFromMessage.id,
    );

    log.info(
      "Calling buildbucket api to get build data for build $buildbucketId",
    );
    final Build build = await buildBucketClient.getBuild(request);

    log.info("Checking for existing task in datastore");
    final Task? existingTask =
        await datastore.getTaskFromBuildbucketBuild(build);

    late Task taskToInsert;
    if (existingTask != null) {
      log.info("Updating Task from existing Task");
      existingTask.updateFromBuildbucketBuild(build);
      taskToInsert = existingTask;
    } else {
      log.info("Creating Task from Buildbucket result");
      taskToInsert = await Task.fromBuildbucketBuild(build, datastore);
    }

    log.info("Inserting Task into the datastore: ${taskToInsert.toString()}");
    await datastore.insert(<Task>[taskToInsert]);

    return Body.forJson(taskToInsert.toString());
  }
}
