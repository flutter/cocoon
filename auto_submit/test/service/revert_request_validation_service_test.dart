// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/discord_message.dart';
import 'package:auto_submit/requests/github_pull_request_event.dart';
import 'package:auto_submit/service/revert_request_validation_service.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server/testing/bigquery_testing.dart';
import 'package:cocoon_server/testing/mocks.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../revert/revert_support_data.dart';
import '../src/action/fake_revert_method.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_approver_service.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_discord_notification.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/validations/fake_approval.dart';
import '../src/validations/fake_mergeable.dart';
import '../src/validations/fake_required_check_runs.dart';
import '../src/validations/fake_validation_filter.dart';
import '../utilities/utils.dart';

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

  setUpAll(() {
    log = Logger('auto_submit');
  });

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(
        githubService: githubService, githubGraphQLClient: githubGraphQLClient);
    revertMethod = FakeRevertMethod();
    validationService = RevertRequestValidationService(
      config,
      retryOptions: const RetryOptions(
          delayFactor: Duration.zero, maxDelay: Duration.zero, maxAttempts: 1),
      revertMethod: revertMethod,
    );
    slug = RepositorySlug('flutter', 'cocoon');
    jobsResource = MockJobsResource();
    bigqueryService = FakeBigqueryService(jobsResource);
    config.bigqueryService = bigqueryService;
    config.repositoryConfigurationMock =
        RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    discordNotification =
        FakeDiscordNotification(targetUri: Uri(host: 'localhost'));
    validationService.discordNotification = discordNotification;

    when(jobsResource.query(captureAny, any))
        .thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse)
            as Map<dynamic, dynamic>),
      );
    });
  });

  group('Testing time limit check:', () {
    test('Pull request is rejected if merged over 24 hours ago.', () {
      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );
      expect(validationService.isWithinTimeLimit(pullRequest), isFalse);
    });

    test('Pull request is rejected if mergedAt is null', () {
      final pullRequest = PullRequest(
        number: 0,
        base: PullRequestHead(repo: Repository(name: slug.name)),
        mergedAt: null,
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isFalse);
    });

    test('Pull request is accepted if mergedAt is within 24 hours ago.', () {
      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 23)),
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isTrue);
    });

    test('Pull request is accepted if mergedAt is exactly 24 hours ago.', () {
      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 24)),
      );

      expect(validationService.isWithinTimeLimit(pullRequest), isTrue);
    });
  });

  group('shouldProcess:', () {
    test('Process revert from closed as "revert"', () async {
      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, state: 'closed');
      final issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.revert);
    });

    test('Process open revert request as "revert of"', () async {
      final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
          state: 'open',
          author: config.autosubmitBot);
      final issueLabel = IssueLabel(name: 'revert of');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.revertOf);

      // The revert branch should not be deleted immediately. The PR may still
      // be in the queue. The branch will be deleted after GitHub successfully
      // merges the PR and notified the webhook using the "closed" event.
      expect(githubService.deletedBranches, isEmpty);
    });

    test('Pull request state is open with revert label is not processed',
        () async {
      final pullRequest =
          generatePullRequest(prNumber: 0, repoName: slug.name, state: 'open');
      final issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test('Pull request is closed with "revert of" label is not processed',
        () async {
      final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
          state: 'closed',
          author: config.autosubmitBot);
      final issueLabel = IssueLabel(name: 'revert of');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test(
        '"revert of" pull request not authored by autosubmit bot is not processed.',
        () async {
      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, state: 'open', author: 'octocat');
      final issueLabel = IssueLabel(name: 'revert of');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });

    test('Closed pull request not processed if it was not merged', () async {
      final pullRequest = PullRequest(
        number: 0,
        base: PullRequestHead(repo: Repository(name: slug.name)),
        state: 'closed',
        mergedAt: null,
      );
      final issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      final revertProcessMethod =
          await validationService.shouldProcess(pullRequest);

      expect(revertProcessMethod, RevertProcessMethod.none);
    });
  });

  group('Process revert pull requests:', () {
    test(
        'Remove label and post comment when issue has passed time limit to be reverted.',
        () async {
      // setup objects
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        mergedAt: DateTime.now().subtract(const Duration(hours: 25)),
      );

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;

      // run tests
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final pullRequestComment = IssueComment(
        body: 'Reason for revert: test is failing consistently.',
      );

      final pullRequestCommentList = <IssueComment>[pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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

    test('Create the new revert issue, reason has links.', () async {
      // setup
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final pullRequestComment = IssueComment(
        body:
            'Reason for revert: Broke engine post-submit, see https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8753367119442265873/+/u/test:_Android_Unit_Tests__API_28_/stdout.',
      );

      final pullRequestCommentList = <IssueComment>[pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final pullRequestComment = IssueComment(
        body: 'Reverting this issue due to failures.',
      );

      final pullRequestCommentList = <IssueComment>[pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(
          githubService.issueComment!.body!
              .contains('A reason for requesting a revert of'),
          isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Empty revert reason given, label removed.', () async {
      // setup
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final pullRequestComment = IssueComment(
        body: 'Reason for revert: ',
      );

      final pullRequestCommentList = <IssueComment>[pullRequestComment];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(
          githubService.issueComment!.body!
              .contains('A reason for requesting a revert of'),
          isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('No reason given for revert, label is removed.', () async {
      // setup
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
          prNumber: 0, repoName: slug.name, author: 'auto-submit[bot]');

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // setup fields
      githubService.createCommentData = createPullRequestCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = pullRequest;

      final pullRequestCommentList = <IssueComment>[];
      githubService.issueCommentsMock = pullRequestCommentList;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(
          githubService.issueComment!.body!
              .contains('A reason for requesting a revert of'),
          isTrue);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('New revert request is not created, label is removed.', () async {
      // setup
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
      );

      final queryResult = createQueryResult(flutterRequest);

      final githubPullRequestEvent = GithubPullRequestEvent(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      config.repositoryConfigurationMock =
          RepositoryConfiguration.fromYaml(sampleConfigRevertReviewRequired);
      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        // body: 'Reverts flutter/flutter#1234',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
          true,
          Action.REMOVE_LABEL,
          'This PR has met approval requirements for merging.\n');
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
          true, Action.REMOVE_LABEL, 'All required check runs have completed.');
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        false,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is not in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
          true,
          Action.REMOVE_LABEL,
          'This PR has met approval requirements for merging.\n');
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
          false,
          Action.IGNORE_TEMPORARILY,
          'All required check runs have not yet completed.');
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
          true,
          Action.REMOVE_LABEL,
          'Pull request flutter/flutter/1234 is in a mergeable state.');
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
          true,
          Action.REMOVE_LABEL,
          'This PR has met approval requirements for merging.\n');
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
          false,
          Action.IGNORE_TEMPORARILY,
          'All required check runs have not yet completed.');
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        false,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is not in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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
      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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

    test('Exhaust retries on merge on retryable error. Unable to merge.',
        () async {
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

      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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

      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      final pullRequestMergeFail = PullRequestMerge(
        merged: false,
        sha: 'sha',
        message: 'Pull request was not merged successfully',
      );
      final pullRequestMergeSuccess = PullRequestMerge(
        merged: true,
        sha: 'sha',
        message: 'Pull request was merged successfully',
      );

      githubService.pullRequestMergeMockList = [
        pullRequestMergeFail,
        pullRequestMergeSuccess
      ];

      validationService.approverService = FakeApproverService(config);
      validationService.validationFilter = fakeValidationFilter;

      // run test
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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

      final fakeValidationFilter = FakeValidationFilter();
      final fakeApproval = FakeApproval(config: config);
      fakeApproval.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'This PR has met approval requirements for merging.\n',
      );
      final fakeRequiredCheckRuns = FakeRequiredCheckRuns(config: config);
      fakeRequiredCheckRuns.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'All required check runs have completed.',
      );
      final fakeMergeable = FakeMergeable(config: config);
      fakeMergeable.validationResult = ValidationResult(
        true,
        Action.REMOVE_LABEL,
        'Pull request flutter/flutter/1234 is in a mergeable state.',
      );
      fakeValidationFilter.registerValidation(fakeApproval);
      fakeValidationFilter.registerValidation(fakeRequiredCheckRuns);
      fakeValidationFilter.registerValidation(fakeMergeable);

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'ricardoamador'),
      );

      final issue = Issue(
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
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
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

    test('Do not re-enqueue already enqueued pull requests', () async {
      // Use a test slug that has MQ enabled
      slug = RepositorySlug('flutter', 'flutter');

      final logs = <String>[];
      final logSub = log.onRecord.listen((record) {
        logs.add(record.toString());
      });

      final pubsub = FakePubSub();

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
        isInMergeQueue: true,
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final githubPullRequestEvent = GithubPullRequestEvent(
        pullRequest: pullRequest,
        action: 'labeled',
        sender: User(login: 'auto-submit[bot]'),
      );

      // Process the pull request
      unawaited(
          pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertOfRequest(
        result: queryResult,
        githubPullRequestEvent: githubPullRequestEvent,
        ackId: 'test',
        pubsub: pubsub,
      );
      await logSub.cancel();

      // Expectations
      expect(
        logs,
        contains(
            '[INFO] auto_submit: flutter/flutter/0 is already in the merge queue. Skipping.'),
      );
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isEmpty);
    });
  });

  group('Craft discord message', () {
    test('Craft discord message', () async {
      const expected = '''
Pull Request [flutter/cocoon#3460](<https://github.com/flutter/cocoon/pull/3460>) has been reverted by yusuf-goog.
Please see the revert PR here: [flutter/cocoon#3461](<https://github.com/flutter/cocoon/pull/3461>).
Reason for reverting: comment was added by mistake.''';

      const expectedReason =
          'Reason for reverting: comment was added by mistake.';
      final pullRequest = generatePullRequest(
        prNumber: 3461,
        repoName: slug.name,
        labelName: 'revert of',
        body: sampleRevertBody.replaceAll('\n', ''),
      );

      final Message message =
          validationService.craftDiscordRevertMessage(pullRequest);

      expect(message.username, 'Revert bot');
      expect(message.content!.contains(expected), isTrue);
      expect(message.content!.contains(expectedReason), isTrue);
    });
  });

  group('submitPullRequest:', () {
    test('Correct PR titles when merging to use Reland', () async {
      final pullRequest = generatePullRequest(
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

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.message, contains('Reland "My first PR!"'));
    });

    test('includes PR description in commit message', () async {
      final pullRequest = generatePullRequest(
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
      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.message, '''
PR description
which
is multiline.''');
    });

    test('commit message filters out markdown checkboxes', () async {
      const prTitle = 'Important update #4';
      const prBody = '''
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
[Contributor Guide]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#overview
[Tree Hygiene]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md
[test-exempt]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#tests
[Flutter Style Guide]: https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md
[Features we expect every widget to implement]: https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md#features-we-expect-every-widget-to-implement
[CLA]: https://cla.developers.google.com/
[flutter/tests]: https://github.com/flutter/tests
[breaking change policy]: https://github.com/flutter/flutter/blob/master/docs/contributing/Tree-hygiene.md#handling-breaking-changes
[Discord]: https://github.com/flutter/flutter/blob/master/docs/contributing/Chat.md''';

      final pullRequest = generatePullRequest(
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

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.result, isTrue);
      expect(result.message, '''
Various bugfixes and performance improvements.

Fixes #12345 and #3.
This is the second line in a paragraph.''');
    });
  });
}
