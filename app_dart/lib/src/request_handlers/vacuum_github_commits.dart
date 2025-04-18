// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as gh;
import 'package:meta/meta.dart';

import '../model/firestore/commit.dart' as fs;
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/config.dart';
import '../service/datastore.dart';
import '../service/github_service.dart';
import '../service/scheduler.dart';

/// Query GitHub for commits from the past day and ensure they exist in datastore.
@immutable
class VacuumGithubCommits extends ApiRequestHandler<Body> {
  const VacuumGithubCommits({
    required super.config,
    required super.authenticationProvider,
    required this.scheduler,
    @visibleForTesting
    this.datastoreProvider = DatastoreService.defaultProvider,
  });

  final DatastoreServiceProvider datastoreProvider;

  final Scheduler scheduler;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    final datastore = datastoreProvider(config.db);

    for (var slug in config.supportedRepos) {
      final branch =
          request!.uri.queryParameters[branchParam] ??
          Config.defaultBranch(slug);
      await _vacuumRepository(slug, datastore: datastore, branch: branch);
    }

    return Body.empty;
  }

  Future<void> _vacuumRepository(
    gh.RepositorySlug slug, {
    DatastoreService? datastore,
    required String branch,
  }) async {
    final githubService = await config.createGithubService(slug);
    final commits = await _vacuumBranch(
      slug,
      branch,
      datastore: datastore,
      githubService: githubService,
    );
    await scheduler.addCommits(commits);
  }

  Future<List<fs.Commit>> _vacuumBranch(
    gh.RepositorySlug slug,
    String branch, {
    DatastoreService? datastore,
    required GithubService githubService,
  }) async {
    var commits = <gh.RepositoryCommit>[];
    // Sliding window of times to add commits from.
    final queryAfter = DateTime.now().subtract(const Duration(days: 1));
    final queryBefore = DateTime.now().subtract(const Duration(minutes: 3));
    try {
      log.debug(
        'Listing commit for slug: $slug branch: $branch and msSinceEpoch: '
        '${queryAfter.millisecondsSinceEpoch}',
      );
      commits = await githubService.listBranchedCommits(
        slug,
        branch,
        queryAfter.millisecondsSinceEpoch,
      );
      log.debug('Retrieved ${commits.length} commits from GitHub');
      // Do not try to add recent commits as they may already be processed
      // by cocoon, which can cause race conditions.
      commits =
          commits
              .where(
                (commit) =>
                    commit.commit!.committer!.date!.millisecondsSinceEpoch <
                    queryBefore.millisecondsSinceEpoch,
              )
              .toList();
    } on gh.GitHubError catch (e) {
      log.error('Failed retriving commits from GitHub', e);
    }

    return [
      for (final commit in commits)
        fs.Commit.fromGithubCommit(commit, slug: slug, branch: branch),
    ];
  }
}
