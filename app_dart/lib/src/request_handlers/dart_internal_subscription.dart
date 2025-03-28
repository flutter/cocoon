// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_server/logging.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';

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
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketClient buildBucketClient;
  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final datastore = datastoreProvider(config.db);

    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    // This looks to be like we are simply getting the build and not the top level
    // buildsPubSub message.
    final jsonBuildMap = json.decode(message.data!) as Map<String, dynamic>;

    if (jsonBuildMap['build'] == null) {
      log.info('no build information in message');
      return Body.empty;
    }

    final project = jsonBuildMap['build']['builder']['project'] as String;
    final bucket = jsonBuildMap['build']['builder']['bucket'] as String;
    final builder = jsonBuildMap['build']['builder']['builder'] as String;
    final buildId = Int64.parseInt(jsonBuildMap['build']['id'] as String);

    // This should already be covered by the pubsub filter, but adding an additional check
    // to ensure we don't process builds that aren't from dart-internal/flutter.
    if (project != 'dart-internal' || bucket != 'flutter') {
      log.info('Ignoring build not from dart-internal/flutter bucket');
      return Body.empty;
    }

    if (!isTaskFromDartInternalBuilder(builderName: builder)) {
      log.info('Ignoring builder that is not a release builder');
      return Body.empty;
    }

    log.info('Creating build request object with build id $buildId');

    final getBuildRequest = bbv2.GetBuildRequest(id: buildId);

    log.info('Calling buildbucket api to get build data for build $buildId');

    final existingBuild = await buildBucketClient.getBuild(getBuildRequest);

    log.info(
      'Got back existing builder with name: ${existingBuild.builder.builder}',
    );

    log.info('Checking for existing task in datastore');
    final existingTask = await datastore.getTaskFromBuildbucketBuild(
      existingBuild,
    );

    late Task taskToInsert;
    if (existingTask != null) {
      log.info('Updating Task from existing Build');
      existingTask.updateFromBuildbucketBuild(existingBuild);
      taskToInsert = existingTask;
    } else {
      log.info('Creating Task from Buildbucket result');
      taskToInsert = await Task.fromBuildbucketBuild(existingBuild, datastore);
    }

    log.info('Inserting Task into the datastore: ${taskToInsert.toString()}');
    await datastore.insert(<Task>[taskToInsert]);
    final firestoreService = await config.createFirestoreService();
    await firestoreService.upsert(firestore.Task.fromDatastore(taskToInsert));

    return Body.forJson(taskToInsert.toString());
  }
}
