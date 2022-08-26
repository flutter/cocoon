// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../utilities/mocks.dart';

void main() {
  FakeConfig config;
  late ApproverService service;
  late MockGitHub github;
  late MockPullRequestsService pullRequests;

  setUp(() {
    github = MockGitHub();
    config = FakeConfig(githubClient: github);
    service = ApproverService(config);
    pullRequests = MockPullRequestsService();
    when(github.pullRequests).thenReturn(pullRequests);
    when(pullRequests.createReview(any, any)).thenAnswer((_) async => PullRequestReview(id: 123, user: User()));
  });

  test('Verify approval ignored', () async {
    PullRequest pr = generatePullRequest(author: 'not_a_user');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Verify approve', () async {
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => const Stream<PullRequestReview>.empty());
    PullRequest pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    final List<dynamic> reviews = verify(pullRequests.createReview(any, captureAny)).captured;
    expect(reviews.length, 1);
    final CreatePullRequestReview review = reviews.single as CreatePullRequestReview;
    expect(review.event, 'APPROVE');
  });

  test('Already approved', () async {
    PullRequestReview review = PullRequestReview(id: 123, user: User(login: 'fluttergithubbot'), state: 'APPROVED');
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => Stream<PullRequestReview>.value(review));
    PullRequest pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('AutoApproval does not approve revert pull request.', () async {
    PullRequest pr = generatePullRequest(author: 'not_a_user');
    List<IssueLabel> issueLabels = pr.labels ?? [];
    IssueLabel issueLabel = IssueLabel(name: 'revert');
    issueLabels.add(issueLabel);
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Revert request is auto approved.', () async {
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => const Stream<PullRequestReview>.empty());
    PullRequest pr = generatePullRequest(author: 'dependabot[bot]');

    List<IssueLabel> issueLabels = pr.labels ?? [];
    IssueLabel issueLabel = IssueLabel(name: 'revert');
    issueLabels.add(issueLabel);

    await service.revertApproval(pr);
    final List<dynamic> reviews = verify(pullRequests.createReview(any, captureAny)).captured;
    expect(reviews.length, 1);
    final CreatePullRequestReview review = reviews.single as CreatePullRequestReview;
    expect(review.event, 'APPROVE');
  });

  test('Revert request is not auto approved when the revert label is not present.', () async {
    PullRequest pr = generatePullRequest(author: 'not_a_user');
    await service.revertApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Revert request is not auto approved on bad author association.', () async {
    PullRequest pr = generatePullRequest(author: 'not_a_user', authorAssociation: 'CONTRIBUTOR');
    await service.revertApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });
}
