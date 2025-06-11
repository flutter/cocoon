// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common/is_dart_internal.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server/logging.dart';
import 'package:googleapis/firestore/v1.dart';

import '../../cocoon_service.dart';
import '../model/bbv2_extension.dart';
import '../model/firestore/task.dart' as fs;
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';

/// Listens for and saves build updates for `dart-internal` builds.
///
/// See [`dart-internal-build-results`](https://console.cloud.google.com/cloudpubsub/topic/detail/dart-internal-build-results?e=-13802955&invt=Abtx1A&mods=logs_tg_prod&project=flutter-dashboard).
final class DartInternalSubscription extends SubscriptionHandler {
  /// Creates an endpoint for listening for dart-internal build results.
  /// The message should contain a single buildbucket id
  const DartInternalSubscription({
    required super.cache,
    required super.config,
    required FirestoreService firestore,
    super.authProvider,
  }) : _firestore = firestore,
       super(subscriptionName: 'dart-internal-build-results-sub');

  final FirestoreService _firestore;

  @override
  Future<Response> post(Request request) async {
    final bbv2.Build build;
    try {
      final decoded = json.decode(message.data!);
      final pubSub = bbv2.BuildsV2PubSub()..mergeFromProto3Json(decoded);
      build = pubSub.build;
    } on FormatException catch (e) {
      // If we can't decode this message, it will never complete.
      log.error('Could not decode dart-internal message: $message.data', e);
      throw const BadRequestException('Could not decode dart-internal message');
    }

    if (!isTaskFromDartInternalBuilder(builderName: build.builder.builder)) {
      log.info('Ignoring builder that is not a release builder');
      return Response.emptyOk;
    }

    log.info('Checking for existing task in Firestore');
    final fs.Task fsTask;
    {
      final existing = await _firestore.queryLatestTask(
        commitSha: build.input.gitilesCommit.id,
        builderName: build.builder.builder,
      );
      if (existing != null) {
        log.debug('Existing task found in Firestore: $existing');
        fsTask = existing;
        // Don't increment the task attempt if it's waiting for a build numnber.
        if (fsTask.status != TaskStatus.inProgress ||
            fsTask.buildNumber != build.number) {
          log.debug('Marking as retry and incrementing the task number');
          fsTask.resetAsRetry();
        }
        fsTask.setBuildNumber(build.number);
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
          status: build.status.toTaskStatus(),

          // These are all assumed values.
          bringup: false,
          testFlaky: false,
        );
        log.debug('Creating a new task: $fsTask');
      }
    }

    log.info('Inserting Task into Firestore: ${fsTask.toString()}');
    await _firestore.batchWriteDocuments(
      BatchWriteRequest(writes: documentsToWrites([fsTask])),
      kDatabase,
    );

    return Response.json(fsTask.toString());
  }
}
