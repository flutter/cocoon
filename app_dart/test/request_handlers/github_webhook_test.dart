// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import 'package:crypto/crypto.dart';
import 'package:github/github.dart' hide Branch;
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/request_handler_tester.dart';
import '../src/service/fake_buildbucket.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late GithubWebhook webhook;
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
  late RequestHandlerTester tester;
  const String serviceAccountEmail = 'test@test';
  ServiceAccountInfo? serviceAccountInfo;

  const String keyString = 'not_a_real_key';

  String getHmac(Uint8List list, Uint8List key) {
    final Hmac hmac = Hmac(sha1, key);
    return hmac.convert(list).toString();
  }

  setUp(() {
    serviceAccountInfo = const ServiceAccountInfo(email: serviceAccountEmail);
    request = FakeHttpRequest();
    db = FakeDatastoreDB();
    gitHubClient = MockGitHub();
    githubService = FakeGithubService();
    final MockTabledataResource tabledataResource = MockTabledataResource();
    when(tabledataResource.insertAll(any, any, any, any)).thenAnswer((_) async => TableDataInsertAllResponse());
    config = FakeConfig(
      dbValue: db,
      deviceLabServiceAccountValue: serviceAccountInfo,
      githubService: githubService,
      tabledataResource: tabledataResource,
      githubClient: gitHubClient,
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
    tester = RequestHandlerTester(request: request);

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

    webhook = GithubWebhook(
      config,
      datastoreProvider: (_) => DatastoreService(config.db, 5),
      githubChecksService: mockGithubChecksService,
      scheduler: scheduler,
    );

    config.wrongHeadBranchPullRequestMessageValue = 'wrongHeadBranchPullRequestMessage';
    config.wrongBaseBranchPullRequestMessageValue = '{{target_branch}} -> {{default_branch}}';
    config.releaseBranchPullRequestMessageValue = 'releaseBranchPullRequestMessage';
    config.missingTestsPullRequestMessageValue = 'missingTestPullRequestMessage';
    config.githubOAuthTokenValue = 'githubOAuthKey';
    config.webhookKeyValue = keyString;
    config.githubClient = gitHubClient;
    config.deviceLabServiceAccountValue = const ServiceAccountInfo(email: serviceAccountEmail);
  });

  group('github webhook pull_request event', () {
    test('Rejects non-POST methods with methodNotAllowed', () async {
      expect(tester.get(webhook), throwsA(isA<MethodNotAllowed>()));
    });

    test('Rejects missing headers', () async {
      expect(tester.post(webhook), throwsA(isA<BadRequestException>()));
    });

    test('Rejects invalid hmac', () async {
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.headers.set('X-Hub-Signature', 'bar');
      request.body = 'Hello, World!';
      expect(tester.post(webhook), throwsA(isA<Forbidden>()));
    });

    test('Rejects malformed unicode', () async {
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.bodyBytes = Uint8List.fromList(<int>[0xc3, 0x28]);
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(request.bodyBytes, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      expect(tester.post(webhook), throwsA(isA<BadRequestException>()));
    });

    test('Rejects non-json', () async {
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = 'Hello, World!';
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      expect(tester.post(webhook), throwsA(isA<BadRequestException>()));
    });

    test('Closes PR opened from dev', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        headRef: 'dev',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

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

      verify(pullRequestsService.edit(
        Config.flutterSlug,
        issueNumber,
        state: 'closed',
      )).called(1);

      verify(issuesService.createComment(
        Config.flutterSlug,
        issueNumber,
        argThat(contains(config.wrongHeadBranchPullRequestMessageValue)),
      )).called(1);
    });

    test('Acts on opened against dev', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, 'dev');
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

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

      verify(pullRequestsService.edit(
        slug,
        issueNumber,
        base: kDefaultBranchName,
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains('dev -> master')),
      )).called(1);
    });

    test('Acts on opened against master when default is main', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        'master',
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

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

      verify(pullRequestsService.edit(
        slug,
        issueNumber,
        base: 'main',
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains('master -> main')),
      )).called(1);
    });

    test('Does nothing against cherry pick PR', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        'flutter-1.20-candidate.7',
        headRef: 'cherrypicks-flutter-1.20-candidate.7',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

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

      verifyNever(pullRequestsService.edit(
        slug,
        issueNumber,
        base: kDefaultBranchName,
      ));

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.wrongBaseBranchPullRequestMessage)),
      ));
    });

    group('getLabelsForFrameworkPath', () {
      test('Only the team label is applied to pubspec.yaml', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_tools/pubspec.yaml'), <String>{'team'});
      });

      test('Tool label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_tools/hot_reload.dart'), contains('tool'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/fuchsia_remote_debug_protocol/hot_reload.dart'),
            contains('tool'));
      });

      test('Engine label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('bin/internal/engine.version'), contains('engine'));
      });

      test('Framework label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/widget.dart'), contains('framework'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_test/lib/tester.dart'), contains('framework'));
        expect(
            GithubWebhook.getLabelsForFrameworkPath('packages/flutter_driver/lib/driver.dart'), contains('framework'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
            contains('framework'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
            contains('framework'));
      });

      test('Material label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('foo/bar/baz/material/design.dart'),
            contains('f: material design'));
      });

      test('Cupertino label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('foo/bar/baz/cupertino/design.dart'), contains('f: cupertino'));
      });

      test('i18n label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_localizations/allo.dart'),
            contains('a: internationalization'));
      });

      test('Tests label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_test/lib/tester.dart'), contains('a: tests'));
        expect(
            GithubWebhook.getLabelsForFrameworkPath('packages/flutter_driver/lib/driver.dart'), contains('a: tests'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
            contains('a: tests'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
            contains('a: tests'));
      });

      test('a11y label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('foo/bar/baz/semantics/voiceover.dart'),
            contains('a: accessibility'));
        expect(GithubWebhook.getLabelsForFrameworkPath('foo/bar/baz/accessibility/voiceover.dart'),
            contains('a: accessibility'));
      });

      test('Examples label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('examples/foo/bar/baz.dart'), contains('d: examples'));
      });

      test('API Docs label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('examples/api/bar/baz.dart'),
            <String>['d: examples', 'team', 'd: api docs', 'documentation']);
      });

      test('Gallery label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('examples/flutter_gallery/lib/gallery.dart'),
            contains('team: gallery'));
      });

      test('Team label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('dev/foo/bar/baz.dart'), contains('team'));
        expect(GithubWebhook.getLabelsForFrameworkPath('examples/foo/bar/baz.dart'), contains('team'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens/lib/flutter_goldens.dart'),
            contains('team'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter_goldens_client/lib/skia_client.dart'),
            contains('team'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/fix_data.yaml'), contains('team'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/test_fixes'), contains('team'));
        expect(
            GithubWebhook.getLabelsForFrameworkPath('packages/flutter/test_fixes/material.expect'), contains('team'));
      });

      test('tech-debt label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/fix_data.yaml'), contains('tech-debt'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/test_fixes'), contains('tech-debt'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/test_fixes/material.expect'),
            contains('tech-debt'));
      });

      test('gestures label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/gestures'), contains('f: gestures'));
      });

      test('focus label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_node.dart'),
            contains('f: focus'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_scope.dart'),
            contains('f: focus'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/focus_manager.dart'),
            contains('f: focus'));
      });

      test('routes label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/router.dart'),
            contains('f: routes'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/routes.dart'),
            contains('f: routes'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/navigator.dart'),
            contains('f: routes'));
      });

      test('text input label applied', () {
        expect(
            GithubWebhook.getLabelsForFrameworkPath(
                'dev/integration_tests/web_e2e_tests/test_driver/text_editing_integration.dart'),
            contains('a: text input'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/text_editing_action.dart'),
            contains('a: text input'));
      });

      test('animation label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/animation'), contains('a: animation'));
      });

      test('scrolling label applied', () {
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/widgets/sliver.dart'),
            contains('f: scrolling'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/material/scrollbar.dart'),
            contains('f: scrolling'));
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/flutter/lib/src/rendering/viewport.dart'),
            contains('f: scrolling'));
      });

      test('integration_test label is/isn\'t applied', () {
        // Label does not apply to integration tests outside of the
        // integration_test package.
        expect(
            GithubWebhook.getLabelsForFrameworkPath(
                'dev/integration_tests/web_e2e_tests/test_driver/text_editing_integration.dart'),
            <String>{'team', 'a: text input'});
        // Label applies to integration_test package
        expect(GithubWebhook.getLabelsForFrameworkPath('packages/integration_test/lib/common.dart'),
            contains('integration_test'));
      });
    });

    group('getLabelsForEnginePath', () {
      test('No label is applied to paths with no applicable label', () {
        expect(GithubWebhook.getLabelsForEnginePath('nonsense/path/foo.cc'), isEmpty);
      });

      test('platform-android applied for Android embedder', () {
        expect(GithubWebhook.getLabelsForEnginePath('shell/platform/android/RIsForRhubarbPie.java'),
            contains('platform-android'));
      });

      test('platform-ios and platform-macos applied for common Darwin code', () {
        expect(GithubWebhook.getLabelsForEnginePath('shell/platform/darwin/common/ThinkDifferent.mm'),
            containsAll(<String>['platform-ios', 'platform-macos']));
      });

      test('platform-ios and platform-ios applied for iOS embedder', () {
        expect(
            GithubWebhook.getLabelsForEnginePath('shell/platform/darwin/ios/BackButton.mm'), contains('platform-ios'));
      });

      test('platform-macos applied for macOS embedder', () {
        expect(GithubWebhook.getLabelsForEnginePath('shell/platform/darwin/macos/PhysicalEscapeKey.mm'),
            contains('platform-macos'));
      });

      test('platform-fuchsia applied for fuchsia embedder', () {
        expect(GithubWebhook.getLabelsForEnginePath('shell/platform/fuchsia/spell_checker.cc'),
            contains('platform-fuchsia'));
      });

      test('platform-linux applied for linux embedder', () {
        expect(GithubWebhook.getLabelsForEnginePath('shell/platform/linux/systemd_integration.cc'),
            contains('platform-linux'));
      });

      test('platform-windows applied for windows embedder', () {
        expect(
            GithubWebhook.getLabelsForEnginePath('shell/platform/windows/start_menu.cc'), contains('platform-windows'));
      });

      test('platform-web applied for web paths', () {
        expect(GithubWebhook.getLabelsForEnginePath('lib/web_ui/shadow_dom.dart'), contains('platform-web'));
        expect(GithubWebhook.getLabelsForEnginePath('web_sdk/'), contains('platform-web'));
      });
    });

    test('Framework labels PRs, comment if no tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework'],
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);
    });

    test('Framework labels PRs, comment if no tests including hit_test.dart file', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework', 'f: gestures'],
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);
    });

    test('Framework labels PRs, no dart files', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.md',
        ),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework'],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        any,
      ));
    });

    test('Framework labels PRs, no comment if tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
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
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework labels dart fix PRs, no comment if tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/test_fixes/material.dart',
          PullRequestFile()..filename = 'packages/flutter/test_fixes/material.expect',
        ]),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['team', 'tech-debt', 'framework', 'f: material design'],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework labels bot PR, no comment', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName, login: 'fluttergithubbot');
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter_tools/blah.dart',
          PullRequestFile()..filename = 'packages/flutter_driver/blah.dart',
        ]),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['tool', 'framework', 'a: tests', 'team', 'tech-debt', 'team: flakes'],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework labels deletion only PR, no test request', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework'],
      )).called(1);

      // The PR here is only deleting code, so no test comment.
      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('PR with additions and deletions is commented and labeled', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework'],
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);
    });

    test('Framework no comment if only dev bots or devicelab changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'dev/bots/test.dart',
          PullRequestFile()..filename = 'dev/devicelab/bin/tasks/analyzer_benchmark.dart',
          PullRequestFile()..filename = 'dev/devicelab/lib/tasks/plugin_tests.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework no comment if only AUTHORS changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'AUTHORS',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework no comment if only ci.yaml and cirrus.yml changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.ci.yaml',
          PullRequestFile()..filename = '.cirrus.yml',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework no comment if only CODEOWNERS changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'CODEOWNERS',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework no comment if only comments changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework labels PRs, no comment if tests (dev/bots/test.dart)', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
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

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Framework labels PRs, no comment if tests (dev/bots/analyze.dart)', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Engine labels PRs, comment and labels if no tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
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

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['platform-ios'],
      )).called(1);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['needs tests'],
      )).called(1);
    });

    test('Engine labels PRs, no code files', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        'main',
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'DEPS',
        ),
      );

      await tester.post(webhook);

      verifyNever(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        any,
      ));

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        any,
      ));
    });

    test('Engine labels PRs, no comment if Java tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'shell/platform/android/io/flutter/Blah.java',
          PullRequestFile()..filename = 'shell/platform/android/test/io/flutter/BlahTest.java',
        ]),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>[
          'platform-android',
        ],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Engine labels PRs, no comment if cc tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'fml/blah.cc',
          PullRequestFile()..filename = 'fml/blah_unittests.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        any,
      ));

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Engine labels PRs, no comment if cc becnhmarks', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'engine',
        repoFullName: 'flutter/engine',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'engine');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'fml/blah.cc',
          PullRequestFile()..filename = 'fml/blah_benchmarks.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        any,
      ));

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('No labels when only pubspec.yaml changes', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/flutter/pubspec.yaml',
          PullRequestFile()..filename = 'packages/flutter_tools/pubspec.yaml',
        ]),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['team'],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins comments and labels if no tests and no patch info', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
        ),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['needs tests'],
      )).called(1);
    });

    test('Plugins comments and labels for code change', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

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

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()
            ..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m'
            ..additionsCount = 2
            ..deletionsCount = 2
            ..changesCount = 4
            ..patch = patch,
        ),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['needs tests'],
      )).called(1);
    });

    test('Plugins comments and labels for code removal with comment addition', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      const String patch = '''
@@ -128,7 +128,7 @@
  int foo = 0;

  int bar = 0;
-  int baz = 0;
+  // int baz = 0;

  // More code here:

''';

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()
            ..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m'
            ..additionsCount = 1
            ..deletionsCount = 1
            ..changesCount = 2
            ..patch = patch,
        ),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['needs tests'],
      )).called(1);
    });

    test('Plugins does not comment for comment-only changes', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

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

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if Dart tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
          PullRequestFile()..filename = 'packages/foo/test/foo_test.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if Android unit tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_android/src/main/Foo.java',
          PullRequestFile()..filename = 'packages/foo/foo_android/src/test/FooTest.java',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if Android UI tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_android/src/main/Foo.java',
          PullRequestFile()..filename = 'packages/foo/foo_android/example/android/app/src/androidTest/FooTest.java',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if iOS/macOS unit tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
          PullRequestFile()..filename = 'packages/foo/foo_ios/example/ios/RunnerTests/FooTests.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if iOS/macOS UI tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_ios/ios/Classes/Foo.m',
          PullRequestFile()..filename = 'packages/foo/foo_ios/example/ios/RunnerUITests/FooTests.m',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if Windows tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_windows/windows/foo.cpp',
          PullRequestFile()..filename = 'packages/foo/foo_windows/windows/test/foo_test.cpp',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Plugins does not comment if Linux tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'plugins',
        repoFullName: 'flutter/plugins',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'plugins');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/foo_linux/linux/foo.cc',
          PullRequestFile()..filename = 'packages/foo/foo_linux/linux/test/foo_test.cc',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Packages comments and labels if no tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'packages',
        repoFullName: 'flutter/packages',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'packages');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      )).called(1);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['needs tests'],
      )).called(1);
    });

    test('Packages does not comment if Dart tests', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        repoName: 'packages',
        repoFullName: 'flutter/packages',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'packages');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = 'packages/foo/lib/foo.dart',
          PullRequestFile()..filename = 'packages/foo/test/foo_test.dart',
        ]),
      );

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Schedule tasks when pull request is closed and merged', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('closed', issueNumber, kDefaultBranchName, merged: true);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.post(webhook);
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test('Does not test pest draft pull requests.', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        isDraft: true,
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer((_) => Stream<PullRequestFile>.value(
            PullRequestFile()..filename = 'some_change.dart',
          ));

      await tester.post(webhook);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Will not spawn comments if they have already been made.', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(slug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = config.missingTestsPullRequestMessageValue,
        ),
      );

      await tester.post(webhook);

      verify(issuesService.addLabelsToIssue(
        slug,
        issueNumber,
        <String>['framework'],
      )).called(1);

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        argThat(contains(config.missingTestsPullRequestMessageValue)),
      ));
    });

    test('Skips labeling or commenting on autorolls', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = generatePullRequestEvent(
        'opened',
        issueNumber,
        kDefaultBranchName,
        login: 'engine-flutter-autoroll',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

      await tester.post(webhook);

      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      verifyNever(issuesService.createComment(
        slug,
        issueNumber,
        any,
      ));
    });

    test('Comments on PR but does not schedule builds for unmergeable PRs', () async {
      const int issueNumber = 12345;
      request.body = generatePullRequestEvent(
        'synchronize',
        issueNumber,
        kDefaultBranchName,
        includeCqLabel: true,
        // This PR is unmergeable (probably merge conflict)
        isMergeable: false,
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      request.headers.set('X-GitHub-Event', 'pull_request');
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      await tester.post(webhook);
      verify(issuesService.createComment(slug, issueNumber, config.mergeConflictPullRequestMessage));
    });

    test('When synchronized, cancels existing builds and schedules new ones', () async {
      const int issueNumber = 12345;
      bool batchRequestCalled = false;
      Future<BatchResponse> _getBatchResponse() async {
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

      fakeBuildBucketClient.batchResponse = _getBatchResponse();

      request.body = generatePullRequestEvent('synchronize', issueNumber, kDefaultBranchName, includeCqLabel: true);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      request.headers.set('X-GitHub-Event', 'pull_request');
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();
      when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

      await tester.post(webhook);
      expect(batchRequestCalled, isTrue);
    });

    group('BuildBucket', () {
      const int issueNumber = 123;

      setUp(() async {
        request.headers.set('X-GitHub-Event', 'pull_request');
      });

      Future<void> _testActions(String action) async {
        when(issuesService.listLabelsByIssue(any, issueNumber)).thenAnswer((_) {
          return Stream<IssueLabel>.fromIterable(<IssueLabel>[
            IssueLabel()..name = 'Random Label',
          ]);
        });

        fakeBuildBucketClient.batchResponse = Future<BatchResponse>.value(
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

        request.body = generatePullRequestEvent(action, 1, 'master');

        final Uint8List body = utf8.encode(request.body!) as Uint8List;
        final Uint8List key = utf8.encode(keyString) as Uint8List;
        final String hmac = getHmac(body, key);
        request.headers.set('X-Hub-Signature', 'sha1=$hmac');

        await tester.post(webhook);
      }

      test('Edited Action works properly', () async {
        await _testActions('edited');
      });

      test('Opened Action works properly', () async {
        await _testActions('opened');
      });

      test('Ready_for_review Action works properly', () async {
        await _testActions('ready_for_review');
      });

      test('Reopened Action works properly', () async {
        await _testActions('reopened');
      });

      test('Labeled Action works properly', () async {
        await _testActions('labeled');
      });

      test('Synchronize Action works properly', () async {
        await _testActions('synchronize');
      });

      test('Comments on PR but does not schedule builds for unmergeable PRs', () async {
        when(issuesService.listCommentsByIssue(any, any)).thenAnswer((_) => Stream<IssueComment>.value(IssueComment()));
        request.body = generatePullRequestEvent(
          'synchronize',
          issueNumber,
          kDefaultBranchName,
          includeCqLabel: true,
          // This PR is unmergeable (probably merge conflict)
          isMergeable: false,
        );
        final Uint8List body = utf8.encode(request.body!) as Uint8List;
        final Uint8List key = utf8.encode(keyString) as Uint8List;
        final String hmac = getHmac(body, key);
        request.headers.set('X-Hub-Signature', 'sha1=$hmac');

        await tester.post(webhook);
        verify(issuesService.createComment(Config.flutterSlug, issueNumber, config.mergeConflictPullRequestMessage));
      });

      test('When synchronized, cancels existing builds and schedules new ones', () async {
        fakeBuildBucketClient.batchResponse = Future<BatchResponse>.value(
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

        request.body = generatePullRequestEvent('synchronize', issueNumber, kDefaultBranchName, includeCqLabel: true);
        final Uint8List body = utf8.encode(request.body!) as Uint8List;
        final Uint8List key = utf8.encode(keyString) as Uint8List;
        final String hmac = getHmac(body, key);
        request.headers.set('X-Hub-Signature', 'sha1=$hmac');
        final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();
        when(gitHubClient.repositories).thenReturn(mockRepositoriesService);

        await tester.post(webhook);
      });
    });
  });

  group('github webhook create branch event', () {
    test('process create branch event', () async {
      request.headers.set('X-GitHub-Event', 'create');
      request.body = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      await tester.post(webhook);
    });
  });

  group('github webhook check_run event', () {
    setUp(() {
      request.headers.set('X-GitHub-Event', 'check_run');
    });

    test('processes check run event', () async {
      request.body = generateCheckRunEvent();
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      await tester.post(webhook);
    });

    test('processes completed check run event', () async {
      request.body = generateCheckRunEvent(
        action: 'completed',
        numberOfPullRequests: 0,
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      await tester.post(webhook);
    });
  });
}
