// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../model/appengine/commit.dart';
import '../model/appengine/task.dart';
import '../model/firestore/commit_tasks_status.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';

/// Returns [List<String>] of the commit shas that had all passing tests.
///
/// A [CommitStatus] that have all passing tests is used to help the release tooling find commits Flutter infrastructure has validated.
/// In order to qualify as a [CommitStatus] that have all passing tests, the rules are:
/// 1. The [Commit] inside [CommitStatus] had all its tests run (at least those that are not in bringup)
/// 2. all the blocking [Task] in [CommitStatus] should pass
/// A [List<String>] of commit shas of the qualified [CommitStatus]s are returned, in the order of [Commit] timestamp, i.e.,
/// A [Commit] with an earlier timestamp will apprear earlier in the result [List<String>], as compared to another [Commit]
/// with a later timestamp.
///
/// Parameters:
///   branch: defaults to the defaults branch for the repository.
///   repo: default: 'flutter'. Name of the repository.
///
/// GET: /api/public/get-green-commits?repo=$repo

@immutable
class GetGreenCommits extends RequestHandler<Body> {
  const GetGreenCommits({
    required super.config,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusProvider,
  }) : buildStatusProvider =
           buildStatusProvider ?? BuildStatusService.defaultProvider;

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kBranchParam = 'branch';
  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final repoName =
        request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final slug = RepositorySlug('flutter', repoName);
    final branch =
        request!.uri.queryParameters[kBranchParam] ??
        Config.defaultBranch(slug);
    final datastore = datastoreProvider(config.db);
    final firestoreService = await config.createFirestoreService();
    final buildStatusService = buildStatusProvider(datastore, firestoreService);
    final commitNumber = config.commitNumber;

    final greenCommits =
        await buildStatusService
            .retrieveCommitStatusFirestore(
              limit: commitNumber,
              branch: branch,
              slug: slug,
            )
            .where(everyNonFlakyTaskSucceed)
            .map((status) => status.commit.sha)
            .toList();

    return Body.forJson(greenCommits);
  }

  bool everyNonFlakyTaskSucceed(CommitTasksStatus status) {
    return status.tasks
        .where((task) => !task.testFlaky!)
        .every((nonFlakyTask) => nonFlakyTask.status == Task.statusSucceeded);
  }
}
