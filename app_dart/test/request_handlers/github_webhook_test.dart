// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

import 'package:crypto/crypto.dart';
import 'package:github/github.dart';
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

void main() {
  group('githubWebhookPullRequest', () {
    late GithubWebhook webhook;
    late FakeBuildBucketClient fakeBuildBucketClient;
    late FakeDatastoreDB db;
    FakeGithubService githubService;
    late FakeHttpRequest request;
    late FakeConfig config;
    late MockGitHub gitHubClient;
    late MockIssuesService issuesService;
    late MockPullRequestsService pullRequestsService;
    FakeScheduler scheduler;
    late RequestHandlerTester tester;
    const String serviceAccountEmail = 'test@test';
    ServiceAccountInfo? serviceAccountInfo;
    MockGithubChecksService mockGithubChecksService;
    MockGithubChecksUtil mockGithubChecksUtil;

    const String keyString = 'not_a_real_key';

    String getHmac(Uint8List list, Uint8List key) {
      final Hmac hmac = Hmac(sha1, key);
      return hmac.convert(list).toString();
    }

    setUp(() async {
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
      when(pullRequestsService.listFiles(config.flutterSlug, any))
          .thenAnswer((_) => const Stream<PullRequestFile>.empty());
      when(pullRequestsService.edit(any, any,
              title: anyNamed('title'), state: anyNamed('state'), base: anyNamed('base')))
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
      when(mockGithubChecksUtil.createCheckRun(any, any, any, output: anyNamed('output'))).thenAnswer((_) async {
        return CheckRun.fromJson(const <String, dynamic>{
          'id': 1,
          'started_at': '2020-05-10T02:49:31Z',
          'check_suite': <String, dynamic>{'id': 2}
        });
      });

      webhook = GithubWebhook(
        config,
        githubChecksService: mockGithubChecksService,
        scheduler: scheduler,
      );

      config.wrongHeadBranchPullRequestMessageValue = 'wrongHeadBranchPullRequestMessage';
      config.wrongBaseBranchPullRequestMessageValue = 'wrongBaseBranchPullRequestMessage';
      config.releaseBranchPullRequestMessageValue = 'releaseBranchPullRequestMessage';
      config.missingTestsPullRequestMessageValue = 'missingTestPullRequestMessage';
      config.githubOAuthTokenValue = 'githubOAuthKey';
      config.webhookKeyValue = keyString;
      config.githubClient = gitHubClient;
      config.deviceLabServiceAccountValue = const ServiceAccountInfo(email: serviceAccountEmail);
    });

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
      request.body = jsonTemplate(
        'opened',
        issueNumber,
        kDefaultBranchName,
        headRef: 'dev',
      );
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');

      when(pullRequestsService.listFiles(config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.value(
          PullRequestFile()..filename = 'packages/flutter/blah.dart',
        ),
      );

      when(issuesService.listCommentsByIssue(config.flutterSlug, issueNumber)).thenAnswer(
        (_) => Stream<IssueComment>.value(
          IssueComment()..body = 'some other comment',
        ),
      );

      await tester.post(webhook);

      verify(pullRequestsService.edit(
        config.flutterSlug,
        issueNumber,
        state: 'closed',
      )).called(1);

      verify(issuesService.createComment(
        config.flutterSlug,
        issueNumber,
        argThat(contains(config.wrongHeadBranchPullRequestMessageValue)),
      )).called(1);
    });

    test('Acts on opened against dev', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = jsonTemplate('opened', issueNumber, 'dev');
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
        argThat(contains(config.wrongBaseBranchPullRequestMessage)),
      )).called(1);
    });

    test('Does nothing against cherry pick PR', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = jsonTemplate(
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

      test('integration_test label applied', () {
        expect(
            GithubWebhook.getLabelsForFrameworkPath(
                'dev/integration_tests/web_e2e_tests/test_driver/text_editing_integration.dart'),
            contains('integration_test'));
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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

    test('Framework labels PRs, no dart files', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName, login: 'fluttergithubbot');
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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

    test('Framework no comment if only ci.yaml changed', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
      final Uint8List body = utf8.encode(request.body!) as Uint8List;
      final Uint8List key = utf8.encode(keyString) as Uint8List;
      final String hmac = getHmac(body, key);
      request.headers.set('X-Hub-Signature', 'sha1=$hmac');
      final RepositorySlug slug = RepositorySlug('flutter', 'flutter');

      when(pullRequestsService.listFiles(slug, issueNumber)).thenAnswer(
        (_) => Stream<PullRequestFile>.fromIterable(<PullRequestFile>[
          PullRequestFile()..filename = '.ci.yaml',
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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

    test('Schedule tasks when pull request is closed and merged', () async {
      const int issueNumber = 123;
      request.headers.set('X-GitHub-Event', 'pull_request');
      request.body = jsonTemplate('closed', issueNumber, kDefaultBranchName, merged: true);
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate('opened', issueNumber, kDefaultBranchName);
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
      request.body = jsonTemplate(
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
      request.body = jsonTemplate(
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

      request.body = jsonTemplate('synchronize', issueNumber, kDefaultBranchName, includeCqLabel: true);
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

        request.body = jsonTemplate(action, 1, 'master');

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
        request.body = jsonTemplate(
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
        verify(issuesService.createComment(config.flutterSlug, issueNumber, config.mergeConflictPullRequestMessage));
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

        request.body = jsonTemplate('synchronize', issueNumber, kDefaultBranchName, includeCqLabel: true);
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
}

String jsonTemplate(String action, int number, String baseRef,
        {String login = 'flutter',
        String headRef = 'wait_for_reassemble',
        bool includeCqLabel = false,
        bool isDraft = false,
        bool merged = false,
        String repoFullName = 'flutter/flutter',
        String repoName = 'flutter',
        bool isMergeable = true}) =>
    '''{
  "action": "$action",
  "number": $number,
  "pull_request": {
    "url": "https://api.github.com/repos/$repoFullName/pulls/$number",
    "id": 294034,
    "node_id": "MDExOlB1bGxSZXF1ZXN0Mjk0MDMzODQx",
    "html_url": "https://github.com/$repoFullName/pull/$number",
    "diff_url": "https://github.com/$repoFullName/pull/$number.diff",
    "patch_url": "https://github.com/$repoFullName/pull/$number.patch",
    "issue_url": "https://api.github.com/repos/$repoFullName/issues/$number",
    "number": $number,
    "state": "open",
    "locked": false,
    "title": "Defer reassemble until reload is finished",
    "user": {
      "login": "$login",
      "id": 862741,
      "node_id": "MDQ6VXNlcjg2MjA3NDE=",
      "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "draft" : "$isDraft",
    "body": "The body",
    "created_at": "2019-07-03T07:14:35Z",
    "updated_at": "2019-07-03T16:34:53Z",
    "closed_at": null,
    "merged_at": "2019-07-03T16:34:53Z",
    "merge_commit_sha": "d22ab7ced21d3b2a5be00cf576d383eb5ffddb8a",
    "assignee": null,
    "assignees": [],
    "requested_reviewers": [],
    "requested_teams": [],
    "labels": [
      {
        "id": 487496476,
        "node_id": "MDU6TGFiZWw0ODc0OTY0NzY=",
        "url": "https://api.github.com/repos/$repoFullName/labels/cla:%20yes",
        "name": "cla: yes",
        "color": "ffffff",
        "default": false
      },
      {
        "id": 284437560,
        "node_id": "MDU6TGFiZWwyODQ0Mzc1NjA=",
        "url": "https://api.github.com/repos/$repoFullName/labels/framework",
        "name": "framework",
        "color": "207de5",
        "default": false
      },
      ${includeCqLabel ? '''
      {
        "id": 283480100,
        "node_id": "MDU6TGFiZWwyODM0ODAxMDA=",
        "url": "https://api.github.com/repos/$repoFullName/labels/tool",
        "color": "5319e7",
        "default": false
      },''' : ''}
      {
        "id": 283480100,
        "node_id": "MDU6TGFiZWwyODM0ODAxMDA=",
        "url": "https://api.github.com/repos/$repoFullName/labels/tool",
        "name": "tool",
        "color": "5319e7",
        "default": false
      }
    ],
    "milestone": null,
    "commits_url": "https://api.github.com/repos/$repoFullName/pulls/$number/commits",
    "review_comments_url": "https://api.github.com/repos/$repoFullName/pulls/$number/comments",
    "review_comment_url": "https://api.github.com/repos/$repoFullName/pulls/comments{/number}",
    "comments_url": "https://api.github.com/repos/$repoFullName/issues/$number/comments",
    "statuses_url": "https://api.github.com/repos/$repoFullName/statuses/be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
    "head": {
      "label": "$login:$headRef",
      "ref": "$headRef",
      "sha": "be6ff099a4ee56e152a5fa2f37edd10f79d1269a",
      "user": {
        "login": "$login",
        "id": 8620741,
        "node_id": "MDQ6VXNlcjg2MjA3NDE=",
        "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "User",
        "site_admin": false
      },
      "repo": {
        "id": 131232406,
        "node_id": "MDEwOlJlcG9zaXRvcnkxMzEyMzI0MDY=",
        "name": "$repoName",
        "full_name": "$repoFullName",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 8620741,
          "node_id": "MDQ6VXNlcjg2MjA3NDE=",
          "avatar_url": "https://avatars3.githubusercontent.com/u/8620741?v=4",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "User",
          "site_admin": false
        },
        "html_url": "https://github.com/$repoFullName",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": true,
        "url": "https://api.github.com/repos/$repoFullName",
        "forks_url": "https://api.github.com/repos/$repoFullName/forks",
        "keys_url": "https://api.github.com/repos/$repoFullName/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/$repoFullName/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/$repoFullName/teams",
        "hooks_url": "https://api.github.com/repos/$repoFullName/hooks",
        "issue_events_url": "https://api.github.com/repos/$repoFullName/issues/events{/number}",
        "events_url": "https://api.github.com/repos/$repoFullName/events",
        "assignees_url": "https://api.github.com/repos/$repoFullName/assignees{/user}",
        "branches_url": "https://api.github.com/repos/$repoFullName/branches{/branch}",
        "tags_url": "https://api.github.com/repos/$repoFullName/tags",
        "blobs_url": "https://api.github.com/repos/$repoFullName/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/$repoFullName/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/$repoFullName/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/$repoFullName/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/$repoFullName/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/$repoFullName/languages",
        "stargazers_url": "https://api.github.com/repos/$repoFullName/stargazers",
        "contributors_url": "https://api.github.com/repos/$repoFullName/contributors",
        "subscribers_url": "https://api.github.com/repos/$repoFullName/subscribers",
        "subscription_url": "https://api.github.com/repos/$repoFullName/subscription",
        "commits_url": "https://api.github.com/repos/$repoFullName/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/$repoFullName/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/$repoFullName/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/$repoFullName/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/$repoFullName/contents/{+path}",
        "compare_url": "https://api.github.com/repos/$repoFullName/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/$repoFullName/merges",
        "archive_url": "https://api.github.com/repos/$repoFullName/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/$repoFullName/downloads",
        "issues_url": "https://api.github.com/repos/$repoFullName/issues{/number}",
        "pulls_url": "https://api.github.com/repos/$repoFullName/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/$repoFullName/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/$repoFullName/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/$repoFullName/labels{/name}",
        "releases_url": "https://api.github.com/repos/$repoFullName/releases{/id}",
        "deployments_url": "https://api.github.com/repos/$repoFullName/deployments",
        "created_at": "2018-04-27T02:03:08Z",
        "updated_at": "2019-06-27T06:56:59Z",
        "pushed_at": "2019-07-03T19:40:11Z",
        "git_url": "git://github.com/$repoFullName.git",
        "ssh_url": "git@github.com:$repoFullName.git",
        "clone_url": "https://github.com/$repoFullName.git",
        "svn_url": "https://github.com/$repoFullName",
        "homepage": "https://flutter.io",
        "size": 94508,
        "stargazers_count": 1,
        "watchers_count": 1,
        "language": "Dart",
        "has_issues": false,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 0,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 0,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 0,
        "open_issues": 0,
        "watchers": 1,
        "default_branch": "$kDefaultBranchName"
      }
    },
    "base": {
      "label": "flutter:$baseRef",
      "ref": "$baseRef",
      "sha": "4cd12fc8b7d4cc2d8609182e1c4dea5cddc86890",
      "user": {
        "login": "flutter",
        "id": 14101776,
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
        "avatar_url": "https://avatars3.githubblahblahblah",
        "gravatar_id": "",
        "url": "https://api.github.com/users/flutter",
        "html_url": "https://github.com/flutter",
        "followers_url": "https://api.github.com/users/flutter/followers",
        "following_url": "https://api.github.com/users/flutter/following{/other_user}",
        "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
        "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
        "organizations_url": "https://api.github.com/users/flutter/orgs",
        "repos_url": "https://api.github.com/users/flutter/repos",
        "events_url": "https://api.github.com/users/flutter/events{/privacy}",
        "received_events_url": "https://api.github.com/users/flutter/received_events",
        "type": "Organization",
        "site_admin": false
      },
      "repo": {
        "id": 31792824,
        "node_id": "MDEwOlJlcG9zaXRvcnkzMTc5MjgyNA==",
        "name": "$repoName",
        "full_name": "$repoFullName",
        "private": false,
        "owner": {
          "login": "flutter",
          "id": 14101776,
          "node_id": "MDEyOk9yZ2FuaXphdGlvbjE0MTAxNzc2",
          "avatar_url": "https://avatars3.githubblahblahblah",
          "gravatar_id": "",
          "url": "https://api.github.com/users/flutter",
          "html_url": "https://github.com/flutter",
          "followers_url": "https://api.github.com/users/flutter/followers",
          "following_url": "https://api.github.com/users/flutter/following{/other_user}",
          "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
          "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
          "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
          "organizations_url": "https://api.github.com/users/flutter/orgs",
          "repos_url": "https://api.github.com/users/flutter/repos",
          "events_url": "https://api.github.com/users/flutter/events{/privacy}",
          "received_events_url": "https://api.github.com/users/flutter/received_events",
          "type": "Organization",
          "site_admin": false
        },
        "html_url": "https://github.com/$repoFullName",
        "description": "Flutter makes it easy and fast to build beautiful mobile apps.",
        "fork": false,
        "url": "https://api.github.com/repos/$repoFullName",
        "forks_url": "https://api.github.com/repos/$repoFullName/forks",
        "keys_url": "https://api.github.com/repos/$repoFullName/keys{/key_id}",
        "collaborators_url": "https://api.github.com/repos/$repoFullName/collaborators{/collaborator}",
        "teams_url": "https://api.github.com/repos/$repoFullName/teams",
        "hooks_url": "https://api.github.com/repos/$repoFullName/hooks",
        "issue_events_url": "https://api.github.com/repos/$repoFullName/issues/events{/number}",
        "events_url": "https://api.github.com/repos/$repoFullName/events",
        "assignees_url": "https://api.github.com/repos/$repoFullName/assignees{/user}",
        "branches_url": "https://api.github.com/repos/$repoFullName/branches{/branch}",
        "tags_url": "https://api.github.com/repos/$repoFullName/tags",
        "blobs_url": "https://api.github.com/repos/$repoFullName/git/blobs{/sha}",
        "git_tags_url": "https://api.github.com/repos/$repoFullName/git/tags{/sha}",
        "git_refs_url": "https://api.github.com/repos/$repoFullName/git/refs{/sha}",
        "trees_url": "https://api.github.com/repos/$repoFullName/git/trees{/sha}",
        "statuses_url": "https://api.github.com/repos/$repoFullName/statuses/{sha}",
        "languages_url": "https://api.github.com/repos/$repoFullName/languages",
        "stargazers_url": "https://api.github.com/repos/$repoFullName/stargazers",
        "contributors_url": "https://api.github.com/repos/$repoFullName/contributors",
        "subscribers_url": "https://api.github.com/repos/$repoFullName/subscribers",
        "subscription_url": "https://api.github.com/repos/$repoFullName/subscription",
        "commits_url": "https://api.github.com/repos/$repoFullName/commits{/sha}",
        "git_commits_url": "https://api.github.com/repos/$repoFullName/git/commits{/sha}",
        "comments_url": "https://api.github.com/repos/$repoFullName/comments{/number}",
        "issue_comment_url": "https://api.github.com/repos/$repoFullName/issues/comments{/number}",
        "contents_url": "https://api.github.com/repos/$repoFullName/contents/{+path}",
        "compare_url": "https://api.github.com/repos/$repoFullName/compare/{base}...{head}",
        "merges_url": "https://api.github.com/repos/$repoFullName/merges",
        "archive_url": "https://api.github.com/repos/$repoFullName/{archive_format}{/ref}",
        "downloads_url": "https://api.github.com/repos/$repoFullName/downloads",
        "issues_url": "https://api.github.com/repos/$repoFullName/issues{/number}",
        "pulls_url": "https://api.github.com/repos/$repoFullName/pulls{/number}",
        "milestones_url": "https://api.github.com/repos/$repoFullName/milestones{/number}",
        "notifications_url": "https://api.github.com/repos/$repoFullName/notifications{?since,all,participating}",
        "labels_url": "https://api.github.com/repos/$repoFullName/labels{/name}",
        "releases_url": "https://api.github.com/repos/$repoFullName/releases{/id}",
        "deployments_url": "https://api.github.com/repos/$repoFullName/deployments",
        "created_at": "2015-03-06T22:54:58Z",
        "updated_at": "2019-07-04T02:08:44Z",
        "pushed_at": "2019-07-04T02:03:04Z",
        "git_url": "git://github.com/$repoFullName.git",
        "ssh_url": "git@github.com:$repoFullName.git",
        "clone_url": "https://github.com/$repoFullName.git",
        "svn_url": "https://github.com/$repoFullName",
        "homepage": "https://flutter.dev",
        "size": 65507,
        "stargazers_count": 68944,
        "watchers_count": 68944,
        "language": "Dart",
        "has_issues": true,
        "has_projects": true,
        "has_downloads": true,
        "has_wiki": true,
        "has_pages": false,
        "forks_count": 7987,
        "mirror_url": null,
        "archived": false,
        "disabled": false,
        "open_issues_count": 6536,
        "license": {
          "key": "other",
          "name": "Other",
          "spdx_id": "NOASSERTION",
          "url": null,
          "node_id": "MDc6TGljZW5zZTA="
        },
        "forks": 7987,
        "open_issues": 6536,
        "watchers": 68944,
        "default_branch": "$kDefaultBranchName"
      }
    },
    "_links": {
      "self": {
        "href": "https://api.github.com/repos/$repoFullName/pulls/$number"
      },
      "html": {
        "href": "https://github.com/$repoFullName/pull/$number"
      },
      "issue": {
        "href": "https://api.github.com/repos/$repoFullName/issues/$number"
      },
      "comments": {
        "href": "https://api.github.com/repos/$repoFullName/issues/$number/comments"
      },
      "review_comments": {
        "href": "https://api.github.com/repos/$repoFullName/pulls/$number/comments"
      },
      "review_comment": {
        "href": "https://api.github.com/repos/$repoFullName/pulls/comments{/number}"
      },
      "commits": {
        "href": "https://api.github.com/repos/$repoFullName/pulls/$number/commits"
      },
      "statuses": {
        "href": "https://api.github.com/repos/$repoFullName/statuses/deadbeef"
      }
    },
    "author_association": "MEMBER",
    "draft" : $isDraft,
    "merged": $merged,
    "mergeable": $isMergeable,
    "rebaseable": true,
    "mergeable_state": "draft",
    "merged_by": null,
    "comments": 1,
    "review_comments": 0,
    "maintainer_can_modify": true,
    "commits": 5,
    "additions": 55,
    "deletions": 36,
    "changed_files": 5
  },
  "repository": {
    "id": 1868532,
    "node_id": "MDEwOlJlcG9zaXRvcnkxODY4NTMwMDI=",
    "name": "$repoName",
    "full_name": "$repoFullName",
    "private": false,
    "owner": {
      "login": "flutter",
      "id": 21031067,
      "node_id": "MDQ6VXNlcjIxMDMxMDY3",
      "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
      "gravatar_id": "",
      "url": "https://api.github.com/users/flutter",
      "html_url": "https://github.com/flutter",
      "followers_url": "https://api.github.com/users/flutter/followers",
      "following_url": "https://api.github.com/users/flutter/following{/other_user}",
      "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
      "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
      "organizations_url": "https://api.github.com/users/flutter/orgs",
      "repos_url": "https://api.github.com/users/flutter/repos",
      "events_url": "https://api.github.com/users/flutter/events{/privacy}",
      "received_events_url": "https://api.github.com/users/flutter/received_events",
      "type": "User",
      "site_admin": false
    },
    "html_url": "https://github.com/$repoFullName",
    "description": null,
    "fork": false,
    "url": "https://api.github.com/repos/$repoFullName",
    "forks_url": "https://api.github.com/repos/$repoFullName/forks",
    "keys_url": "https://api.github.com/repos/$repoFullName/keys{/key_id}",
    "collaborators_url": "https://api.github.com/repos/$repoFullName/collaborators{/collaborator}",
    "teams_url": "https://api.github.com/repos/$repoFullName/teams",
    "hooks_url": "https://api.github.com/repos/$repoFullName/hooks",
    "issue_events_url": "https://api.github.com/repos/$repoFullName/issues/events{/number}",
    "events_url": "https://api.github.com/repos/$repoFullName/events",
    "assignees_url": "https://api.github.com/repos/$repoFullName/assignees{/user}",
    "branches_url": "https://api.github.com/repos/$repoFullName/branches{/branch}",
    "tags_url": "https://api.github.com/repos/$repoFullName/tags",
    "blobs_url": "https://api.github.com/repos/$repoFullName/git/blobs{/sha}",
    "git_tags_url": "https://api.github.com/repos/$repoFullName/git/tags{/sha}",
    "git_refs_url": "https://api.github.com/repos/$repoFullName/git/refs{/sha}",
    "trees_url": "https://api.github.com/repos/$repoFullName/git/trees{/sha}",
    "statuses_url": "https://api.github.com/repos/$repoFullName/statuses/{sha}",
    "languages_url": "https://api.github.com/repos/$repoFullName/languages",
    "stargazers_url": "https://api.github.com/repos/$repoFullName/stargazers",
    "contributors_url": "https://api.github.com/repos/$repoFullName/contributors",
    "subscribers_url": "https://api.github.com/repos/$repoFullName/subscribers",
    "subscription_url": "https://api.github.com/repos/$repoFullName/subscription",
    "commits_url": "https://api.github.com/repos/$repoFullName/commits{/sha}",
    "git_commits_url": "https://api.github.com/repos/$repoFullName/git/commits{/sha}",
    "comments_url": "https://api.github.com/repos/$repoFullName/comments{/number}",
    "issue_comment_url": "https://api.github.com/repos/$repoFullName/issues/comments{/number}",
    "contents_url": "https://api.github.com/repos/$repoFullName/contents/{+path}",
    "compare_url": "https://api.github.com/repos/$repoFullName/compare/{base}...{head}",
    "merges_url": "https://api.github.com/repos/$repoFullName/merges",
    "archive_url": "https://api.github.com/repos/$repoFullName/{archive_format}{/ref}",
    "downloads_url": "https://api.github.com/repos/$repoFullName/downloads",
    "issues_url": "https://api.github.com/repos/$repoFullName/issues{/number}",
    "pulls_url": "https://api.github.com/repos/$repoFullName/pulls{/number}",
    "milestones_url": "https://api.github.com/repos/$repoFullName/milestones{/number}",
    "notifications_url": "https://api.github.com/repos/$repoFullName/notifications{?since,all,participating}",
    "labels_url": "https://api.github.com/repos/$repoFullName/labels{/name}",
    "releases_url": "https://api.github.com/repos/$repoFullName/releases{/id}",
    "deployments_url": "https://api.github.com/repos/$repoFullName/deployments",
    "created_at": "2019-05-15T15:19:25Z",
    "updated_at": "2019-05-15T15:19:27Z",
    "pushed_at": "2019-05-15T15:20:32Z",
    "git_url": "git://github.com/$repoFullName.git",
    "ssh_url": "git@github.com:$repoFullName.git",
    "clone_url": "https://github.com/$repoFullName.git",
    "svn_url": "https://github.com/$repoFullName",
    "homepage": null,
    "size": 0,
    "stargazers_count": 0,
    "watchers_count": 0,
    "language": null,
    "has_issues": true,
    "has_projects": true,
    "has_downloads": true,
    "has_wiki": true,
    "has_pages": true,
    "forks_count": 0,
    "mirror_url": null,
    "archived": false,
    "disabled": false,
    "open_issues_count": 2,
    "license": null,
    "forks": 0,
    "open_issues": 2,
    "watchers": 0,
    "default_branch": "$kDefaultBranchName"
  },
  "sender": {
    "login": "$login",
    "id": 21031067,
    "node_id": "MDQ6VXNlcjIxMDMxMDY3",
    "avatar_url": "https://avatars1.githubusercontent.com/u/21031067?v=4",
    "gravatar_id": "",
    "url": "https://api.github.com/users/flutter",
    "html_url": "https://github.com/flutter",
    "followers_url": "https://api.github.com/users/flutter/followers",
    "following_url": "https://api.github.com/users/flutter/following{/other_user}",
    "gists_url": "https://api.github.com/users/flutter/gists{/gist_id}",
    "starred_url": "https://api.github.com/users/flutter/starred{/owner}{/repo}",
    "subscriptions_url": "https://api.github.com/users/flutter/subscriptions",
    "organizations_url": "https://api.github.com/users/flutter/orgs",
    "repos_url": "https://api.github.com/users/flutter/repos",
    "events_url": "https://api.github.com/users/flutter/events{/privacy}",
    "received_events_url": "https://api.github.com/users/flutter/received_events",
    "type": "User",
    "site_admin": false
  }
}''';
