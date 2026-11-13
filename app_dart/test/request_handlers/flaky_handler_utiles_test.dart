// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/request_handlers/test_ownership.dart';
import 'package:cocoon_service/src/service/big_query.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart' hide Team;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('Gets test ownership', () {
    String testOwnersContent;

    group('framework host only', () {
      test(
        'returns correct owner when no mulitple tests share the same file',
        () async {
          final target = pb.Target(name: 'Linux abc');
          testOwnersContent = '''
## Host only framework tests
# Linux abc
abc_test.sh @ghi @flutter/engine
## Firebase tests
''';
          final ownership = getTestOwnership(
            target,
            BuilderType.frameworkHostOnly,
            testOwnersContent,
          );
          expect(ownership.owner, 'ghi');
          expect(ownership.team, Team.engine);
        },
      );

      test(
        'returns correct owner when mulitple tests share the same file',
        () async {
          final target1 = pb.Target(name: 'Linux abc');
          final target2 = pb.Target(name: 'Linux def');
          testOwnersContent = '''
## Host only framework tests
# Linux abc
# Linu def
abc_test.sh @ghi @flutter/framework
## Firebase tests
''';
          final ownership1 = getTestOwnership(
            target1,
            BuilderType.frameworkHostOnly,
            testOwnersContent,
          );
          expect(ownership1.owner, 'ghi');
          expect(ownership1.team, Team.framework);
          final ownership2 = getTestOwnership(
            target2,
            BuilderType.frameworkHostOnly,
            testOwnersContent,
          );
          expect(ownership2.owner, 'ghi');
          expect(ownership2.team, Team.framework);
        },
      );
    });

    group('firebaselab only', () {
      test('returns correct owner', () async {
        final target = pb.Target(name: 'Linux firebase_abc');
        testOwnersContent = '''
## Firebase tests
# Linux abc
/test/abc @def @flutter/tool
## Shards tests
''';
        final ownership = getTestOwnership(
          target,
          BuilderType.firebaselab,
          testOwnersContent,
        );
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.tool);
      });
    });

    group('devicelab tests', () {
      test('returns correct owner', () async {
        final target = pb.Target(name: 'abc', properties: {'task_name': 'abc'});
        testOwnersContent = '''
## Linux Android DeviceLab tests
/dev/devicelab/bin/tasks/abc.dart @def @flutter/web

## Host only framework tests
''';
        final ownership = getTestOwnership(
          target,
          BuilderType.devicelab,
          testOwnersContent,
        );
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.web);
      });
    });

    group('shards tests', () {
      test('returns correct owner', () async {
        final target = pb.Target(name: 'Linux abc');
        testOwnersContent = '''
## Shards tests
#
# abc @def @flutter/engine
''';
        final ownership = getTestOwnership(
          target,
          BuilderType.shard,
          testOwnersContent,
        );
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.engine);
      });
    });

    group('getExistingPRs', () {
      test(
        'throws more detailed logs for bad prs with inappropriate body meta tag',
        () async {
          final mockGitHubClient = MockGitHub();
          final mockPullRequestsService = MockPullRequestsService();
          const expectedHtml = 'https://someurl';
          // when gets existing marks flaky prs.
          when(mockPullRequestsService.list(captureAny)).thenAnswer((
            Invocation invocation,
          ) {
            return Stream<PullRequest>.value(
              PullRequest(
                htmlUrl: expectedHtml,
                body: '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name"
}
-->''',
              ),
            );
          });
          when(
            mockGitHubClient.pullRequests,
          ).thenReturn(mockPullRequestsService);
          final config = FakeConfig(
            githubService: GithubService(mockGitHubClient),
          );
          expect(
            () => getExistingPRs(config.githubService!, Config.flutterSlug),
            throwsA(
              predicate<String>((String e) {
                return e.contains('Unable to parse body of $expectedHtml');
              }),
            ),
          );
        },
      );

      test('handles PRs with empty body message', () async {
        final mockGitHubClient = MockGitHub();
        final mockPullRequestsService = MockPullRequestsService();
        const expectedHtml = 'https://someurl';
        when(mockPullRequestsService.list(captureAny)).thenAnswer((
          Invocation invocation,
        ) {
          return Stream<PullRequest>.value(PullRequest(htmlUrl: expectedHtml));
        });
        when(mockGitHubClient.pullRequests).thenReturn(mockPullRequestsService);
        final config = FakeConfig(
          githubService: GithubService(mockGitHubClient),
        );
        expect(
          await getExistingPRs(config.githubService!, Config.flutterSlug),
          <String?, PullRequest>{},
        );
      });
    });
  });
  group('Gets team label', () {
    test('returns correct label when matched', () async {
      expect(getTeamLabelFromTeam(Team.framework), kFrameworkLabel);
      expect(getTeamLabelFromTeam(Team.engine), kEngineLabel);
      expect(getTeamLabelFromTeam(Team.tool), kToolLabel);
      expect(getTeamLabelFromTeam(Team.web), kWebLabel);
      expect(getTeamLabelFromTeam(Team.infra), kInfraLabel);
      expect(getTeamLabelFromTeam(Team.android), kAndroidLabel);
      expect(getTeamLabelFromTeam(Team.ios), kIosLabel);
      expect(getTeamLabelFromTeam(Team.linux), kLinuxLabel);
      expect(getTeamLabelFromTeam(Team.macos), kMacosLabel);
      expect(getTeamLabelFromTeam(Team.windows), kWindowsLabel);
      expect(getTeamLabelFromTeam(Team.plugins), kEcosystemLabel);
    });

    test('returns null when not matched', () async {
      expect(getTeamLabelFromTeam(Team.unknown), null);
    });

    test('teamFromString maps all supported teams', () {
      expect(teamFromString('flutter/framework'), Team.framework);
      expect(teamFromString('flutter/engine'), Team.engine);
      expect(teamFromString('flutter/tool'), Team.tool);
      expect(teamFromString('flutter/web'), Team.web);
      expect(teamFromString('flutter/infra'), Team.infra);
      expect(teamFromString('flutter/releases'), Team.infra);
      expect(teamFromString('flutter/android'), Team.android);
      expect(teamFromString('flutter/ios'), Team.ios);
      expect(teamFromString('flutter/linux'), Team.linux);
      expect(teamFromString('flutter/macos'), Team.macos);
      expect(teamFromString('flutter/windows'), Team.windows);
      expect(teamFromString('flutter/plugin'), Team.plugins);
      expect(teamFromString('flutter/plugins'), Team.plugins);
      expect(teamFromString('flutter/ecosystem'), Team.plugins);
      expect(teamFromString('flutter/packages'), Team.plugins);
      expect(teamFromString('flutter/nonexistent'), Team.unknown);
      expect(teamFromString('  flutter/framework  '), Team.framework);
      expect(teamFromString('Flutter/Engine'), Team.engine);
    });
  });

  group('IssueBuilder', () {
    test('buildBucket is prod regardless of bringup', () {
      final statistic = BuilderStatistic(
        name: 'Linux abc',
        flakyRate: 0.5,
        flakyNumber: 5,
        totalNumber: 10,
      );
      final ownership = TestOwnership('owner', Team.framework);
      final issueBuilderBringupFalse = IssueBuilder(
        statistic: statistic,
        ownership: ownership,
        threshold: 0.1,
        bringup: false,
      );
      final issueBuilderBringupTrue = IssueBuilder(
        statistic: statistic,
        ownership: ownership,
        threshold: 0.1,
        bringup: true,
      );

      expect(issueBuilderBringupFalse.buildBucket, Bucket.prod);
      expect(issueBuilderBringupTrue.buildBucket, Bucket.prod);
    });
  });
}
