// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:retry/retry.dart';
import 'package:truncate/truncate.dart';

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
      id: buildbucketId.toString(),
      fields:
          "id,builder,number,createdBy,createTime,startTime,endTime,updateTime,status,input.properties,input.gitilesCommit",
    );

    log.info(
      "Calling buildbucket api to get build data for build $buildbucketId",
    );
    final Build build = await _getBuildFromBuildbucket(request);

    // This is for handling subbuilds, based on the engine_v2 strategy of running
    // builds under the same builder ({Platform} Engine Drone).
    String? name;
    if (build.input?.properties != null && build.input?.properties?["build"] != null) {
      final Map<String, dynamic> buildProperties = build.input?.properties?["build"] as Map<String, dynamic>;
      name = buildProperties["name"] as String;
    }

    final Key<String> commitKey = Commit.createKeyFromBuildbucketBuild(db: datastore.db, build: build);

    try {
      await Commit.fromDatastore(datastore: datastore, key: commitKey);
      log.fine('Commit found in datastore.');
    } on KeyNotFoundException {
      log.fine('Commit not found in datastore. Creating commit and storing into datastore');
      final Commit commit = await _getCommitFromBuildbucketBuild(build, datastore.db);
      await datastore.insert(<Commit>[commit]);
    }

    log.info("Checking for existing task in datastore");
    final Task? existingTask = await datastore.getTaskByCommitKeyAndName(commitKey, name);

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

  Future<Commit> _getCommitFromBuildbucketBuild(
    Build build,
    DatastoreDB db,
  ) async {
    // Example: "flutter" from "mirrors/flutter".
    final String repository =
        build.input!.gitilesCommit!.project!.split('/')[1];
    // Example: "stable" from "refs/heads/stable".
    final String branch = build.input!.gitilesCommit!.ref!.split('/')[2];
    final String sha = build.input!.gitilesCommit!.hash!;
    final RepositorySlug slug = RepositorySlug("flutter", repository);
    final Key<String> key = db.emptyKey.append(
      Commit,
      id: '${slug.fullName}/$branch/$sha',
    );
    log.fine("Creating github service");
    final GithubService githubService = await config.createDefaultGitHubService();
    log.fine("Obtaining commit for sha $sha");
    final RepositoryCommit commit =
        await githubService.getSingleCommit(slug, sha);
    return Commit(
      key: key,
      timestamp: commit.commit!.committer!.date!.millisecondsSinceEpoch,
      repository: slug.fullName,
      sha: commit.sha!,
      author: commit.author!.login!,
      authorAvatarUrl: commit.author!.avatarUrl!,
      // The field has a size of 1500 we need to ensure the commit message
      // is at most 1500 chars long.
      message: truncate(commit.commit!.message!, 1490, omission: '...'),
      branch: branch,
    );
  }
}
