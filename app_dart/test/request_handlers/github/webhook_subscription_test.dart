// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/github/checks.dart' hide CheckRun;
import 'package:cocoon_service/src/request_handlers/github/webhook_subscription.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_service/src/service/scheduler.dart';
import 'package:fixnum/fixnum.dart';
import 'package:github/github.dart' hide Branch;
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_build_bucket_client.dart';
import '../../src/service/fake_fusion_tester.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/service/fake_github_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/webhook_generators.dart';

void main() {
  useTestLoggerPerTest();

  late GithubWebhookSubscription webhook;
  late FakeBuildBucketClient fakeBuildBucketClient;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeGithubService githubService;
  late FakeHttpRequest request;
  late FakeScheduler scheduler;
  late FakeGerritService gerritService;
  late MockCommitService commitService;
  late MockGitHub gitHubClient;
  late MockFirestoreService mockFirestoreService;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late MockIssuesService issuesService;
  late MockPullRequestsService pullRequestsService;
  late SubscriptionTester tester;
  late FakeFusionTester fakeFusionTester;
  late MockPullRequestLabelProcessor mockPullRequestLabelProcessor;

  /// Name of an example release base branch name.
  const kReleaseBaseRef = 'flutter-2.12-candidate.4';

  /// Name of an example release head branch name.
  const kReleaseHeadRef = 'cherrypicks-flutter-2.12-candidate.4';

  late DateTime fakeNow;

  setUp(() {
    request = FakeHttpRequest();
    db = FakeDatastoreDB();
    mockFirestoreService = MockFirestoreService();
    when(
      // ignore: discarded_futures
      mockFirestoreService.queryRecentTasksByName(
        name: anyNamed('name'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => []);

    gitHubClient = MockGitHub();
    githubService = FakeGithubService();
    commitService = MockCommitService();
    final tabledataResource = MockTabledataResource();
    when(
      // ignore: discarded_futures
      tabledataResource.insertAll(any, any, any, any),
    ).thenAnswer((_) async => TableDataInsertAllResponse());
    config = FakeConfig(
      dbValue: db,
      githubClient: gitHubClient,
      githubService: githubService,
      firestoreService: mockFirestoreService,
      githubOAuthTokenValue: 'githubOAuthKey',
      missingTestsPullRequestMessageValue: 'missingTestPullRequestMessage',
      releaseBranchPullRequestMessageValue: 'releaseBranchPullRequestMessage',
      rollerAccountsValue: const <String>{
        'skia-flutter-autoroll',
        'engine-flutter-autoroll',
        'dependabot',
        'dependabot[bot]',
      },
      tabledataResource: tabledataResource,
      wrongHeadBranchPullRequestMessageValue:
          'wrongHeadBranchPullRequestMessage',
      wrongBaseBranchPullRequestMessageValue:
          '{{target_branch}} -> {{default_branch}}',
    );
    issuesService = MockIssuesService();
    when(
      // ignore: discarded_futures
      issuesService.addLabelsToIssue(any, any, any),
    ).thenAnswer((_) async => <IssueLabel>[]);
    when(
      // ignore: discarded_futures
      issuesService.createComment(any, any, any),
    ).thenAnswer((_) async => IssueComment());
    when(issuesService.listCommentsByIssue(any, any)).thenAnswer(
      (_) => Stream<IssueComment>.fromIterable(<IssueComment>[IssueComment()]),
    );
    pullRequestsService = MockPullRequestsService();
    when(
      pullRequestsService.listFiles(Config.flutterSlug, any),
    ).thenAnswer((_) => const Stream<PullRequestFile>.empty());
    when(
      // ignore: discarded_futures
      pullRequestsService.edit(
        any,
        any,
        title: anyNamed('title'),
        state: anyNamed('state'),
        base: anyNamed('base'),
      ),
    ).thenAnswer((_) async => PullRequest());
    fakeBuildBucketClient = FakeBuildBucketClient();
    fakeFusionTester = FakeFusionTester();
    fakeFusionTester.isFusion = (_, _) => false;
    mockGithubChecksUtil = MockGithubChecksUtil();
    scheduler = FakeScheduler(
      config: config,
      buildbucket: fakeBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
      fusionTester: fakeFusionTester,
    );
    tester = SubscriptionTester(request: request);

    when(gitHubClient.issues).thenReturn(issuesService);
    when(gitHubClient.pullRequests).thenReturn(pullRequestsService);
    when(
      // ignore: discarded_futures
      mockGithubChecksUtil.createCheckRun(
        any,
        any,
        any,
        any,
        output: anyNamed('output'),
      ),
    ).thenAnswer((_) async {
      return CheckRun.fromJson(const <String, dynamic>{
        'id': 1,
        'started_at': '2020-05-10T02:49:31Z',
        'check_suite': <String, dynamic>{'id': 2},
      });
    });

    mockPullRequestLabelProcessor = MockPullRequestLabelProcessor();
    gerritService = FakeGerritService();

    fakeNow = DateTime.now();
    webhook = GithubWebhookSubscription(
      config: config,
      cache: CacheService(inMemory: true),
      gerritService: gerritService,
      scheduler: scheduler,
      commitService: commitService,
      fusionTester: fakeFusionTester,
      pullRequestLabelProcessorProvider:
          ({
            required Config config,
            required GithubService githubService,
            required PullRequest pullRequest,
          }) => mockPullRequestLabelProcessor,
      now: () => fakeNow,
    );
  });

  group('github webhook pull_request event', () {
    test('Closes PR opened from dev', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        headRef: 'dev',
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        pullRequestsService.edit(
          Config.flutterSlug,
          issueNumber,
          state: 'closed',
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.wrongHeadBranchPullRequestMessageValue)),
        ),
      ).called(1);
    });

    test('No action against candidate branches', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'flutter-2.13-candidate.0',
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        pullRequestsService.edit(
          Config.flutterSlug,
          issueNumber,
          base: kDefaultBranchName,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains('-> master')),
        ),
      );
    });

    test('Acts on opened against dev', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'dev',
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        pullRequestsService.edit(
          Config.flutterSlug,
          issueNumber,
          base: kDefaultBranchName,
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains('dev -> master')),
        ),
      ).called(1);
    });

    test('Acts on closed, cancels presubmit targets', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        baseRef: 'dev',
        merged: false,
      );

      await tester.post(webhook);
      expect(scheduler.cancelPreSubmitTargetsCallCnt, 1);
      expect(scheduler.addPullRequestCallCnt, 0);
    });

    test(
      'Acts on closed, cancels presubmit targets, add pr for postsubmit target create',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'closed',
          number: issueNumber,
          baseRef: 'dev',
          merged: true,
          baseSha: 'abc',
          mergeCommitSha: 'cde',

          // Just spelling this out here, because this test specifically tests a
          // non-revert PR.
          withRevertOf: false,
        );

        await tester.post(webhook);

        expect(scheduler.cancelPreSubmitTargetsCallCnt, 1);
        expect(scheduler.addPullRequestCallCnt, 1);

        // This was not a revert PR, so no branches deleted.
        expect(githubService.deletedBranches, isEmpty);
      },
    );

    test('Removes temporary revert branches upon merging the PR', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        baseRef: 'dev',
        merged: true,
        baseSha: 'abc',
        mergeCommitSha: 'cde',
        withRevertOf: true,
        headRef: 'test/headref',
      );

      await tester.post(webhook);

      // This was a merged revert PR. The temp branch should be deleted.
      expect(githubService.deletedBranches, [
        (RepositorySlug('flutter', 'flutter'), 'test/headref'),
      ]);
    });

    test(
      'Does NOT remove temporary revert branches upon closing a revert PR because the PR may be manually reopened',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'closed',
          number: issueNumber,
          baseRef: 'dev',
          merged: false,
          baseSha: 'sha1',
          mergeCommitSha: 'sha2',
          withRevertOf: true,
        );

        await tester.post(webhook);

        // This was a closed (not merged) revert PR, so no branches deleted.
        expect(githubService.deletedBranches, isEmpty);
      },
    );

    test('Acts on opened against master when default is main', () async {
      const issueNumber = 123;

      final pushMessage = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'master',
        slug: Config.packagesSlug,
      );

      tester.message = pushMessage;

      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        pullRequestsService.edit(
          Config.packagesSlug,
          issueNumber,
          base: 'main',
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains('master -> main')),
        ),
      ).called(1);

      expect(scheduler.triggerPresubmitTargetsCallCount, 1);
      scheduler.resetTriggerPresubmitTargetsCallCount();
    });

    test('Acts on edited against master when default is main', () async {
      const issueNumber = 123;

      final pushMessage = generateGithubWebhookMessage(
        action: 'edited',
        number: issueNumber,
        baseRef: 'master',
        slug: Config.packagesSlug,
        includeChanges: true,
      );

      tester.message = pushMessage;

      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        pullRequestsService.edit(
          Config.packagesSlug,
          issueNumber,
          base: 'main',
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains('master -> main')),
        ),
      ).called(1);

      expect(scheduler.triggerPresubmitTargetsCallCount, 1);
      scheduler.resetTriggerPresubmitTargetsCallCount();
    });

    // We already schedule checks when a draft is opened, don't need to re-test
    // just because it was marked ready for review
    test('Does nothing on ready_for_review', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'ready_for_review',
        number: issueNumber,
      );
      var batchRequestCalled = false;

      Future<bbv2.BatchResponse> getBatchResponse(_, _) async {
        batchRequestCalled = true;
        fail('Marking a draft ready for review should not trigger new builds');
      }

      fakeBuildBucketClient.batchResponse = getBatchResponse;

      await tester.post(webhook);

      expect(batchRequestCalled, isFalse);
    });

    test('Triggers builds when opening a draft PR', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        isDraft: true,
      );

      var batchRequestCalled = false;

      Future<bbv2.BatchResponse> getBatchResponse(_, _) async {
        batchRequestCalled = true;
        return bbv2.BatchResponse(
          responses: <bbv2.BatchResponse_Response>[
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  bbv2.Build(
                    number: 999,
                    builder: bbv2.BuilderID(builder: 'Linux'),
                    status: bbv2.Status.SUCCESS,
                  ),
                ],
              ),
            ),
            bbv2.BatchResponse_Response(
              searchBuilds: bbv2.SearchBuildsResponse(
                builds: <bbv2.Build>[
                  bbv2.Build(
                    number: 998,
                    builder: bbv2.BuilderID(builder: 'Linux'),
                    status: bbv2.Status.SUCCESS,
                  ),
                ],
              ),
            ),
          ],
        );
      }

      fakeBuildBucketClient.batchResponse = getBatchResponse;

      await tester.post(webhook);

      expect(batchRequestCalled, isTrue);
      expect(scheduler.cancelPreSubmitTargetsCallCnt, 1);
    });

    test('Does nothing against cherry pick PR', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'flutter-1.20-candidate.7',
        headRef: 'cherrypicks-flutter-1.20-candidate.7',
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        pullRequestsService.edit(
          Config.flutterSlug,
          issueNumber,
          base: kDefaultBranchName,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.wrongBaseBranchPullRequestMessage)),
        ),
      );
    });

    test('Does nothing against non supported repository', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'master',
        slug: RepositorySlug.full('flutter/engine'),
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      expect(tester.post(webhook), throwsA(isA<InternalServerError>()));

      verifyNever(
        pullRequestsService.edit(
          Config.flutterSlug,
          issueNumber,
          base: kDefaultBranchName,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.wrongBaseBranchPullRequestMessage)),
        ),
      );
    });

    test('release PRs are approved', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        // Base is where the PR will merge into
        baseRef: 'flutter-2.13-candidate.0',
        login: 'dart-flutter-releaser',
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(
        pullRequestsService.createReview(Config.flutterSlug, any),
      ).thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      final reviews =
          verify(
            pullRequestsService.createReview(Config.flutterSlug, captureAny),
          ).captured;
      expect(reviews.length, 1);
      final review = reviews.single as CreatePullRequestReview;
      expect(review.event, 'APPROVE');
    });

    test('fake release PRs are not approved', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        // Base is where the PR will merge into
        baseRef: 'master',
        // Head is the branch from the fork
        headRef: 'flutter-2.13-candidate.0',
        login: 'dart-flutter-releaser',
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(
        pullRequestsService.createReview(Config.flutterSlug, any),
      ).thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      verifyNever(
        pullRequestsService.createReview(Config.flutterSlug, captureAny),
      );
    });

    test('release PRs are not approved for outsider PRs', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        headRef: 'flutter-2.13-candidate.0',
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(
        pullRequestsService.createReview(Config.flutterSlug, any),
      ).thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      verifyNever(pullRequestsService.createReview(Config.flutterSlug, any));
    });

    test('Framework labels PRs, comment if no tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);
    });

    test('Fusion labels engine PRs, comment if no tests', () async {
      // Note: engine doesn't add any labels, so we're only looking for comments
      const issueNumber = 123;

      fakeFusionTester.isFusion = (_, _) => true;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable([
          PullRequestFile()..filename = 'engine/src/flutter/fu.cc',
        ]),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);
    });

    test('Fusion labels engine PRs, no comment for tests', () async {
      // Note: engine doesn't add any labels, so we're only looking for comments
      const issueNumber = 123;

      fakeFusionTester.isFusion = (_, _) => true;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable([
          PullRequestFile()..filename = 'engine/src/flutter/fu.cc',
          PullRequestFile()..filename = 'engine/src/flutter/fu_benchmarks.cc',
        ]),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('logs pull_request/labeled events', () async {
      const prNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'labeled',
        number: prNumber,
      );

      await tester.post(webhook);

      expect(
        log,
        bufferedLoggerOf(
          containsAll([
            logThat(message: equals('Processing pull_request')),
            logThat(
              message: equals(
                'GithubWebhookSubscription._handlePullRequest(123): processing labeled for https://github.com/flutter/flutter/pull/123',
              ),
            ),
            logThat(
              message: equals(
                'GithubWebhookSubscription._handlePullRequest(123): PR labels = ["cla: yes", "framework", "tool"]',
              ),
            ),
          ]),
        ),
      );
    });

    group(
      'Auto-roller accounts do not label Framework PR with test label or comment.',
      () {
        final inputs = <String>{'skia-flutter-autoroll', 'dependabot'};

        for (var element in inputs) {
          test(
            'Framework does not label PR with no tests label if author is $element',
            () async {
              const issueNumber = 123;

              tester.message = generateGithubWebhookMessage(
                action: 'opened',
                number: issueNumber,
                login: element,
              );

              final slug = RepositorySlug('flutter', 'flutter');

              when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
                (_) => Stream<PullRequestFile>.value(
                  PullRequestFile()..filename = 'packages/flutter/blah.dart',
                ),
              );

              when(
                issuesService.listCommentsByIssue(slug, issueNumber),
              ).thenAnswer(
                (_) => Stream<IssueComment>.value(
                  IssueComment()..body = 'some other comment',
                ),
              );

              await tester.post(webhook);

              verifyNever(
                issuesService.addLabelsToIssue(slug, issueNumber, any),
              );

              verifyNever(
                issuesService.createComment(
                  slug,
                  issueNumber,
                  argThat(contains(config.missingTestsPullRequestMessageValue)),
                ),
              );
            },
          );
        }
      },
    );

    test(
      'Framework does not label PR with no tests label if author is engine-flutter-autoroll',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          login: 'engine-flutter-autoroll',
        );
        final slug = RepositorySlug('flutter', 'flutter');

        when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()..filename = 'packages/flutter/blah.dart',
          ),
        );

        when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verifyNever(issuesService.addLabelsToIssue(slug, issueNumber, any));

        verifyNever(
          issuesService.createComment(
            slug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Framework does not label PR with no tests label if file is test exempt',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );
        final slug = RepositorySlug('flutter', 'flutter');

        when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()
              ..filename = 'dev/devicelab/lib/versions/gallery.dart',
            PullRequestFile()
              ..filename =
                  'dev/integration_tests/some_package/android/build.gradle',
            PullRequestFile()..filename = 'docs/app_anatomy.svg',
            PullRequestFile()
              ..filename = 'example/test/flutter_test_config.dart',
            PullRequestFile()..filename = 'impeller/fixtures/dart_tests.dart',
            PullRequestFile()
              ..filename = 'impeller/golden_tests/golden_tests.cc',
            PullRequestFile()..filename = 'impeller/playground/playground.cc',
            PullRequestFile()
              ..filename =
                  'shell/platform/embedder/tests/embedder_test_context.cc',
            PullRequestFile()
              ..filename = 'shell/platform/embedder/fixtures/main.dart',
            PullRequestFile()..filename = 'testing/test_gl_surface.h',
            PullRequestFile()..filename = 'tools/clangd_check/bin/main.dart',
            PullRequestFile()..filename = 'test/flutter_test_config.dart',
          ]),
        );

        when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verifyNever(issuesService.addLabelsToIssue(slug, issueNumber, any));

        verifyNever(
          issuesService.createComment(
            slug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Framework labels PRs, comment if no tests. Verify a trailing slash was added to the path prefix',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );
        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()..filename = 'testingénieux/davoir/trouvé/ce/truc',
          ),
        );

        when(
          issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verify(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        ).called(1);
      },
    );

    test(
      'Framework labels PRs, comment if no tests including hit_test.dart file',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );
        final slug = RepositorySlug('flutter', 'flutter');

        when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()
              ..additionsCount = 10
              ..changesCount = 10
              ..filename = 'packages/flutter/lib/src/gestures/hit_test.dart',
          ),
        );

        when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verify(
          issuesService.createComment(
            slug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        ).called(1);
      },
    );

    test('Framework labels PRs, no dart files', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.md',
        ),
      );

      await tester.post(webhook);

      verifyNever(issuesService.addLabelsToIssue(slug, issueNumber, any));

      verifyNever(issuesService.createComment(slug, issueNumber, any));
    });

    test('Framework labels PRs, no comment if tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/semantics_test.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
          PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()
            ..filename = 'dev/devicelab/bin/tasks/analyzer_benchmark.dart',
          PullRequestFile()..filename = 'bin/internal/engine.version',
          PullRequestFile()
            ..filename = 'packages/flutter/lib/src/cupertino/blah.dart',
          PullRequestFile()
            ..filename = 'packages/flutter/lib/src/material/blah.dart',
          PullRequestFile()
            ..filename = 'packages/flutter_localizations/blah.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework labels dart fix PRs, no comment if tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/flutter/test_fixes/material.dart',
          PullRequestFile()
            ..filename = 'packages/flutter/test_fixes/material.expect',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework labels bot PR, no comment', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        login: 'fluttergithubbot',
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework labels deletion only PR, no test request', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/flutter/blah.dart'
            ..deletionsCount = 20
            ..additionsCount = 0
            ..changesCount = 20,
        ]),
      );

      await tester.post(webhook);

      // The PR here is only deleting code, so no test comment.
      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('PR with additions and deletions is commented and labeled', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/flutter/blah.dart'
            ..deletionsCount = 20
            ..additionsCount = 1
            ..changesCount = 21,
        ]),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);
    });

    test('Framework no comment if code has only devicelab test', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/flutter_tools/lib/src/ios/devices.dart',
          PullRequestFile()
            ..filename = 'dev/devicelab/lib/tasks/plugin_tests.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no comment if only dev bots or devicelab changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()
            ..filename = 'dev/devicelab/bin/tasks/analyzer_benchmark.dart',
          PullRequestFile()
            ..filename = 'dev/devicelab/lib/tasks/plugin_tests.dart',
          PullRequestFile()
            ..filename =
                'dev/benchmarks/microbenchmarks/lib/foundation/all_elements_bench.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no comment if only .gitignore changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.gitignore',
          PullRequestFile()
            ..filename = 'dev/integration_tests/foo_app/.gitignore',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          any,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no test comment if Objective-C test changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          // Example of real behavior code change.
          PullRequestFile()
            ..filename =
                'packages/flutter_tools/templates/app_shared/macos.tmpl/Runner/Base.lproj/MainMenu.xib',
          // Example of Objective-C test.
          PullRequestFile()
            ..filename =
                'dev/integration_tests/flutter_gallery/macos/RunnerTests/RunnerTests.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no test comment if Kotlin test changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          // Example of real behavior code change.
          PullRequestFile()
            ..filename =
                'packages/flutter_tools/gradle/src/main/kotlin/Deeplink.kt',
          // Example of Kotlin test.
          PullRequestFile()
            ..filename =
                'packages/flutter_tools/gradle/src/test/kotlin/DeeplinkTest.kt',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no comment if only AUTHORS changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'AUTHORS',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no comment if only ci.yamlchanged', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.ci.yaml',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework no comment if only analysis options changed', () async {
      const issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'analysis_options.yaml',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test(
      'Framework no comment if only CODEOWNERS or TESTOWNERS changed',
      () async {
        const issueNumber = 123;
        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );
        final slug = RepositorySlug('flutter', 'flutter');

        when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()..filename = 'CODEOWNERS',
            PullRequestFile()..filename = 'TESTOWNERS',
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            slug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    for (var extention in knownCommentCodeExtensions) {
      test(
        'Framework no comment if only comments changed .$extention',
        () async {
          const issueNumber = 123;
          tester.message = generateGithubWebhookMessage(
            action: 'opened',
            number: issueNumber,
          );
          final slug = RepositorySlug('flutter', 'flutter');

          const patch = '''
@@ -128,7 +128,7 @@

/// Insert interesting comment here.
///
-/// More details here, but some of them are wrong.
+/// These are the right details!
void foo() {
  int bar = 0;
  String baz = '';
''';

          when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
            (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
              PullRequestFile()
                ..filename = 'packages/foo/lib/foo.$extention'
                ..additionsCount = 1
                ..deletionsCount = 1
                ..changesCount = 2
                ..patch = patch,
            ]),
          );

          await tester.post(webhook);

          verifyNever(
            issuesService.createComment(
              slug,
              issueNumber,
              argThat(contains(config.missingTestsPullRequestMessageValue)),
            ),
          );
        },
      );
    }

    test(
      'Framework labels PRs, no comment if tests (dev/bots/test.dart)',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()..filename = 'dev/bots/test.dart',
            PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
            PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
            PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
            PullRequestFile()
              ..filename = 'packages/flutter/lib/src/material/blah.dart',
            PullRequestFile()
              ..filename = 'packages/flutter_localizations/blah.dart',
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Framework labels PRs, no comment if tests (dev/bots/analyze.dart)',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );
        final slug = RepositorySlug('flutter', 'flutter');

        when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()..filename = 'dev/bots/analyze.dart',
            PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
            PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
            PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
            PullRequestFile()
              ..filename = 'packages/flutter/lib/src/material/blah.dart',
            PullRequestFile()
              ..filename = 'packages/flutter_localizations/blah.dart',
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            slug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Framework labels PRs, no comment if tests (flutter_tools/test/helper.dart)',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
            PullRequestFile()
              ..filename = 'packages/flutter_tools/test/helper.dart',
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Framework labels PRs, apply label but no comment when rolling engine version',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          baseRef: kReleaseBaseRef,
          headRef: kReleaseHeadRef,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()
              ..filename = 'bin/internal/engine.version'
              ..deletionsCount = 20
              ..additionsCount = 1
              ..changesCount = 21,
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.addLabelsToIssue(Config.flutterSlug, issueNumber, any),
        );

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    group(
      'Auto-roller accounts do not label Engine PR with test label or comment.',
      () {
        final inputs = <String>{
          'engine-flutter-autoroll',
          'dependabot',
          'dependabot[bot]',
        };

        for (var element in inputs) {
          test(
            'Engine does not label PR for no tests if author is $element',
            () async {
              const issueNumber = 123;

              tester.message = generateGithubWebhookMessage(
                action: 'opened',
                number: issueNumber,
                slug: Config.flutterSlug,
                login: element,
              );

              when(
                pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
              ).thenAnswer(
                (_) => Stream<PullRequestFile>.value(
                  PullRequestFile()
                    ..filename =
                        'engine/src/flutter/shell/platform/darwin/ios/framework/Source/boost.mm',
                ),
              );

              when(
                issuesService.listCommentsByIssue(
                  Config.flutterSlug,
                  issueNumber,
                ),
              ).thenAnswer(
                (_) => Stream<IssueComment>.value(
                  IssueComment()..body = 'some other comment',
                ),
              );

              await tester.post(webhook);

              verifyNever(
                issuesService.createComment(
                  Config.flutterSlug,
                  issueNumber,
                  argThat(contains(config.missingTestsPullRequestMessageValue)),
                ),
              );
            },
          );
        }
      },
    );

    test(
      'Engine does not label PR for no tests if author is skia-flutter-autoroll',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          slug: Config.flutterSlug,
          login: 'skia-flutter-autoroll',
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()
              ..filename =
                  'engine/src/flutter/shell/platform/darwin/ios/framework/Source/boost.mm',
          ),
        );

        when(
          issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test('Engine labels PRs, no comment if DEPS-only', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'master',
        slug: Config.flutterSlug,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) =>
            Stream<PullRequestFile>.value(PullRequestFile()..filename = 'DEPS'),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(Config.flutterSlug, issueNumber, any),
      );

      verifyNever(
        issuesService.createComment(Config.flutterSlug, issueNumber, any),
      );
    });

    test('Engine labels PRs, no comment if build-file-only', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'master',
        slug: Config.flutterSlug,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'engine/src/flutter/shell/config.gni',
          PullRequestFile()..filename = 'engine/src/flutter/shell/BUILD.gn',
          PullRequestFile()
            ..filename = 'engine/src/flutter/sky/tools/create_ios_framework.py',
          PullRequestFile()
            ..filename = 'engine/src/flutter/ci/builders/mac_host_engine.json',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(Config.flutterSlug, issueNumber, any),
      );

      verifyNever(
        issuesService.createComment(Config.flutterSlug, issueNumber, any),
      );
    });

    test(
      'Engine labels PRs, no comment for license goldens or build configs',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          baseRef: 'master',
          slug: Config.flutterSlug,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()
              ..filename =
                  'engine/src/flutter/ci/licenses_golden/licenses_dart',
            PullRequestFile()
              ..filename = 'engine/src/flutter/ci/builders/linux_unopt.json',
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.addLabelsToIssue(Config.flutterSlug, issueNumber, any),
        );

        verifyNever(
          issuesService.createComment(Config.flutterSlug, issueNumber, any),
        );
      },
    );

    test('Engine labels PRs, no comment if tested', () async {
      final pullRequestFileList = <List<String>>[
        <String>[
          // Java tests.
          'engine/src/flutter/shell/platform/android/io/flutter/Blah.java',
          'engine/src/flutter/shell/platform/android/test/io/flutter/BlahTest.java',
        ],
        <String>[
          // Script tests.
          'engine/src/flutter/fml/blah.cc',
          'engine/src/flutter/fml/testing/blah_test.sh',
        ],
        <String>[
          // cc tests.
          'engine/src/flutter/fml/blah.cc',
          'engine/src/flutter/fml/blah_unittests.cc',
        ],
        <String>[
          // cc benchmarks.
          'engine/src/flutter/fml/blah.cc',
          'engine/src/flutter/fml/blah_benchmarks.cc',
        ],
        <String>[
          // py tests.
          'engine/src/flutter/tools/font-subset/main.cc',
          'engine/src/flutter/tools/font-subset/test.py',
        ],
        <String>[
          // scenario app is a test.
          'engine/src/flutter/testing/scenario_app/project.pbxproj',
          'engine/src/flutter/testing/scenario_app/Info_Impeller.plist',
        ],
      ];

      for (
        var issueNumber = 0;
        issueNumber < pullRequestFileList.length;
        issueNumber++
      ) {
        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          slug: Config.flutterSlug,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(
            pullRequestFileList[issueNumber].map(
              (String filename) => PullRequestFile()..filename = filename,
            ),
          ),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      }
    });

    test('bot does not comment for whitespace only changes', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.flutterSlug,
      );
      const patch = '''
@@ -128,7 +128,7 @@

  int bar = 0;
+
  int baz = 0;
''';

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'flutter/lib/ui/foo.dart'
            ..additionsCount = 1
            ..deletionsCount = 1
            ..changesCount = 2
            ..patch = patch,
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine does not comment for comment-only changes', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.flutterSlug,
      );
      const patch = '''
@@ -128,7 +128,7 @@

/// Insert interesting comment here.
///
-/// More details here, but some of them are wrong.
+/// These are the right details!
void foo() {
  int bar = 0;
  String baz = '';
''';

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'flutter/lib/ui/foo.dart'
            ..additionsCount = 1
            ..deletionsCount = 1
            ..changesCount = 2
            ..patch = patch,
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels deletion only PR, no test request', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.flutterSlug,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'engine/src/flutter/lib/ui/foo.dart'
            ..deletionsCount = 20
            ..additionsCount = 0
            ..changesCount = 20,
          PullRequestFile()
            ..filename =
                'engine/src/flutter/shell/platform/darwin/ios/platform_view_ios.mm'
            ..deletionsCount = 20
            ..additionsCount = 0
            ..changesCount = 20,
        ]),
      );

      await tester.post(webhook);

      // The PR here is only deleting code, so no test comment.
      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('No labels when only pubspec.yaml changes', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/pubspec.yaml',
          PullRequestFile()..filename = 'packages/flutter_tools/pubspec.yaml',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Packages does not comment if Pigeon native tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
        baseRef: Config.defaultBranch(Config.packagesSlug),
      );
      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/pigeon/lib/swift_generator.dart',
          PullRequestFile()
            ..filename =
                'packages/pigeon/platform_tests/shared_test_plugin_code/lib/integration_tests.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Packages does not comment if shared Darwin native tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
        baseRef: Config.defaultBranch(Config.packagesSlug),
      );
      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename =
                'packages/foo/foo_foundation/darwin/Classes/SomeClass.m',
          PullRequestFile()
            ..filename =
                'packages/foo/foo_foundation/darwin/Tests/SomeClassTest.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test(
      'Packages does not comment if editing test files in go_router',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          slug: Config.packagesSlug,
          baseRef: Config.defaultBranch(Config.packagesSlug),
        );
        when(
          pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()
              ..filename =
                  'packages/packages/go_router/test_fixes/go_router.dart'
              ..additionsCount = 10,
            PullRequestFile()
              ..filename = 'packages/packages/go_router/lib/fix_data.yaml'
              ..additionsCount = 10,
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.packagesSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test(
      'Packages does not comment if editing test files in go_router_builder',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          slug: Config.packagesSlug,
          baseRef: Config.defaultBranch(Config.packagesSlug),
        );
        when(
          pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
            PullRequestFile()
              ..filename =
                  'packages/packages/go_router_builder/lib/src/route_config.dart'
              ..additionsCount = 10,
            PullRequestFile()
              ..filename =
                  'packages/packages/go_router_builder/test_inputs/bad_path_pattern.dart'
              ..additionsCount = 10,
          ]),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.packagesSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test('Packages comments and labels if no tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
        baseRef: Config.defaultBranch(Config.packagesSlug),
      );
      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);
    });

    test(
      'Packages do not comment or label if pr is for release branches',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          baseRef: kReleaseBaseRef,
          headRef: kReleaseHeadRef,
          slug: Config.packagesSlug,
        );

        when(
          pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
          ),
        );

        when(
          issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<IssueComment>.value(
            IssueComment()..body = 'some other comment',
          ),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.packagesSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );

        verifyNever(
          issuesService.addLabelsToIssue(Config.packagesSlug, issueNumber, any),
        );
      },
    );

    test('Packages does not comment if Dart tests', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
      );

      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
          PullRequestFile()..filename = 'packages/foo/test/foo_test.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Packages does not comment for custom test driver', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
      );

      when(
        pullRequestsService.listFiles(Config.packagesSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/tool/run_tests.dart',
          PullRequestFile()..filename = 'packages/foo/run_tests.sh',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.packagesSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Schedule tasks when pull request is closed and merged', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        merged: true,
        baseSha: 'abc', // Found in pre-populated commits in FakeGerritService.
        mergeCommitSha: 'cde',
      );

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.post(webhook);
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test(
      'fail (allow retries) when pull request is closed and merged, but merged commit is not found on GoB',
      () async {
        const issueNumber = 123;

        final mergedSha = 'fd6b46416c18de36ce87d0241994b2da180cab4c';
        tester.message = generateGithubWebhookMessage(
          action: 'closed',
          number: issueNumber,
          merged: true,
          baseSha: 'unknown_sha',
          closedAt: fakeNow.subtract(const Duration(minutes: 1)),
          mergeCommitSha: mergedSha,
        );

        expect(db.values.values.whereType<Commit>(), isEmpty);
        await tester.post(webhook);

        expect(tester.response.statusCode, HttpStatus.internalServerError);
        expect(
          tester.response.reasonPhrase,
          contains('$mergedSha was not found on GoB'),
        );
        expect(db.values.values.whereType<Commit>(), isEmpty);
      },
    );

    test(
      'fail (do not retry, it is very old) when pull request is closed and merged, but merged commit is not found on GoB',
      () async {
        const issueNumber = 123;

        final mergedSha = 'fd6b46416c18de36ce87d0241994b2da180cab4c';
        tester.message = generateGithubWebhookMessage(
          action: 'closed',
          number: issueNumber,
          merged: true,
          baseSha: 'unknown_sha',
          closedAt: fakeNow.subtract(const Duration(minutes: 5)),
          mergeCommitSha: mergedSha,
        );

        expect(db.values.values.whereType<Commit>(), isEmpty);
        await tester.post(webhook);

        expect(tester.response.statusCode, HttpStatus.notFound);
        expect(
          tester.response.reasonPhrase,
          contains('$mergedSha was not found on GoB'),
        );
        expect(db.values.values.whereType<Commit>(), isEmpty);
      },
    );

    test(
      'Does not comment about needing tests on draft pull requests.',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'opened',
          number: issueNumber,
          isDraft: true,
        );

        when(
          pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
        ).thenAnswer(
          (_) => Stream<PullRequestFile>.value(
            PullRequestFile()..filename = 'some_change.dart',
          ),
        );

        await tester.post(webhook);

        verifyNever(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            argThat(contains(config.missingTestsPullRequestMessageValue)),
          ),
        );
      },
    );

    test('Will not spawn comments if they have already been made.', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(
        pullRequestsService.listFiles(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(
        issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber),
      ).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = config.missingTestsPullRequestMessageValue,
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(Config.flutterSlug, issueNumber, any),
      );

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Skips labeling or commenting on autorolls', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        login: 'engine-flutter-autoroll',
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(any, issueNumber, any));
    });

    test(
      'Comments on PR but does not schedule builds for unmergeable PRs',
      () async {
        const issueNumber = 12345;
        tester.message = generateGithubWebhookMessage(
          action: 'synchronize',
          number: issueNumber,
          // This PR is unmergeable (probably merge conflict)
          mergeable: false,
        );

        await tester.post(webhook);
        verify(
          issuesService.createComment(
            Config.flutterSlug,
            issueNumber,
            config.mergeConflictPullRequestMessage,
          ),
        );
      },
    );

    test(
      'When synchronized, cancels existing builds and schedules new ones',
      () async {
        const issueNumber = 12345;
        var batchRequestCalled = false;

        Future<bbv2.BatchResponse> getBatchResponse(
          bbv2.BatchRequest _,
          String _,
        ) async {
          batchRequestCalled = true;
          return bbv2.BatchResponse(
            responses: <bbv2.BatchResponse_Response>[
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(
                  builds: <bbv2.Build>[
                    bbv2.Build(
                      number: 999,
                      builder: bbv2.BuilderID(builder: 'Linux'),
                      status: bbv2.Status.SUCCESS,
                    ),
                  ],
                ),
              ),
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(
                  builds: <bbv2.Build>[
                    bbv2.Build(
                      number: 998,
                      builder: bbv2.BuilderID(builder: 'Linux'),
                      status: bbv2.Status.SUCCESS,
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        fakeBuildBucketClient.batchResponse = getBatchResponse;

        tester.message = generateGithubWebhookMessage(
          action: 'synchronize',
          number: issueNumber,
        );

        final mockRepositoriesService = MockRepositoriesService();
        when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

        await tester.post(webhook);
        expect(batchRequestCalled, isTrue);
      },
    );

    test('Removes the "autosubmit" label on dequeued', () async {
      const issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'dequeued',
        number: issueNumber,
        withAutosubmit: true,
      );

      await tester.post(webhook);

      expect(githubService.removedLabels, [
        (RepositorySlug('flutter', 'flutter'), 123, 'autosubmit'),
      ]);
    });

    test(
      'Does not try to remove the "autosubmit" label on dequeued if it is not there',
      () async {
        const issueNumber = 123;

        tester.message = generateGithubWebhookMessage(
          action: 'dequeued',
          number: issueNumber,
          withAutosubmit: false,
        );

        await tester.post(webhook);

        expect(githubService.removedLabels, isEmpty);
      },
    );

    group('BuildBucket', () {
      const issueNumber = 123;

      Future<void> testActions(String action) async {
        when(issuesService.listLabelsByIssue(any, issueNumber)).thenAnswer((_) {
          return Stream<IssueLabel>.fromIterable(<IssueLabel>[
            IssueLabel()..name = 'Random Label',
          ]);
        });

        fakeBuildBucketClient.batchResponse =
            (_, _) => Future<bbv2.BatchResponse>.value(
              bbv2.BatchResponse(
                responses: <bbv2.BatchResponse_Response>[
                  bbv2.BatchResponse_Response(
                    searchBuilds: bbv2.SearchBuildsResponse(
                      builds: <bbv2.Build>[],
                    ),
                  ),
                  bbv2.BatchResponse_Response(
                    searchBuilds: bbv2.SearchBuildsResponse(
                      builds: <bbv2.Build>[],
                    ),
                  ),
                ],
              ),
            );

        tester.message = generateGithubWebhookMessage(
          action: action,
          number: 1,
        );

        await tester.post(webhook);
      }

      test('Edited Action works properly', () async {
        await testActions('edited');
      });

      test('Opened Action works properly', () async {
        await testActions('opened');
      });

      test('Ready_for_review Action works properly', () async {
        await testActions('ready_for_review');
      });

      test('Reopened Action works properly', () async {
        await testActions('reopened');
      });

      test('Labeled Action works properly', () async {
        await testActions('labeled');
      });

      test('Synchronize Action works properly', () async {
        await testActions('synchronize');
      });

      test(
        'Comments on PR but does not schedule builds for unmergeable PRs',
        () async {
          when(
            issuesService.listCommentsByIssue(any, any),
          ).thenAnswer((_) => Stream<IssueComment>.value(IssueComment()));
          tester.message = generateGithubWebhookMessage(
            action: 'synchronize',
            number: issueNumber,
            // This PR is unmergeable (probably merge conflict)
            mergeable: false,
          );
          await tester.post(webhook);
          verify(
            issuesService.createComment(
              Config.flutterSlug,
              issueNumber,
              config.mergeConflictPullRequestMessage,
            ),
          );
        },
      );

      test(
        'When synchronized, cancels existing builds and schedules new ones',
        () async {
          fakeBuildBucketClient.batchResponse =
              (_, _) => Future<bbv2.BatchResponse>.value(
                bbv2.BatchResponse(
                  responses: <bbv2.BatchResponse_Response>[
                    bbv2.BatchResponse_Response(
                      searchBuilds: bbv2.SearchBuildsResponse(
                        builds: <bbv2.Build>[
                          bbv2.Build(
                            number: 999,
                            builder: bbv2.BuilderID(builder: 'Linux'),
                            status: bbv2.Status.ENDED_MASK,
                          ),
                        ],
                      ),
                    ),
                    bbv2.BatchResponse_Response(
                      searchBuilds: bbv2.SearchBuildsResponse(
                        builds: <bbv2.Build>[
                          bbv2.Build(
                            number: 998,
                            builder: bbv2.BuilderID(builder: 'Linux'),
                            status: bbv2.Status.ENDED_MASK,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

          tester.message = generateGithubWebhookMessage(
            action: 'synchronize',
            number: issueNumber,
          );
          final mockRepositoriesService = MockRepositoriesService();
          when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

          await tester.post(webhook);
        },
      );
    });

    test(
      'on "pull_request/labeled" refreshes pull request info and calls PullRequestLabelProcessor',
      () async {
        tester.message = generateGithubWebhookMessage(
          action: 'labeled',
          number: 123,
          baseRef: 'master',
          slug: Config.flutterSlug,
          includeChanges: true,
        );

        await tester.post(webhook);

        verify(mockPullRequestLabelProcessor.processLabels()).called(1);
      },
    );

    group('PullRequestLabelProcessor.processLabels', () {
      test('applies emergency label on approved PRs', () async {
        final pullRequest = generatePullRequest(
          number: 123,
          headSha: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          labels: [IssueLabel(name: 'emergency')],
        );

        githubService.checkRunsMock = '''{
  "total_count": 2,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "Merge Queue Guard",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

        final pullRequestLabelProcessor = PullRequestLabelProcessor(
          config: config,
          githubService: githubService,
          pullRequest: pullRequest,
        );

        await pullRequestLabelProcessor.processLabels();

        expect(
          log,
          bufferedLoggerOf(
            containsAll([
              logThat(
                message: equals(
                  'PullRequestLabelProcessor(flutter/flutter/pull/123): attempting to unlock the Merge Queue Guard for emergency',
                ),
              ),
              logThat(
                message: equals(
                  'PullRequestLabelProcessor(flutter/flutter/pull/123): unlocked "Merge Queue Guard", allowing it to land as an emergency.',
                ),
              ),
            ]),
          ),
        );
      });

      test(
        'logs and gracefully skips emergency label on missing Merge Queue Guard',
        () async {
          final pullRequest = generatePullRequest(
            number: 123,
            headSha: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
            labels: [IssueLabel(name: 'emergency')],
          );

          githubService.checkRunsMock = '''{
  "total_count": 2,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "Not A Guard For Sure",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

          final pullRequestLabelProcessor = PullRequestLabelProcessor(
            config: config,
            githubService: githubService,
            pullRequest: pullRequest,
          );

          await pullRequestLabelProcessor.processLabels();

          expect(
            log,
            bufferedLoggerOf(
              containsAll([
                logThat(
                  message: equals(
                    'PullRequestLabelProcessor(flutter/flutter/pull/123): attempting to unlock the Merge Queue Guard for emergency',
                  ),
                ),
                logThat(
                  message: equals(
                    'PullRequestLabelProcessor(flutter/flutter/pull/123): failed to process the emergency label. "Merge Queue Guard" check run is missing.',
                  ),
                ),
              ]),
            ),
          );
        },
      );

      test(
        'does nothing w.r.t. emergency label when the label is missing',
        () async {
          final pullRequest = generatePullRequest(number: 123);

          final pullRequestLabelProcessor = PullRequestLabelProcessor(
            config: config,
            githubService: githubService,
            pullRequest: pullRequest,
          );

          await pullRequestLabelProcessor.processLabels();

          expect(
            log,
            bufferedLoggerOf(
              containsAll([
                logThat(
                  message: equals(
                    'PullRequestLabelProcessor(flutter/flutter/pull/123): no emergency label; moving on.',
                  ),
                ),
              ]),
            ),
          );
        },
      );

      test('leaves educational comment for new emergency PRs', () async {
        final pullRequest = generatePullRequest(
          number: 123,
          headSha: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          labels: [IssueLabel(name: 'emergency')],
        );
        githubService.createdComments.clear();
        githubService.checkRunsMock = '''{
  "total_count": 2,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "Merge Queue Guard",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

        final pullRequestLabelProcessor = PullRequestLabelProcessor(
          config: config,
          githubService: githubService,
          pullRequest: pullRequest,
        );

        await pullRequestLabelProcessor.processLabels();

        expect(githubService.createdComments, [
          (
            RepositorySlug.full('flutter/flutter'),
            issueNumber: 123,
            body: PullRequestLabelProcessor.kEmergencyLabelEducation,
          ),
        ]);
      });

      test(
        'leaves only one educational comment for new emergency PRs',
        () async {
          final pullRequest = generatePullRequest(
            number: 123,
            headSha: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
            labels: [IssueLabel(name: 'emergency')],
          );
          githubService.createdComments.clear();
          githubService.checkRunsMock = '''{
  "total_count": 2,
  "check_runs": [
    {
      "id": 2,
      "head_sha": "6dcb09b5b57875f334f61aebed695e2e4193db5e",
      "external_id": "",
      "details_url": "https://example.com",
      "status": "in_progress",
      "started_at": "2018-05-04T01:14:52Z",
      "name": "Merge Queue Guard",
      "check_suite": {
        "id": 5
      }
    }
  ]
}''';

          final pullRequestLabelProcessor = PullRequestLabelProcessor(
            config: config,
            githubService: githubService,
            pullRequest: pullRequest,
          );

          githubService.commentExistsCalls.clear();
          githubService.commentExistsMock = false;
          await pullRequestLabelProcessor.processLabels();
          githubService.commentExistsMock = true;
          await pullRequestLabelProcessor.processLabels();

          expect(githubService.createdComments, [
            (
              RepositorySlug.full('flutter/flutter'),
              issueNumber: 123,
              body: PullRequestLabelProcessor.kEmergencyLabelEducation,
            ),
          ]);
          expect(githubService.commentExistsCalls, hasLength(2));
        },
      );
    });
  });

  group('github webhook check_run event', () {
    test('processes check run event', () async {
      tester.message = generateCheckRunEvent();

      await tester.post(webhook);
    });

    test('processes completed check run event', () async {
      tester.message = generateCheckRunEvent(
        action: 'completed',
        numberOfPullRequests: 0,
      );

      await tester.post(webhook);
    });
  });

  group('github webhook push event', () {
    test('handles push events for flutter/flutter beta branch', () async {
      tester.message = generatePushMessage('beta', 'flutter', 'flutter');

      await tester.post(webhook);

      verify(commitService.handlePushGithubRequest(any)).called(1);
    });

    test('handles push events for flutter/flutter stable branch', () async {
      tester.message = generatePushMessage('stable', 'flutter', 'flutter');

      await tester.post(webhook);

      verify(commitService.handlePushGithubRequest(any)).called(1);
    });

    test(
      'does not handle push events for branches that are not beta|stable',
      () async {
        tester.message = generatePushMessage('main', 'flutter', 'flutter');

        await tester.post(webhook);

        verifyNever(commitService.handlePushGithubRequest(any)).called(0);
      },
    );

    test(
      'does not handle push events for repositories that are not flutter/flutter',
      () async {
        tester.message = generatePushMessage('beta', 'flutter', 'packages');

        await tester.post(webhook);

        verifyNever(commitService.handlePushGithubRequest(any)).called(0);
      },
    );
  });

  group('github webhook create event', () {
    test(
      'Does not create a new commit due to not being a candidate branch',
      () async {
        tester.message = generateCreateBranchMessage(
          'cool-branch',
          'flutter/flutter',
        );

        await tester.post(webhook);

        verifyNever(commitService.handleCreateGithubRequest(any)).called(0);
      },
    );

    test('Creates a new commit due to being a candidate branch', () async {
      tester.message = generateCreateBranchMessage(
        'flutter-1.2-candidate.3',
        'flutter/flutter',
      );

      await tester.post(webhook);

      verify(commitService.handleCreateGithubRequest(any)).called(1);
    });
  });

  group('github webhook merge_group event', () {
    setUpAll(() {
      Scheduler.debugCheckPretendDelay = Duration.zero;
    });

    setUp(() {
      gerritService.commitsValue = [
        generateGerritCommit('c9affbbb12aa40cb3afbe94b9ea6b119a256bebf', 1),
      ];
    });

    test('checks_requested success for non-fusion repository (simulated)', () async {
      tester.message = generateMergeGroupMessage(
        repository: 'flutter/flutter',
        action: 'checks_requested',
        message: 'Implement an amazing feature',
      );

      await tester.post(webhook);

      verify(
        mockGithubChecksUtil.updateCheckRun(
          any,
          any,
          any,
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
        ),
      ).called(1);

      expect(
        log,
        bufferedLoggerOf(
          containsAllInOrder([
            logThat(message: equals('Processing merge_group')),
            logThat(
              message: equals(
                'Processing checks_requested for merge queue @ c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Checks requests for merge queue @ c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf was found on GoB mirror. Scheduling merge group tasks',
              ),
            ),
            logThat(
              message: equals(
                'triggerMergeGroupTargets(flutter/flutter, c9affbbb12aa40cb3afbe94b9ea6b119a256bebf, simulated): scheduling merge group checks',
              ),
            ),
            logThat(
              message: equals(
                'Unlocking Merge Queue Guard for flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
          ]),
        ),
      );
    });

    test('destroyed', () async {
      tester.message = generateMergeGroupMessage(
        repository: 'flutter/flutter',
        action: 'destroyed',
        message: 'test message',
        reason: MergeGroupEvent.dequeued,
      );

      final luciLog = <String>[];

      fakeBuildBucketClient.batchResponse = (batchRequest, uri) async {
        final batchResponseRc = bbv2.BatchResponse.create();
        final batchResponseResponses = batchResponseRc.responses;

        for (final request in batchRequest.requests) {
          if (request.hasSearchBuilds()) {
            final requestSha =
                request.searchBuilds.predicate.tags
                    .singleWhere((tag) => tag.key == 'buildset')
                    .value;
            final userAgent =
                request.searchBuilds.predicate.tags
                    .singleWhere((tag) => tag.key == 'user_agent')
                    .value;
            luciLog.add('search builds for $requestSha by $userAgent');
            batchResponseResponses.add(
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(
                  builds: <bbv2.Build>[
                    for (final status in bbv2.Status.values)
                      bbv2.Build(
                        id: Int64(status.value),
                        status: status,
                        builder: bbv2.BuilderID(
                          builder: 'builder_abc',
                          bucket: 'try',
                          project: 'flutter',
                        ),
                        tags: <bbv2.StringPair>[
                          bbv2.StringPair(
                            key: 'buildset',
                            value: 'pr/git/12345',
                          ),
                          bbv2.StringPair(
                            key: 'cipd_version',
                            value: 'refs/heads/main',
                          ),
                          bbv2.StringPair(
                            key: 'github_link',
                            value: 'https://github/flutter/flutter/pull/1',
                          ),
                        ],
                        input: bbv2.Build_Input(
                          properties: bbv2.Struct(
                            fields: {
                              'bringup': bbv2.Value(stringValue: 'false'),
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          } else if (request.hasCancelBuild()) {
            final cancelBuildRequest = request.cancelBuild;
            luciLog.add('cancel ${cancelBuildRequest.id}');
            batchResponseResponses.add(
              bbv2.BatchResponse_Response(
                cancelBuild: bbv2.Build(id: cancelBuildRequest.id),
              ),
            );
          } else {
            throw UnimplementedError();
          }
        }
        return batchResponseRc;
      };

      await tester.post(webhook);

      expect(luciLog, <String>[
        'search builds for commit/git/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf by flutter-cocoon',
        // Even though there are 8 builds in total, only 2 of them are eligible
        // for cancellation.
        'cancel ${bbv2.Status.SCHEDULED.value}',
        'cancel ${bbv2.Status.STARTED.value}',
      ]);

      expect(
        log,
        bufferedLoggerOf(
          containsAllInOrder([
            logThat(message: equals('Processing merge_group')),
            logThat(
              message: equals(
                'Processing destroyed for merge queue @ c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Merge group destroyed for flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf because it was dequeued.',
              ),
            ),
            logThat(
              message: equals(
                'Cancelling merge group targets for c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Attempting to cancel builds (v2) for git SHA c9affbbb12aa40cb3afbe94b9ea6b119a256bebf because Merge group was destroyed',
              ),
            ),
            logThat(
              message: equals('Responses from get builds batch request = 1'),
            ),
            logThat(message: contains('Found a response: searchBuilds:')),
            logThat(message: equals('Found 8 builds.')),
            logThat(message: equals('Cancelling build with build id 1.')),
            logThat(message: equals('Cancelling build with build id 2.')),
          ]),
        ),
      );
    });

    test('destroyed with no builds', () async {
      tester.message = generateMergeGroupMessage(
        repository: 'flutter/flutter',
        action: 'destroyed',
        message: 'test message',
        reason: MergeGroupEvent.invalidated,
      );

      final luciLog = <String>[];

      fakeBuildBucketClient.batchResponse = (batchRequest, uri) async {
        final batchResponseRc = bbv2.BatchResponse.create();
        final batchResponseResponses = batchResponseRc.responses;

        for (final request in batchRequest.requests) {
          if (request.hasSearchBuilds()) {
            final requestSha =
                request.searchBuilds.predicate.tags
                    .singleWhere((tag) => tag.key == 'buildset')
                    .value;
            final userAgent =
                request.searchBuilds.predicate.tags
                    .singleWhere((tag) => tag.key == 'user_agent')
                    .value;
            luciLog.add('search builds for $requestSha by $userAgent');
            batchResponseResponses.add(
              bbv2.BatchResponse_Response(
                searchBuilds: bbv2.SearchBuildsResponse(builds: <bbv2.Build>[]),
              ),
            );
          } else {
            throw UnimplementedError();
          }
        }
        return batchResponseRc;
      };

      await tester.post(webhook);

      expect(luciLog, <String>[
        'search builds for commit/git/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf by flutter-cocoon',
      ]);

      expect(
        log,
        bufferedLoggerOf(
          containsAllInOrder([
            logThat(message: equals('Processing merge_group')),
            logThat(
              message: equals(
                'Processing destroyed for merge queue @ c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Merge group destroyed for flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf because it was invalidated.',
              ),
            ),
            logThat(
              message: equals(
                'Cancelling merge group targets for c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Attempting to cancel builds (v2) for git SHA c9affbbb12aa40cb3afbe94b9ea6b119a256bebf because Merge group was destroyed',
              ),
            ),
            logThat(
              message: equals('Responses from get builds batch request = 1'),
            ),
            logThat(message: contains('Found a response: searchBuilds:')),
            logThat(
              message: equals(
                'No builds found. Will not request cancellation from LUCI.',
              ),
            ),
          ]),
        ),
      );
    });

    test('does not cancel builds if destroyed because merged successfully', () async {
      tester.message = generateMergeGroupMessage(
        repository: 'flutter/flutter',
        action: 'destroyed',
        message: 'test message',
        reason: MergeGroupEvent.merged,
      );

      fakeBuildBucketClient.batchResponse = (batchRequest, uri) async {
        fail('Must not attempt to cancel builds.');
      };

      await tester.post(webhook);

      expect(
        log,
        bufferedLoggerOf(
          containsAllInOrder([
            logThat(message: equals('Processing merge_group')),
            logThat(
              message: equals(
                'Processing destroyed for merge queue @ c9affbbb12aa40cb3afbe94b9ea6b119a256bebf',
              ),
            ),
            logThat(
              message: equals(
                'Merge group destroyed for flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf because it was merged.',
              ),
            ),
            logThat(
              message: equals(
                'Merge group for flutter/flutter/c9affbbb12aa40cb3afbe94b9ea6b119a256bebf was merged successfully.',
              ),
            ),
          ]),
        ),
      );
    });
  });
}
