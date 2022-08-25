// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' as qr hide PullRequest;
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/service/process_method.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart' as gh;
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
  late FakeGraphQLClient graphQLClient;
  late gh.RepositorySlug slug;

  setUp(() {
    graphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService, githubGraphQLClient: graphQLClient);
    validationService = ValidationService(config);
    slug = gh.RepositorySlug('flutter', 'cocoon');
  });

  test('removes label and post comment when no approval', () async {
    PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    final FakePubSub pubsub = FakePubSub();
    final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    pubsub.publish('auto-submit-queue-sub', pullRequest);
    qr.QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(config, queryResult, pullRequest, 'test', pubsub);

    expect(githubService.issueComment, isNotNull);
    expect(githubService.labelRemoved, true);
    assert(pubsub.messagesQueue.isEmpty);
  });

  group('shouldProcess pull request', () {
    test('should process message when autosubmit label exists and pr is open', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processAutosubmit);
    });

    test('skip processing message when autosubmit label does not exist anymore', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.labels = <gh.IssueLabel>[];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });

    test('skip processing message when the pull request is closed', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });

    test('should process message when revert label exists and pr is open', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      gh.IssueLabel issueLabel = gh.IssueLabel(name: 'revert');
      pullRequest.labels = <gh.IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processRevert);
    });

    test('should process message as revert when revert and autosubmit labels are present and pr is open', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      gh.IssueLabel issueLabel = gh.IssueLabel(name: 'revert');
      pullRequest.labels!.add(issueLabel);
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.processRevert);
    });

    test('skip processing message when revert label exists and pr is closed', () async {
      final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      gh.IssueLabel issueLabel = gh.IssueLabel(name: 'revert');
      pullRequest.labels = <gh.IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final ProcessMethod processMethod = await validationService.processPullRequestMethod(pullRequest);

      expect(processMethod, ProcessMethod.doNotProcess);
    });
  });

  group('ProcessMerge testing.', () {
    late PullRequestHelper flutterRequest;
    gh.RepositorySlug slug = gh.RepositorySlug('flutter', 'cocoon');
    final gh.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    late qr.QueryResult queryResult;
    late FakeValidationService validationService;
    final FakePubSub pubsub = FakePubSub();

    setUp(() {
      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );
      githubService.checkRunsData = checkRunsMock;
      githubService.createCommentData = createCommentMock;
      //  final FakePubSub pubsub = FakePubSub();
      queryResult = createQueryResult(flutterRequest);
      validationService = FakeValidationService(config);
    });

    test('ProcessMerge is successful.', () async {
      validationService.processMergeReturn = true;
      bool validated = await validationService.processMergeSafely(
          config, githubService, pullRequest, queryResult, pubsub, 'id', pullRequest.base!.repo!.slug(), 0, 'merge');

      expect(validated, isTrue);
      expect(validationService.threwException, isFalse);
    });

    test('ProcessMerge is unsuccessful.', () async {
      bool validated = await validationService.processMergeSafely(
          config, githubService, pullRequest, queryResult, pubsub, 'id', pullRequest.base!.repo!.slug(), 0, 'merge');

      expect(validated, isFalse);
      expect(validationService.threwException, isFalse);
    });

    test('ProcessMerge is unsuccessful.', () async {
      validationService.returnValue = false;
      bool validated = await validationService.processMergeSafely(
          config, githubService, pullRequest, queryResult, pubsub, 'id', pullRequest.base!.repo!.slug(), 0, 'merge');

      expect(validated, isFalse);
      expect(validationService.threwException, isTrue);
    });
  });
}

class FakeValidationService extends ValidationService {
  FakeValidationService(super.config);

  bool processMergeReturn = false;
  bool returnValue = true;
  bool threwException = false;

  @override
  Future<bool> processMerge(Config config, qr.QueryResult queryResult, gh.PullRequest messagePullRequest) async {
    if (returnValue) {
      return processMergeReturn;
    }
    threwException = true;
    throw Exception();
  }
}
