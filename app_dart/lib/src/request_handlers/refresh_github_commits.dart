// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';

import '../datastore/cocoon_config.dart';
import '../foundation/providers.dart';
import '../foundation/typedefs.dart';
import '../foundation/utils.dart';
import '../model/appengine/commit.dart';
import '../model/devicelab/manifest.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';
import '../service/scheduler.dart';

/// Queries GitHub for the list of recent commits according to different branches,
/// and creates corresponding rows in the cloud datastore and the BigQuery for any commits
///  not yet there. Then creates new task rows in the datastore for any commits that
/// were added. The task rows that it creates are driven by the Flutter [Manifest].
@immutable
class RefreshGithubCommits extends ApiRequestHandler<Body> {
  const RefreshGithubCommits(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
    @visibleForTesting this.httpClientProvider = Providers.freshHttpClient,
    @visibleForTesting this.gitHubBackoffCalculator = twoSecondLinearBackoff,
  })  : assert(datastoreProvider != null),
        assert(httpClientProvider != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;
  final GitHubBackoffCalculator gitHubBackoffCalculator;
  final HttpClientProvider httpClientProvider;

  @override
  Future<Body> get() async {
    final RepositorySlug slug = RepositorySlug('flutter', 'flutter');
    final GithubService githubService = await config.createGithubService(slug.owner, slug.name);
    final DatastoreService datastore = datastoreProvider(config.db);

    final Scheduler scheduler = Scheduler(
        config: config,
        datastore: datastore,
        httpClient: httpClientProvider(),
        gitHubBackoffCalculator: gitHubBackoffCalculator,
        log: log);

    for (String branch in await config.flutterBranches) {
      final List<Commit> lastProcessedCommit = await datastore.queryRecentCommits(limit: 1, branch: branch).toList();

      /// That [lastCommitTimestampMills] equals 0 means a new release branch is detected.
      int lastCommitTimestampMills = 0;
      if (lastProcessedCommit.isNotEmpty) {
        lastCommitTimestampMills = lastProcessedCommit[0].timestamp;
      }

      List<RepositoryCommit> commits;
      try {
        commits = await githubService.listCommits(slug, branch, lastCommitTimestampMills);
      } on GitHubError catch (error) {
        log.error('$error');
        continue;
      }

      final List<Commit> recentCommits = await _getRecentCommits(commits, datastore, branch);
      await scheduler.addCommits(recentCommits);
    }
    return Body.empty;
  }

  Future<List<Commit>> _getRecentCommits(
      List<RepositoryCommit> commits, DatastoreService datastore, String branch) async {
    final List<Commit> recentCommits = <Commit>[];
    for (RepositoryCommit commit in commits) {
      final String id = 'flutter/flutter/$branch/${commit.sha}';
      final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
      recentCommits.add(Commit(
        key: key,
        timestamp: commit.commit.committer.date.millisecondsSinceEpoch,
        repository: 'flutter/flutter',
        sha: commit.sha,
        author: commit.author.login,
        authorAvatarUrl: commit.author.avatarUrl,
        // The field has a size of 1500 we need to ensure the commit message
        // is at most 1500 chars long.
        message: truncate(commit.commit.message, 1490, omission: '...'),
        branch: branch,
      ));
    }
    return recentCommits;
  }
}
