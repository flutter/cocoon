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
    String? checkRunsMock,
    String? commitMock,
    String? compareTwoCommitsMock,
    String? successMergeMock,
    String? createCommentMock,
    String? pullRequestMergeMock,
  }) : github = client ?? MockGitHub();

  @override
  final GitHub github;

  String? checkRunsMock;
  String? commitMock;
  String? compareTwoCommitsMock;
  String? successMergeMock;
  String? createCommentMock;
  String? pullRequestMergeMock;

  set checkRunsData(String? checkRunsMock) {
    this.checkRunsMock = checkRunsMock;
  }

  set commitData(String? commitMock) {
    this.commitMock = commitMock;
  }

  set compareTwoCommitsData(String? compareTwoCommitsMock) {
    this.compareTwoCommitsMock = compareTwoCommitsMock;
  }

  set successMergeData(String? successMergeMock) {
    this.successMergeMock = successMergeMock;
  }

  set createCommentData(String? createCommentMock) {
    this.createCommentMock = createCommentMock;
  }

  set pullRequestMergeData(String? pullRequestMergeMock) {
    this.pullRequestMergeMock = pullRequestMergeMock;
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
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    final RepositoryCommit commit = RepositoryCommit.fromJson(jsonDecode(commitMock!));
    return commit;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    final GitHubComparison githubComparison = GitHubComparison.fromJson(jsonDecode(compareTwoCommitsMock!));
    return githubComparison;
  }

  @override
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return true;
  }

  @override
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody) async {
    final IssueComment issueComment = IssueComment.fromJson(jsonDecode(createCommentMock!));
    return issueComment;
  }

  @override
  Future<bool> merge(RepositorySlug slug, String base, String head) async {
    return true;
  }

  @override
  Future<bool> updateBranch(RepositorySlug slug, int number, String headSha) async {
    return true;
  }
}
