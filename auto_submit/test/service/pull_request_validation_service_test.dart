// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/service/pull_request_validation_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/bigquery_testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:graphql/client.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/utils.dart';

void main() {
  late PullRequestValidationService validationService;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late RepositorySlug slug;

  late MockJobsResource jobsResource;
  late FakeBigqueryService bigqueryService;

  setUpAll(() {
    log = Logger('auto_submit');
  });

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
    );
    validationService = PullRequestValidationService(
      config,
      retryOptions: const RetryOptions(
        delayFactor: Duration.zero,
        maxDelay: Duration.zero,
        maxAttempts: 1,
      ),
      subscription: 'test-sub',
    );
    slug = RepositorySlug('flutter', 'cocoon');

    jobsResource = MockJobsResource();
    bigqueryService = FakeBigqueryService(jobsResource);
    config.bigqueryService = bigqueryService;
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
      sampleConfigNoOverride,
    );

    // ignore: discarded_futures
    when(jobsResource.query(captureAny, any)).thenAnswer((
      Invocation invocation,
    ) {
      return Future<QueryResponse>.value(
        QueryResponse.fromJson(
          jsonDecode(insertDeleteUpdateSuccessResponse)
              as Map<dynamic, dynamic>,
        ),
      );
    });
  });

  test(
    'Leaves label and no comment when no approval if both parties are members',
    () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );
      githubService.checkRunsData = checkRunsMock;
      githubService.createCommentData = createCommentMock;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['member'] = true;
      final pubsub = FakePubSub();
      final pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      githubService.pullRequestData = pullRequest;
      unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
      final queryResult = createQueryResult(flutterRequest);

      await validationService.processPullRequest(
        config: config,
        result: queryResult,
        pullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isNotEmpty);
    },
  );

  // This tests for valid pull request into not default base branch which
  // will ignore the tree status as it does not matter.
  test('Processes successfully when base branch is not default', () async {
    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[
        const PullRequestReviewHelper(
          authorName: 'member',
          state: ReviewState.APPROVED,
          memberType: MemberType.OWNER,
        ),
      ],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.checkRunsMock = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    githubService.isTeamMemberMockMap['author1'] = true;
    githubService.isTeamMemberMockMap['member'] = true;
    final pubsub = FakePubSub();
    final pullRequest = generatePullRequest(
      prNumber: 0,
      repoName: slug.name,
      baseRef: 'feature_a',
      mergeable: true,
    );
    unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
    final queryResult = createQueryResult(flutterRequest);
    githubService.pullRequestMock = pullRequest;
    githubService.mergeRequestMock = PullRequestMerge(
      merged: true,
      sha: 'asdfioefmasdf',
      message: 'Merged successfully.',
    );

    await validationService.processPullRequest(
      config: config,
      result: queryResult,
      pullRequest: pullRequest,
      ackId: 'test',
      pubsub: pubsub,
    );

    // These checks indicate that the pull request has been merged, the label
    // was removed, there was no issue comment generated, and the message was
    // acknowledged.
    expect(githubService.issueComment, isNull);
    expect(githubService.labelRemoved, isFalse);
    assert(pubsub.messagesQueue.isEmpty);
  });

  // This tests for valid pull request where tree status was not ready for
  // processing, meaning no issueComment was created and the 'autosubmit' label
  // is not removed and we do not ack the message.
  test(
    'Processing fails when base branch is default with no statuses',
    () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
            authorName: 'member',
            state: ReviewState.APPROVED,
            memberType: MemberType.OWNER,
          ),
        ],
        lastCommitStatuses: null,
      );
      githubService.checkRunsData = checkRunsMock;
      githubService.createCommentData = createCommentMock;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['member'] = true;
      final pubsub = FakePubSub();
      final pullRequest = generatePullRequest(prNumber: 0);
      githubService.pullRequestData = pullRequest;
      unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
      final queryResult = createQueryResult(flutterRequest);

      await validationService.processPullRequest(
        config: config,
        result: queryResult,
        pullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, false);
      assert(pubsub.messagesQueue.isNotEmpty);
    },
  );

  group('Process pull request method tests', () {
    test(
      'Should process message when autosubmit label exists and pr is open',
      () async {
        final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
        );
        githubService.pullRequestData = pullRequest;
        expect(validationService.shouldProcess(pullRequest), true);
      },
    );

    test(
      'Skip processing message when autosubmit label does not exist anymore',
      () async {
        final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
        );
        pullRequest.labels = <IssueLabel>[];
        githubService.pullRequestData = pullRequest;
        expect(validationService.shouldProcess(pullRequest), false);
      },
    );

    test('Skip processing message when the pull request is closed', () async {
      final pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      githubService.pullRequestData = pullRequest;
      expect(validationService.shouldProcess(pullRequest), false);
    });

    test(
      'Should not process message when revert label exists and pr is open',
      () async {
        final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
        );
        final issueLabel = IssueLabel(name: 'revert');
        pullRequest.labels = <IssueLabel>[issueLabel];
        githubService.pullRequestData = pullRequest;
        expect(validationService.shouldProcess(pullRequest), false);
      },
    );

    test(
      'Skip processing message when revert label exists and pr is closed',
      () async {
        final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
        );
        pullRequest.state = 'closed';
        final issueLabel = IssueLabel(name: 'revert');
        pullRequest.labels = <IssueLabel>[issueLabel];
        githubService.pullRequestData = pullRequest;
        expect(validationService.shouldProcess(pullRequest), false);
      },
    );
  });

  group('submitPullRequest', () {
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

    test(
      'Removes label and post comment when no approval for non-flutter hacker',
      () async {
        final flutterRequest = PullRequestHelper(
          prNumber: 0,
          lastCommitHash: oid,
          reviews: <PullRequestReviewHelper>[],
        );
        githubService.checkRunsData = checkRunsMock;
        githubService.createCommentData = createCommentMock;
        githubService.isTeamMemberMockMap['author1'] = false;
        githubService.isTeamMemberMockMap['member'] = true;
        final pubsub = FakePubSub();
        final pullRequest = generatePullRequest(
          prNumber: 0,
          repoName: slug.name,
        );
        githubService.pullRequestData = pullRequest;
        unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
        final queryResult = createQueryResult(flutterRequest);

        await validationService.processPullRequest(
          config: config,
          result: queryResult,
          pullRequest: pullRequest,
          ackId: 'test',
          pubsub: pubsub,
        );

        expect(githubService.issueComment, isNotNull);
        expect(githubService.labelRemoved, true);
        assert(pubsub.messagesQueue.isEmpty);
      },
    );

    // This tests for valid pull request where tree status was not ready for
    // processing, meaning no issueComment was created and the 'autosubmit' label
    // is not removed and we do not ack the message.
    test(
      'Processing fails when base branch is default with no statuses',
      () async {
        final flutterRequest = PullRequestHelper(
          prNumber: 0,
          lastCommitHash: oid,
          reviews: <PullRequestReviewHelper>[
            const PullRequestReviewHelper(
              authorName: 'member',
              state: ReviewState.APPROVED,
              memberType: MemberType.OWNER,
            ),
          ],
          lastCommitStatuses: null,
        );
        githubService.checkRunsData = checkRunsMock;
        githubService.createCommentData = createCommentMock;
        githubService.isTeamMemberMockMap['author1'] = true;
        githubService.isTeamMemberMockMap['member'] = true;
        final pubsub = FakePubSub();
        final pullRequest = generatePullRequest(prNumber: 0);
        githubService.pullRequestData = pullRequest;
        unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
        final queryResult = createQueryResult(flutterRequest);

        await validationService.processPullRequest(
          config: config,
          result: queryResult,
          pullRequest: pullRequest,
          ackId: 'test',
          pubsub: pubsub,
        );

        expect(githubService.issueComment, isNull);
        expect(githubService.labelRemoved, false);
        assert(pubsub.messagesQueue.isNotEmpty);
      },
    );

    test('Processes successfully when base branch is not default', () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
            authorName: 'member',
            state: ReviewState.APPROVED,
            memberType: MemberType.OWNER,
          ),
        ],
      );
      githubService.checkRunsData = checkRunsMock;
      githubService.checkRunsMock = checkRunsMock;
      githubService.createCommentData = createCommentMock;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['member'] = true;
      final pubsub = FakePubSub();
      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        baseRef: 'feature_a',
        mergeable: true,
      );
      unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
      final queryResult = createQueryResult(flutterRequest);
      githubService.pullRequestMock = pullRequest;
      githubService.mergeRequestMock = PullRequestMerge(
        merged: true,
        sha: 'asdfioefmasdf',
        message: 'Merged successfully.',
      );

      await validationService.processPullRequest(
        config: config,
        result: queryResult,
        pullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      // These checks indicate that the pull request has been merged, the label
      // was removed, there was no issue comment generated, and the message was
      // acknowledged.
      expect(githubService.issueComment, isNull);
      expect(githubService.labelRemoved, isFalse);
      assert(pubsub.messagesQueue.isEmpty);
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

    test('Enqueues pull request when merge queue is used', () async {
      slug = RepositorySlug('flutter', 'flutter');
      final prTitle = 'This pull request should be enqueueueueueueueueueueued';

      Map<String, Object?>? queryOptions;
      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        queryOptions = options.variables;
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          data: {
            'repository': {
              'pullRequest': {'id': 'PR_blahblah'},
            },
          },
        );
      };

      Map<String, Object?>? mutationOptions;
      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) {
        mutationOptions = options.variables;
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          data: {},
        );
      };

      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        title: prTitle,
        mergeable: true,
      );

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.method, SubmitMethod.enqueue);

      expect(queryOptions, {
        'repoOwner': 'flutter',
        'repoName': 'flutter',
        'pullRequestNumber': 0,
      });

      expect(mutationOptions, {'pullRequestId': 'PR_blahblah', 'jump': false});
      expect(result.result, isTrue);
      expect(result.message, contains(prTitle));
    });

    test(
      'Merges instead of enqueuing when the branch is not main or master',
      () async {
        final pullRequest = generatePullRequest(
          repoName: 'flutter',
          title: 'Release branch PR',
          baseRef: 'release-branch',
        );

        final result = await validationService.submitPullRequest(
          config: config,
          pullRequest: pullRequest,
        );

        expect(result.method, SubmitMethod.merge);
      },
    );

    test('Enqueues instead of merging when the branch is main', () async {
      final pullRequest = generatePullRequest(
        repoName: 'flutter',
        title: 'Regular PR',
        baseRef: 'main',
      );

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.method, SubmitMethod.enqueue);
    });

    test('Enqueues instead of merging when the branch is master', () async {
      final pullRequest = generatePullRequest(
        repoName: 'flutter',
        title: 'Regular PR',
        baseRef: 'master',
      );

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(result.method, SubmitMethod.enqueue);
    });

    test('Fails to enqueue pull request when merge queue is used', () async {
      slug = RepositorySlug('flutter', 'flutter');
      final prTitle = 'This pull request should fail to enqueueueueueueueueueu';

      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          data: {
            'repository': {
              'pullRequest': {'id': 'PR_blahblah'},
            },
          },
        );
      };

      Map<String, Object?>? mutationOptions;
      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) {
        mutationOptions = options.variables;
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          exception: OperationException(),
        );
      };

      final pullRequest = generatePullRequest(
        prNumber: 42,
        repoName: slug.name,
        title: prTitle,
        mergeable: true,
      );

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(mutationOptions, {'pullRequestId': 'PR_blahblah', 'jump': false});
      expect(result.result, isFalse);
      expect(
        result.message,
        contains(
          'Failed to enqueue flutter/flutter/42 with HTTP 400: GraphQL mutate failed',
        ),
      );
    });

    test('Jumps the queue for emergency pull requests', () async {
      slug = RepositorySlug('flutter', 'flutter');
      final prTitle = 'This pull request should fail to enqueueueueueueueueueu';

      githubGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          data: {
            'repository': {
              'pullRequest': {'id': 'PR_blahblah'},
            },
          },
        );
      };

      Map<String, Object?>? mutationOptions;
      githubGraphQLClient.mutateResultForOptions = (MutationOptions options) {
        mutationOptions = options.variables;
        return QueryResult(
          options: options,
          source: QueryResultSource.network,
          data: {},
        );
      };

      final pullRequest = generatePullRequest(
        prNumber: 42,
        repoName: slug.name,
        title: prTitle,
        mergeable: true,
        labelName: 'emergency',
      );

      final result = await validationService.submitPullRequest(
        config: config,
        pullRequest: pullRequest,
      );

      expect(mutationOptions, {'pullRequestId': 'PR_blahblah', 'jump': true});
      expect(result.result, isTrue);
      expect(result.message, contains(prTitle));
    });

    test('Does not enqueue pull requests already in the queue', () async {
      final logs = <String>[];
      final logSub = log.onRecord.listen((record) {
        logs.add(record.toString());
      });

      slug = RepositorySlug('flutter', 'flutter');
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        isInMergeQueue: true,
        reviews: <PullRequestReviewHelper>[
          const PullRequestReviewHelper(
            authorName: 'member',
            state: ReviewState.APPROVED,
            memberType: MemberType.OWNER,
          ),
        ],
      );
      githubService.checkRunsData = checkRunsMock;
      githubService.checkRunsMock = checkRunsMock;
      githubService.createCommentData = createCommentMock;
      githubService.isTeamMemberMockMap['author1'] = true;
      githubService.isTeamMemberMockMap['member'] = true;
      final pubsub = FakePubSub();
      final pullRequest = generatePullRequest(
        prNumber: 0,
        repoName: slug.name,
        baseRef: 'master',
        mergeable: true,
      );

      unawaited(
        pubsub.publish(config.pubsubRevertRequestSubscription, pullRequest),
      );
      await validationService.processPullRequest(
        config: config,
        result: createQueryResult(flutterRequest),
        pullRequest: pullRequest,
        ackId: 'test',
        pubsub: pubsub,
      );

      await logSub.cancel();
      expect(
        logs,
        contains(
          '[INFO] auto_submit: flutter/flutter/0 is already in the merge queue. Skipping.',
        ),
      );
      expect(pubsub.acks, contains((subscription: 'test-sub', ackId: 'test')));
      assert(pubsub.messagesQueue.isEmpty);
    });
  });
}
