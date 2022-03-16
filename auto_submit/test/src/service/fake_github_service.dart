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
    final List<dynamic> reviews = json.decode(reviewsMock!) as List;
    final List<PullRequestReview> prReviews =
        reviews.map((dynamic review) => PullRequestReview.fromJson(review)).toList();
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
    final rawBody = json.decode(repositoryStatusesMock!) as Map<String, dynamic>;
    final List<dynamic> statusesBody = rawBody["statuses"]!;
    List<RepositoryStatus> statuses = <RepositoryStatus>[];
    if (statusesBody[0].isNotEmpty) {
      statuses.addAll(statusesBody.map((dynamic state) => RepositoryStatus.fromJson(state)).toList());
    }
    return statuses;
  }

  @override
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    final RepositoryCommit commit = RepositoryCommit.fromJson(jsonDecode(commitMock!));
    return commit;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    final GitHubComparison githubComparison = GitHubComparison.fromJson(jsonDecode(compareTowCommitsMock!));
    return githubComparison;
  }

  @override
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return true;
  }

  @override
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody, String sha) async {
    final IssueComment issueComment = IssueComment.fromJson(jsonDecode(createCommentMock!));
    return issueComment;
  }
}
