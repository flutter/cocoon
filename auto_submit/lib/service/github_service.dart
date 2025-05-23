// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';

/// If a pull request was behind the tip of tree by _kBehindToT commits
/// then the bot tries to rebase it
const int _kBehindToT = 10;

/// [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Retrieves check runs with the ref.
  Future<List<CheckRun>> getCheckRuns(RepositorySlug slug, String ref) async {
    return github.checks.checkRuns.listCheckRunsForRef(slug, ref: ref).toList();
  }

  Future<List<CheckRun>> getCheckRunsFiltered({
    required RepositorySlug slug,
    required String ref,
    String? checkName,
    CheckRunStatus? status,
    CheckRunFilter? filter,
  }) async {
    return github.checks.checkRuns
        .listCheckRunsForRef(
          slug,
          ref: ref,
          checkName: checkName,
          status: status,
          filter: filter,
        )
        .toList();
  }

  Future<CheckRun> updateCheckRun({
    required RepositorySlug slug,
    required CheckRun checkRun,
    String? name,
    String? detailsUrl,
    String? externalId,
    DateTime? startedAt,
    CheckRunStatus status = CheckRunStatus.queued,
    CheckRunConclusion? conclusion,
    DateTime? completedAt,
    CheckRunOutput? output,
    List<CheckRunAction>? actions,
  }) async {
    return github.checks.checkRuns.updateCheckRun(
      slug,
      checkRun,
      name: name,
      detailsUrl: detailsUrl,
      externalId: externalId,
      startedAt: startedAt,
      status: status,
      conclusion: conclusion,
      completedAt: completedAt,
      output: output,
      actions: actions,
    );
  }

  /// Fetches the specified commit.
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    return github.repositories.getCommit(slug, sha);
  }

  Future<List<PullRequestFile>> getPullRequestFiles(
    RepositorySlug slug,
    PullRequest pullRequest,
  ) async {
    final pullRequestId = pullRequest.number;
    final listPullRequestFiles = <PullRequestFile>[];

    if (pullRequestId == null) {
      return listPullRequestFiles;
    }

    final pullRequestFiles = github.pullRequests.listFiles(slug, pullRequestId);

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
    final issueRequest = IssueRequest(
      title: title,
      body: body,
      labels: labels,
      assignee: assignee,
      assignees: assignees,
      state: state,
    );
    return github.issues.create(slug, issueRequest);
  }

  Future<Issue> getIssue({
    required RepositorySlug slug,
    required int issueNumber,
  }) async {
    return github.issues.get(slug, issueNumber);
  }

  /// Create a pull request.
  Future<PullRequest> createPullRequest({
    required RepositorySlug slug,
    String? title,
    String? head,
    required String base,
    bool draft = false,
    String? body,
  }) async {
    final createPullRequest = CreatePullRequest(
      title,
      head,
      base,
      draft: draft,
      body: body,
    );
    return github.pullRequests.create(slug, createPullRequest);
  }

  /// Fetches the specified pull request.
  Future<PullRequest> getPullRequest(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    return github.pullRequests.get(slug, pullRequestNumber);
  }

  Future<List<PullRequest>> listPullRequests(
    RepositorySlug slug, {
    int? pages,
    String? base,
    String direction = 'desc',
    String? head,
    String sort = 'created',
    String state = 'open',
  }) async {
    final pullRequestsFound = <PullRequest>[];
    final pullRequestStream = github.pullRequests.list(
      slug,
      pages: pages,
      direction: direction,
      head: head,
      sort: sort,
      state: state,
    );
    await for (PullRequest pullRequest in pullRequestStream) {
      pullRequestsFound.add(pullRequest);
    }
    return pullRequestsFound;
  }

  Future<bool> addReviewersToPullRequest(
    RepositorySlug slug,
    int pullRequestNumber,
    List<String> reviewerLogins,
  ) async {
    final response = await github.request(
      'POST',
      '/repos/${slug.fullName}/pulls/$pullRequestNumber/requested_reviewers',
      body: GitHubJson.encode({'reviewers': reviewerLogins}),
    );
    return response.statusCode == StatusCodes.CREATED;
  }

  /// Get the reviews for Pull Request with number pullRequestNumber.
  Future<List<PullRequestReview>> getPullRequestReviews(
    RepositorySlug slug,
    int pullRequestNumber,
  ) async {
    return github.pullRequests.listReviews(slug, pullRequestNumber).toList();
  }

  /// Compares two commits to fetch diff.
  ///
  /// The response will include details on the files that were changed between the two commits.
  /// Relevant APIs: https://docs.github.com/en/rest/reference/commits#compare-two-commits
  Future<GitHubComparison> compareTwoCommits(
    RepositorySlug slug,
    String refBase,
    String refHead,
  ) async {
    return github.repositories.compareCommits(slug, refBase, refHead);
  }

  /// Removes a label from a pull request.
  Future<bool> removeLabel(
    RepositorySlug slug,
    int issueNumber,
    String label,
  ) async {
    return github.issues.removeLabelForIssue(slug, issueNumber, label);
  }

  /// Add labels to a pull request.
  Future<List<IssueLabel>> addLabels(
    RepositorySlug slug,
    int issueNumber,
    List<String> labels,
  ) async {
    return github.issues.addLabelsToIssue(slug, issueNumber, labels);
  }

  /// Relevant API: https://docs.github.com/en/rest/issues/assignees?apiVersion=2022-11-28#add-assignees-to-an-issue
  Future<bool> addAssignee(
    RepositorySlug slug,
    int number,
    List<String> assignees,
  ) async {
    final response = await github.request(
      'POST',
      '/repos/${slug.fullName}/issues/$number/assignees',
      body: GitHubJson.encode({'assignees': assignees}),
    );
    return response.statusCode == StatusCodes.CREATED;
  }

  /// Create a comment for a pull request.
  Future<IssueComment> createComment(
    RepositorySlug slug,
    int issueNumber,
    String body,
  ) async {
    return github.issues.createComment(slug, issueNumber, body);
  }

  Future<List<IssueComment>> getIssueComments(
    RepositorySlug slug,
    int issueNumber,
  ) async {
    return github.issues.listCommentsByIssue(slug, issueNumber).toList();
  }

  /// Update a pull request branch
  Future<bool> updateBranch(
    RepositorySlug slug,
    int number,
    String headSha,
  ) async {
    final response = await github.request(
      'PUT',
      '/repos/${slug.fullName}/pulls/$number/update-branch',
      body: GitHubJson.encode({'expected_head_sha': headSha}),
    );
    return response.statusCode == StatusCodes.ACCEPTED;
  }

  Future<Branch> getBranch(RepositorySlug slug, String branchName) async {
    return github.repositories.getBranch(slug, branchName);
  }

  Future<bool> deleteBranch(RepositorySlug slug, String branchName) async {
    final ref = 'heads/$branchName';
    return github.git.deleteReference(slug, ref);
  }

  /// Merges a pull request according to the MergeMethod type. Current supported
  /// merge method types are merge, rebase and squash.
  Future<PullRequestMerge> mergePullRequest(
    RepositorySlug slug,
    int number, {
    String? commitMessage,
    MergeMethod mergeMethod = MergeMethod.merge,
    String? requestSha,
  }) async {
    return github.pullRequests.merge(
      slug,
      number,
      message: commitMessage,
      mergeMethod: mergeMethod,
      requestSha: requestSha,
    );
  }

  /// Automerges a given pull request with HEAD to ensure the commit is not in conflicting state.
  Future<void> autoMergeBranch(PullRequest pullRequest) async {
    final slug = pullRequest.base!.repo!.slug();
    final prNumber = pullRequest.number!;
    final totCommit = await getCommit(slug, 'HEAD');
    final comparison = await compareTwoCommits(
      slug,
      totCommit.sha!,
      pullRequest.base!.sha!,
    );
    if (comparison.behindBy! >= _kBehindToT) {
      log.info(
        'The current branch is behind by ${comparison.behindBy} commits.',
      );
      final headSha = pullRequest.head!.sha!;
      await updateBranch(slug, prNumber, headSha);
    }
  }

  /// Get contents from a repository at the supplied path.
  Future<String> getFileContents(
    RepositorySlug slug,
    String path, {
    String? ref,
  }) async {
    final repositoryContents = await github.repositories.getContents(
      slug,
      path,
      ref: ref,
    );
    if (!repositoryContents.isFile) {
      throw 'Contents do not point to a file.';
    }
    final content = utf8.decode(
      base64.decode(repositoryContents.file!.content!.replaceAll('\n', '')),
    );
    return content;
  }

  /// Check to see if user is a member of team in org.
  ///
  /// Note that we catch here as the api returns a 404 if the user has no
  /// membership in general or is not a member of the team.
  Future<bool> isTeamMember(String team, String user, String org) async {
    try {
      final teamMembershipState = await github.organizations
          .getTeamMembershipByName(org, team, user);
      return teamMembershipState.isActive;
    } on GitHubError {
      return false;
    }
  }

  /// Get the definition of a single repository
  Future<Repository> getRepository(RepositorySlug slug) async {
    return github.repositories.getRepository(slug);
  }

  Future<String> getDefaultBranch(RepositorySlug slug) async {
    final repository = await getRepository(slug);
    return repository.defaultBranch;
  }
}
