// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// The [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Gets a pull request with the pr number
  Future<PullRequest> getPullRequest(
    RepositorySlug slug, {
    required int prNumber,
  }) {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(prNumber);
    PullRequestsService pr = github.pullRequests;
    return pr.get(slug, prNumber);
  }

  /// Retrieves check runs with the ref.
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug, {
    required String ref,
    String? checkName,
    CheckRunStatus? status,
    CheckRunFilter? filter,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(ref);
    return await github.checks.checkRuns
        .listCheckRunsForRef(slug, ref: ref)
        .toList();
  }

  /// Retrieves the check suites with the ref.
  Future<List<CheckSuite>> listCheckSuites(
    RepositorySlug slug, {
    required String ref,
    int? appId,
    String? checkName,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(ref);
    return await github.checks.checkSuites
        .listCheckSuitesForRef(slug, ref: ref)
        .toList();
  }

  /// Retrieves the reviews for a pull request.
  Future<List<PullRequestReview>> getReviews(
    RepositorySlug slug, {
    required int prNumber,
  }) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(prNumber);
    return await github.pullRequests.listReviews(slug, prNumber).toList();
  }

  /// Retrieves the statuses of a repository at the specified reference.
  Future<List<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(ref);
    return await github.repositories.listStatuses(slug, ref).toList();
  }

  /// Fetches the specified commit.
  Future<RepositoryCommit> getRepoCommit(
      RepositorySlug slug, String sha) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(sha);
    return await github.repositories.getCommit(slug, sha);
  }

  /// Compares two commits
  Future<GitHubComparison> compareTwoCommits(
      RepositorySlug slug, String refBase, String refHead) async {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(refBase);
    ArgumentError.checkNotNull(refHead);
    return await github.repositories.compareCommits(slug, refBase, refHead);
  }
}
