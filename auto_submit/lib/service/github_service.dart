// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Retrieves the reviews for a pull request.
  Future<Iterable<PullRequestReview>> getReviews(
    RepositorySlug slug,
    int prNumber,
  ) async {
    return await github.pullRequests.listReviews(slug, prNumber).toList();
  }

  /// Retrieves check runs with the ref.
  Future<Iterable<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.checks.checkRuns.listCheckRunsForRef(slug, ref: ref).toList();
  }

  /// Retrieves the check suites with the ref.
  Future<Iterable<CheckSuite>> getCheckSuites(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.checks.checkSuites.listCheckSuitesForRef(slug, ref: ref).toList();
  }

  /// Retrieves the statuses of a repository at the specified reference.
  Future<Iterable<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.repositories.listStatuses(slug, ref).toList();
  }
}
