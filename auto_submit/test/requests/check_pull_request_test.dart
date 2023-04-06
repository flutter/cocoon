// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names
import 'dart:async';
import 'dart:convert';
import 'package:auto_submit/service/config.dart';

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:auto_submit/service/log.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:googleapis/pubsub/v1.dart' as pub;
import 'package:graphql/client.dart' hide Request, Response;
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

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

      flutterOption = QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: const <String, dynamic>{
          'sOwner': 'flutter',
          'sName': 'flutter',
          'sPrNumber': 0,
        },
      );
      cocoonOption = QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: const <String, dynamic>{
          'sOwner': 'flutter',
          'sName': 'cocoon',
          'sPrNumber': 1,
        },
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
      pullRequests = MockPullRequestsService();
      when(gitHub.pullRequests).thenReturn(pullRequests);
      when(pullRequests.get(any, any)).thenAnswer((_) async => PullRequest(
            number: 123,
            state: 'open',
          ));

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
      githubService.pullRequestData = pullRequest1;
      for (int i = 0; i < 2; i++) {
        unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest1));
      }

      checkPullRequest = CheckPullRequest(
        config: config,
        pubsub: pubsub,
        cronAuthProvider: auth,
      );
      cocoonRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);

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
      when(pullRequests.get(any, any)).thenAnswer((_) async => PullRequest(
            number: 0,
            state: 'close',
          ));
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
      githubService.pullRequestData = pullRequest;
      unawaited(pubsub.publish(
        testTopic,
        pullRequest,
      ));

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
        authorAssociation: '',
      );
      githubService.pullRequestData = pullRequest;
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
          )
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
        unawaited(pubsub.publish(
          'auto-submit-queue-sub',
          pullRequest,
        ));
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

    test('decode test', () {
      print(String.fromCharCodes(base64.decode(
          "eyJpZCI6MTMwMjAzODMzNiwiaHRtbF91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTI0MTM4IiwiZGlmZl91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTI0MTM4LmRpZmYiLCJwYXRjaF91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyL3B1bGwvMTI0MTM4LnBhdGNoIiwibnVtYmVyIjoxMjQxMzgsInN0YXRlIjoib3BlbiIsInRpdGxlIjoiW2ZsdXR0ZXJfdG9vbHNdIFBhc3MgYXBwIGVudHJ5cG9pbnQgdG8gRFdEUyB2ZXJzaW9uIDE5LjAuMCIsImJvZHkiOm51bGwsImNyZWF0ZWRfYXQiOiIyMDIzLTA0LTA0VDE3OjQxOjU0LjAwMFoiLCJ1cGRhdGVkX2F0IjoiMjAyMy0wNC0wNFQxOTowMDo1Mi4wMDBaIiwiY2xvc2VkX2F0IjpudWxsLCJtZXJnZWRfYXQiOm51bGwsImhlYWQiOnsibGFiZWwiOiJlbGxpZXR0ZTpkd2RzLTE5LjAuMCIsInJlZiI6ImR3ZHMtMTkuMC4wIiwic2hhIjoiMjMyZTU4NWRhMWMzZTVmZTljZWE4NjE5NGQ5OWJlYzk3YmVkY2I4NiIsInVzZXIiOnsibG9naW4iOiJlbGxpZXR0ZSIsImlkIjoyMTI3MDg3OCwiYXZhdGFyX3VybCI6Imh0dHBzOi8vYXZhdGFycy5naXRodWJ1c2VyY29udGVudC5jb20vdS8yMTI3MDg3OD92PTQiLCJodG1sX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9lbGxpZXR0ZSIsInNpdGVfYWRtaW4iOmZhbHNlLCJuYW1lIjpudWxsLCJjb21wYW55IjpudWxsLCJibG9nIjpudWxsLCJsb2NhdGlvbiI6bnVsbCwiZW1haWwiOm51bGwsImhpcmFibGUiOm51bGwsImJpbyI6bnVsbCwicHVibGljX3JlcG9zIjpudWxsLCJwdWJsaWNfZ2lzdHMiOm51bGwsImZvbGxvd2VycyI6bnVsbCwiZm9sbG93aW5nIjpudWxsLCJjcmVhdGVkX2F0IjpudWxsLCJ1cGRhdGVkX2F0IjpudWxsLCJ0d2l0dGVyX3VzZXJuYW1lIjpudWxsfSwicmVwbyI6eyJuYW1lIjoiZmx1dHRlciIsImlkIjozOTUxMzg4MjksImZ1bGxfbmFtZSI6ImVsbGlldHRlL2ZsdXR0ZXIiLCJvd25lciI6eyJsb2dpbiI6ImVsbGlldHRlIiwiaWQiOjIxMjcwODc4LCJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9hdmF0YXJzLmdpdGh1YnVzZXJjb250ZW50LmNvbS91LzIxMjcwODc4P3Y9NCIsImh0bWxfdXJsIjoiaHR0cHM6Ly9naXRodWIuY29tL2VsbGlldHRlIn0sInByaXZhdGUiOmZhbHNlLCJmb3JrIjp0cnVlLCJodG1sX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9lbGxpZXR0ZS9mbHV0dGVyIiwiZGVzY3JpcHRpb24iOiJGbHV0dGVyIG1ha2VzIGl0IGVhc3kgYW5kIGZhc3QgdG8gYnVpbGQgYmVhdXRpZnVsIGFwcHMgZm9yIG1vYmlsZSBhbmQgYmV5b25kLiIsImNsb25lX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9lbGxpZXR0ZS9mbHV0dGVyLmdpdCIsInNzaF91cmwiOiJnaXRAZ2l0aHViLmNvbTplbGxpZXR0ZS9mbHV0dGVyLmdpdCIsInN2bl91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZWxsaWV0dGUvZmx1dHRlciIsImdpdF91cmwiOiJnaXQ6Ly9naXRodWIuY29tL2VsbGlldHRlL2ZsdXR0ZXIuZ2l0IiwiaG9tZXBhZ2UiOiJodHRwczovL2ZsdXR0ZXIuZGV2Iiwic2l6ZSI6MjUwNTQ0LCJzdGFyZ2F6ZXJzX2NvdW50IjowLCJ3YXRjaGVyc19jb3VudCI6MCwibGFuZ3VhZ2UiOiJEYXJ0IiwiaGFzX2lzc3VlcyI6ZmFsc2UsImhhc193aWtpIjp0cnVlLCJoYXNfZG93bmxvYWRzIjp0cnVlLCJoYXNfcGFnZXMiOmZhbHNlLCJmb3Jrc19jb3VudCI6MCwib3Blbl9pc3N1ZXNfY291bnQiOjAsImRlZmF1bHRfYnJhbmNoIjoibWFzdGVyIiwic3Vic2NyaWJlcnNfY291bnQiOjAsIm5ldHdvcmtfY291bnQiOjAsImNyZWF0ZWRfYXQiOiIyMDIxLTA4LTExVDIzOjIwOjA1LjAwMFoiLCJwdXNoZWRfYXQiOiIyMDIzLTA0LTA0VDE3OjQwOjU0LjAwMFoiLCJ1cGRhdGVkX2F0IjoiMjAyMS0xMS0xOFQyMjozOToyMy4wMDBaIiwibGljZW5zZSI6eyJrZXkiOiJic2QtMy1jbGF1c2UiLCJuYW1lIjoiQlNEIDMtQ2xhdXNlIFwiTmV3XCIgb3IgXCJSZXZpc2VkXCIgTGljZW5zZSIsInNwZHhfaWQiOiJCU0QtMy1DbGF1c2UiLCJ1cmwiOiJodHRwczovL2FwaS5naXRodWIuY29tL2xpY2Vuc2VzL2JzZC0zLWNsYXVzZSIsIm5vZGVfaWQiOiJNRGM2VEdsalpXNXpaVFU9In0sImFyY2hpdmVkIjpmYWxzZSwiZGlzYWJsZWQiOmZhbHNlLCJwZXJtaXNzaW9ucyI6bnVsbH19LCJiYXNlIjp7ImxhYmVsIjoiZmx1dHRlcjptYXN0ZXIiLCJyZWYiOiJtYXN0ZXIiLCJzaGEiOiJmOTg1N2RmNmIzMTY4YmQ5M2I2ODgwNmVlZmY5MzEzZWZmMzczYjc4IiwidXNlciI6eyJsb2dpbiI6ImZsdXR0ZXIiLCJpZCI6MTQxMDE3NzYsImF2YXRhcl91cmwiOiJodHRwczovL2F2YXRhcnMuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3UvMTQxMDE3NzY/dj00IiwiaHRtbF91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlciIsInNpdGVfYWRtaW4iOmZhbHNlLCJuYW1lIjpudWxsLCJjb21wYW55IjpudWxsLCJibG9nIjpudWxsLCJsb2NhdGlvbiI6bnVsbCwiZW1haWwiOm51bGwsImhpcmFibGUiOm51bGwsImJpbyI6bnVsbCwicHVibGljX3JlcG9zIjpudWxsLCJwdWJsaWNfZ2lzdHMiOm51bGwsImZvbGxvd2VycyI6bnVsbCwiZm9sbG93aW5nIjpudWxsLCJjcmVhdGVkX2F0IjpudWxsLCJ1cGRhdGVkX2F0IjpudWxsLCJ0d2l0dGVyX3VzZXJuYW1lIjpudWxsfSwicmVwbyI6eyJuYW1lIjoiZmx1dHRlciIsImlkIjozMTc5MjgyNCwiZnVsbF9uYW1lIjoiZmx1dHRlci9mbHV0dGVyIiwib3duZXIiOnsibG9naW4iOiJmbHV0dGVyIiwiaWQiOjE0MTAxNzc2LCJhdmF0YXJfdXJsIjoiaHR0cHM6Ly9hdmF0YXJzLmdpdGh1YnVzZXJjb250ZW50LmNvbS91LzE0MTAxNzc2P3Y9NCIsImh0bWxfdXJsIjoiaHR0cHM6Ly9naXRodWIuY29tL2ZsdXR0ZXIifSwicHJpdmF0ZSI6ZmFsc2UsImZvcmsiOmZhbHNlLCJodG1sX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIiLCJkZXNjcmlwdGlvbiI6IkZsdXR0ZXIgbWFrZXMgaXQgZWFzeSBhbmQgZmFzdCB0byBidWlsZCBiZWF1dGlmdWwgYXBwcyBmb3IgbW9iaWxlIGFuZCBiZXlvbmQiLCJjbG9uZV91cmwiOiJodHRwczovL2dpdGh1Yi5jb20vZmx1dHRlci9mbHV0dGVyLmdpdCIsInNzaF91cmwiOiJnaXRAZ2l0aHViLmNvbTpmbHV0dGVyL2ZsdXR0ZXIuZ2l0Iiwic3ZuX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIiLCJnaXRfdXJsIjoiZ2l0Oi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0IiwiaG9tZXBhZ2UiOiJodHRwczovL2ZsdXR0ZXIuZGV2Iiwic2l6ZSI6MjUyMDg1LCJzdGFyZ2F6ZXJzX2NvdW50IjoxNTE3NDUsIndhdGNoZXJzX2NvdW50IjoxNTE3NDUsImxhbmd1YWdlIjoiRGFydCIsImhhc19pc3N1ZXMiOnRydWUsImhhc193aWtpIjp0cnVlLCJoYXNfZG93bmxvYWRzIjp0cnVlLCJoYXNfcGFnZXMiOmZhbHNlLCJmb3Jrc19jb3VudCI6MjUwMjQsIm9wZW5faXNzdWVzX2NvdW50IjoxMTUwOCwiZGVmYXVsdF9icmFuY2giOiJtYXN0ZXIiLCJzdWJzY3JpYmVyc19jb3VudCI6MCwibmV0d29ya19jb3VudCI6MCwiY3JlYXRlZF9hdCI6IjIwMTUtMDMtMDZUMjI6NTQ6NTguMDAwWiIsInB1c2hlZF9hdCI6IjIwMjMtMDQtMDRUMTg6NTk6NTkuMDAwWiIsInVwZGF0ZWRfYXQiOiIyMDIzLTA0LTA0VDE4OjQyOjI3LjAwMFoiLCJsaWNlbnNlIjp7ImtleSI6ImJzZC0zLWNsYXVzZSIsIm5hbWUiOiJCU0QgMy1DbGF1c2UgXCJOZXdcIiBvciBcIlJldmlzZWRcIiBMaWNlbnNlIiwic3BkeF9pZCI6IkJTRC0zLUNsYXVzZSIsInVybCI6Imh0dHBzOi8vYXBpLmdpdGh1Yi5jb20vbGljZW5zZXMvYnNkLTMtY2xhdXNlIiwibm9kZV9pZCI6Ik1EYzZUR2xqWlc1elpUVT0ifSwiYXJjaGl2ZWQiOmZhbHNlLCJkaXNhYmxlZCI6ZmFsc2UsInBlcm1pc3Npb25zIjpudWxsfX0sInVzZXIiOnsibG9naW4iOiJlbGxpZXR0ZSIsImlkIjoyMTI3MDg3OCwiYXZhdGFyX3VybCI6Imh0dHBzOi8vYXZhdGFycy5naXRodWJ1c2VyY29udGVudC5jb20vdS8yMTI3MDg3OD92PTQiLCJodG1sX3VybCI6Imh0dHBzOi8vZ2l0aHViLmNvbS9lbGxpZXR0ZSIsInNpdGVfYWRtaW4iOmZhbHNlLCJuYW1lIjpudWxsLCJjb21wYW55IjpudWxsLCJibG9nIjpudWxsLCJsb2NhdGlvbiI6bnVsbCwiZW1haWwiOm51bGwsImhpcmFibGUiOm51bGwsImJpbyI6bnVsbCwicHVibGljX3JlcG9zIjpudWxsLCJwdWJsaWNfZ2lzdHMiOm51bGwsImZvbGxvd2VycyI6bnVsbCwiZm9sbG93aW5nIjpudWxsLCJjcmVhdGVkX2F0IjpudWxsLCJ1cGRhdGVkX2F0IjpudWxsLCJ0d2l0dGVyX3VzZXJuYW1lIjpudWxsfSwiZHJhZnQiOmZhbHNlLCJtZXJnZV9jb21taXRfc2hhIjoiMjRiMjRkNzY4OTdhNWFmNmMzMDc1ZDNkMjQyMzMxZjYxY2Y3MmJkNSIsIm1lcmdlZCI6ZmFsc2UsIm1lcmdlYWJsZSI6dHJ1ZSwibWVyZ2VkX2J5IjpudWxsLCJjb21tZW50cyI6MywiY29tbWl0cyI6MiwiYWRkaXRpb25zIjo3LCJkZWxldGlvbnMiOjQsImNoYW5nZWRfZmlsZXMiOjIsImxhYmVscyI6W3sibmFtZSI6InRlYW0iLCJjb2xvciI6ImQ0YzVmOSIsImRlc2NyaXB0aW9uIjoiSW5mcmEgdXBncmFkZXMsIHRlYW0gcHJvZHVjdGl2aXR5LCBjb2RlIGhlYWx0aCwgdGVjaG5pY2FsIGRlYnQuIFNlZSBhbHNvIHRlYW06IGxhYmVscy4ifSx7Im5hbWUiOiJ0b29sIiwiY29sb3IiOiI1MzE5ZTciLCJkZXNjcmlwdGlvbiI6IkFmZmVjdHMgdGhlIFwiZmx1dHRlclwiIGNvbW1hbmQtbGluZSB0b29sLiBTZWUgYWxzbyB0OiBsYWJlbHMuIn0seyJuYW1lIjoiYXV0b3N1Ym1pdCIsImNvbG9yIjoiMEU4QTE2IiwiZGVzY3JpcHRpb24iOiJNZXJnZSBQUiB3aGVuIHRyZWUgYmVjb21lcyBncmVlbiB2aWEgYXV0byBzdWJtaXQgQXBwIn1dLCJyZXF1ZXN0ZWRfcmV2aWV3ZXJzIjpbXSwicmV2aWV3X2NvbW1lbnRzIjowLCJtaWxlc3RvbmUiOm51bGwsInJlYmFzZWFibGUiOnRydWUsIm1lcmdlYWJsZV9zdGF0ZSI6InVuc3RhYmxlIiwibWFpbnRhaW5lcl9jYW5fbW9kaWZ5Ijp0cnVlLCJhdXRob3JfYXNzb2NpYXRpb24iOiJNRU1CRVIiLCJyZXBvIjpudWxsfQ==")));
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
