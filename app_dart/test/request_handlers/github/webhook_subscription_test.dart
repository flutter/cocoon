// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handlers/github/webhook_subscription.dart';
import 'package:cocoon_service/src/service/cache_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import 'package:github/github.dart' hide Branch;
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../src/datastore/fake_config.dart';
import '../../src/datastore/fake_datastore.dart';
import '../../src/request_handling/fake_http.dart';
import '../../src/request_handling/subscription_tester.dart';
import '../../src/service/fake_buildbucket.dart';
import '../../src/service/fake_github_service.dart';
import '../../src/service/fake_gerrit_service.dart';
import '../../src/service/fake_scheduler.dart';
import '../../src/utilities/entity_generators.dart';
import '../../src/utilities/mocks.dart';
import '../../src/utilities/webhook_generators.dart';

void main() {
  late GithubWebhookSubscription webhook;
  late FakeBuildBucketClient fakeBuildBucketClient;
  late FakeConfig config;
  late FakeDatastoreDB db;
  late FakeGithubService githubService;
  late FakeHttpRequest request;
  late FakeScheduler scheduler;
  late FakeGerritService gerritService;
  late MockGitHub gitHubClient;
  late MockGithubChecksUtil mockGithubChecksUtil;
  late MockGithubChecksService mockGithubChecksService;
  late MockIssuesService issuesService;
  late MockPullRequestsService pullRequestsService;
  late SubscriptionTester tester;

  /// Name of an example release base branch name.
  const String kReleaseBaseRef = 'flutter-2.12-candidate.4';

  /// Name of an example release head branch name.
  const String kReleaseHeadRef = 'cherrypicks-flutter-2.12-candidate.4';

  setUp(() {
    request = FakeHttpRequest();
    db = FakeDatastoreDB();
    gitHubClient = MockGitHub();
    githubService = FakeGithubService();
    final MockTabledataResource tabledataResource = MockTabledataResource();
    when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((_) async => TableDataInsertAllResponse());
    config = FakeConfig(
      dbValue: db,
      githubClient: gitHubClient,
      githubService: githubService,
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
      wrongHeadBranchPullRequestMessageValue: 'wrongHeadBranchPullRequestMessage',
      wrongBaseBranchPullRequestMessageValue: '{{target_branch}} -> {{default_branch}}',
    );
    issuesService = MockIssuesService();
    when(issuesService.addLabelsToIssue(any, any, any)).thenAnswer((_) async => <IssueLabel>[]);
    when(issuesService.createComment(any, any, any)).thenAnswer((_) async => IssueComment());
    when(issuesService.listCommentsByIssue(any, any))
        .thenAnswer((_) => Stream<IssueComment>.fromIterable(<IssueComment>[IssueComment()]));
    pullRequestsService = MockPullRequestsService();
    when(pullRequestsService.listFiles(Config.flutterSlug, any))
        .thenAnswer((_) => const Stream<PullRequestFile>.empty());
    when(pullRequestsService.edit(any, any, title: anyNamed('title'), state: anyNamed('state'), base: anyNamed('base')))
        .thenAnswer((_) async => PullRequest());
    fakeBuildBucketClient = FakeBuildBucketClient();
    mockGithubChecksUtil = MockGithubChecksUtil();
    scheduler = FakeScheduler(
      config: config,
      buildbucket: fakeBuildBucketClient,
      githubChecksUtil: mockGithubChecksUtil,
    );
    tester = SubscriptionTester(request: request);

    mockGithubChecksService = MockGithubChecksService();
    when(gitHubClient.issues).thenReturn(issuesService);
    when(gitHubClient.pullRequests).thenReturn(pullRequestsService);
    when(mockGithubChecksUtil.createCheckRun(any, any, any, any, output: anyNamed('output'))).thenAnswer((_) async {
      return CheckRun.fromJson(const <String, dynamic>{
        'id': 1,
        'started_at': '2020-05-10T02:49:31Z',
        'check_suite': <String, dynamic>{'id': 2}
      });
    });

    gerritService = FakeGerritService();
    webhook = GithubWebhookSubscription(
      config: config,
      cache: CacheService(inMemory: true),
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      gerritService: gerritService,
      githubChecksService: mockGithubChecksService,
      scheduler: scheduler,
    );
  });

  group('github webhook pull_request event', () {
    test('Closes PR opened from dev', () async {
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        headRef: 'dev',
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'flutter-2.13-candidate.0',
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'dev',
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

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

    test('Acts on closed, cancels presubmit targets, add pr for postsubmit target create', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        baseRef: 'dev',
        merged: true,
        baseSha: 'sha1',
        mergeCommitSha: 'sha2',
      );

      await tester.post(webhook);

      expect(scheduler.cancelPreSubmitTargetsCallCnt, 1);
      expect(scheduler.addPullRequestCallCnt, 1);
    });

    // We already schedule checks when a draft is opened, don't need to re-test
    // just because it was marked ready for review
    test('Does nothing on ready_for_review', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'ready_for_review',
        number: issueNumber,
      );
      bool batchRequestCalled = false;

      Future<BatchResponse> getBatchResponse() async {
        batchRequestCalled = true;
        fail('Marking a draft ready for review should not trigger new builds');
      }

      fakeBuildBucketClient.batchResponse = getBatchResponse;

      await tester.post(webhook);

      expect(batchRequestCalled, isFalse);
    });

    test('Triggers builds when opening a draft PR', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        isDraft: true,
      );
      bool batchRequestCalled = false;

      Future<BatchResponse> getBatchResponse() async {
        batchRequestCalled = true;
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(999, name: 'Linux', status: Status.ended),
                ],
              ),
            ),
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux', status: Status.ended),
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'flutter-1.20-candidate.7',
        headRef: 'cherrypicks-flutter-1.20-candidate.7',
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
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

    test('release PRs are approved', () async {
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        // Base is where the PR will merge into
        baseRef: 'flutter-2.13-candidate.0',
        login: 'dart-flutter-releaser',
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber))
          .thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(pullRequestsService.createReview(Config.flutterSlug, any))
          .thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      final List<dynamic> reviews = verify(pullRequestsService.createReview(Config.flutterSlug, captureAny)).captured;
      expect(reviews.length, 1);
      final CreatePullRequestReview review = reviews.single as CreatePullRequestReview;
      expect(review.event, 'APPROVE');
    });

    test('fake release PRs are not approved', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        // Base is where the PR will merge into
        baseRef: 'master',
        // Head is the branch from the fork
        headRef: 'flutter-2.13-candidate.0',
        login: 'dart-flutter-releaser',
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber))
          .thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(pullRequestsService.createReview(Config.flutterSlug, any))
          .thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      verifyNever(pullRequestsService.createReview(Config.flutterSlug, captureAny));
    });

    test('release PRs are not approved for outsider PRs', () async {
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        headRef: 'flutter-2.13-candidate.0',
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber))
          .thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(pullRequestsService.createReview(Config.flutterSlug, any))
          .thenAnswer((_) async => PullRequestReview(id: 123, user: User()));

      await tester.post(webhook);

      verifyNever(pullRequestsService.createReview(Config.flutterSlug, any));
    });

    test('Framework labels PRs, comment if no tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
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

    group("Auto-roller accounts do not label Framework PR with test label or comment.", () {
      final Set<String> inputs = {
        'skia-flutter-autoroll',
        'dependabot',
      };

      for (String element in inputs) {
        test('Framework does not label PR with no tests label if author is $element', () async {
          const int issueNumber = 123;

          tester.message = generateGithubWebhookMessage(
            action: 'opened',
            number: issueNumber,
            login: element,
          );

          final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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

          verifyNever(
            issuesService.addLabelsToIssue(
              slug,
              issueNumber,
              any,
            ),
          );

          verifyNever(
            issuesService.createComment(
              slug,
              issueNumber,
              argThat(contains(config.missingTestsPullRequestMessageValue)),
            ),
          );
        });
      }
    });

    test('Framework does not label PR with no tests label if author is engine-flutter-autoroll', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        login: 'engine-flutter-autoroll',
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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

      verifyNever(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework does not label PR with no tests label if file is test exempt', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/devicelab/lib/versions/gallery.dart',
          PullRequestFile()..filename = 'dev/integration_tests/some_package/android/build.gradle',
          PullRequestFile()..filename = 'shell/platform/embedder/tests/embedder_test_context.cc',
          PullRequestFile()..filename = 'shell/platform/embedder/fixtures/main.dart',
        ]),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Framework labels PRs, comment if no tests including hit_test.dart file', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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
    });

    test('Framework labels PRs, no dart files', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.md',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          slug,
          issueNumber,
          any,
        ),
      );
    });

    test('Framework labels PRs, no comment if tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/semantics_test.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
          PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()..filename = 'dev/devicelab/bin/tasks/analyzer_benchmark.dart',
          PullRequestFile()..filename = 'bin/internal/engine.version',
          PullRequestFile()..filename = 'packages/flutter/lib/src/cupertino/blah.dart',
          PullRequestFile()..filename = 'packages/flutter/lib/src/material/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_localizations/blah.dart',
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/test_fixes/material.dart',
          PullRequestFile()..filename = 'packages/flutter/test_fixes/material.expect',
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        login: 'fluttergithubbot',
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter_tools/lib/src/ios/devices.dart',
          PullRequestFile()..filename = 'dev/devicelab/lib/tasks/plugin_tests.dart',
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
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()..filename = 'dev/devicelab/bin/tasks/analyzer_benchmark.dart',
          PullRequestFile()..filename = 'dev/devicelab/lib/tasks/plugin_tests.dart',
          PullRequestFile()..filename = 'dev/benchmarks/microbenchmarks/lib/foundation/all_elements_bench.dart',
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
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.gitignore',
          PullRequestFile()..filename = 'dev/integration_tests/foo_app/.gitignore',
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
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          // Example of real behavior code change.
          PullRequestFile()
            ..filename = 'packages/flutter_tools/templates/app_shared/macos.tmpl/Runner/Base.lproj/MainMenu.xib',
          // Example of Objective-C test.
          PullRequestFile()..filename = 'dev/integration_tests/flutter_gallery/macos/RunnerTests/RunnerTests.m',
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
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
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

    test('Framework no comment if only ci.yaml and cirrus.yml changed', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.ci.yaml',
          PullRequestFile()..filename = '.cirrus.yml',
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
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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

    test('Framework no comment if only CODEOWNERS or TESTOWNERS changed', () async {
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

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
    });

    for (String extention in knownCommentCodeExtensions) {
      test('Framework no comment if only comments changed .$extention', () async {
        const int issueNumber = 123;
        tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);
        final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

        const String patch = '''
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
      });
    }

    test('Framework labels PRs, no comment if tests (dev/bots/test.dart)', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
          PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
          PullRequestFile()..filename = 'packages/flutter/lib/src/material/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_localizations/blah.dart',
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

    test('Framework labels PRs, no comment if tests (dev/bots/analyze.dart)', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/bots/analyze.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
          PullRequestFile()..filename = 'examples/flutter_gallery/blah.dart',
          PullRequestFile()..filename = 'packages/flutter/lib/src/material/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_localizations/blah.dart',
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

    test('Framework labels PRs, no comment if tests (flutter_tools/test/helper.dart)', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_tools/test/helper.dart',
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

    test('Framework labels PRs, apply label but no comment when rolling engine version', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: kReleaseBaseRef,
        headRef: kReleaseHeadRef,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
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
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, comment if no tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
        baseRef: Config.defaultBranch(Config.engineSlug),
      );
      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'shell/platform/darwin/ios/framework/Source/boost.mm',
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
    });

    group("Auto-roller accounts do not label Engine PR with test label or comment.", () {
      final Set<String> inputs = {
        'engine-flutter-autoroll',
        'dependabot',
        'dependabot[bot]',
      };

      for (String element in inputs) {
        test('Engine does not label PR for no tests if author is $element', () async {
          const int issueNumber = 123;

          tester.message = generateGithubWebhookMessage(
            action: 'opened',
            number: issueNumber,
            slug: Config.engineSlug,
            login: element,
          );

          when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
            (_) => Stream<PullRequestFile>.value(
              PullRequestFile()..filename = 'shell/platform/darwin/ios/framework/Source/boost.mm',
            ),
          );

          when(issuesService.listCommentsByIssue(Config.engineSlug, issueNumber)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          await tester.post(webhook);

          verifyNever(
            issuesService.createComment(
              Config.engineSlug,
              issueNumber,
              argThat(contains(config.missingTestsPullRequestMessageValue)),
            ),
          );
        });
      }
    });

    test('Engine does not label PR for no tests if on branch', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
        baseRef: 'flutter-3.12-candidate.1',
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'shell/platform/darwin/ios/framework/Source/boost.mm',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      );
    });

    test('Engine does not label PR for no tests if author is skia-flutter-autoroll', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
        login: 'skia-flutter-autoroll',
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'shell/platform/darwin/ios/framework/Source/boost.mm',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      );
    });

    test('Engine labels PRs, no code files', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'main',
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'DEPS',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          any,
        ),
      );
    });

    test('Engine labels PRs, no comment if Java tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'shell/platform/android/io/flutter/Blah.java',
          PullRequestFile()..filename = 'shell/platform/android/test/io/flutter/BlahTest.java',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(Config.engineSlug, issueNumber, any),
      );

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, no comment if script tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'fml/blah.cc',
          PullRequestFile()..filename = 'fml/testing/blah_test.sh',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, no comment if cc tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'fml/blah.cc',
          PullRequestFile()..filename = 'fml/blah_unittests.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, no comment if cc benchmarks', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'fml/blah.cc',
          PullRequestFile()..filename = 'fml/blah_benchmarks.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          any,
        ),
      );

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, no comments if pr is for release branches', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: kReleaseBaseRef,
        headRef: kReleaseHeadRef,
        slug: Config.engineSlug,
      );
      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'shell/platform/darwin/ios/framework/Source/boost.mm',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('bot does not comment for whitespace only changes', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );
      const String patch = '''
@@ -128,7 +128,7 @@

  int bar = 0;
+
  int baz = 0;
''';

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
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
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine does not comment for comment-only changes', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );
      const String patch = '''
@@ -128,7 +128,7 @@

/// Insert interesting comment here.
///
-/// More details here, but some of them are wrong.
+/// These are the right details!
void foo() {
  int bar = 0;
  String baz = '';
''';

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
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
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels deletion only PR, no test request', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'flutter/lib/ui/foo.dart'
            ..deletionsCount = 20
            ..additionsCount = 0
            ..changesCount = 20,
        ]),
      );

      await tester.post(webhook);

      // The PR here is only deleting code, so no test comment.
      verifyNever(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('No labels when only pubspec.yaml changes', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
      );
      when(pullRequestsService.listFiles(Config.packagesSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/pigeon/lib/swift_generator.dart',
          PullRequestFile()
            ..filename = 'packages/pigeon/platform_tests/shared_test_plugin_code/lib/integration_tests.dart',
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

    test('Packages comments and labels if no tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
        baseRef: Config.defaultBranch(Config.packagesSlug),
      );
      when(pullRequestsService.listFiles(Config.packagesSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber)).thenAnswer(
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

      verify(
        issuesService.addLabelsToIssue(
          Config.packagesSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      ).called(1);
    });

    test('Packages do not comment or label if pr is for release branches', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: kReleaseBaseRef,
        headRef: kReleaseHeadRef,
        slug: Config.packagesSlug,
      );

      when(pullRequestsService.listFiles(Config.packagesSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.packagesSlug, issueNumber)).thenAnswer(
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
        issuesService.addLabelsToIssue(
          Config.packagesSlug,
          issueNumber,
          any,
        ),
      );
    });

    test('Packages does not comment if Dart tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
      );

      when(pullRequestsService.listFiles(Config.packagesSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.packagesSlug,
      );

      when(pullRequestsService.listFiles(Config.packagesSlug, issueNumber)).thenAnswer(
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        merged: true,
        baseSha: 'sha1', // Found in pre-populated commits in FakeGerritService.
        mergeCommitSha: 'sha2',
      );

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.post(webhook);
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test('Fail when pull request is closed and merged, but merged commit is not found on GoB', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'closed',
        number: issueNumber,
        merged: true,
        baseSha: 'unknown_sha',
      );

      expect(db.values.values.whereType<Commit>().length, 0);
      try {
        await tester.post(webhook);
      } catch (e) {
        expect(
          e.toString(),
          matches(
            r'HTTP 500: (.+) was not found on GoB\. Failing so this event can be retried\.\.\.',
          ),
        );
      }
      expect(db.values.values.whereType<Commit>().length, 0);
    });

    test('Does not comment about needing tests on draft pull requests.', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        isDraft: true,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
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
    });

    test('Will not spawn comments if they have already been made.', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
      );

      when(pullRequestsService.listFiles(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = config.missingTestsPullRequestMessageValue,
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          any,
        ),
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
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        login: 'engine-flutter-autoroll',
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          any,
          issueNumber,
          any,
        ),
      );
    });

    test('Comments on PR but does not schedule builds for unmergeable PRs', () async {
      const int issueNumber = 12345;
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
    });

    test('When synchronized, cancels existing builds and schedules new ones', () async {
      const int issueNumber = 12345;
      bool batchRequestCalled = false;
      Future<BatchResponse> getBatchResponse() async {
        batchRequestCalled = true;
        return BatchResponse(
          responses: <Response>[
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(999, name: 'Linux', status: Status.ended),
                ],
              ),
            ),
            Response(
              searchBuilds: SearchBuildsResponse(
                builds: <Build>[
                  generateBuild(998, name: 'Linux', status: Status.ended),
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

      final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();
      when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

      await tester.post(webhook);
      expect(batchRequestCalled, isTrue);
    });

    group('BuildBucket', () {
      const int issueNumber = 123;

      Future<void> testActions(String action) async {
        when(issuesService.listLabelsByIssue(any, issueNumber)).thenAnswer((_) {
          return Stream<IssueLabel>.fromIterable(<IssueLabel>[
            IssueLabel()..name = 'Random Label',
          ]);
        });

        fakeBuildBucketClient.batchResponse = () => Future<BatchResponse>.value(
              const BatchResponse(
                responses: <Response>[
                  Response(
                    searchBuilds: SearchBuildsResponse(
                      builds: <Build>[],
                    ),
                  ),
                  Response(
                    searchBuilds: SearchBuildsResponse(
                      builds: <Build>[],
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

      test('Comments on PR but does not schedule builds for unmergeable PRs', () async {
        when(issuesService.listCommentsByIssue(any, any)).thenAnswer((_) => Stream<IssueComment>.value(IssueComment()));
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
      });

      test('When synchronized, cancels existing builds and schedules new ones', () async {
        fakeBuildBucketClient.batchResponse = () => Future<BatchResponse>.value(
              BatchResponse(
                responses: <Response>[
                  Response(
                    searchBuilds: SearchBuildsResponse(
                      builds: <Build>[
                        generateBuild(999, name: 'Linux', status: Status.ended),
                      ],
                    ),
                  ),
                  Response(
                    searchBuilds: SearchBuildsResponse(
                      builds: <Build>[
                        generateBuild(998, name: 'Linux', status: Status.ended),
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
        final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();
        when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

        await tester.post(webhook);
      });
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
}
