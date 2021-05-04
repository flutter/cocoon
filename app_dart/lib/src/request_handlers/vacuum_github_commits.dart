// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:truncate/truncate.dart';

import '../model/appengine/commit.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';
import '../service/scheduler.dart';

/// Query GitHub for commits from the past day and ensure they exist in datastore.
@immutable
class VacuumGithubCommits extends ApiRequestHandler<Body> {
  const VacuumGithubCommits(
    Config config,
    AuthenticationProvider authenticationProvider, {
    @required this.scheduler,
    @visibleForTesting this.datastoreProvider = DatastoreService.defaultProvider,
  })  : assert(datastoreProvider != null),
        super(config: config, authenticationProvider: authenticationProvider);

  final DatastoreServiceProvider datastoreProvider;

  final Scheduler scheduler;

  @override
  Future<Body> get() async {
    final DatastoreService datastore = datastoreProvider(config.db);
    scheduler.setLogger(log);

    for (RepositorySlug slug in Config.schedulerSupportedRepos) {
      await _vacuumRepository(slug, datastore: datastore);
    }

    return Body.empty;
  }

  Future<void> _vacuumRepository(RepositorySlug slug, {DatastoreService datastore}) async {
    final GithubService githubService = await config.createGithubService(slug);
    for (String branch in await config.getSupportedBranches(slug)) {
      final List<Commit> commits =
          await _vacuumBranch(slug, branch, datastore: datastore, githubService: githubService);
      await scheduler.addCommits(commits);
    }
  }

  Future<List<Commit>> _vacuumBranch(
    RepositorySlug slug,
    String branch, {
    DatastoreService datastore,
    GithubService githubService,
  }) async {
    List<RepositoryCommit> commits;
    // Sliding window of times to add commits from.
    final DateTime queryAfter = DateTime.now().subtract(const Duration(days: 1));
    final DateTime queryBefore = DateTime.now().subtract(const Duration(minutes: 3));
    try {
      commits = await githubService.listCommits(slug, branch, queryAfter.millisecondsSinceEpoch);
      log.debug('Retrieved ${commits.length} commits from GitHub');
      // Do not try to add recent commits as they may already be processed
      // by cocoon, which can cause race conditions.
      commits = commits
          .where((RepositoryCommit commit) =>
              commit.commit.committer.date.millisecondsSinceEpoch < queryBefore.millisecondsSinceEpoch)
          .toList();
    } on GitHubError catch (error) {
      log.error('$error');
    }

    // For release branches, only look at the latest commit.
    if (branch != config.defaultBranch && commits.isNotEmpty) {
      commits = <RepositoryCommit>[commits.last];
    }

    return _toDatastoreCommit(slug, commits, datastore, branch);
  }

  /// Convert [RepositoryCommit] to Cocoon's [Commit] format.
  Future<List<Commit>> _toDatastoreCommit(
      RepositorySlug slug, List<RepositoryCommit> commits, DatastoreService datastore, String branch) async {
    final List<Commit> recentCommits = <Commit>[];
    for (RepositoryCommit commit in commits) {
      final String id = '${slug.fullName}/$branch/${commit.sha}';
      final Key<String> key = datastore.db.emptyKey.append<String>(Commit, id: id);
      recentCommits.add(Commit(
        key: key,
        timestamp: commit.commit.committer.date.millisecondsSinceEpoch,
        repository: slug.fullName,
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
