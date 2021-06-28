// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';

import '../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  List<RepositoryCommit> Function(String, int) listCommitsBranch;
  List<PullRequest> Function(String) listPullRequestsBranch;

  @override
  final GitHub github = MockGitHub();

  @override
  Future<List<RepositoryCommit>> listCommits(RepositorySlug slug, String branch, int lastCommitTimestampMills) async {
    return listCommitsBranch(branch, lastCommitTimestampMills);
  }

  @override
  Future<List<PullRequest>> listPullRequests(RepositorySlug slug, String branch) async {
    return listPullRequestsBranch(branch);
  }

  @override
  Future<void> assignReviewer(RepositorySlug slug, { int pullRequestNumber, String reviewer }) async {}

  @override
  Future<Issue> createIssue(
      RepositorySlug slug, {
        String title,
        String body,
        List<String> labels,
        String assignee,
      }) async {
    return Issue();
  }

  @override
  Future<PullRequest> createPullRequest(
    RepositorySlug slug, {
    String title,
    String body,
    String commitMessage,
    GitReference baseRef,
    List<CreateGitTreeEntry> entries,
  }) async {
    return PullRequest();
  }

  @override
  Future<String> getFileContent(RepositorySlug slug, String path) async {
    return '';
  }

  @override
  Future<List<String>> listFiles(RepositorySlug slug, int prNumber) async {
    return <String>['abc/def'];
  }

  @override
  Future<GitReference> getReference(RepositorySlug slug, String ref) async {
    return GitReference();
  }

  @override
  Future<List<Issue>> listIssues(
    RepositorySlug slug, {
    List<String> labels,
    String state = 'open',
  }) async {
    return <Issue>[];
  }

  @override
  Future<RateLimit> getRateLimit() {
    throw UnimplementedError();
  }
}
