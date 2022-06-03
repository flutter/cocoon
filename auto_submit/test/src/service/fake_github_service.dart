// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:shelf/src/response.dart';

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
    final List<dynamic> checkRunsBody = rawBody["check_runs"]! as List<dynamic>;
    List<CheckRun> checkRuns = <CheckRun>[];
    if ((checkRunsBody[0] as Map<String, dynamic>).isNotEmpty) {
      checkRuns.addAll(
          checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun as Map<String, dynamic>)).toList());
    }
    return checkRuns;
  }

  @override
  Future<RepositoryCommit> getCommit(RepositorySlug slug, String sha) async {
    final RepositoryCommit commit = RepositoryCommit.fromJson(jsonDecode(commitMock!) as Map<String, dynamic>);
    return commit;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    final GitHubComparison githubComparison =
        GitHubComparison.fromJson(jsonDecode(compareTwoCommitsMock!) as Map<String, dynamic>);
    return githubComparison;
  }

  @override
  Future<bool> removeLabel(RepositorySlug slug, int issueNumber, String label) async {
    return true;
  }

  @override
  Future<IssueComment> createComment(RepositorySlug slug, int number, String commentBody) async {
    final IssueComment issueComment = IssueComment.fromJson(jsonDecode(createCommentMock!) as Map<String, dynamic>);
    return issueComment;
  }

  @override
  Future<bool> updateBranch(RepositorySlug slug, int number, String headSha) async {
    return true;
  }

  @override
  Future<Response> autoMergeBranch(PullRequest pullRequest) {
    // TODO: implement autoMergeBranch
    throw UnimplementedError();
  }
}
