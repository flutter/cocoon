// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/model/appengine/stage.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';
import '../service/build_status_provider.dart';
import '../service/config.dart';
import '../service/datastore.dart';

/// Returns a list of the commit shas that had green runs.
///
/// A green commit is used to help the release tooling find commits Flutter infrastructure has validated. The rules are:
/// 1. A commit had all its tests run (at least those that are not in bringup)
/// 2. All those blocking tasks were green
/// Green commit shas are returned in the order of commit timestamp.
///
/// Parameters:
///   repo: default: 'flutter'. Name of the repository.
///
/// GET: /api/public/get-green-commits?repo=$repo
///
/// Response: Status: 200 OK
/// {
///   "greenCommits":[
///     "d5b0b3c8d1c5fd89302089077ccabbcfaae045e4",
///     "ea28a9c34dc701de891eaf74503ca4717019f829"
///   ]
/// }
///
@immutable
class GetGreenCommits extends RequestHandler<Body> {
  const GetGreenCommits(
    Config config, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting BuildStatusServiceProvider? buildStatusProvider,
  })  : buildStatusProvider = buildStatusProvider ?? BuildStatusService.defaultProvider,
        super(config: config);

  final DatastoreServiceProvider datastoreProvider;
  final BuildStatusServiceProvider buildStatusProvider;

  static const String kRepoParam = 'repo';

  @override
  Future<Body> get() async {
    final String repoName = request!.uri.queryParameters[kRepoParam] ?? Config.flutterSlug.name;
    final RepositorySlug slug = RepositorySlug('flutter', repoName);
    final String branch = Config.defaultBranch(slug);
    final DatastoreService datastore = datastoreProvider(config.db);
    final BuildStatusService buildStatusService = buildStatusProvider(datastore);
    final int commitNumber = config.commitNumber;
    final int lastCommitTimestamp = DateTime.now().millisecondsSinceEpoch;

    final List<String?> greenCommits = await buildStatusService
        .retrieveCommitStatus(
          limit: commitNumber,
          timestamp: lastCommitTimestamp,
          branch: branch,
          slug: slug,
        )
        .where((CommitStatus status) => everyNonFlakyTaskSucceed(status))
        .map<String?>((CommitStatus status) => status.commit.sha)
        .toList();

    return Body.forJson(<String, List<String?>>{
      'greenCommits': greenCommits,
    });
  }

  bool everyNonFlakyTaskSucceed(CommitStatus status) {
    return status.stages.every((Stage stage) => stage.tasks
        .where((Task task) => !task.isFlaky!)
        .every((Task nonFlakyTask) => nonFlakyTask.status == Task.statusSucceeded));
  }
}
