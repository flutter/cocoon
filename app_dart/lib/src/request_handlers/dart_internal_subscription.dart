// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';
import '../service/exceptions.dart';
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
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    this.retryOptions = Config.buildbucketRetry,
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketClient buildBucketClient;
  final DatastoreServiceProvider datastoreProvider;
  final RetryOptions retryOptions;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    // This message comes from the engine_v2 recipes once a build run on
    // dart-internal has completed.
    //
    // Example: https://flutter.googlesource.com/recipes/+/c6af020f0f22e392e30b769a5ed97fadace308fa/recipes/engine_v2/engine_v2.py#185
    log.info("Getting buildbucket id from pubsub message");
    final dynamic messageJson = json.decode(message.data.toString());

    final int buildbucketId = messageJson['buildbucket_id'];
    log.info("Buildbucket id: $buildbucketId");

    log.info("Creating build request object");
    final GetBuildRequest request = GetBuildRequest(
        id: messageJson['buildbucket_id'].toString(),
        fields:
            "id,builder,number,createdBy,createTime,startTime,endTime,updateTime,status,input.properties,input.gitilesCommit");

    log.info(
      "Calling buildbucket api to get build data for build $buildbucketId",
    );
    final Build build = await _getBuildFromBuildbucket(request);

    String? name;
    if (build.input?.properties != null && build.input?.properties?["build"] != null) {
      final Map<String, Object> buildProperties = build.input?.properties?["build"] as Map<String, Object>;
      name = buildProperties["name"] as String;
    }

    log.info("Checking for existing task in datastore");
    final Task? existingTask = await datastore.getTaskFromBuildbucketBuild(build, customName: name);

    late Task taskToInsert;
    if (existingTask != null) {
      log.info("Updating Task from existing Task");
      existingTask.updateFromBuildbucketBuild(build);
      taskToInsert = existingTask;
    } else {
      log.info("Creating Task from Buildbucket result");
      taskToInsert = await Task.fromBuildbucketBuild(build, datastore, customName: name);
    }

    log.info("Inserting Task into the datastore: ${taskToInsert.toString()}");
    await datastore.insert(<Task>[taskToInsert]);

    return Body.forJson(taskToInsert.toString());
  }

  Future<Build> _getBuildFromBuildbucket(
    GetBuildRequest request,
  ) async {
    return retryOptions.retry(
      () async {
        final Build build = await buildBucketClient.getBuild(request);

        if (build.status != Status.success &&
            build.status != Status.failure &&
            build.status != Status.infraFailure &&
            build.status != Status.canceled) {
          log.info(
            "Build is not finished",
          );
          throw UnfinishedBuildException(
            "Build is not finished",
          );
        }
        return build;
      },
      retryIf: (Exception e) => e is UnfinishedBuildException,
    );
  }
}
