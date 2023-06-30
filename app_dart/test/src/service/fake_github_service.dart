// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';

import '../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({GitHub? client}) : github = client ?? MockGitHub();
  late List<RepositoryCommit> Function(String, int) listCommitsBranch;
  late List<PullRequest> Function(String?) listPullRequestsBranch;

  @override
  final GitHub github;

  @override
  Future<List<RepositoryCommit>> listBranchedCommits(
    RepositorySlug slug,
    String branch,
    int? lastCommitTimestampMills,
  ) async {
    return listCommitsBranch(branch, lastCommitTimestampMills ?? 0);
  }

  @override
  Future<List<PullRequest>> listPullRequests(RepositorySlug slug, String? branch) async {
    return listPullRequestsBranch(branch);
  }

  @override
  Future<List<IssueLabel>> addIssueLabels(
    RepositorySlug slug,
    int issueNumber,
    List<String> labels,
  ) async {
    return <IssueLabel>[];
  }

  @override
  Future<void> assignReviewer(RepositorySlug slug, {int? pullRequestNumber, String? reviewer}) async {}

  @override
  Future<Issue> createIssue(
    RepositorySlug slug, {
    String? title,
    String? body,
    List<String?>? labels,
    String? assignee,
  }) async {
    return Issue();
  }

  @override
  Future<void> assignIssue(
    RepositorySlug slug, {
    int? issueNumber,
    String? assignee,
  }) async {
    return;
  }

  @override
  Future<PullRequest> createPullRequest(
    RepositorySlug slug, {
    String? title,
    String? body,
    String? commitMessage,
    GitReference? baseRef,
    List<CreateGitTreeEntry>? entries,
  }) async {
    return PullRequest();
  }

  @override
  Future<String> getFileContent(RepositorySlug slug, String path, {String? ref}) async {
    if (path == 'bin/internal/release-candidate-branch.version') {
      if (ref == 'beta') {
        return 'flutter-3.2-candidate.5\n';
      } else if (ref == 'stable') {
        return 'flutter-2.13-candidate.0\n';
      }
      return Future<String>.value('');
    } else {
      return Future<String>.value('');
    }
  }

  @override
  Future<List<String>> listFiles(PullRequest pullRequest) async {
    return <String>['abc/def'];
  }

  @override
  Future<GitReference> getReference(RepositorySlug slug, String ref) async {
    return GitReference();
  }

  @override
  Future<List<Issue>> listIssues(
    RepositorySlug slug, {
    List<String>? labels,
    String state = 'open',
  }) async {
    return <Issue>[];
  }

  @override
  Future<Issue>? getIssue(
    RepositorySlug slug, {
    int? issueNumber,
  }) {
    return null;
  }

  @override
  Future<IssueComment?> createComment(
    RepositorySlug slug, {
    int? issueNumber,
    String? body,
  }) async {
    return null;
  }

  @override
  Future<List<IssueLabel>> replaceLabelsForIssue(
    RepositorySlug slug, {
    int? issueNumber,
    List<String>? labels,
  }) async {
    return <IssueLabel>[];
  }

  @override
  Future<RateLimit> getRateLimit() {
    throw UnimplementedError();
  }

  @override
  Future<PullRequest> getPullRequest(RepositorySlug slug, int number) async {
    return PullRequest();
  }

  @override
  Future<List<Issue>> searchIssuesAndPRs(
    RepositorySlug slug,
    String query, {
    String? sort,
    int pages = 2,
  }) async {
    return <Issue>[];
  }
}
