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
  Future<Iterable<PullRequestReview>> getReviews(RepositorySlug slug, int prNumber) async {
    final Iterable<dynamic> reviews = json.decode(reviewsMock) as Iterable;
    final Iterable<PullRequestReview> prReviews =
        reviews.map((dynamic review) => PullRequestReview.fromJson(review)).toList();
    return prReviews;
  }

  @override
  Future<Iterable<CheckRun>> getCheckRuns(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(checkRunsMock) as Map<String, dynamic>;
    final Iterable<dynamic> checkRunsBody = rawBody["check_runs"];
    final Iterable<CheckRun> checkRuns = checkRunsBody.map((dynamic checkRun) => CheckRun.fromJson(checkRun)).toList();
    return checkRuns;
  }

  @override
  Future<Iterable<CheckSuite>> getCheckSuites(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(checkSuitesMock) as Map<String, dynamic>;
    final Iterable<dynamic> checkSuitesBody = rawBody["check_suites"];
    final Iterable<CheckSuite> checkSuites =
        checkSuitesBody.map((dynamic checkSuite) => CheckSuite.fromJson(checkSuite)).toList();
    return checkSuites;
  }

  @override
  Future<Iterable<RepositoryStatus>> getStatuses(
    RepositorySlug slug,
    String ref,
  ) async {
    final rawBody = json.decode(repositoryStatusesMock) as Map<String, dynamic>;
    final Iterable<dynamic> statusesBody = rawBody["statuses"];
    final Iterable<RepositoryStatus> statuses =
        statusesBody.map((dynamic state) => RepositoryStatus.fromJson(state)).toList();
    return statuses;
  }
}
