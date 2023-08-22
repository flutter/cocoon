// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto hide PullRequest;
import 'package:auto_submit/service/revert_request_validation_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/action/fake_revert_method.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_approver_service.dart';
import '../src/service/fake_bigquery_service.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/service/fake_github_service.dart';
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

    when(jobsResource.query(captureAny, any)).thenAnswer((Invocation invocation) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
      );
    });
  });

  group('Testing time limit check.', () {
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

  group('Should process method', () {
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

  group('Process revert pull requests', () {
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

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;

      // run tests
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        messagePullRequest: pullRequest,
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
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
      );
      final auto.QueryResult queryResult = createQueryResult(flutterRequest);

      // setup fields
      githubService.createCommentData = createCommentMock;
      githubService.pullRequestMock = pullRequest;
      revertMethod.object = queryResult.repository!.pullRequest;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        messagePullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
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

      // setup fields
      githubService.createCommentData = createCommentMock;
      revertMethod.throwException = true;
      revertMethod.object = queryResult.repository!.pullRequest;
      githubService.pullRequestMock = pullRequest;

      // run test
      unawaited(pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest));
      await validationService.processRevertRequest(
        result: queryResult,
        messagePullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      expect(githubService.labelRemoved, true);
      assert(pubsub.messagesQueue.isEmpty);
    });
  });

  group('Process "revert of" pull requests', () {
    test('Pull request is not processed due to repo config', () async {
      // setup
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
        body: 'Reverts flutter/flutter#1234',
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
      await validationService.processRevertRequest(
        result: queryResult,
        messagePullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      // validate
      expect(githubService.issueComment, isNotNull);
      assert(pubsub.messagesQueue.isEmpty);
    });
  });

//   group('Processing revert reqeuest tests', () {
//     test('Merge valid revert request and message is acknowledged.', () async {
//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.isTeamMemberMockMap['author1'] = true;
//       githubService.isTeamMemberMockMap['member'] = true;
//       githubService.mergeRequestMock = PullRequestMerge(
//         merged: true,
//         sha: 'sha',
//         message: 'Pull Request successfully merged',
//       );

//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//       );

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       final Issue issue = Issue(
//         id: 1234,
//         assignee: User(login: 'keyonghan'),
//         createdAt: DateTime.now(),
//       );
//       githubService.githubIssueMock = issue;
//       githubService.pullRequestMock = pullRequest;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNull);
//       expect(githubService.labelRemoved, false);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Fail to merge non valid revert, comment is added and message is acknowledged.', () async {
//       githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult();
//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//       );

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(false, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNotNull);
//       expect(githubService.labelRemoved, true);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Remove label and post comment when unable to process merge.', () async {
//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );
//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       expect(githubService.issueComment, isNotNull);
//       expect(githubService.labelRemoved, true);
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Revert returns on in process required checkRuns.', () async {
//       githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult();
//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = inProgressCheckRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.throwOnCreateIssue = true;
//       githubService.useRealComment = true;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//       );
//       githubService.pullRequestMock = pullRequest;
//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult =
//       //     ValidationResult(false, Action.IGNORE_TEMPORARILY, 'Some of the required checks did not complete in time.');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNull);
//       expect(githubService.labelRemoved, false);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isNotEmpty);
//     });

//     test('Exhaust retries on merge on retryable error.', () async {
//       validationService = RevertRequestValidationService(
//         config,
//         retryOptions: const RetryOptions(
//           delayFactor: Duration.zero,
//           maxDelay: Duration.zero,
//           maxAttempts: 1,
//         ),
//       );

//       githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult(
//             exception: OperationException(
//               graphqlErrors: [
//                 const GraphQLError(message: 'Base branch was modified. Review and try the merge again'),
//               ],
//             ),
//           );

//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.useRealComment = true;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//         mergeable: true,
//       );

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;
//       githubService.pullRequestData = pullRequest;

//       final Issue issue = Issue(
//         id: 1234,
//         assignee: User(login: 'keyonghan'),
//         createdAt: DateTime.now(),
//       );
//       githubService.githubIssueMock = issue;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNotNull);
//       expect(githubService.labelRemoved, true);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Do not retry merge on non retryable error.', () async {
//       githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult(
//             exception: OperationException(
//               graphqlErrors: [
//                 const GraphQLError(message: 'Branches have diverged. Request cannot be merged.'),
//               ],
//             ),
//           );
//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.useRealComment = true;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       final Issue issue = Issue(
//         id: 1234,
//         assignee: User(login: 'keyonghan'),
//         createdAt: DateTime.now(),
//       );
//       githubService.githubIssueMock = issue;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNotNull);
//       expect(githubService.labelRemoved, true);
//       final IssueComment issueComment = githubService.issueComment!;
//       expect(issueComment.body!.contains('merge attempts were exhausted'), false);
//       expect(issueComment.body!.contains('Failed to merge'), true);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Do not retry merge on multiple errors with retryable error.', () async {
//       githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult(
//             exception: OperationException(
//               graphqlErrors: [
//                 const GraphQLError(message: 'Account does not have merge permissions.'),
//                 const GraphQLError(message: 'Base branch was modified. Review and try the merge again.'),
//               ],
//             ),
//           );

//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.useRealComment = true;
//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       final Issue issue = Issue(
//         id: 1234,
//         assignee: User(login: 'keyonghan'),
//         createdAt: DateTime.now(),
//       );
//       githubService.githubIssueMock = issue;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNotNull);
//       expect(githubService.labelRemoved, true);
//       final IssueComment issueComment = githubService.issueComment!;
//       expect(issueComment.body!.contains('merge attempts were exhausted'), false);
//       expect(issueComment.body!.contains('Failed to merge'), true);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });

//     test('Merge fails the first time but then succeeds after retry.', () async {
//       validationService = RevertRequestValidationService(
//         config,
//         retryOptions: const RetryOptions(
//           delayFactor: Duration.zero,
//           maxDelay: Duration.zero,
//           maxAttempts: 3,
//         ),
//       );

//       githubService.useMergeRequestMockList = true;
//       githubService.pullRequestMergeMockList.add(
//         PullRequestMerge(
//           merged: false,
//           message: 'Unable to merge pull request.',
//         ),
//       );
//       githubService.pullRequestMergeMockList.add(
//         PullRequestMerge(
//           merged: true,
//           sha: 'sha',
//           message: 'Pull Request successfully merged',
//         ),
//       );

//       final PullRequestHelper flutterRequest = PullRequestHelper(
//         prNumber: 0,
//         lastCommitHash: oid,
//         reviews: <PullRequestReviewHelper>[],
//       );

//       githubService.checkRunsData = checkRunsMock;
//       githubService.createCommentData = createCommentMock;
//       githubService.useRealComment = true;

//       final FakePubSub pubsub = FakePubSub();
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         labelName: 'revert',
//         body: 'Reverts flutter/flutter#1234',
//       );

//       // final FakeRevert fakeRevert = FakeRevert(config: config);
//       // fakeRevert.validationResult = ValidationResult(true, Action.REMOVE_LABEL, '');
//       // validationService.revertValidation = fakeRevert;
//       final FakeApproverService fakeApproverService = FakeApproverService(config);
//       validationService.approverService = fakeApproverService;

//       final Issue issue = Issue(
//         id: 1234,
//         assignee: User(login: 'keyonghan'),
//         createdAt: DateTime.now(),
//       );
//       githubService.githubIssueMock = issue;
//       githubService.pullRequestMock = pullRequest;

//       unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
//       final auto.QueryResult queryResult = createQueryResult(flutterRequest);

//       await validationService.processRevertRequest(
//         result: queryResult,
//         messagePullRequest: pullRequest,
//         ackId: 'test',
//         pubsub: pubsub,
//       );

//       // if the merge is successful we do not remove the label and we do not add a comment to the issue.
//       expect(githubService.issueComment, isNull);
//       expect(githubService.labelRemoved, false);
//       // We acknowledge the issue.
//       assert(pubsub.messagesQueue.isEmpty);
//     });
//   });

//   group('Process pull request method tests', () {
//     test('Should process message when revert label exists and pr is open', () async {
//       final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name, state: 'closed');
//       final IssueLabel issueLabel = IssueLabel(name: 'revert of');
//       final List<String> labelNames = ['revert of'];
//       pullRequest.labels = <IssueLabel>[issueLabel];
//       githubService.pullRequestData = pullRequest;
//       final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);
//       expect(revertProcessMethod, RevertProcessMethod.revertOf);
//     });

//     test('Should process message when revert label exists and pr is closed', () async {
//       final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
//       pullRequest.state = 'closed';
//       final IssueLabel issueLabel = IssueLabel(name: 'revert');
//       final List<String> labelNames = ['revert'];
//       pullRequest.labels = <IssueLabel>[issueLabel];
//       githubService.pullRequestData = pullRequest;
//       final RevertProcessMethod revertProcessMethod = await validationService.shouldProcess(pullRequest, labelNames);
//       expect(revertProcessMethod, RevertProcessMethod.revert);
//     });
//   });

//   group('processMerge', () {
//     test('Correct PR titles when merging to use Reland', () async {
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         title: 'Revert "Revert "My first PR!"',
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;
//       githubService.mergeRequestMock = PullRequestMerge(
//         merged: true,
//         sha: pullRequest.mergeCommitSha,
//       );

//       final MergeResult result = await validationService.processMerge(
//         config: config,
//         messagePullRequest: pullRequest,
//       );

//       expect(result.message, contains('Reland "My first PR!"'));
//     });

//     test('includes PR description in commit message', () async {
//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         title: 'PR title',
//         // The test-only helper function `generatePullRequest` will interpolate
//         // this string into a JSON string which will then be decoded--thus, this string must be
//         // a valid JSON substring, with escaped newlines.
//         body: r'PR description\nwhich\nis multiline.',
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;
//       githubService.mergeRequestMock = PullRequestMerge(
//         merged: true,
//         sha: pullRequest.mergeCommitSha,
//       );
//       final MergeResult result = await validationService.processMerge(
//         config: config,
//         messagePullRequest: pullRequest,
//       );

//       expect(result.message, '''
// PR description
// which
// is multiline.''');
//     });

//     test('commit message filters out markdown checkboxes', () async {
//       const String prTitle = 'Important update #4';
//       const String prBody = '''
// Various bugfixes and performance improvements.

// Fixes #12345 and #3.
// This is the second line in a paragraph.

// ## Pre-launch Checklist

// - [ ] I read the [Contributor Guide] and followed the process outlined there for submitting PRs.
// - [ ] I read the [Tree Hygiene] wiki page, which explains my responsibilities.
// - [ ] I read and followed the [Flutter Style Guide], including [Features we expect every widget to implement].
// - [x] I signed the [CLA].
// - [ ] I listed at least one issue that this PR fixes in the description above.
// - [ ] I updated/added relevant documentation (doc comments with `///`).
// - [X] I added new tests to check the change I am making, or this PR is [test-exempt].
// - [ ] All existing and new tests are passing.

// If you need help, consider asking for advice on the #hackers-new channel on [Discord].

// <!-- Links -->
// [Contributor Guide]: https://github.com/flutter/flutter/wiki/Tree-hygiene#overview
// [Tree Hygiene]: https://github.com/flutter/flutter/wiki/Tree-hygiene
// [test-exempt]: https://github.com/flutter/flutter/wiki/Tree-hygiene#tests
// [Flutter Style Guide]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo
// [Features we expect every widget to implement]: https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#features-we-expect-every-widget-to-implement
// [CLA]: https://cla.developers.google.com/
// [flutter/tests]: https://github.com/flutter/tests
// [breaking change policy]: https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes
// [Discord]: https://github.com/flutter/flutter/wiki/Chat''';

//       final PullRequest pullRequest = generatePullRequest(
//         prNumber: 0,
//         repoName: slug.name,
//         title: prTitle,
//         // The test-only helper function `generatePullRequest` will interpolate
//         // this string into a JSON string which will then be decoded--thus, this string must be
//         // a valid JSON substring, with escaped newlines.
//         body: prBody.replaceAll('\n', r'\n'),
//         mergeable: true,
//       );
//       githubService.pullRequestData = pullRequest;
//       githubService.mergeRequestMock = PullRequestMerge(
//         merged: true,
//         sha: pullRequest.mergeCommitSha,
//       );

//       final MergeResult result = await validationService.processMerge(
//         config: config,
//         messagePullRequest: pullRequest,
//       );

//       expect(result.result, isTrue);
//       expect(result.message, '''
// Various bugfixes and performance improvements.

// Fixes #12345 and #3.
// This is the second line in a paragraph.''');
//     });
  // });
}
