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

    webhook = GithubWebhookSubscription(
      config: config,
      cache: CacheService(inMemory: true),
      datastoreProvider: (_) => DatastoreService(config.db, 5),
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

    test('Acts on opened against master when default is main', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: 'master',
        slug: Config.engineSlug,
      );

      when(pullRequestsService.listFiles(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.engineSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        pullRequestsService.edit(
          Config.engineSlug,
          issueNumber,
          base: 'main',
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          Config.engineSlug,
          issueNumber,
          argThat(contains('master -> main')),
        ),
      ).called(1);
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

    group('getLabelsForFrameworkPath', () {
      test('Only the team label is applied to pubspec.yaml', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_tools/pubspec.yaml'),
          <String>{'team'},
        );
      });

      test('Tool label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_tools/hot_reload.dart'),
          contains('tool'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath(
            'packages/fuchsia_remote_debug_protocol/hot_reload.dart',
          ),
          contains('tool'),
        );
      });

      test('iOS label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_tools/lib/src/ios/devices.dart'),
          <String>{'platform-ios', 'tool'},
        );
      });

      test('Engine label applied', () {
        expect(GithubWebhookSubscription.getLabelsForFrameworkPath('bin/internal/engine.version'), contains('engine'));
      });

      test('Framework label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/widget.dart'),
          contains('framework'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_test/lib/tester.dart'),
          contains('framework'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_driver/lib/driver.dart'),
          contains('framework'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
          contains('framework'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
          contains('framework'),
        );
      });

      test('Material label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('foo/bar/baz/material/design.dart'),
          contains('f: material design'),
        );
      });

      test('Cupertino label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('foo/bar/baz/cupertino/design.dart'),
          contains('f: cupertino'),
        );
      });

      test('i18n label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_localizations/allo.dart'),
          contains('a: internationalization'),
        );
      });

      test('Tests label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_test/lib/tester.dart'),
          contains('a: tests'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_driver/lib/driver.dart'),
          contains('a: tests'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
          contains('a: tests'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
          contains('a: tests'),
        );
      });

      test('a11y label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('foo/bar/baz/semantics/voiceover.dart'),
          contains('a: accessibility'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('foo/bar/baz/accessibility/voiceover.dart'),
          contains('a: accessibility'),
        );
      });

      test('Examples label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('examples/foo/bar/baz.dart'),
          contains('d: examples'),
        );
      });

      test('API Docs label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('examples/api/bar/baz.dart'),
          <String>['d: examples', 'team', 'd: api docs', 'documentation'],
        );
      });

      test('Gallery label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('examples/flutter_gallery/lib/gallery.dart'),
          contains('team: gallery'),
        );
      });

      test('Team label applied', () {
        expect(GithubWebhookSubscription.getLabelsForFrameworkPath('dev/foo/bar/baz.dart'), contains('team'));
        expect(GithubWebhookSubscription.getLabelsForFrameworkPath('examples/foo/bar/baz.dart'), contains('team'));
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
          contains('team'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
          contains('team'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/fix_data.yaml'),
          contains('team'),
        );
        expect(GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/test_fixes'), contains('team'));
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/test_fixes/material.expect'),
          contains('team'),
        );
      });

      test('tech-debt label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/fix_data.yaml'),
          contains('tech-debt'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/test_fixes'),
          contains('tech-debt'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/test_fixes/material.expect'),
          contains('tech-debt'),
        );
      });

      test('gestures label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/gestures'),
          contains('f: gestures'),
        );
      });

      test('focus label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_node.dart'),
          contains('f: focus'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_scope.dart'),
          contains('f: focus'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_manager.dart'),
          contains('f: focus'),
        );
      });

      test('routes label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/router.dart'),
          contains('f: routes'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/routes.dart'),
          contains('f: routes'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/navigator.dart'),
          contains('f: routes'),
        );
      });

      test('text input label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath(
            'dev/integration_tests/web_e2e_tests/test_driver/text_editing_integration.dart',
          ),
          contains('a: text input'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath(
            'packages/flutter/lib/src/widgets/text_editing_action.dart',
          ),
          contains('a: text input'),
        );
      });

      test('animation label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/animation'),
          contains('a: animation'),
        );
      });

      test('scrolling label applied', () {
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/sliver.dart'),
          contains('f: scrolling'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/material/scrollbar.dart'),
          contains('f: scrolling'),
        );
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/flutter/lib/src/rendering/viewport.dart'),
          contains('f: scrolling'),
        );
      });

      test('integration_test label is/isn\'t applied', () {
        // Label does not apply to integration tests outside of the
        // integration_test package.
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath(
            'dev/integration_tests/web_e2e_tests/test_driver/text_editing_integration.dart',
          ),
          <String>{'team', 'a: text input'},
        );
        // Label applies to integration_test package
        expect(
          GithubWebhookSubscription.getLabelsForFrameworkPath('packages/integration_test/lib/common.dart'),
          contains('integration_test'),
        );
      });
    });

    group('getLabelsForEnginePath', () {
      test('No label is applied to paths with no applicable label', () {
        expect(GithubWebhookSubscription.getLabelsForEnginePath('nonsense/path/foo.cc'), isEmpty);
      });

      test('platform-android applied for Android embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/android/RIsForRhubarbPie.java'),
          contains('platform-android'),
        );
      });

      test('platform-ios and platform-macos applied for common Darwin code', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/darwin/common/ThinkDifferent.mm'),
          containsAll(<String>['platform-ios', 'platform-macos']),
        );
      });

      test('platform-ios and platform-ios applied for iOS embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/darwin/ios/BackButton.mm'),
          contains('platform-ios'),
        );
      });

      test('platform-macos applied for macOS embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/darwin/macos/PhysicalEscapeKey.mm'),
          contains('platform-macos'),
        );
      });

      test('platform-fuchsia applied for fuchsia embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/fuchsia/spell_checker.cc'),
          contains('platform-fuchsia'),
        );
      });

      test('platform-linux applied for linux embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/linux/systemd_integration.cc'),
          contains('platform-linux'),
        );
      });

      test('platform-windows applied for windows embedder', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('shell/platform/windows/start_menu.cc'),
          contains('platform-windows'),
        );
      });

      test('platform-web applied for web paths', () {
        expect(
          GithubWebhookSubscription.getLabelsForEnginePath('lib/web_ui/shadow_dom.dart'),
          contains('platform-web'),
        );
        expect(GithubWebhookSubscription.getLabelsForEnginePath('web_sdk/'), contains('platform-web'));
      });
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
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          <String>['framework'],
        ),
      ).called(1);

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

          verify(
            issuesService.addLabelsToIssue(
              slug,
              issueNumber,
              <String>['framework'],
            ),
          ).called(1);

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
          <String>['framework'],
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
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'dev/devicelab/lib/versions/gallery.dart',
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
          <String>['framework'],
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
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['framework', 'f: gestures'],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['framework'],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>[
            'framework',
            'a: accessibility',
            'tool',
            'a: tests',
            'd: examples',
            'team',
            'team: gallery',
            'engine',
            'f: cupertino',
            'f: material design',
            'a: internationalization',
          ],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['team', 'tech-debt', 'framework', 'f: material design'],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['tool', 'framework', 'a: tests', 'team', 'tech-debt', 'team: flakes'],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['framework'],
        ),
      ).called(1);

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
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['framework'],
        ),
      ).called(1);

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

    test('Framework no comment if only CODEOWNERS changed', () async {
      const int issueNumber = 123;
      tester.message = generateGithubWebhookMessage(action: 'opened', number: issueNumber);
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'CODEOWNERS',
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

    test('Framework no comment if only comments changed', () async {
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
            ..filename = 'packages/foo/lib/foo.dart'
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

      verify(
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          <String>['engine'],
        ),
      ).called(1);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Engine labels PRs, comment and labels if no tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.engineSlug,
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
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['platform-ios'],
        ),
      ).called(1);

      verify(
        issuesService.createComment(
          slug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);

      verify(
        issuesService.addLabelsToIssue(
          slug,
          issueNumber,
          <String>['needs tests'],
        ),
      ).called(1);
    });

    group("Auto-roller accounts do not label Engine PR with test label or comment.", () {
      final Set<String> inputs = {
        'engine-flutter-autoroll',
        'dependabot',
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

          verify(
            issuesService.addLabelsToIssue(
              Config.engineSlug,
              issueNumber,
              <String>['platform-ios'],
            ),
          ).called(1);

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
      }
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
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          <String>['platform-ios'],
        ),
      );

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

      verify(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          <String>[
            'platform-android',
          ],
        ),
      ).called(1);

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

    test('Engine labels PRs, no comment if cc becnhmarks', () async {
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

      verify(
        issuesService.addLabelsToIssue(
          Config.engineSlug,
          issueNumber,
          <String>['platform-ios'],
        ),
      ).called(1);

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

      verify(
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          <String>['team'],
        ),
      ).called(1);

      verifyNever(
        issuesService.createComment(
          Config.flutterSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins comments and labels if no tests and no patch info', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );

      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);

      verify(
        issuesService.addLabelsToIssue(
          Config.pluginsSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      ).called(1);
    });

    group('Plugins does not comment and label if author is an autoroller account.', () {
      final Set<String> inputs = {
        'engine-flutter-autoroll',
        'skia-flutter-autoroll',
        'dependabot',
      };

      for (String element in inputs) {
        test('Plugins does not comment and label if author is $element.', () async {
          const int issueNumber = 123;

          tester.message = generateGithubWebhookMessage(
            action: 'opened',
            number: issueNumber,
            slug: Config.pluginsSlug,
            login: element,
          );

          when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
            (_) => Stream<PullRequestFile>.value(
              PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
            ),
          );

          when(issuesService.listCommentsByIssue(Config.pluginsSlug, issueNumber)).thenAnswer(
            (_) => Stream<IssueComment>.value(
              IssueComment()..body = 'some other comment',
            ),
          );

          await tester.post(webhook);

          verifyNever(
            issuesService.createComment(
              Config.pluginsSlug,
              issueNumber,
              argThat(contains(config.missingTestsPullRequestMessageValue)),
            ),
          );

          verifyNever(
            issuesService.addLabelsToIssue(
              Config.pluginsSlug,
              issueNumber,
              <String>['needs tests'],
            ),
          );
        });
      }
    });

    test('Plugins apply no label or comment if pr is for release branches', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        baseRef: kReleaseBaseRef,
        headRef: kReleaseHeadRef,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
        ),
      );

      when(issuesService.listCommentsByIssue(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );

      verifyNever(
        issuesService.addLabelsToIssue(
          Config.pluginsSlug,
          issueNumber,
          any,
        ),
      );
    });

    test('Plugins comments and labels for code change', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      const String patch = '''
@@ -128,8 +128,8 @@
  NSString* foo = "";
  int bar = 0;

-  // Some incorrect code:
-  int baz = 7 / bar;
+  // Better code:
+  int baz = 7 * bar;
  return baz;
}

''';

      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()
            ..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m'
            ..additionsCount = 2
            ..deletionsCount = 2
            ..changesCount = 4
            ..patch = patch,
        ),
      );

      when(issuesService.listCommentsByIssue(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);

      verify(
        issuesService.addLabelsToIssue(
          Config.pluginsSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      ).called(1);
    });

    test('Plugins comments and labels for code removal with comment addition', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      const String patch = '''
@@ -128,7 +128,7 @@
  int foo = 0;

  int bar = 0;
-  int baz = 0;
+  // int baz = 0;

  // More code here:

''';

      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()
            ..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m'
            ..additionsCount = 1
            ..deletionsCount = 1
            ..changesCount = 2
            ..patch = patch,
        ),
      );

      when(issuesService.listCommentsByIssue(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      ).called(1);

      verify(
        issuesService.addLabelsToIssue(
          Config.pluginsSlug,
          issueNumber,
          <String>['needs tests'],
        ),
      ).called(1);
    });

    test('Plugins does not comment for comment-only changes', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
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

      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()
            ..filename = 'packages/foo/lib/foo.dart'
            ..additionsCount = 1
            ..deletionsCount = 1
            ..changesCount = 2
            ..patch = patch,
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if Dart tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
          PullRequestFile()..filename = 'packages/foo/test/foo_test.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if Android unit tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_android/src/main/Foo.java',
          PullRequestFile()..filename = 'packages/foo/foo_android/src/test/FooTest.java',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if Android UI tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_android/src/main/Foo.java',
          PullRequestFile()..filename = 'packages/foo/foo_android/example/android/app/src/androidTest/FooTest.java',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if iOS/macOS unit tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
          PullRequestFile()..filename = 'packages/foo/foo_ios/example/ios/RunnerTests/FooTests.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if iOS/macOS UI tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
          PullRequestFile()..filename = 'packages/foo/foo_ios/example/ios/RunnerUITests/FooTests.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if Windows tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_windows/windows/foo.cpp',
          PullRequestFile()..filename = 'packages/foo/foo_windows/windows/test/foo_test.cpp',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
          issueNumber,
          argThat(contains(config.missingTestsPullRequestMessageValue)),
        ),
      );
    });

    test('Plugins does not comment if Linux tests', () async {
      const int issueNumber = 123;

      tester.message = generateGithubWebhookMessage(
        action: 'opened',
        number: issueNumber,
        slug: Config.pluginsSlug,
      );
      when(pullRequestsService.listFiles(Config.pluginsSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_linux/linux/foo.cc',
          PullRequestFile()..filename = 'packages/foo/foo_linux/linux/test/foo_test.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(
        issuesService.createComment(
          Config.pluginsSlug,
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
      );

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.post(webhook);
      expect(db.values.values.whereType<Commit>().length, 1);
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

      verify(
        issuesService.addLabelsToIssue(
          Config.flutterSlug,
          issueNumber,
          <String>['framework'],
        ),
      ).called(1);

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
