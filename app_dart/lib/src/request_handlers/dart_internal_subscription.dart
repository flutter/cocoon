// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/task.dart';
import '../model/appengine/commit.dart';
import '../request_handling/exceptions.dart';
import '../request_handling/subscription_handler.dart';
import '../service/datastore.dart';
import '../service/logging.dart';

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
    final DatastoreService datastore = datastoreProvider(config.db);

    log.info("Converting message data to non nullable int");

    final int buildbucketId = int.parse(message.data.toString().replaceAll("'", ""));

    log.info("Creating build request object");
    final GetBuildRequest request = GetBuildRequest(id: buildbucketId.toString());

    log.info(
      "Calling buildbucket api to get build data for build $buildbucketId",
    );
    late Build build;
    try {
      build = await buildBucketClient.getBuild(request);
    } catch (e) {
      log.severe(
        "Failed to get build data for build $buildbucketId with the exception: ${e.toString()}",
      );
      throw InternalServerError(
        'Failed to get build number $buildbucketId from Buildbucket. Error: $e',
      );
    }

    log.info("Creating Task from Buildbucket result");
    final Task task = await _createTaskFromBuildbucketResult(build, datastore);

    log.fine(task.toString());
    log.info("Inserting Task into the datastore");
    // TODO(drewroengoogle): Uncomment this once we are completely
    // ready to publish the task into the datastore.
    // await datastore.insert(<Task>[task]);

    return Body.forJson(task.toString());
  }

  Future<Task> _createTaskFromBuildbucketResult(
    Build build,
    DatastoreService datastore,
  ) async {
    final String repository =
        build.input!.gitilesCommit!.project!.split('/')[1];
    final String branch = build.input!.gitilesCommit!.ref!.split('/')[2];
    final String hash = build.input!.gitilesCommit!.hash!;
    final RepositorySlug slug = RepositorySlug("flutter", repository);
    final Key<String> key = Commit.createKey(
      db: datastore.db,
      slug: slug,
      gitBranch: branch,
      sha: hash,
    );

    final String id = 'flutter/${slug.name}/$branch/$hash';
    final Key<String> commitKey =
        datastore.db.emptyKey.append<String>(Commit, id: id);
    final Commit commit = await config.db.lookupValue<Commit>(commitKey);
    final task = Task(
      buildNumber: build.number,
      buildNumberList: build.number.toString(),
      builderName: build.builderId.builder,
      commitKey: key,
      createTimestamp: build.startTime!.millisecondsSinceEpoch,
      endTimestamp: build.endTime!.millisecondsSinceEpoch,
      luciBucket: build.builderId.bucket,
      name: build.builderId.builder,
      stageName: "dart-internal",
      startTimestamp: build.startTime!.millisecondsSinceEpoch,
      status: _convertStatusToString(build.status!),
      key: commit.key.append(Task),
    );
    return task;
  }

  String _convertStatusToString(Status status) {
    switch (status) {
      case Status.success:
        return Task.statusSucceeded;
      case Status.canceled:
        return Task.statusCancelled;
      case Status.infraFailure:
        return Task.statusInfraFailure;
      default:
        return Task.statusFailed;
    }
  }
}
