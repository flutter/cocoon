// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/requests/cirrus_graphql_client.dart';
import 'package:auto_submit/requests/github_webhook.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../service/fake_config.dart';
import '../utilities/mocks.dart';

void main() {
  group('Check Webhook handler', () {
    late Request req;
    late Request reqWithOverrideTreeLabel;
    late GithubWebhook handler;
    late FakeConfig config;
    late RepositorySlug slug;
    final MockCirrusGraphQLClient mockCirrusClient = MockCirrusGraphQLClient();
    final MockGithubService mockGitHubService = MockGithubService();

    const int number = 2;
    const String sha = 'be6ff099a4ee56e152a5fa2f37edd10f79d1269a';
    List<dynamic> statuses = <dynamic>[];
    String? branch;

    setUp(() {
      req = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);

      reqWithOverrideTreeLabel = Request('POST', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock_OverrideTreeStatusLabel);

      config = FakeConfig(
          rollerAccountsValue: <String>{},
          githubService: mockGitHubService,
          cirrusGraphQLClient: mockCirrusClient);
      handler = GithubWebhook(config);
      config.overrideTreeStatusLabelValue =
          'warning: land on red to fix tree breakage';
      slug = RepositorySlug('flutter', 'cocoon');
      branch = null;
      statuses.clear();
    });

    test('Merges PR with successful status and checks', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'SKIPPED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });

    test('Merges unapproved PR from autoroller', () async {
      config.rollerAccountsValue = <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot'
      };
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock_rollerAuthor)
                as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody =
            json.decode(reviewsMock_Unapproved) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'SKIPPED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });

    test(
        'Merges PR with failed tree status if override tree status label is provided',
        () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock_Failure_notInAuthorsControl)
                as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'SKIPPED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(reqWithOverrideTreeLabel);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock_OverrideTreeStatusLabel);
    });

    test('Does not merge PR with failed tests', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'FAILED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Does not merge PR with in progress tests', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'EXECUTING'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Does not merge PR with in progress checks', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock_InProgress) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock_Neutral) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'COMPLETED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Does not merge PR with failed status', () async {
      when(mockGitHubService.getPullRequest(slug, prNumber: number))
          .thenAnswer((_) async {
        return PullRequest.fromJson(
            json.decode(singlePullRequestMock) as Map<String, dynamic>);
      });
      when(mockGitHubService.getCheckRuns(slug, ref: sha))
          .thenAnswer((_) async {
        final checkRunsBody =
            json.decode(checkRunsMock) as Map<String, dynamic>;
        List<CheckRun> checkRuns = [];
        checkRunsBody['check_runs']
            .forEach((el) => checkRuns.add(CheckRun.fromJson(el)));
        return checkRuns;
      });
      when(mockGitHubService.listCheckSuites(slug, ref: sha))
          .thenAnswer((_) async {
        final checkSuitesBody =
            json.decode(checkSuitesMock) as Map<String, dynamic>;
        List<CheckSuite> checkSuites = [];
        checkSuitesBody['check_suites']
            .forEach((el) => checkSuites.add(CheckSuite.fromJson(el)));
        return checkSuites;
      });
      when(mockGitHubService.getReviews(slug, prNumber: number))
          .thenAnswer((_) async {
        final reviewsBody = json.decode(reviewsMock) as List<dynamic>;
        List<PullRequestReview> reviews = [];
        for (var el in reviewsBody) {
          reviews.add(PullRequestReview.fromJson(el));
        }
        return reviews;
      });
      when(mockGitHubService.getStatuses(slug, sha)).thenAnswer((_) async {
        final statusesBody =
            json.decode(repositoryStatusesMock_Failure) as Map<String, dynamic>;
        List<RepositoryStatus> repoStatuses = [];
        statusesBody['statuses']
            .forEach((el) => repoStatuses.add(RepositoryStatus.fromJson(el)));
        return repoStatuses;
      });
      when(mockCirrusClient.queryCirrusGraphQL(sha, slug.name))
          .thenAnswer((_) async {
        List<CirrusResult> queryResults = [];
        List<Map<String, dynamic>> tasks = [
          {'id': '1', 'name': 'a', 'status': 'COMPLETED'},
          {'id': '2', 'name': 'b', 'status': 'SKIPPED'}
        ];
        CirrusResult queryResult = CirrusResult(branch, tasks);
        queryResults.add(queryResult);
        return queryResults;
      });

      final RepositoryCommit secondTotCommit = RepositoryCommit.fromJson(
          json.decode(commitMock) as Map<String, dynamic>);
      when(mockGitHubService.getRepoCommit(slug, 'HEAD~'))
          .thenAnswer((_) async {
        return secondTotCommit;
      });
      when(mockGitHubService.compareTwoCommits(slug, secondTotCommit.sha!, sha))
          .thenAnswer((_) async {
        return GitHubComparison.fromJson(
            json.decode(compareTowCOmmitsMock) as Map<String, dynamic>);
      });

      Response response = await handler.post(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });
  });
}
