// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart' as auto hide PullRequest;
import 'package:auto_submit/service/pull_request_validation_service.dart';
import 'package:auto_submit/service/validation_service.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/request_handling/fake_pubsub.dart';
import '../src/service/fake_bigquery_service.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_graphql_client.dart';
import '../src/service/fake_github_service.dart';
import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import 'bigquery_test.dart';

void main() {
  late PullRequestValidationService validationService;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  late RepositorySlug slug;

  late MockJobsResource jobsResource;
  late FakeBigqueryService bigqueryService;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient);
    validationService = PullRequestValidationService(
      config,
      retryOptions: const RetryOptions(delayFactor: Duration.zero, maxDelay: Duration.zero, maxAttempts: 1),
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

  test('Removes label and post comment when no approval', () async {
    final PullRequestHelper flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    githubService.checkRunsData = checkRunsMock;
    githubService.createCommentData = createCommentMock;
    githubService.isTeamMemberMockMap['author1'] = true;
    githubService.isTeamMemberMockMap['member'] = true;
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
    githubService.pullRequestData = pullRequest;
    unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
    final auto.QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(
      config: config,
      result: queryResult,
      messagePullRequest: pullRequest,
      ackId: 'test',
      pubsub: pubsub,
    );

    expect(githubService.issueComment, isNotNull);
    expect(githubService.labelRemoved, true);
    assert(pubsub.messagesQueue.isEmpty);
  });

  // This tests for valid pull request into not default base branch which
  // will ignore the tree status as it does not matter.
  test('Processes successfully when base branch is not default', () async {
    final PullRequestHelper flutterRequest = PullRequestHelper(
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
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(
      prNumber: 0,
      repoName: slug.name,
      baseRef: 'feature_a',
      mergeable: true,
    );
    unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
    final auto.QueryResult queryResult = createQueryResult(flutterRequest);
    githubService.pullRequestMock = pullRequest;
    githubService.mergeRequestMock = PullRequestMerge(
      merged: true,
      sha: 'asdfioefmasdf',
      message: 'Merged successfully.',
    );

    await validationService.processPullRequest(
      config: config,
      result: queryResult,
      messagePullRequest: pullRequest,
      ackId: 'test',
      pubsub: pubsub,
    );

    // These checks indicate that the pull request has been merged as the label
    // is not removed and there was no issue coment generated and the message
    // was acknowledged.
    expect(githubService.issueComment, isNull);
    expect(githubService.labelRemoved, false);
    assert(pubsub.messagesQueue.isEmpty);
  });

  // This tests for valid pull request where tree status was not ready for
  // processing, meaning no issueComment was created and the 'autosubmit' label
  // is not removed and we do not ack the message.
  test('Processing fails when base branch is default with no statuses', () async {
    final PullRequestHelper flutterRequest = PullRequestHelper(
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
    final FakePubSub pubsub = FakePubSub();
    final PullRequest pullRequest = generatePullRequest(prNumber: 0);
    githubService.pullRequestData = pullRequest;
    unawaited(pubsub.publish('auto-submit-queue-sub', pullRequest));
    final auto.QueryResult queryResult = createQueryResult(flutterRequest);

    await validationService.processPullRequest(
      config: config,
      result: queryResult,
      messagePullRequest: pullRequest,
      ackId: 'test',
      pubsub: pubsub,
    );

    expect(githubService.issueComment, isNull);
    expect(githubService.labelRemoved, false);
    assert(pubsub.messagesQueue.isNotEmpty);
  });

  group('Process pull request method tests', () {
    test('Should process message when autosubmit label exists and pr is open', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      githubService.pullRequestData = pullRequest;
      expect(await validationService.shouldProcess(pullRequest), true);
    });

    test('Skip processing message when autosubmit label does not exist anymore', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.labels = <IssueLabel>[];
      githubService.pullRequestData = pullRequest;
      expect(await validationService.shouldProcess(pullRequest), false);
    });

    test('Skip processing message when the pull request is closed', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      githubService.pullRequestData = pullRequest;
      expect(await validationService.shouldProcess(pullRequest), false);
    });

    test('Should not process message when revert label exists and pr is open', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      final IssueLabel issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      expect(await validationService.shouldProcess(pullRequest), false);
    });

    test('Skip processing message when revert label exists and pr is closed', () async {
      final PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      pullRequest.state = 'closed';
      final IssueLabel issueLabel = IssueLabel(name: 'revert');
      pullRequest.labels = <IssueLabel>[issueLabel];
      githubService.pullRequestData = pullRequest;
      expect(await validationService.shouldProcess(pullRequest), false);
    });
  });

  group('processMerge', () {
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
