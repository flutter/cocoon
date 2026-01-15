// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart' as gh;
import 'package:meta/meta.dart';

import '../model/firestore/commit.dart' as fs;
import '../request_handling/api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import '../service/scheduler.dart';

/// Ensures Github commits from the past day exist in Firestore.
@immutable
final class VacuumGithubCommits extends ApiRequestHandler {
  const VacuumGithubCommits({
    required super.config,
    required super.authenticationProvider,
    required Scheduler scheduler,
  }) : _scheduler = scheduler;

  final Scheduler _scheduler;

  static const _paramRepo = 'repo';
  static const _paramBranch = 'branch';

  @override
  Future<Response> get(Request request) async {
    final Iterable<gh.RepositorySlug> repos;
    if (request.uri.queryParameters[_paramRepo] case final specific?) {
      repos = [gh.RepositorySlug.full(specific)];
    } else {
      repos = config.supportedRepos;
    }

    final String? branch;
    if (request.uri.queryParameters[_paramBranch] case final specific?) {
      branch = specific;
    } else {
      branch = null;
    }

    for (final slug in repos) {
      await _vacuumRepository(
        slug,
        branch: branch ?? Config.defaultBranch(slug),
      );
    }

    return Response.emptyOk;
  }

  Future<void> _vacuumRepository(
    gh.RepositorySlug slug, {
    required String branch,
  }) async {
    final githubService = await config.createGithubService(slug);
    final commits = await _vacuumBranch(
      slug,
      branch,
      githubService: githubService,
    );
    await _scheduler.addCommits(commits);
  }

  Future<List<fs.Commit>> _vacuumBranch(
    gh.RepositorySlug slug,
    String branch, {
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

      try {
        commits = await githubService.listBranchedCommits(
          slug,
          branch,
          queryAfter.millisecondsSinceEpoch,
        );
      } catch (e) {
        log.error('Failed retrieving commits from githubService', e);

        final gh = config.createGitHubClientWithToken(
          await config.githubOAuthToken,
        );
        commits = await gh.repositories
            .listCommits(
              slug,
              sha: branch,
              since: queryAfter,
              until: queryBefore,
            )
            .toList();
      }
      log.debug('Retrieved ${commits.length} commits from GitHub');
      // Do not try to add recent commits as they may already be processed
      // by cocoon, which can cause race conditions.
      commits = commits
          .where(
            (commit) =>
                commit.commit!.committer!.date!.millisecondsSinceEpoch <
                queryBefore.millisecondsSinceEpoch,
          )
          .toList();
    } on gh.GitHubError catch (e) {
      log.error('Failed retrieving commits from GitHub', e);
    }

    return [
      for (final commit in commits)
        fs.Commit.fromGithubCommit(commit, slug: slug, branch: branch),
    ];
  }
}
