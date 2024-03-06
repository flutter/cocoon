// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto hide PullRequest;
import 'package:auto_submit/requests/github_pull_request_event.dart';
import 'package:auto_submit/model/discord_message.dart';
import 'package:auto_submit/service/revert_request_validation_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../revert/revert_support_data.dart';
import '../src/action/fake_revert_method.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_approver_service.dart';
import '../src/service/fake_bigquery_service.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_discord_notification.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/service/fake_github_service.dart';
import '../src/validations/fake_approval.dart';
import '../src/validations/fake_mergeable.dart';
import '../src/validations/fake_required_check_runs.dart';
import '../src/validations/fake_validation_filter.dart';
import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import 'bigquery_test.dart';

void main() {
  late RevertRequestValidationService validationService;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late RepositorySlug slug;

  late MockJobsResource jobsResource;
  late FakeBigqueryService bigqueryService;
  late FakeRevertMethod revertMethod;
  late FakeDiscordNotification discordNotification;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
    revertMethod = FakeRevertMethod();
    validationService = RevertRequestValidationService(
      config,
      retryOptions: const RetryOptions(delayFactor: Duration.zero, maxDelay: Duration.zero, maxAttempts: 1),
      revertMethod: revertMethod,
    );
    slug = RepositorySlug('flutter', 'cocoon');
    jobsResource = MockJobsResource();
    bigqueryService = FakeBigqueryService(jobsResource);
    config.bigqueryService = bigqueryService;
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    discordNotification = FakeDiscordNotification(targetUri: Uri(host: 'localhost'));
    validationService.discordNotification = discordNotification;

    when(jobsResource.query(captureAny, any)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
      );
    });
  });

  group('Testing time limit check:', () {
    test('Pull request is rejected if merged over 24 hours ago.', () {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(validationService.isWithinTimeLimit(pullRequest), isFalse);
    });

    test('Pull request is rejected if mergedAt is null', () {
      final PullRequest pullRequest = PullRequest(
        number: 0,
        base: PullRequestHead(repo: Repository(name: slug.name)),
        mergedAt: null,
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isFalse);
    });

    test('Pull request is accepted if mergedAt is within 24 hours ago.', () {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 23)),
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isTrue);
    });

    test('Pull request is accepted if mergedAt is exactly 24 hours ago.', () {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 24)),
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isTrue);
    });
  });

  group('shouldProcess:', () {
    test('Process revert from closed as "revert"', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, state: 'closed');
      final IssueLabel issueLabel = IssueLabel(name: 'revert');
      final List<String> labelNames = ['revert'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.revert);
    });

    test('Process open revert request as "revert of"', () async {
      final PullRequest pullRequest =
          generatePullRequest(prNumber: 0, repoName: slug.name, state: 'open', author: config.autosubmitBot);
      final IssueLabel issueLabel = IssueLabel(name: 'revert of');
      final List<String> labelNames = ['revert of'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.revertOf);
    });

    test('Pull request state is open with revert label is not processed', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, state: 'open');
      final IssueLabel issueLabel = IssueLabel(name: 'revert');
      final List<String> labelNames = ['revert'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test('Pull request is closed with "revert of" label is not processed', () async {
      final PullRequest pullRequest =
          generatePullRequest(prNumber: 0, repoName: slug.name, state: 'closed', author: config.autosubmitBot);
      final IssueLabel issueLabel = IssueLabel(name: 'revert of');
      final List<String> labelNames = ['revert of'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test('"revert of" pull request not authored by autosubmit bot is not processed.', () async {
      final PullRequest pullRequest =
          generatePullRequest(prNumber: 0, repoName: slug.name, state: 'open', author: 'octocat');
      final IssueLabel issueLabel = IssueLabel(name: 'revert of');
      final List<String> labelNames = ['revert of'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test('Closed pull request not processed if it was not merged', () async {
      final PullRequest pullRequest = PullRequest(
        number: 0,
        base: PullRequestHead(repo: Repository(name: slug.name)),
        state: 'closed',
        mergedAt: null,
      );
      final IssueLabel issueLabel = IssueLabel(name: 'revert');
      final List<String> labelNames = ['revert'];
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });
  });

  group('Process revert pull requests:', () {
    test('Remove label and post comment when issue has passed time limit to be reverted.', () async {
      // setup objects
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;

      // run tests
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Create the new revert issue from the closed one.', () async {
      // setup
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final IssueComment pullRequestComment = IssueComment(
        body: 'Reason for revert: test is failing consistently.',
      );

      final List<IssueComment> pullRequestCommentList = [pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Improperly formatted revert reason given, label removed.', () async {
      // setup
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final IssueComment pullRequestComment = IssueComment(
        body: 'Reverting this issue due to failures.',
      );

      final List<IssueComment> pullRequestCommentList = [pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.issueComment!.body!.contains('A reason for requesting a revert of'), isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Empty revert reason given, label removed.', () async {
      // setup
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final IssueComment pullRequestComment = IssueComment(
        body: 'Reason for revert: ',
      );

      final List<IssueComment> pullRequestCommentList = [pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.issueComment!.body!.contains('A reason for requesting a revert of'), isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('No reason given for revert, label is removed.', () async {
      // setup
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final List<IssueComment> pullRequestCommentList = [];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.issueComment!.body!.contains('A reason for requesting a revert of'), isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('New revert request is not created, label is removed.', () async {
      // setup
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      revertMethod.throwException = true;
      revertMethod.object = queryResult.repository!.pullRequest;
      githubService.pullRequestMock = pullRequest;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });
  });

  group('Process "revert of" pull requests:', () {
    test('Pull request is not processed due to repo config', () async {
      // setup
      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigRevertReviewRequired);
      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        // body: 'Reverts flutter/flutter#1234',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      validationService.approverService = FakeApproverService(config);

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Validation failure, label is removed.', () async {
      // setup
      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult =
          ValidationResult(true, Action.REMOVE_LABEL, 'This PR has met approval requirements for merging.\n');
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult =
          ValidationResult(true, Action.REMOVE_LABEL, 'All required check runs have completed.');
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        false,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is not in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Temporary validation failure label not removed.', () async {
      // setup
      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult =
          ValidationResult(true, Action.REMOVE_LABEL, 'This PR has met approval requirements for merging.\n');
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult =
          ValidationResult(false, Action.IGNORE_TEMPORARILY, 'All required check runs have not yet completed.');
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult =
          ValidationResult(true, Action.REMOVE_LABEL, 'Pull request flutter/flutter/1234 is in a mergeable state.');
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isNotEmpty);
    });

    test('Temp and hard failure result in label removed', () async {
      // setup
      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult =
          ValidationResult(true, Action.REMOVE_LABEL, 'This PR has met approval requirements for merging.\n');
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult =
          ValidationResult(false, Action.IGNORE_TEMPORARILY, 'All required check runs have not yet completed.');
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        false,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is not in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merge valid "revert of" request', () async {
      // setup
      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'sha',
        message: 'Pull Request successfully merged',
      );
      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Unable to merge valid "revert of" request.', () async {
      // setup
      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: false,
        sha: 'sha',
        message: 'Pull Request was not merged successfully',
      );
      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Exhaust retries on merge on retryable error. Unable to merge.', () async {
      // setup
      validationService = RevertRequestValidationService(
        config,
        retryOptions: const RetryOptions(
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
          // three attempts
          maxAttempts: 3,
        ),
      );

      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;

      githubService.mergeRequestMock = PullRequestMerge(
        merged: false,
        sha: 'sha',
        message: 'Pull Request was not merged successfully',
      );

      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merge fails first time then succeeds after retry.', () async {
      // setup
      validationService = RevertRequestValidationService(
        config,
        retryOptions: const RetryOptions(
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
          // three attempts
          maxAttempts: 3,
        ),
      );

      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;

      // TODO use the mock list.
      githubService.useMergeRequestMockList = true;
      final PullRequestMerge pullRequestMergeFail = PullRequestMerge(
        merged: false,
        sha: 'sha',
        message: 'Pull request was not merged successfully',
      );
      final PullRequestMerge pullRequestMergeSuccess = PullRequestMerge(
        merged: true,
        sha: 'sha',
        message: 'Pull request was merged successfully',
      );

      githubService.pullRequestMergeMockList = [pullRequestMergeFail, pullRequestMergeSuccess];

      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merge is not retried on non retryable exception', () async {
      // setup
      validationService = RevertRequestValidationService(
        config,
        retryOptions: const RetryOptions(
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
          // three attempts
          maxAttempts: 3,
        ),
      );

      final FakeValidationFilter fakeValidationFilter = FakeValidationFilter();
      final FakeApproval fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final FakeRequiredCheckRuns fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final FakeMergeable fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final FakePubSub pubsub = FakePubSub();

      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final GithubPullRequestEvent githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final Issue issue = Issue(
        id: 1234,
        assignee: User(login: 'keyonghan'),
        createdAt: DateTime.now(),
      );

      // setup fields
      githubService.githubIssueMock = issue;
      githubService.pullRequestMock = pullRequest;
      githubService.createCommentData = createCommentMock;

      githubService.throwExceptionOnMerge = true;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: false,
        sha: 'sha',
        message: 'Pull Request was not merged successfully',
      );

      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });
  });

  group('Craft discord message', () {
    test('Craft discord message', () async {
      const String expected = '''
Pull Request [flutter/cocoon#3460](<https://github.com/flutter/cocoon/pull/3460>) has been reverted by yusuf-goog.
Please see the revert PR here: [flutter/cocoon#3461](<https://github.com/flutter/cocoon/pull/3461>).
Reason for reverting: comment was added by mistake.''';

      const String expectedReason = 'Reason for reverting: comment was added by mistake.';
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 3461,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final Message message = validationService.craftDiscordRevertMessage(pullRequest);

      expect(message.username, 'Revert bot');
      expect(message.content!.contains(expected), isTrue);
      expect(message.content!.contains(expectedReason), isTrue);
    });
  });

  group('processMerge:', () {
    test('Correct PR titles when merging to use Reland', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        title: 'Revert "Revert "My first PR!"',
        mergeable: true,
      );
      githubService.pullRequestData = pullRequest;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: pullRequest.mergeCommitSha,
      );

      final MergeResult result = await validationService.processMerge(
        config: config,
        messagePullRequest: pullRequest,
      );

      expect(result.message, contains('Reland "My first PR!"'));
    });

    test('includes PR description in commit message', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        title: 'PR title',
        // The test-only helper function `generatePullRequest` will interpolate
        // this string into a JSON string which will then be decoded--thus, this string must be
        // a valid JSON substring, with escaped newlines.
        body: r'PR description\nwhich\nis multiline.',
        mergeable: true,
      );
      githubService.pullRequestData = pullRequest;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: pullRequest.mergeCommitSha,
      );
      final MergeResult result = await validationService.processMerge(
        config: config,
        messagePullRequest: pullRequest,
      );

      expect(result.message, '''
PR description
which
is multiline.''');
    });

    test('commit message filters out markdown checkboxes', () async {
      const String prTitle = 'Important update #4';
      const String prBody = '''
Various bugfixes and performance improvements.

Fixes #12345 and #3.
This is the second line in a paragraph.

## Pre-launch Checklist

- [ ] I read the [Contributor Guide] and followed the process outlined there for submitting PRs.
- [ ] I read the [Tree Hygiene] wiki page, which explains my responsibilities.
- [ ] I read and followed the [Flutter Style Guide], including [Features we expect every widget to implement].
- [x] I signed the [CLA].
- [ ] I listed at least one issue that this PR fixes in the description above.
- [ ] I updated/added relevant documentation (doc comments with `///`).
- [X] I added new tests to check the change I am making, or this PR is [test-exempt].
- [ ] All existing and new tests are passing.

If you need help, consider asking for advice on the #hackers-new channel on [Discord].

<!-- Links -->
[Contributor Guide]: https://github.com/flutter/flutter/wiki/Tree-hygiene#overview
[Tree Hygiene]: https://github.com/flutter/flutter/wiki/Tree-hygiene
[test-exempt]: https://github.com/flutter/flutter/wiki/Tree-hygiene#tests
[Flutter Style Guide]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo
[Features we expect every widget to implement]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#features-we-expect-every-widget-to-implement
[CLA]: https://cla.developers.google.com/
[flutter/tests]: https://github.com/flutter/tests
[breaking change policy]: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes
[Discord]: https://github.com/flutter/flutter/wiki/Chat''';

      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        title: prTitle,
        // The test-only helper function `generatePullRequest` will interpolate
        // this string into a JSON string which will then be decoded--thus, this string must be
        // a valid JSON substring, with escaped newlines.
        body: prBody.replaceAll('\n', r'\n'),
        mergeable: true,
      );
      githubService.pullRequestData = pullRequest;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: pullRequest.mergeCommitSha,
      );

      final MergeResult result = await validationService.processMerge(
        config: config,
        messagePullRequest: pullRequest,
      );

      expect(result.result, isTrue);
      expect(result.message, '''
Various bugfixes and performance improvements.

Fixes #12345 and #3.
This is the second line in a paragraph.''');
    });
  });
}
