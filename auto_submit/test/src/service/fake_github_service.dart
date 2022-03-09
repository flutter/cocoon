// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';

import '../../requests/github_webhook_test_data.dart';
import '../../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({GitHub? client}) : github = client ?? MockGitHub();

  @override
  final GitHub github;

  @override
  Future<List<PullRequestReview>> getReviews(RepositorySlug slug, int prNumber) async {
    final List<dynamic> reviews = json.decode(reviewsMock) as List;
    final List<PullRequestReview> prReviews =
        reviews.map((dynamic review) => PullRequestReview.fromJson(review)).toList();
    return prReviews;
  }

  @override
  Future<List<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(checkRunsMock) as Map<String, dynamic>;
    final List<dynamic> checkRunsBody = rawBody["check_runs"];
    final List<CheckRun> checkRuns = checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun)).toList();
    return checkRuns;
  }

  @override
  Future<List<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(repositoryStatusesMock) as Map<String, dynamic>;
    final List<dynamic> statusesBody = rawBody["statuses"];
    final List<RepositoryStatus> statuses =
        statusesBody.map((dynamic state) => RepositoryStatus.fromJson(state)).toList();
    return statuses;
  }

  @override
  Future<RepositoryCommit> getRepoCommit(RepositorySlug slug, String sha) async {
    RepositoryCommit commit = RepositoryCommit.fromJson(jsonDecode(commitMock));
    return commit;
  }

  @override
  Future<GitHubComparison> compareTwoCommits(RepositorySlug slug, String refBase, String refHead) async {
    GitHubComparison githubComparison = GitHubComparison.fromJson(jsonDecode(compareTowCOmmitsMock));
    return githubComparison;
  }
}
