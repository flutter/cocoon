// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' hide PullRequest;
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/service/fake_github_service.dart';
import '../utilities/utils.dart';
import '../utilities/mocks.dart';

void main() {
  late ValidationService validationService;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late RepositorySlug slug;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
    validationService = ValidationService(config);
    slug = RepositorySlug('flutter', 'cocoon');
  });

  test('Removes label and post comment when no approval', () async {
    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    pubsub.publish('auto-submit-queue-sub', pullRequest);
    QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(
        config: config, result: queryResult, messagePullRequest: pullRequest, ackId: 'test', pubsub: pubsub);

    expect(githubService.issueComment, isNotNull);
    expect(githubService.labelRemoved, true);
    assert(pubsub.messagesQueue.isEmpty);
  });

  group('ShouldProcess pull request', () {
    test('Should process message when autosubmit label exists and pr is open', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processAutosubmit);
    });

    test('Skip processing message when autosubmit label does not exist anymore', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.labels = <IssueLabel>[];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });

    test('Skip processing message when the pull request is closed', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });

    test('Should process message when revert label exists and pr is open', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      IssueLabel issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processRevert);
    });

    test('Should process message as revert when revert and autosubmit labels are present and pr is open', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      IssueLabel issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels!.add(issueLabel);
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processRevert);
    });

    test('Skip processing message when revert label exists and pr is closed', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      IssueLabel issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });

    group('Process merge tests.', () {});
  });
}
