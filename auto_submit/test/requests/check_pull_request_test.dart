// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/config.dart';

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:auto_submit/requests/graphql_queries.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:graphql/client.dart' hide Request, Response;
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../service/bigquery_test.dart';
import '../src/service/fake_bigquery_service.dart';
import './github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/mocks.dart';
import '../utilities/utils.dart' hide createQueryResult;

const String oid = '6dcb09b5b57875f334f61aebed695e2e4193db5e';
const String title = 'some_title';

void main() {
  group('Check CheckPullRequest', () {
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    late FakeCronAuthProvider auth;
    late FakeGraphQLClient githubGraphQLClient;
    late FakeGithubService githubService;
    late MockJobsResource jobsResource;
    late FakeBigqueryService bigqueryService;
    late MockPullRequestsService pullRequests;
    final MockGitHub gitHub = MockGitHub();
    late FakePubSub pubsub;
    late PullRequestHelper flutterRequest;
    late PullRequestHelper cocoonRequest;
    late List<QueryOptions> expectedOptions;
    late QueryOptions flutterOption;
    late QueryOptions cocoonOption;
    const String testTopic = 'test-topic';
    const String rollorAuthor = "engine-flutter-autoroll";
    const String labelName = "warning: land on red to fix tree breakage";
    const String cocoonRepo = 'cocoon';
    const String noAutosubmitLabel = 'no_autosubmit';

    setUp(() {
      githubGraphQLClient = FakeGraphQLClient();
      auth = FakeCronAuthProvider();
      pubsub = FakePubSub();
      expectedOptions = <QueryOptions>[];
      githubService = FakeGithubService();

      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) => createFakeQueryResult();

      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        expect(options.variables['sOwner'], 'flutter');
        final String? repoName = options.variables['sName'] as String?;
        if (repoName == 'flutter') {
          return createQueryResult(flutterRequest);
        } else if (repoName == 'cocoon') {
          return createQueryResult(cocoonRequest);
        } else {
          fail('unexpected repo $repoName');
        }
      };

      final FindPullRequestsWithReviewsQuery findPullRequestsWithReviewsQueryFlutter = FindPullRequestsWithReviewsQuery(
        repositoryOwner: 'flutter',
        repositoryName: 'flutter',
        pullRequestNumber: 0,
      );

      flutterOption = QueryOptions(
        document: findPullRequestsWithReviewsQueryFlutter.documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: findPullRequestsWithReviewsQueryFlutter.variables,
      );

      final FindPullRequestsWithReviewsQuery findPullRequestsWithReviewsQueryCocoon = FindPullRequestsWithReviewsQuery(
        repositoryOwner: 'flutter',
        repositoryName: 'cocoon',
        pullRequestNumber: 1,
      );

      cocoonOption = QueryOptions(
        document: findPullRequestsWithReviewsQueryCocoon.documentNode,
        fetchPolicy: FetchPolicy.noCache,
        variables: findPullRequestsWithReviewsQueryCocoon.variables,
      );

      githubService.checkRunsData = checkRunsMock;
      githubService.compareTwoCommitsData = compareTwoCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      githubService.commitData = commitMock;
      jobsResource = MockJobsResource();
      bigqueryService = FakeBigqueryService(jobsResource);
      config = FakeConfig(
        githubService: githubService,
        githubGraphQLClient: githubGraphQLClient,
        githubClient: gitHub,
      );
      config.bigqueryService = bigqueryService;
      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
      pullRequests = MockPullRequestsService();
      when(gitHub.pullRequests).thenReturn(pullRequests);
      when(pullRequests.get(any, any)).thenAnswer(
        (_) async => PullRequest(
          number: 123,
          state: 'open',
        ),
      );

      when(jobsResource.query(captureAny, any)).thenAnswer((Invocation invocation) {
        return Future<QueryResponse>.value(
          QueryResponse.fromJson(jsonDecode(insertDeleteUpdateSuccessResponse) as Map<dynamic, dynamic>),
        );
      });
    });

    void verifyQueries(List<QueryOptions> expectedOptions) {
      githubGraphQLClient.verifyQueries(expectedOptions);
    }

    test('Multiple identical messages are processed once', () async {
      final PullRequest pullRequest1 = generatePullRequest(
        prNumber: 0,
        repoName: cocoonRepo,
      );
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.pullRequestData = pullRequest1;
      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest1));
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug('flutter', cocoonRepo);

      await checkPullRequest.get();

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      expect(0, pubsub.messagesQueue.length);
    });

    test('Closed PRs are not processed', () async {
      final PullRequest pullRequest1 = generatePullRequest(
        prNumber: 0,
        repoName: cocoonRepo,
        state: 'close',
      );
      githubService.pullRequestData = pullRequest1;
      when(pullRequests.get(any, any)).thenAnswer(
        (_) async => PullRequest(
          number: 0,
          state: 'close',
        ),
      );
      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest1));
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      await checkPullRequest.get();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[],
      );
      expect(0, pubsub.messagesQueue.length);
    });

    test('Merge exception is handled correctly', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );

      githubService.pullRequestData = pullRequest1;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;

      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        lastCommitHash: oid,
      );

      githubService.useMergeRequestMockList = true;
      githubService.pullRequestMergeMockList.add(
        PullRequestMerge(
          merged: false,
          message: 'Unable to merge pull request',
        ),
      );
      githubService.pullRequestMergeMockList.add(
        PullRequestMerge(
          merged: true,
          sha: 'sha',
          message: 'Pull request merged successfully',
        ),
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug(
        'flutter',
        'flutter',
      );
      expectedMergeRequestMap[1] = RepositorySlug(
        'flutter',
        cocoonRepo,
      );

      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      // this is the test.
      await checkPullRequest.get();
      // every failure is now acknowledged from the queue.
      expect(pubsub.messagesQueue.length, 0);
      final List<LogRecord> errorLogs = records.where((LogRecord record) => record.level == Level.SEVERE).toList();
      expect(errorLogs.length, 1);
      expect(errorLogs[0].message.contains('Failed to merge'), true);
      pubsub.messagesQueue.clear();
    });

    test('Merges PR with successful status and checks', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest1;
      // 'octocat' is the pr author from generatePullRequest calls.
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        lastCommitHash: oid,
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      verifyQueries(expectedOptions);

      githubService.useMergeRequestMockList = true;
      githubService.pullRequestMergeMockList.add(
        PullRequestMerge(
          merged: true,
          sha: 'sha1',
          message: 'Pull request merged successfully',
        ),
      );
      githubService.pullRequestMergeMockList.add(
        PullRequestMerge(
          merged: true,
          sha: 'sha2',
          message: 'Pull request merged successfully',
        ),
      );

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug('flutter', 'flutter');
      expectedMergeRequestMap[1] = RepositorySlug('flutter', cocoonRepo);

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges unapproved PR from autoroller', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        author: rollorAuthor,
      );
      githubService.pullRequestData = pullRequest;
      unawaited(pubsub.publish(testTopic, pullRequest));

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
        approverProvider: (Config config) => MockApproverService(),
      );

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        author: 'dependabot',
        reviews: const <PullRequestReviewHelper>[],
        lastCommitHash: oid,
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug(
        'flutter',
        'flutter',
      );

      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'sha1',
        message: 'Pull request merged successfully',
      );

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        labelName: labelName,
      );
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.pullRequestData = pullRequest;
      unawaited(
        pubsub.publish(
          testTopic,
          pullRequest,
        ),
      );

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug(
        'flutter',
        'flutter',
      );

      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'sha1',
        message: 'Pull request merged successfully',
      );

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0);
      githubService.pullRequestData = pullRequest;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      unawaited(pubsub.publish(testTopic, pullRequest));
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
        lastCommitMessage: 'Revert "This is a test PR" This reverts commit abc.',
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[0] = RepositorySlug(
        'flutter',
        'flutter',
      );

      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'sha1',
        message: 'Pull request merged successfully',
      );

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      unawaited(pubsub.publish(testTopic, pullRequest));

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      cocoonRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[],
      );

      await checkPullRequest.get();
      expectedOptions.add(cocoonOption);
      verifyQueries(expectedOptions);

      final Map<int, RepositorySlug> expectedMergeRequestMap = {};
      expectedMergeRequestMap[1] = RepositorySlug(
        'flutter',
        cocoonRepo,
      );

      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'sha1',
        message: 'Pull request merged successfully',
      );

      githubService.verifyMergePullRequests(expectedMergeRequestMap);

      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with neutral status checkrun', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest1;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }
      githubService.checkRunsData = neutralCheckRunsMock;
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        lastCommitHash: oid,
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed tests', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest1;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }
      githubService.checkRunsData = failedCheckRunsMock;
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        lastCommitHash: oid,
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed status', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0);
      githubService.pullRequestData = pullRequest;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      unawaited(pubsub.publish(testTopic, pullRequest));

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
          StatusHelper.otherStatusFailure,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
      );
      githubService.pullRequestData = pullRequest;
      // 'octocat' is the pr author from generatePullRequest calls.
      githubService.isTeamMemberMockMap['octocat'] = false;
      unawaited(pubsub.publish(testTopic, pullRequest));

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        authorAssociation: '',
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with null checks and statuses', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0);
      githubService.pullRequestData = pullRequest;
      // 'octocat' is the pr author from generatePullRequest calls.
      githubService.isTeamMemberMockMap['octocat'] = true;
      unawaited(pubsub.publish(testTopic, pullRequest));

      githubService.checkRunsData = emptyCheckRunsMock;
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );

      flutterRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not merge PR with in progress checks', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest1;
      // 'member' is in the review nodes and 'author1' is the pr author.
      githubService.isTeamMemberMockMap['member'] = true;
      githubService.isTeamMemberMockMap['author1'] = true;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }
      githubService.checkRunsData = inProgressCheckRunsMock;
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);
      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      verifyQueries(expectedOptions);
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      final PullRequest pullRequest1 = generatePullRequest(
        prNumber: 0,
        autosubmitLabel: noAutosubmitLabel,
      );
      final PullRequest pullRequest2 = generatePullRequest(
        prNumber: 1,
        autosubmitLabel: noAutosubmitLabel,
        repoName: cocoonRepo,
      );
      githubService.pullRequestData = pullRequest1;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        unawaited(pubsub.publish(testTopic, pr));
      }
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);
      await checkPullRequest.get();
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Self review is disallowed', () async {
      final PullRequest pullRequest = generatePullRequest(
        prNumber: 0,
        author: 'some_rando',
      );
      githubService.pullRequestData = pullRequest;
      // 'octocat' is the pr author from generatePullRequest calls.
      githubService.isTeamMemberMockMap['some_rando'] = true;
      unawaited(pubsub.publish(testTopic, pullRequest));
      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      flutterRequest = PullRequestHelper(
        author: 'some_rando',
        lastCommitHash: oid,
        authorAssociation: 'MEMBER',
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
            authorName: 'some_rando',
            state: ReviewState.APPROVED,
            memberType: MemberType.MEMBER,
          ),
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );
      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('All messages are pulled', () async {
      for (int i = 0; i < 3; i++) {
        final PullRequest pullRequest = generatePullRequest(
          prNumber: i,
          repoName: cocoonRepo,
        );
        unawaited(
          pubsub.publish(
            'auto-submit-queue-sub',
            pullRequest,
          ),
        );
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      final List<pub.ReceivedMessage> messages = await checkPullRequest.pullMessages();
      expect(messages.length, 3);
    });
  });
}

QueryResult createQueryResult(PullRequestHelper pullRequest) {
  return createFakeQueryResult(
    data: <String, dynamic>{
      'repository': <String, dynamic>{
        'pullRequest': pullRequest.toEntry().cast<String, dynamic>(),
      },
    },
  );
}

Map<String, dynamic> getMergePullRequestVariables(
  String id,
  String number,
) {
  return <String, dynamic>{
    'id': id,
    'oid': oid,
    'title': '$title (#$number)',
  };
}
