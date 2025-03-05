// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:cocoon_server/testing/mocks.dart';
import 'package:github/github.dart' as gh;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';

void main() {
  FakeConfig config;
  late ApproverService service;
  late MockGitHub github;
  late MockPullRequestsService pullRequests;

  setUp(() {
    github = MockGitHub();
    config = FakeConfig(githubClient: github);
    config.repositoryConfigurationMock =
        RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    service = ApproverService(config);
    pullRequests = MockPullRequestsService();
    when(github.pullRequests).thenReturn(pullRequests);
    when(pullRequests.createReview(any, any)).thenAnswer(
        (_) async => gh.PullRequestReview(id: 123, user: gh.User()));
  });

  test('Verify approval ignored', () async {
    final pr = generatePullRequest(author: 'not_a_user');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Verify approve', () async {
    when(pullRequests.listReviews(any, any))
        .thenAnswer((_) => const Stream<gh.PullRequestReview>.empty());
    final pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    final reviews = verify(pullRequests.createReview(any, captureAny)).captured;
    expect(reviews.length, 1);
    final review = reviews.single as gh.CreatePullRequestReview;
    expect(review.event, 'APPROVE');
  });

  test('Already approved', () async {
    final review = gh.PullRequestReview(
        id: 123, user: gh.User(login: 'fluttergithubbot'), state: 'APPROVED');
    when(pullRequests.listReviews(any, any))
        .thenAnswer((_) => Stream<gh.PullRequestReview>.value(review));
    final pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });
}
