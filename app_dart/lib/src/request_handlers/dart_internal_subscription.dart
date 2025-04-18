// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart' as ds;
import '../model/firestore/task.dart' as fs;
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
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  @override
  Future<Body> post() async {
    final bbv2.Build build;
    {
      final decoded = json.decode(message.data!);
      final pubSub = bbv2.BuildsV2PubSub()..mergeFromProto3Json(decoded);
      build = pubSub.build;
    }

    if (!isTaskFromDartInternalBuilder(builderName: build.builder.builder)) {
      log.info('Ignoring builder that is not a release builder');
      return Body.empty;
    }

    log.info('Checking for existing task in Firestore');
    final firestore = await config.createFirestoreService();
    final fs.Task fsTask;
    {
      final existing = await firestore.queryLatestTask(
        commitSha: build.input.gitilesCommit.id,
        builderName: build.builder.builder,
      );
      if (existing != null) {
        fsTask = existing;
        if (build.number != fsTask.buildNumber) {
          fsTask.resetAsRetry();
          fsTask.setBuildNumber(build.number);
        }
        fsTask.updateFromBuild(build);
      } else {
        fsTask = fs.Task(
          currentAttempt: 1,
          buildNumber: build.number,
          builderName: build.builder.builder,
          createTimestamp: build.createTime.toDateTime().millisecondsSinceEpoch,
          startTimestamp: build.startTime.toDateTime().millisecondsSinceEpoch,
          endTimestamp: build.endTime.toDateTime().millisecondsSinceEpoch,
          commitSha: build.input.gitilesCommit.id,
          status: ds.Task.convertBuildbucketStatusToString(build.status),

          // These are all assumed values.
          bringup: false,
          testFlaky: false,
        );
      }
    }

    log.info('Inserting Task into Firestore: ${fsTask.toString()}');
    await firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites([fsTask])),
      kDatabase,
    );

    await _legacyUpdateDatastoretask(build);

    return Body.forJson(fsTask.toString());
  }

  Future<void> _legacyUpdateDatastoretask(bbv2.Build build) async {
    if (!await config.useLegacyDatastore) {
      return;
    }

    log.info('Checking for existing task in Datastore');
    final datastore = DatastoreService.defaultProvider(config.db);
    final existingTask = await datastore.getTaskFromBuildbucketBuild(build);

    final ds.Task taskToInsert;
    if (existingTask != null) {
      log.info('Updating Task from existing Build');
      existingTask.updateFromBuildbucketBuild(build);
      taskToInsert = existingTask;
    } else {
      log.info('Creating Task from Buildbucket result');
      taskToInsert = await ds.Task.fromBuildbucketBuild(build, datastore);
    }

    await datastore.insert([taskToInsert]);
  }
}
