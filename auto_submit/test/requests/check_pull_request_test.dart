// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:github/github.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import './github_webhook_test_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('Check CheckPullRequest', () {
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    final FakeGithubService githubService = FakeGithubService();
    final FakePubSub pubsub = FakePubSub();

    test('Merges PR with successful status and checks', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Merge the pull request.');
    });

    test('Merges unapproved PR from autoroller', () async {
      PullRequest pullRequest = generatePullRequest(login: "engine-flutter-autoroll");
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = unApprovedReviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Merge the pull request.');
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      PullRequest pullRequest = generatePullRequest(labelName: "warning: land on red to fix tree breakage");
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedAuthorsStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Merge the pull request.');
    });

    test('Merges a clean revert PR with in progress tests', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareToTCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Merge the pull request.');
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      PullRequest pullRequest = generatePullRequest(repoName: 'cocoon');
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Merge the pull request.');
    });

    test('Removes the label for the PR with failed tests', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = failedCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Does not merge PR with in progress checks', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Does not merge the pull request.');
    });

    test('Remove the label for the PR with failed status', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedNonAuthorsStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      PullRequest pullRequest = generatePullRequest(authorAssociation: '');
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      PullRequest pullRequest = generatePullRequest(autosubmitLabel: 'no_autosubmit');
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Does not merge the pull request.');
    });

    test('Does not fail with null checks', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });

    test('Empty validations do not merge', () async {
      PullRequest pullRequest = generatePullRequest();
      pubsub.publish('test-topic', pullRequest);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final Response response = await checkPullRequest.get();
      final String resBody = await response.readAsString();
      expect(resBody, 'Remove the autosubmit label.');
    });
  });
}
