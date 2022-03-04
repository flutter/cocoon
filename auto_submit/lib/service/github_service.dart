// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Retrieves the reviews for a pull request.
  Future<List<PullRequestReview>> getReviews(
    RepositorySlug slug, {
    required int prNumber,
  }) async {
    return await github.pullRequests.listReviews(slug, prNumber).toList();
  }

  /// Retrieves check runs with the ref.
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug, {
    required String ref,
    String? checkName,
    CheckRunStatus? status,
    CheckRunFilter? filter,
  }) async {
    return await github.checks.checkRuns.listCheckRunsForRef(slug, ref: ref).toList();
  }

  /// Retrieves the check suites with the ref.
  Future<List<CheckSuite>> getCheckSuites(
    RepositorySlug slug, {
    required String ref,
    int? appId,
    String? checkName,
  }) async {
    return await github.checks.checkSuites.listCheckSuitesForRef(slug, ref: ref).toList();
  }

  /// Retrieves the statuses of a repository at the specified reference.
  Future<List<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.repositories.listStatuses(slug, ref).toList();
  }
}
