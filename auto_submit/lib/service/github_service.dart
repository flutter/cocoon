// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';

/// If a pull request was behind the tip of tree by _kBehindToT commits
/// then the bot tries to rebase it
const int _kBehindToT = 10;

/// [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Retrieves check runs with the ref.
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    return await github.checks.checkRuns.listCheckRunsForRef(slug, ref: ref).toList();
  }

  /// Fetches the specified commit.
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    return await github.repositories.getCommit(slug, sha);
  }

  Future<List<PullRequestFile>> getPullRequestFiles(RepositorySlug slug, PullRequest pullRequest) async {
    final int? pullRequestId = pullRequest.number;
    final List<PullRequestFile> listPullRequestFiles = [];

    if (pullRequestId == null) {
      return listPullRequestFiles;
    }

    Stream<PullRequestFile> pullRequestFiles = github.pullRequests.listFiles(slug, pullRequestId);

    await for (PullRequestFile file in pullRequestFiles) {
      listPullRequestFiles.add(file);
    }

    return listPullRequestFiles;
  }

  /// Create a new issue in github.
  Future<Issue> createIssue({
    required RepositorySlug slug,
    required String title,
    required String body,
    List<String>? labels,
    String? assignee,
    List<String>? assignees,
    String? state,
  }) async {
    IssueRequest issueRequest = IssueRequest(
      title: title,
      body: body,
      labels: labels,
      assignee: assignee,
      assignees: assignees,
      state: state,
    );
    return await github.issues.create(slug, issueRequest);
  }

  /// Fetches the specified pull request.
  Future<PullRequest> getPullRequest(RepositorySlug slug, int pullRequestNumber) async {
    return await github.pullRequests.get(slug, pullRequestNumber);
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
  Future<IssueComment> createComment(
    RepositorySlug slug,
    int issueNumber,
    String body,
  ) async {
    return await github.issues.createComment(slug, issueNumber, body);
  }

  /// Update a pull request branch
  Future<bool> updateBranch(RepositorySlug slug, int number, String headSha) async {
    final response = await github.request('PUT', '/repos/${slug.fullName}/pulls/$number/update-branch',
        body: GitHubJson.encode({'expected_head_sha': headSha}),);
    return response.statusCode == StatusCodes.ACCEPTED;
  }

  /// Automerges a given pull request with HEAD to ensure the commit is not in conflicting state.
  Future<void> autoMergeBranch(PullRequest pullRequest) async {
    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final int prNumber = pullRequest.number!;
    final RepositoryCommit totCommit = await getCommit(slug, 'HEAD');
    final GitHubComparison comparison = await compareTwoCommits(slug, totCommit.sha!, pullRequest.base!.sha!);
    if (comparison.behindBy! >= _kBehindToT) {
      log.info('The current branch behinds by ${comparison.behindBy} commits.');
      final String headSha = pullRequest.head!.sha!;
      await updateBranch(slug, prNumber, headSha);
    }
  }

  /// Compare the filesets of the current pull request and the original pull
  /// request that is being reverted.
  Future<bool> comparePullRequests(RepositorySlug repositorySlug, PullRequest revert, PullRequest current) async {
    List<PullRequestFile> originalPullRequestFiles = await getPullRequestFiles(repositorySlug, revert);
    List<PullRequestFile> currentPullRequestFiles = await getPullRequestFiles(repositorySlug, current);

    return _validateFileSetsAreEqual(originalPullRequestFiles, currentPullRequestFiles);
  }

  /// Validate that each pull request has the same number of files and that the
  /// file names match. This must be the case in order to process the revert.
  bool _validateFileSetsAreEqual(
      List<PullRequestFile> revertPullRequestFiles, List<PullRequestFile> currentPullRequestFiles,) {
    List<String?> revertFileNames = [];
    List<String?> currentFileNames = [];

    for (PullRequestFile element in revertPullRequestFiles) {
      revertFileNames.add(element.filename);
    }
    for (PullRequestFile element in currentPullRequestFiles) {
      currentFileNames.add(element.filename);
    }

    return revertFileNames.toSet().containsAll(currentFileNames) &&
        currentFileNames.toSet().containsAll(revertFileNames);
  }
}
