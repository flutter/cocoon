// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: constant_identifier_names

import 'package:auto_submit/requests/check_pull_request.dart';
import 'package:auto_submit/requests/check_pull_request_queries.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:graphql/client.dart' hide Response;

import './github_webhook_test_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';

void main() {
  group('Check CheckPullRequest', () {
    late CheckPullRequest checkPullRequest;
    late FakeConfig config;
    late FakeGraphQLClient githubGraphQLClient;
    final FakeGithubService githubService = FakeGithubService();
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
      expectedOptions = <QueryOptions>[];

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
        variables: <String, dynamic>{
          'sOwner': 'flutter',
          'sName': 'flutter',
          'sPrNumber': 0,
        },
      );
      cocoonOption = QueryOptions(
        document: pullRequestWithReviewsQuery,
        fetchPolicy: FetchPolicy.noCache,
        variables: <String, dynamic>{
          'sOwner': 'flutter',
          'sName': 'cocoon',
          'sPrNumber': 1,
        },
      );
    });

    void _verifyQueries(List<QueryOptions> expectedOptions) {
      githubGraphQLClient.verifyQueries(expectedOptions);
    }

    test('Merges PR with successful status and checks', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0);
      final PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      final List<PullRequest> pullRequests = <PullRequest>[pullRequest1, pullRequest2];
      for (PullRequest pr in pullRequests) {
        pubsub.publish(testTopic, pr);
      }

      githubService.checkRunsData = checkRunsMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      for (int index = 0; index < responses.length; index++) {
        final String resBody = await responses[index].readAsString();
        expect(resBody,
            'Should merge the pull request ${pullRequests[index].number} in ${pullRequests[index].base!.repo!.slug().fullName} repository.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges unapproved PR from autoroller', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, author: rollorAuthor);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        reviews: const <PullRequestReviewHelper>[],
      );
      cocoonRequest = PullRequestHelper(
        prNumber: 1,
        reviews: const <PullRequestReviewHelper>[],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody,
          'Should merge the pull request ${pullRequest.number} in ${pullRequest.base!.repo!.slug().fullName} repository.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with failed tree status if override tree status label is provided', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, labelName: labelName);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildFailure,
        ],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody,
          'Should merge the pull request ${pullRequest.number} in ${pullRequest.base!.repo!.slug().fullName} repository.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges a clean revert PR with in progress tests', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);
      githubService.checkRunsData = inProgressCheckRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareToTCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
        lastCommitMessage: 'Revert "This is a test PR" This reverts commit abc.',
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody,
          'Should merge the pull request ${pullRequest.number} in ${pullRequest.base!.repo!.slug().fullName} repository.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges PR with successful checks on repo without tree status', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 1, repoName: cocoonRepo);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      cocoonRequest = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);

      final String resBody = await responses[0].readAsString();
      expect(resBody,
          'Should merge the pull request ${pullRequest.number} in ${pullRequest.base!.repo!.slug().fullName} repository.');
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
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      for (int index = 0; index < responses.length; index++) {
        final String resBody = await responses[index].readAsString();
        expect(resBody, 'Remove the autosubmit label for commit: ${pullRequests[index].head!.sha}.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with failed status', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.otherStatusFailure,
        ],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody, 'Remove the autosubmit label for commit: ${pullRequest.head!.sha}.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label if non member does not have at least 2 member reviews', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, authorAssociation: '');
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        authorAssociation: '',
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody, 'Remove the autosubmit label for commit: ${pullRequest.head!.sha}.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Removes the label for the PR with null checks and statuses', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0);
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = emptyCheckRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        lastCommitStatuses: const <StatusHelper>[],
      );

      final List<Response> responses = await checkPullRequest.get();
      final String resBody = await responses[0].readAsString();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      expect(resBody, 'Remove the autosubmit label for commit: ${pullRequest.head!.sha}.');
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
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      for (int index = 0; index < responses.length; index++) {
        final String resBody = await responses[index].readAsString();
        expect(resBody, 'Does not merge the pull request ${pullRequests[index].number}.');
      }
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
      githubService.checkRunsData = checkRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      flutterRequest = PullRequestHelper(prNumber: 0);
      cocoonRequest = PullRequestHelper(prNumber: 1);

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      expectedOptions.add(cocoonOption);
      _verifyQueries(expectedOptions);
      for (int index = 0; index < responses.length; index++) {
        final String resBody = await responses[index].readAsString();
        expect(
            resBody,
            'Does not merge the pull request ${pullRequests[index].number} '
            'for no autosubmit label any more.');
      }
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Self review is disallowed', () async {
      PullRequest pullRequest = generatePullRequest(prNumber: 0, author: 'some_rando');
      pubsub.publish(testTopic, pullRequest);

      githubService.checkRunsData = checkRunsMock;
      githubService.commitData = commitMock;
      githubService.compareTowCommitsData = compareTowCommitsMock;
      githubService.successMergeData = successMergeMock;
      githubService.createCommentData = createCommentMock;
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);

      flutterRequest = PullRequestHelper(
        authorAssociation: 'MEMBER',
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
              authorName: 'some_rando', state: ReviewState.APPROVED, memberType: MemberType.MEMBER)
        ],
        lastCommitStatuses: const <StatusHelper>[
          StatusHelper.flutterBuildSuccess,
        ],
      );

      final List<Response> responses = await checkPullRequest.get();
      expectedOptions.add(flutterOption);
      _verifyQueries(expectedOptions);
      final String resBody = await responses[0].readAsString();
      expect(resBody, 'Remove the autosubmit label for commit: ${pullRequest.head!.sha}.');
      assert(pubsub.messagesQueue.isEmpty);
    });

    test('Merges only _kMergeCountPerRepo PR per cycle per repo', () async {
      final PullRequest pullRequest1 = generatePullRequest(prNumber: 0, repoName: 'flutter', login: 'flutter');
      final PullRequest pullRequest2 = generatePullRequest(prNumber: 1, repoName: 'flutter', login: 'flutter');
      final PullRequest pullRequest3 = generatePullRequest(prNumber: 2, repoName: cocoonRepo, login: 'flutter');
      config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
      checkPullRequest = CheckPullRequest(config: config, pubsub: pubsub);
      final Map<String, Set<PullRequest>> repoPullRequestsMap = <String, Set<PullRequest>>{
        'flutter/flutter': <PullRequest>{pullRequest1, pullRequest2},
        'flutter/cocoon': <PullRequest>{pullRequest3}
      };

      List<Map<int, String>> mergeResult = await checkPullRequest.checkPullRequests(repoPullRequestsMap);
      expect(mergeResult[0], <int, String>{0: 'merged'});
      expect(mergeResult[1], <int, String>{1: 'queued'});
      expect(mergeResult[2], <int, String>{2: 'merged'});
      expect(pubsub.messagesQueue.length, 1);
      pubsub.messagesQueue.clear();
    });
  });
}

enum ReviewState {
  APPROVED,
  CHANGES_REQUESTED,
}

enum MemberType {
  OWNER,
  MEMBER,
  OTHER,
}

@immutable
class PullRequestReviewHelper {
  const PullRequestReviewHelper({
    required this.authorName,
    required this.state,
    required this.memberType,
  });

  final String authorName;
  final ReviewState state;
  final MemberType memberType;
}

@immutable
class StatusHelper {
  const StatusHelper(this.name, this.state);

  static const StatusHelper flutterBuildSuccess = StatusHelper('luci-flutter', 'SUCCESS');
  static const StatusHelper flutterBuildFailure = StatusHelper('luci-flutter', 'FAILURE');
  static const StatusHelper otherStatusFailure = StatusHelper('other status', 'FAILURE');

  final String name;
  final String state;
}

class PullRequestHelper {
  PullRequestHelper({
    this.prNumber = 0,
    this.repo = 'flutter',
    this.authorAssociation = 'MEMBER',
    this.reviews = const <PullRequestReviewHelper>[
      PullRequestReviewHelper(authorName: 'member', state: ReviewState.APPROVED, memberType: MemberType.MEMBER)
    ],
    this.lastCommitHash = 'oid',
    this.lastCommitStatuses = const <StatusHelper>[StatusHelper.flutterBuildSuccess],
    this.lastCommitMessage = '',
    this.dateTime,
  }) : _count = _counter++;

  static int _counter = 0;

  final int _count;
  String get id => _count.toString();

  final int prNumber;
  final String repo;
  final String authorAssociation;
  final List<PullRequestReviewHelper> reviews;
  final String lastCommitHash;
  List<StatusHelper>? lastCommitStatuses;
  final String? lastCommitMessage;
  final DateTime? dateTime;

  RepositorySlug get slug => RepositorySlug('flutter', repo);

  Map<String, dynamic> toEntry() {
    return <String, dynamic>{
      'authorAssociation': authorAssociation,
      'reviews': <String, dynamic>{
        'nodes': reviews.map((PullRequestReviewHelper review) {
          return <String, dynamic>{
            'author': <String, dynamic>{'login': review.authorName},
            'authorAssociation': review.memberType.toString().replaceFirst('MemberType.', ''),
            'state': review.state.toString().replaceFirst('ReviewState.', ''),
          };
        }).toList(),
      },
      'commits': <String, dynamic>{
        'nodes': <dynamic>[
          <String, dynamic>{
            'commit': <String, dynamic>{
              'oid': lastCommitHash,
              'pushedDate': (dateTime ?? DateTime.now().add(const Duration(hours: -2))).toUtc().toIso8601String(),
              'message': lastCommitMessage,
              'status': <String, dynamic>{
                'contexts': lastCommitStatuses != null
                    ? lastCommitStatuses!.map((StatusHelper status) {
                        return <String, dynamic>{
                          'context': status.name,
                          'state': status.state,
                          'targetUrl': 'https://${status.name}',
                        };
                      }).toList()
                    : <dynamic>[]
              },
            },
          }
        ],
      },
    };
  }
}

QueryResult createQueryResult(PullRequestHelper pullRequest) {
  return QueryResult(
    data: <String, dynamic>{
      'repository': <String, dynamic>{
        'pullRequest': pullRequest.toEntry().cast<String, dynamic>(),
      },
    },
    source: QueryResultSource.network,
  );
}
