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
        .where((CommitStatus status) => status.stages.every((Stage s) => s.taskStatus == Task.statusSucceeded))
        .map<String?>((CommitStatus status) => status.commit.sha)
        .toList();

    return Body.forJson(<String, List<String?>>{
      'greenCommits': greenCommits,
    });
  }
}
