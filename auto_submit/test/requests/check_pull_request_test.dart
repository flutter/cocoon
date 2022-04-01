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
    const String login = "engine-flutter-autoroll";
    const String labelName = "warning: land on red to fix tree breakage";
    const String repoName = 'cocoon';
    const String autosubmitLabel = 'no_autosubmit';

    test('Merges PR with successful status and checks', () async {
      final PullRequest pr1 = generatePullRequest(prNumber: 0);
      final PullRequest pr2 = generatePullRequest(prNumber: 1);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody,
            'Should merge the pull request ${pullRequests[i].number} in ${pullRequests[i].base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges unapproved PR from autoroller', () async {
      final PullRequest pr1 = generatePullRequest(prNumber: 2, login: login);
      final PullRequest pr2 = generatePullRequest(prNumber: 3, login: login);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody,
            'Should merge the pull request ${pullRequests[i].number} in ${pullRequests[i].base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 4, labelName: labelName);
      PullRequest pr2 = generatePullRequest(prNumber: 5, labelName: labelName);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody,
            'Should merge the pull request ${pullRequests[i].number} in ${pullRequests[i].base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 6);
      pubsub.publish(testTopic, pullRequest);
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
        expect(resBody,
            'Should merge the pull request ${pullRequest.number} in ${pullRequest.base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 7, repoName: repoName);
      PullRequest pr2 = generatePullRequest(prNumber: 8, repoName: repoName);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody,
            'Should merge the pull request ${pullRequests[i].number} in ${pullRequests[i].base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed tests', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 9);
      PullRequest pr2 = generatePullRequest(prNumber: 10);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Remove the autosubmit label for commit: ${pullRequests[i].head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Remove the label for the PR with failed status', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 11);
      PullRequest pr2 = generatePullRequest(prNumber: 12);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Remove the autosubmit label for commit: ${pullRequests[i].head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 13, authorAssociation: '');
      PullRequest pr2 = generatePullRequest(prNumber: 14, authorAssociation: '');
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Remove the autosubmit label for commit: ${pullRequests[i].head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not fail with null checks', () async {
      PullRequest pr = generatePullRequest(prNumber: 15, authorAssociation: '');
      pubsub.publish(testTopic, pr);
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
        expect(resBody, 'Remove the autosubmit label for commit: ${pr.head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not merge PR with in progress checks', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 16);
      PullRequest pr2 = generatePullRequest(prNumber: 17);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Does not merge the pull request ${pullRequests[i].number}.');
      }
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 18, autosubmitLabel: autosubmitLabel);
      PullRequest pr2 = generatePullRequest(prNumber: 19, autosubmitLabel: autosubmitLabel);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Does not merge the pull request ${pullRequests[i].number}.');
      }
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Empty validations do not merge', () async {
      PullRequest pr1 = generatePullRequest(prNumber: 20);
      PullRequest pr2 = generatePullRequest(prNumber: 21);
      final List<PullRequest> pullRequests = <PullRequest>[pr1, pr2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
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
      for (int i = 0; i < responses.length; i++) {
        final String resBody = await responses[i].readAsString();
        expect(resBody, 'Remove the autosubmit label for commit: ${pullRequests[i].head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges only _kMergeCountPerRepo PR per cycle per repo', () async {
      final PullRequest pr1 = generatePullRequest(prNumber: 22);
      final PullRequest pr2 = generatePullRequest(prNumber: 23);
      final PullRequest pr3 = generatePullRequest(prNumber: 24);
      config = FakeConfig(githubService: githubService);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      Set shouldMergeSet = {pr1, pr2, pr3};
      final Set mergeSet = await checkPullRequest.checkMerge(shouldMergeSet);
      List<bool> mergeResult = await checkPullRequest.mergePullRequest(mergeSet);
      expect(mergeSet.length, 2);
      for (int i = 0; i < mergeResult.length; i++) {
        expect(mergeResult[i], true);
      }
      expect(pubsub.messagesQueue.length, 1);
      pubsub.messagesQueue.clear();
    });
  });
}
