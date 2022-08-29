// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart' as gh;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../utilities/mocks.dart';
import '../utilities/utils.dart';

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
    when(pullRequests.createReview(any, any)).thenAnswer((_) async => gh.PullRequestReview(id: 123, user: gh.User()));
  });

  test('Verify approval ignored', () async {
    gh.PullRequest pr = generatePullRequest(author: 'not_a_user');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Verify approve', () async {
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => const Stream<gh.PullRequestReview>.empty());
    gh.PullRequest pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    final List<dynamic> reviews = verify(pullRequests.createReview(any, captureAny)).captured;
    expect(reviews.length, 1);
    final gh.CreatePullRequestReview review = reviews.single as gh.CreatePullRequestReview;
    expect(review.event, 'APPROVE');
  });

  test('Already approved', () async {
    gh.PullRequestReview review =
        gh.PullRequestReview(id: 123, user: gh.User(login: 'fluttergithubbot'), state: 'APPROVED');
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => Stream<gh.PullRequestReview>.value(review));
    gh.PullRequest pr = generatePullRequest(author: 'dependabot[bot]');
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('AutoApproval does not approve revert pull request.', () async {
    gh.PullRequest pr = generatePullRequest(author: 'not_a_user');
    List<gh.IssueLabel> issueLabels = pr.labels ?? [];
    gh.IssueLabel issueLabel = gh.IssueLabel(name: 'revert');
    issueLabels.add(issueLabel);
    await service.autoApproval(pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Revert request is auto approved.', () async {
    when(pullRequests.listReviews(any, any)).thenAnswer((_) => const Stream<gh.PullRequestReview>.empty());
    gh.PullRequest pr = generatePullRequest(author: 'dependabot[bot]');

    List<gh.IssueLabel> issueLabels = pr.labels ?? [];
    gh.IssueLabel issueLabel = gh.IssueLabel(name: 'revert');
    issueLabels.add(issueLabel);

    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    QueryResult queryResult = createQueryResult(flutterRequest);

    await service.revertApproval(queryResult, pr);
    final List<dynamic> reviews = verify(pullRequests.createReview(any, captureAny)).captured;
    expect(reviews.length, 1);
    final gh.CreatePullRequestReview review = reviews.single as gh.CreatePullRequestReview;
    expect(review.event, 'APPROVE');
  });

  test('Revert request is not auto approved when the revert label is not present.', () async {
    gh.PullRequest pr = generatePullRequest(author: 'not_a_user');

    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    QueryResult queryResult = createQueryResult(flutterRequest);

    await service.revertApproval(queryResult, pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });

  test('Revert request is not auto approved on bad author association.', () async {
    gh.PullRequest pr = generatePullRequest(author: 'not_a_user', authorAssociation: 'CONTRIBUTOR');

    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    QueryResult queryResult = createQueryResult(flutterRequest);

    await service.revertApproval(queryResult, pr);
    verifyNever(pullRequests.createReview(any, captureAny));
  });
}
