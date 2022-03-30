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
    RepositorySlug slug,
    int prNumber,
  ) async {
    return await github.pullRequests.listReviews(slug, prNumber).toList();
  }

  /// Retrieves check runs with the ref.
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.checks.checkRuns.listCheckRunsForRef(slug, ref: ref).toList();
  }

  /// Retrieves the statuses of a repository at the specified reference.
  Future<List<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.repositories.listStatuses(slug, ref).toList();
  }

  /// Fetches the specified commit.
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    return await github.repositories.getCommit(slug, sha);
  }

  /// Compares two commits to fetch diff.
  ///
  /// The response will include details on the files that were changed between the two commits.
  /// Relevant APIs: https://docs.github.com/en/rest/reference/commits#compare-two-commits
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    return await github.repositories.compareCommits(slug, refBase, refHead);
  }

  /// Removes a lable for a pull request.
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return await github.issues.removeLabelForIssue(slug, issueNumber, label);
  }

  /// Create a comment for a pull request.
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody, String sha) async {
    CreatePullRequestComment comment = CreatePullRequestComment(commentBody, sha, null, null);
    return await github.pullRequests.createComment(slug, number, comment);
  }

  /// List commits on a pull request.
  Future<List<RepositoryCommit>> listCommits(RepositorySlug slug, int number) async {
    return await github.pullRequests.listCommits(slug, number).toList();
  }
}
