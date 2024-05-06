// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'dart:convert';
import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:fixnum/fixnum.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../request_handling/subscription_handler_v2.dart';
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
class DartInternalSubscription extends SubscriptionHandlerV2 {
  /// Creates an endpoint for listening for dart-internal build results.
  /// The message should contain a single buildbucket id
  const DartInternalSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
    required this.buildBucketClient,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketV2Client buildBucketClient;
  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    // This looks to be like we are simply getting the build and not the top level
    // buildsPubSub message.
    final Map<String, dynamic> jsonBuildMap = json.decode(message.data!);

    if (jsonBuildMap['build'] == null) {
      log.info('no build information in message');
      return Body.empty;
    }

    final String project = jsonBuildMap['build']['builder']['project'];
    final String bucket = jsonBuildMap['build']['builder']['bucket'];
    final String builder = jsonBuildMap['build']['builder']['builder'];
    final Int64 buildId = Int64.parseInt(jsonBuildMap['build']['id']);

    // This should already be covered by the pubsub filter, but adding an additional check
    // to ensure we don't process builds that aren't from dart-internal/flutter.
    if (project != 'dart-internal' || bucket != 'flutter') {
      log.info('Ignoring build not from dart-internal/flutter bucket');
      return Body.empty;
    }

    // Only publish the parent release_builder builds to the datastore.
    // TODO(drewroengoogle): Remove this regex in favor of supporting *all* dart-internal build results.
    // Issue: https://github.com/flutter/flutter/issues/134674
    final regex =
        RegExp(r'(Linux|Mac|Windows)\s+(engine_release_builder|packaging_release_builder|flutter_release_builder)');
    if (!regex.hasMatch(builder)) {
      log.info('Ignoring builder that is not a release builder');
      return Body.empty;
    }

    log.info('Creating build request object with build id $buildId');

    final bbv2.GetBuildRequest getBuildRequest = bbv2.GetBuildRequest(
      id: buildId,
    );

    log.info(
      'Calling buildbucket api to get build data for build $buildId',
    );

    final bbv2.Build existingBuild = await buildBucketClient.getBuild(getBuildRequest);

    log.info('Got back existing builder with name: ${existingBuild.builder.builder}');

    log.info('Checking for existing task in datastore');
    final Task? existingTask = await datastore.getTaskFromBuildbucketV2Build(existingBuild);

    late Task taskToInsert;
    if (existingTask != null) {
      log.info('Updating Task from existing Build');
      existingTask.updateFromBuildbucketV2Build(existingBuild);
      taskToInsert = existingTask;
    } else {
      log.info('Creating Task from Buildbucket result');
      taskToInsert = await Task.fromBuildbucketV2Build(existingBuild, datastore);
    }

    log.info('Inserting Task into the datastore: ${taskToInsert.toString()}');
    await datastore.insert(<Task>[taskToInsert]);
    try {
      final FirestoreService firestoreService = await config.createFirestoreService();
      final firestore.Task taskDocument = firestore.taskToDocument(taskToInsert);
      final List<Write> writes = documentsToWrites([taskDocument]);
      await firestoreService.batchWriteDocuments(BatchWriteRequest(writes: writes), kDatabase);
    } catch (error) {
      log.warning('Failed to insert dart internal task into firestore: $error');
    }

    return Body.forJson(taskToInsert.toString());
  }
}
