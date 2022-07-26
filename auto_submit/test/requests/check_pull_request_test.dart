// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names
import 'package:auto_submit/service/config.dart';

import 'package:auto_submit/service/log.dart';
import 'package:logging/logging.dart';
import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:graphql/client.dart' hide Request, Response;

import '../utilities/mocks.dart';
import '../utilities/utils.dart' hide createQueryResult;
import './github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';

const String oid = '6dcb09b5b57875f334f61aebed695e2e4193db5e';
const String title = 'some_title';

void main() {
  group('Check CheckPullRequest', () {
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    late FakeCronAuthProvider auth;
    late FakeGraphQLClient githubGraphQLClient;
    final FakeGithubService githubService = FakeGithubService();
    late MockPullRequestsService pullRequests;
    final MockGitHub gitHub = MockGitHub();
    final FakePubSub pubsub = FakePubSub();
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
      expectedOptions = <QueryOptions>[];

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
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
      pullRequests = MockPullRequestsService();
      when(gitHub.pullRequests).thenReturn(pullRequests);
      when(pullRequests.get(any, any)).thenAnswer((_) async => PullRequest(number: 123, state: 'open'));
    });

    void _verifyQueries(List<QueryOptions> expectedOptions) {
      githubGraphQLClient.verifyQueries(expectedOptions);
    }

    test('Multiple identical messages are processed once', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0, repoName: cocoonRepo);
      for (int i = 0; i < 3; i++) {
        pubsub.publish('auto-submit-queue-sub', pullRequest1);
      }

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      cocoonRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);
      await checkPullRequest.get();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(pullRequest1.number!.toString(), pullRequest1.number!.toString()),
          ),
        ],
      );
      expect(0, pubsub.messagesQueue.length);
    });

    test('Closed PRs are not processed', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0, repoName: cocoonRepo, state: 'close');
      when(pullRequests.get(any, any)).thenAnswer((_) async => PullRequest(number: 0, state: 'close'));
      for (int i = 0; i < 3; i++) {
        pubsub.publish('auto-submit-queue-sub', pullRequest1);
      }

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      cocoonRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);
      await checkPullRequest.get();

      githubGraphQLClient.verifyMutations(
        <MutationOptions>[],
      );
      expect(0, pubsub.messagesQueue.length);
    });

    test('Merge exception is handled correctly', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      int errorIndex = 0;
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
      );
      cocoonRequest = PullRequestHelper(prNumber: 1, lastCommitHash: oid);
      githubGraphQLClient.mutateResultForOptions = (_) {
        if (errorIndex == 0) {
          errorIndex++;
          throw const GraphQLError(message: 'error');
        }
        return createQueryResult(cocoonRequest);
      };
      final List<LogRecord> records = <LogRecord>[];
      log.onRecord.listen((LogRecord record) => records.add(record));
      await checkPullRequest.get();
      expect(pubsub.messagesQueue.length, 1);
      final List<LogRecord> errorLogs = records.where((LogRecord record) => record.level == Level.SEVERE).toList();
      expect(errorLogs.length, 1);
      expect(errorLogs[0].message.contains('_processMerge'), true);
      pubsub.messagesQueue.clear();
    });

    test('Merges PR with successful status and checks', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);

      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);
      cocoonRequest = PullRequestHelper(prNumber: 1, lastCommitHash: oid);

      await checkPullRequest.get();
      // expectedOptions.add(flutterOption);
      // expectedOptions.add(cocoonOption);
      // _verifyQueries(expectedOptions);
      // githubGraphQLClient.verifyMutations(
      //   <MutationOptions>[
      //     MutationOptions(
      //       document: mergePullRequestMutation,
      //       variables: getMergePullRequestVariables(pullRequest1.number!.toString(), pullRequest1.number!.toString()),
      //     ),
      //     MutationOptions(
      //       document: mergePullRequestMutation,
      //       variables: getMergePullRequestVariables(pullRequest2.number!.toString(), pullRequest2.number!.toString()),
      //     ),
      //   ],
      // );
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges unapproved PR from autoroller', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, author: rollorAuthor);
      pubsub.publish(testTopic, pullRequest);

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
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        author: 'dependabot',
        reviews: const <PullRequestReviewHelper>[],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(pullRequest.number!.toString(), pullRequest.number!.toString()),
          ),
        ],
      );
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, labelName: labelName);
      pubsub.publish(testTopic, pullRequest);

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(pullRequest.number!.toString(), pullRequest.number!.toString()),
          ),
        ],
      );
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

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
      _verifyQueries(expectedOptions);
      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables(pullRequest.number!.toString(), pullRequest.number!.toString()),
          ),
        ],
      );
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      pubsub.publish(testTopic, pullRequest);

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

      cocoonRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[],
      );

      await checkPullRequest.get();
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      githubGraphQLClient.verifyMutations(
        <MutationOptions>[
          MutationOptions(
            document: mergePullRequestMutation,
            variables: getMergePullRequestVariables('0', pullRequest.number!.toString()),
          ),
        ],
      );
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with neutral status checkrun', () async {
      PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
      githubService.checkRunsData = neutralCheckRunsMock;
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);
      cocoonRequest = PullRequestHelper(prNumber: 1, lastCommitHash: oid);

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed tests', () async {
      PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
      githubService.checkRunsData = failedCheckRunsMock;
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(prNumber: 0, lastCommitHash: oid);
      cocoonRequest = PullRequestHelper(prNumber: 1, lastCommitHash: oid);

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed status', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

      flutterRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
          StatusHelper.otherStatusFailure,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, authorAssociation: '');
      pubsub.publish(testTopic, pullRequest);

      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

      flutterRequest = PullRequestHelper(
        authorAssociation: '',
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with null checks and statuses', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = emptyCheckRunsMock;
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);

      flutterRequest = PullRequestHelper(
        lastCommitHash: oid,
        lastCommitStatuses: const <StatusHelper>[],
      );

      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Does not merge PR with in progress checks', () async {
      PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
      githubService.checkRunsData = inProgressCheckRunsMock;
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);
      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      expect(pubsub.messagesQueue.length, 2);
      pubsub.messagesQueue.clear();
    });

    test('Does not merge PR if no autosubmit label any more', () async {
      PullRequest pullRequest1 = generatePullRequest(prNumber: 0, autosubmitLabel: noAutosubmitLabel);
      PullRequest pullRequest2 =
          generatePullRequest(prNumber: 1, autosubmitLabel: noAutosubmitLabel, repoName: cocoonRepo);
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);
      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Self review is disallowed', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, author: 'some_rando');
      pubsub.publish(testTopic, pullRequest);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub, cronAuthProvider: auth);
      flutterRequest = PullRequestHelper(
        author: 'some_rando',
        lastCommitHash: oid,
        authorAssociation: 'MEMBER',
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
              authorName: 'some_rando', state: ReviewState.APPROVED, memberType: MemberType.MEMBER)
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );
      await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      assert(pubsub.messagesQueue.isEmpty);
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

Map<String, dynamic> getMergePullRequestVariables(String id, String number) {
  return <String, dynamic>{
    'id': id,
    'oid': oid,
    'title': '$title (#$number)',
  };
}
