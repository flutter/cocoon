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
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    final FakeGithubService githubService = FakeGithubService();

    test('Merges PR with successful status and checks', () async {
      String webHookEvent = generateWebhookEvent();
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
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
      expect(resBody, webHookEvent);
    });

    test('Merges unapproved PR from autoroller', () async {
      String webHookEvent = generateWebhookEvent(login: "engine-flutter-autoroll");
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
      githubService.reviewsData = unApprovedReviewsMock;
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
      expect(resBody, webHookEvent);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      String webHookEvent = generateWebhookEvent(labelName: "warning: land on red to fix tree breakage");
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
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
      expect(resBody, webHookEvent);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      String webHookEvent = generateWebhookEvent();
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
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
      expect(resBody, webHookEvent);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      String webHookEvent = generateWebhookEvent(repoName: 'cocoon');
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config);

      final Response response = await checkPullRequest.get(req);
      final String resBody = await response.readAsString();
      expect(resBody, webHookEvent);
    });

    test('Removes the label for the PR with failed tests', () async {
      req = Request('GET', Uri.parse('http://localhost/'), body: generateWebhookEvent());
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
      req = Request('GET', Uri.parse('http://localhost/'), body: generateWebhookEvent());
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
      req = Request('GET', Uri.parse('http://localhost/'), body: generateWebhookEvent());
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
      String webHookEvent = generateWebhookEvent(authorAssociation: '');
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
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
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      String webHookEvent = generateWebhookEvent(autosubmitLabel: 'no_autosubmit');
      req = Request('GET', Uri.parse('http://localhost/'), body: webHookEvent);
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
      expect(resBody, '{}');
    });

    test('Does not fail with null checks', () async {
      req = Request('GET', Uri.parse('http://localhost/'), body: generateWebhookEvent());
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
      req = Request('GET', Uri.parse('http://localhost/'), body: generateWebhookEvent());
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
