// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('Check CheckPullRequest', () {
    late Request req;
    late Request reqWithAutoRoller;
    late Request reqWithOverrideTreeLabel;
    late Request reqWithoutAuhorAsso;
    late Request reqWaithoutLabel;
    late Request reqWaithoutRepo;
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    final FakeGithubService githubService = FakeGithubService();

    setUp(() {
      req = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookEventMock);

      reqWithAutoRoller = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookAutoRollerMock);

      reqWithOverrideTreeLabel = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookOverrideTreeStatusLabelMock);

      reqWithoutAuhorAsso = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookNoneAuthorMock);

      reqWaithoutLabel = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookNoLabelMock);

      reqWaithoutRepo = Request('GET', Uri.parse('http://localhost/'),
          headers: {
            'header1': 'header value1',
          },
          body: webhookNoStatusRepoMock);
    });

    test('Merges PR with successful status and checks', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });

    test('Merges unapproved PR from autoroller', () async {
      githubService.reviewsData = unApprovedReviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(reqWithAutoRoller);
      final String resBody = await response.readAsString();
      expect(resBody, webhookAutoRollerMock);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedRepositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(reqWithOverrideTreeLabel);
      final String resBody = await response.readAsString();
      expect(resBody, webhookOverrideTreeStatusLabelMock);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareToTCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, webhookEventMock);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(reqWaithoutRepo);
      final String resBody = await response.readAsString();
      expect(resBody, webhookNoStatusRepoMock);
    });

    test('Removes the label for the PR with failed tests', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = failedCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Does not merge PR with in progress checks', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Does not merge PR with failed status', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedRepositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(reqWithoutAuhorAsso);
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(reqWaithoutLabel);
      final String resBody = await response.readAsString();
      expect(resBody, '{}');
    });

    test('Does not fail with null checks', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Empty validations do not merge', () async {
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });
  });
}
