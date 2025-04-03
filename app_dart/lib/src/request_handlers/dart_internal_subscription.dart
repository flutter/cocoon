// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_server/logging.dart';
import 'package:fixnum/fixnum.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../model/firestore/task.dart' as firestore;
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';

/// Listens for and saves build updates for `dart-internal` builds.
///
/// See [`dart-internal-build-results`](https://console.cloud.google.com/cloudpubsub/topic/detail/dart-internal-build-results?e=-13802955&invt=Abtx1A&mods=logs_tg_prod&project=flutter-dashboard).
@immutable
final class DartInternalSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening for dart-internal build results.
  /// The message should contain a single buildbucket id
  const DartInternalSubscription({
    required super.cache,
    required super.config,
    super.authProvider,
    required BuildBucketClient buildBucketClient,
    @visibleForTesting
    DatastoreService Function(DatastoreDB) datastoreProvider =
        DatastoreService.defaultProvider,
  }) : _datastoreProvider = datastoreProvider,
       _buildBucketClient = buildBucketClient,
       super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketClient _buildBucketClient;
  final DatastoreServiceProvider _datastoreProvider;

  @override
  Future<Body> post() async {
    final datastore = _datastoreProvider(config.db);

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

    // TODO(matanlurey): Replace json[][][] if this ends up being workable.
    // See https://github.com/flutter/flutter/issues/166535.
    try {
      final data = bbv2.BuildsV2PubSub.fromJson(message.data!);
      var mismatch = false;
      if (data.build.builder.project != project) {
        log.debug('[dart_internal_166535] mismatch: project=$project');
        mismatch = true;
      }
      if (data.build.builder.bucket != bucket) {
        log.debug('[dart_internal_166535] mismatch: bucket=$bucket');
        mismatch = true;
      }
      if (data.build.builder.builder != builder) {
        log.debug('[dart_internal_166535] mismatch: builder=$builder');
        mismatch = true;
      }
      if (data.build.id != buildId) {
        log.debug('[dart_internal_166535] mismatch: buildId=$buildId');
        mismatch = true;
      }
      if (mismatch) {
        log.warn(
          '[dart_internal_166535] bbv2.BuildV2PubSub mismatch: ${data.toDebugString()}',
        );
      }
    } catch (e) {
      log.warn('[dart_internal_166535] bbv2.BuildV2PubSub not compatible', e);
    }

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

    final existingBuild = await _buildBucketClient.getBuild(getBuildRequest);

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
    try {
      final firestoreService = await config.createFirestoreService();
      final writes = documentsToWrites([
        firestore.Task.fromDatastore(taskToInsert),
      ]);
      await firestoreService.batchWriteDocuments(
        BatchWriteRequest(writes: writes),
        kDatabase,
      );
    } catch (e) {
      log.warn('Failed to insert dart internal task into firestore', e);
    }

    return Body.forJson(taskToInsert.toString());
  }
}
