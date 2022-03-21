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
    const String testTopic = 'test-topic';

    test('Merges PR with successful status and checks', () async {
      pubsub.publish(testTopic, generatePullRequest());
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Merge the pull request.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges unapproved PR from autoroller', () async {
      PullRequest pr1 = generatePullRequest(login: "engine-flutter-autoroll");
      PullRequest pr2 = generatePullRequest(login: "engine-flutter-autoroll");
      pubsub.publish(testTopic, pr1);
      pubsub.publish(testTopic, pr2);
      githubService.reviewsData = unApprovedReviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Merge the pull request.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      PullRequest pr1 = generatePullRequest(labelName: "warning: land on red to fix tree breakage");
      PullRequest pr2 = generatePullRequest(labelName: "warning: land on red to fix tree breakage");
      pubsub.publish(testTopic, pr1);
      pubsub.publish(testTopic, pr2);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedAuthorsStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Merge the pull request.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareToTCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Merge the pull request.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      PullRequest pr1 = generatePullRequest(repoName: 'cocoon');
      PullRequest pr2 = generatePullRequest(repoName: 'cocoon');
      pubsub.publish(testTopic, pr1);
      pubsub.publish(testTopic, pr2);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Merge the pull request.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed tests', () async {
      pubsub.publish(testTopic, generatePullRequest());
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = failedCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Remove the autosubmit label.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Remove the label for the PR with failed status', () async {
      pubsub.publish(testTopic, generatePullRequest());
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = failedNonAuthorsStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Remove the autosubmit label.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      PullRequest pr1 = generatePullRequest(authorAssociation: '');
      PullRequest pr2 = generatePullRequest(authorAssociation: '');
      pubsub.publish(testTopic, pr1);
      pubsub.publish(testTopic, pr2);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Remove the autosubmit label.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not fail with null checks', () async {
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Remove the autosubmit label.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not merge PR with in progress checks', () async {
      pubsub.publish(testTopic, generatePullRequest());
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Does not merge the pull request.');
      }
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      PullRequest pr1 = generatePullRequest(autosubmitLabel: 'no_autosubmit');
      PullRequest pr2 = generatePullRequest(autosubmitLabel: 'no_autosubmit');
      pubsub.publish(testTopic, pr1);
      pubsub.publish(testTopic, pr2);
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = checkRunsMock;
      githubService.repositoryStatusesData = repositoryStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Does not merge the pull request.');
      }
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Empty validations do not merge', () async {
      pubsub.publish(testTopic, generatePullRequest());
      pubsub.publish(testTopic, generatePullRequest());
      githubService.reviewsData = reviewsMock;
      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.repositoryStatusesData = emptyStatusesMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      final List<Response> responses = await checkPullRequest.get();
      for (Response response in responses) {
        final String resBody = await response.readAsString();
        expect(resBody, 'Remove the autosubmit label.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });
  });
}
