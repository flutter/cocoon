// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';

import '../../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({
    GitHub? client,
    String? reviewsMock,
    String? checkRunsMock,
    String? repositoryStatusesMock,
    String? commitMock,
    String? compareTowCommitsMock,
    String? successMergeMock,
    String? createCommentMock,
  }) : github = client ?? MockGitHub();

  @override
  final GitHub github;

  String? reviewsMock;
  String? checkRunsMock;
  String? repositoryStatusesMock;
  String? commitMock;
  String? compareTowCommitsMock;
  String? successMergeMock;
  String? createCommentMock;

  set reviewsData(String? reviewsMock) {
    this.reviewsMock = reviewsMock;
  }

  set checkRunsData(String? checkRunsMock) {
    this.checkRunsMock = checkRunsMock;
  }

  set repositoryStatusesData(String? repositoryStatusesMock) {
    this.repositoryStatusesMock = repositoryStatusesMock;
  }

  set commitData(String? commitMock) {
    this.commitMock = commitMock;
  }

  set compareTowCommitsData(String? compareTowCommitsMock) {
    this.compareTowCommitsMock = compareTowCommitsMock;
  }

  set successMergeData(String? successMergeMock) {
    this.successMergeMock = successMergeMock;
  }

  set createCommentData(String? createCommentMock) {
    this.createCommentMock = createCommentMock;
  }

  @override
  Future<List<PullRequestReview>> getReviews(RepositorySlug slug, int prNumber) async {
    final List<Map<String, dynamic>> reviewsBody =
        (jsonDecode(reviewsMock!) as List).map((e) => e as Map<String, dynamic>).toList();
    final List<PullRequestReview> prReviews = <PullRequestReview>[];
    for (Map reviewMap in reviewsBody) {
      PullRequestReview review = PullRequestReview(
          id: reviewMap['id'] as int,
          body: reviewMap['body'] as String?,
          state: reviewMap['state'] as String?,
          user: User(id: reviewMap['user']['id'], login: reviewMap['user']['login']))
        ..authorAssociation = reviewMap['author_association'] as String?;
      prReviews.add(review);
    }
    return prReviews;
  }

  @override
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(checkRunsMock!) as Map<String, dynamic>;
    final List<dynamic> checkRunsBody = rawBody["check_runs"]!;
    List<CheckRun> checkRuns = <CheckRun>[];
    if (checkRunsBody[0].isNotEmpty) {
      checkRuns.addAll(checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun)).toList());
    }
    return checkRuns;
  }

  @override
  Future<List<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    final Map<String, dynamic> statusesBody = jsonDecode(repositoryStatusesMock!) as Map<String, dynamic>;
    final List<Map<String, dynamic>> statusesList = List<Map<String, dynamic>>.from(statusesBody['statuses']!);
    List<RepositoryStatus> statuses = <RepositoryStatus>[];
    if (statusesList[0].isNotEmpty) {
      for (Map statusMap in statusesList) {
        RepositoryStatus status = RepositoryStatus(
          state: statusMap['state'] as String?,
          targetUrl: statusMap['target_url'] as String?,
          context: statusMap['context'] as String?,
        );
        statuses.add(status);
      }
    }
    return statuses;
  }

  @override
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    final Map<String, dynamic> commitBody = jsonDecode(commitMock!) as Map<String, dynamic>;
    final RepositoryCommit commit = RepositoryCommit(
        sha: commitBody['sha'] as String?,
        commit: commitBody['commit'] == null
            ? null
            : GitCommit(
                url: commitBody['commit']['url'] as String?,
                message: commitBody['commit']['message'] as String?,
              ));
    return commit;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    final Map<String, dynamic> comparisonBody = jsonDecode(compareTowCommitsMock!) as Map<String, dynamic>;

    final GitHubComparison githubComparison = GitHubComparison(
      comparisonBody['url'] as String?,
      comparisonBody['status'] as String?,
      comparisonBody['ahead_by'] as int?,
      comparisonBody['behind_by'] as int?,
      comparisonBody['total_commits'] as int?,
      (comparisonBody['files'] as List<dynamic>?)
          ?.map((e) => CommitFile(name: e['filename'] as String?, changes: e['changes'] as int?))
          .toList(),
    );
    return githubComparison;
  }

  @override
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return true;
  }

  @override
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody, String sha) async {
    final Map<String, dynamic> commentBody = jsonDecode(createCommentMock!) as Map<String, dynamic>;
    final IssueComment issueComment = IssueComment(
        id: commentBody['id'] as int?,
        body: commentBody['body'] as String?,
        user: commentBody['user'] == null
            ? null
            : User(id: commentBody['user']['id'], login: commentBody['user']['login']));
    return issueComment;
  }
}
