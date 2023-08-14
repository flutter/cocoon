// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

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
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  }) : super(subscriptionName: 'dart-internal-build-results-sub');

  final BuildBucketClient buildBucketClient;
  final DatastoreServiceProvider datastoreProvider;

  @override
  Future<Body> post() async {
    final DatastoreService datastore = datastoreProvider(config.db);

    if (message.data == null) {
      log.info('no data in message');
      return Body.empty;
    }

    final dynamic buildData = json.decode(message.data!);
    log.info("Build data json: $buildData");

    if (buildData["build"] == null) {
      log.info('no build information in message');
      return Body.empty;
    }

    final String project = buildData['build']['builder']['project'];
    final String bucket = buildData['build']['builder']['bucket'];
    final String builder = buildData['build']['builder']['builder'];

    // This should already be covered by the pubsub filter, but adding an additional check
    // to ensure we don't process builds that aren't from dart-internal/flutter.
    if (project != 'dart-internal' || bucket != 'flutter') {
      log.info("Ignoring build not from dart-internal/flutter bucket");
      return Body.empty;
    }

    // Only publish the parent release_builder builds to the datastore.
    // TODO(drewroengoogle): Determine which builds we want to save to the datastore and check for them.
    final regex = RegExp(r'(Linux|Mac|Windows)\s+(engine_release_builder|packaging_release_builder)');
    if (!regex.hasMatch(builder)) {
      log.info("Ignoring builder that is not a release builder");
      return Body.empty;
    }

    final String buildbucketId = buildData['build']['id'];
    log.info("Creating build request object with build id $buildbucketId");
    final GetBuildRequest request = GetBuildRequest(
      id: buildbucketId,
    );

    log.info(
      "Calling buildbucket api to get build data for build $buildbucketId",
    );
    final Build build = await buildBucketClient.getBuild(request);

    log.info("Checking for existing task in datastore");
    final Task? existingTask = await datastore.getTaskFromBuildbucketBuild(build);

    late Task taskToInsert;
    if (existingTask != null) {
      log.info("Updating Task from existing Task");
      existingTask.updateFromBuildbucketBuild(build);
      taskToInsert = existingTask;
    } else {
      log.info("Getting or creating commit associated with this task");
      final Commit commit = await _getOrCreateCommitForTask(datastore, build);
      log.info("Creating Task from Buildbucket result");
      taskToInsert = await Task.fromBuildbucketBuild(build, datastore, commit: commit);
    }

    log.info("Inserting Task into the datastore: ${taskToInsert.toString()}");
    await datastore.insert(<Task>[taskToInsert]);

    return Body.forJson(taskToInsert.toString());
  }

  Future<Commit> _getOrCreateCommitForTask(DatastoreService datastore, Build build,) async {
    log.info(
        "Gathering commit associated with buildbucket result from the datastore");
    final String repository =
        build.input!.gitilesCommit!.project!.split('/')[1];
    final String branch = build.input!.gitilesCommit!.ref!
        .split('/')[2]; // Example: Pulling "stable" from "refs/heads/stable".
    final String sha = build.input!.gitilesCommit!.hash!;
    final RepositorySlug slug = RepositorySlug("flutter", repository);

    final String id = '${slug.fullName}/$branch/$sha';

    late Commit commit;
    final Key<String> commitKey =
        datastore.db.emptyKey.append<String>(Commit, id: id);
    try {
      commit = await datastore.db.lookupValue<Commit>(commitKey);
    } on KeyNotFoundException {
      log.info(
        "Failed to get commit in candidate branch. Getting commit from the default branch instead.",
      );
      final String defaultBranch = Config.defaultBranch(slug);
      final String defaultBranchId = '${slug.fullName}/$defaultBranch/$sha';
      final Key<String> defaultBranchCommitKey =
          datastore.db.emptyKey.append<String>(Commit, id: defaultBranchId);
      commit = await datastore.db.lookupValue<Commit>(defaultBranchCommitKey);

      log.info(
        "Obtained commit from default branch. Modifying commit branch to $branch and inserting new commit object into datastore.",
      );
      final Commit newCommit = Commit.from(commit);
      newCommit.parentKey = commitKey.parent;
      newCommit.id = commitKey.id;
      newCommit.branch = branch;
      await datastore.insert(<Commit>[newCommit]);
      return newCommit;
    }
    return commit;
  }
}
