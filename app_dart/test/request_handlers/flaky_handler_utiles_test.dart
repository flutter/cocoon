// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' as pb;
import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart' hide Team;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('Gets test ownership', () {
    String testOwnersContent;

    group('framework host only', () {
      test('returns correct owner when no mulitple tests share the same file', () async {
        final pb.Target target = pb.Target(name: 'Linux abc');
        testOwnersContent = '''
## Host only framework tests
# Linux abc
abc_test.sh @ghi @flutter/engine
## Firebase tests
''';
        final TestOwnership ownership = getTestOwnership(target, BuilderType.frameworkHostOnly, testOwnersContent);
        expect(ownership.owner, 'ghi');
        expect(ownership.team, Team.engine);
      });

      test('returns correct owner when mulitple tests share the same file', () async {
        final pb.Target target1 = pb.Target(name: 'Linux abc');
        final pb.Target target2 = pb.Target(name: 'Linux def');
        testOwnersContent = '''
## Host only framework tests
# Linux abc
# Linu def
abc_test.sh @ghi @flutter/framework
## Firebase tests
''';
        final TestOwnership ownership1 = getTestOwnership(target1, BuilderType.frameworkHostOnly, testOwnersContent);
        expect(ownership1.owner, 'ghi');
        expect(ownership1.team, Team.framework);
        final TestOwnership ownership2 = getTestOwnership(target2, BuilderType.frameworkHostOnly, testOwnersContent);
        expect(ownership2.owner, 'ghi');
        expect(ownership2.team, Team.framework);
      });
    });

    group('firebaselab only', () {
      test('returns correct owner', () async {
        final pb.Target target = pb.Target(name: 'Linux firebase_abc');
        testOwnersContent = '''
## Firebase tests
# Linux abc
/test/abc @def @flutter/tool
## Shards tests
''';
        final TestOwnership ownership = getTestOwnership(target, BuilderType.firebaselab, testOwnersContent);
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.tool);
      });
    });

    group('devicelab tests', () {
      test('returns correct owner', () async {
        final pb.Target target = pb.Target(name: 'abc', properties: {'task_name': 'abc'});
        testOwnersContent = '''
## Linux Android DeviceLab tests
/dev/devicelab/bin/tasks/abc.dart @def @flutter/web

## Host only framework tests
''';
        final TestOwnership ownership = getTestOwnership(target, BuilderType.devicelab, testOwnersContent);
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.web);
      });
    });

    group('shards tests', () {
      test('returns correct owner', () async {
        final pb.Target target = pb.Target(name: 'Linux abc');
        testOwnersContent = '''
## Shards tests
#
# abc @def @flutter/engine
''';
        final TestOwnership ownership = getTestOwnership(target, BuilderType.shard, testOwnersContent);
        expect(ownership.owner, 'def');
        expect(ownership.team, Team.engine);
      });
    });

    group('getExistingPRs', () {
      test('throws more detailed logs for bad prs with inappropriate body meta tag', () async {
        final MockGitHub mockGitHubClient = MockGitHub();
        final MockPullRequestsService mockPullRequestsService = MockPullRequestsService();
        const String expectedHtml = 'https://someurl';
        // when gets existing marks flaky prs.
        when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
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
        when(mockGitHubClient.pullRequests).thenReturn(mockPullRequestsService);
        final FakeConfig config = FakeConfig(
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
      });

      test('handles PRs with empty body message', () async {
        final MockGitHub mockGitHubClient = MockGitHub();
        final MockPullRequestsService mockPullRequestsService = MockPullRequestsService();
        const String expectedHtml = 'https://someurl';
        when(mockPullRequestsService.list(captureAny)).thenAnswer((Invocation invocation) {
          return Stream<PullRequest>.value(
            PullRequest(
              htmlUrl: expectedHtml,
            ),
          );
        });
        when(mockGitHubClient.pullRequests).thenReturn(mockPullRequestsService);
        final FakeConfig config = FakeConfig(
          githubService: GithubService(mockGitHubClient),
        );
        expect(await getExistingPRs(config.githubService!, Config.flutterSlug), <String?, PullRequest>{});
      });
    });
  });
  group('Gets team label', () {
    test('returns correct label when matched', () async {
      expect(getTeamLabelFromTeam(Team.infra), kInfraLabel);
    });

    test('returns null when not matched', () async {
      expect(getTeamLabelFromTeam(Team.unknown), null);
    });
  });
}
