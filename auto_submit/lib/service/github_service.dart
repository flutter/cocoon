// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
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

  /// Fetches the specified commit.
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    return github.repositories.getCommit(slug, sha);
  }

  Future<List<PullRequestFile>> getPullRequestFiles(RepositorySlug slug, PullRequest pullRequest) async {
    final int? pullRequestId = pullRequest.number;
    final List<PullRequestFile> listPullRequestFiles = [];

    if (pullRequestId == null) {
      return listPullRequestFiles;
    }

    final Stream<PullRequestFile> pullRequestFiles = github.pullRequests.listFiles(slug, pullRequestId);

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
    final IssueRequest issueRequest = IssueRequest(
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
  Future<PullRequest> createPullRequest(
      {required RepositorySlug slug,
      String? title,
      String? head,
      required String base,
      bool draft = false,
      String? body,}) async {
    final CreatePullRequest createPullRequest = CreatePullRequest(title, head, base, draft: draft, body: body);
    return github.pullRequests.create(slug, createPullRequest);
  }

  /// Fetches the specified pull request.
  Future<PullRequest> getPullRequest(RepositorySlug slug, int pullRequestNumber) async {
    return github.pullRequests.get(slug, pullRequestNumber);
  }

  Future<List<PullRequest>> listPullRequests(RepositorySlug slug,
      {int? pages,
      String? base,
      String direction = 'desc',
      String? head,
      String sort = 'created',
      String state = 'open'}) async {
    final List<PullRequest> pullRequestsFound = [];
    final Stream<PullRequest> pullRequestStream = github.pullRequests.list(
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

  /// Compares two commits to fetch diff.
  ///
  /// The response will include details on the files that were changed between the two commits.
  /// Relevant APIs: https://docs.github.com/en/rest/reference/commits#compare-two-commits
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    return github.repositories.compareCommits(slug, refBase, refHead);
  }

  /// Removes a label from a pull request.
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return github.issues.removeLabelForIssue(slug, issueNumber, label);
  }

  /// Add labels to a pull request.
  Future<List<IssueLabel>> addLabels(RepositorySlug slug, int issueNumber, List<String> labels) async {
    return github.issues.addLabelsToIssue(slug, issueNumber, labels);
  }

  /// Create a comment for a pull request.
  Future<IssueComment> createComment(
    RepositorySlug slug,
    int issueNumber,
    String body,
  ) async {
    return github.issues.createComment(slug, issueNumber, body);
  }

  /// Update a pull request branch
  Future<bool> updateBranch(RepositorySlug slug, int number, String headSha) async {
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
    final RepositorySlug slug = pullRequest.base!.repo!.slug();
    final int prNumber = pullRequest.number!;
    final RepositoryCommit totCommit = await getCommit(slug, 'HEAD');
    final GitHubComparison comparison = await compareTwoCommits(slug, totCommit.sha!, pullRequest.base!.sha!);
    if (comparison.behindBy! >= _kBehindToT) {
      log.info('The current branch is behind by ${comparison.behindBy} commits.');
      final String headSha = pullRequest.head!.sha!;
      await updateBranch(slug, prNumber, headSha);
    }
  }

  /// Get contents from a repository at the supplied path.
  Future<String> getFileContents(RepositorySlug slug, String path, {String? ref}) async {
    final RepositoryContents repositoryContents = await github.repositories.getContents(slug, path, ref: ref);
    if (!repositoryContents.isFile) {
      throw 'Contents do not point to a file.';
    }
    final String content = utf8.decode(base64.decode(repositoryContents.file!.content!.replaceAll('\n', '')));
    return content;
  }

  /// Check to see if user is a member of team in org.
  ///
  /// Note that we catch here as the api returns a 404 if the user has no
  /// membership in general or is not a member of the team.
  Future<bool> isTeamMember(String team, String user, String org) async {
    try {
      final TeamMembershipState teamMembershipState =
          await github.organizations.getTeamMembershipByName(org, team, user);
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
    final Repository repository = await getRepository(slug);
    return repository.defaultBranch;
  }

  /// Compare the filesets of the current pull request and the original pull
  /// request that is being reverted.
  Future<bool> comparePullRequests(RepositorySlug repositorySlug, PullRequest revert, PullRequest current) async {
    final List<PullRequestFile> originalPullRequestFiles = await getPullRequestFiles(repositorySlug, revert);
    final List<PullRequestFile> currentPullRequestFiles = await getPullRequestFiles(repositorySlug, current);

    return validateFileSetsAreEqual(originalPullRequestFiles, currentPullRequestFiles);
  }

  /// Validate that each pull request has the same number of files and that the
  /// file names match. This must be the case in order to process the revert.
  bool validateFileSetsAreEqual(
    List<PullRequestFile> revertRequestFileList,
    List<PullRequestFile> originalRequestFileList,
  ) {
    if (revertRequestFileList.length != originalRequestFileList.length) {
      return false;
    }

    final List<String?> revertFileNames = [];
    final List<String?> originalFileNames = [];

    for (PullRequestFile element in revertRequestFileList) {
      revertFileNames.add(element.filename);
    }
    for (PullRequestFile element in originalRequestFileList) {
      originalFileNames.add(element.filename);
    }

    // At this point we know the file lists have the same amount of files but not the same files.
    if (!revertFileNames.toSet().containsAll(originalFileNames) ||
        !originalFileNames.toSet().containsAll(revertFileNames)) {
      return false;
    }

    // At this point all the files are the same so we can iterate over one list to
    // compare changes.
    for (PullRequestFile revertRequestFile in revertRequestFileList) {
      final PullRequestFile originalRequestFile =
          originalRequestFileList.firstWhere((element) => element.filename == revertRequestFile.filename);
      if (revertRequestFile.changesCount != originalRequestFile.changesCount ||
          revertRequestFile.additionsCount != originalRequestFile.deletionsCount ||
          revertRequestFile.deletionsCount != originalRequestFile.additionsCount) {
        return false;
      }
    }

    return true;
  }
}
