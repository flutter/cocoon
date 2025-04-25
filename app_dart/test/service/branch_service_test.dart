// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart' as rpc_model;
import 'package:cocoon_common_test/cocoon_common_test.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:github/github.dart' as gh;
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/service/fake_gerrit_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/matchers.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  useTestLoggerPerTest();

  late MockConfig config;
  late BranchService branchService;
  late FakeGerritService gerritService;
  late MockGithubService githubService;
  late Map<String, String> simulateGitubFileContent;

  setUp(() {
    githubService = MockGithubService();

    simulateGitubFileContent = {};
    final mockHttp = MockClient((req) async {
      final [_, _, channel, ...] = req.url.pathSegments;
      final result = simulateGitubFileContent[channel];
      if (result == null) {
        return Response('Not Found', 404);
      }
      return Response(result, 200);
    });

    config = MockConfig();
    when(
      // ignore: discarded_futures
      config.createDefaultGitHubService(),
    ).thenAnswer((_) async => githubService);
    gerritService = FakeGerritService();
    branchService = BranchService(
      config: config,
      gerritService: gerritService,
      retryOptions: const RetryOptions(maxDelay: Duration.zero),
      httpClientProvider: () => mockHttp,
    );
  });

  group('getReleaseBranches', () {
    setUp(() {
      when(
        config.releaseCandidateBranchPath,
      ).thenReturn('bin/internal/release-candidate-branch.version');
    });

    test(
      'always returns master branch, even if config.releaseBranches is empty',
      () async {
        when(config.releaseBranches).thenReturn([]);

        final releaseBranches = await branchService.getReleaseBranches(
          slug: Config.flutterSlug,
        );
        // NOTE, master is intentionally used as both the channel and the
        // reference, because on the frontend, the "channel" moniker is just
        // ignored, and the "reference" must point to an actual git reference
        // (HEAD is not sufficient or correct).
        //
        // See https://github.com/flutter/flutter/issues/164726.
        expect(releaseBranches, [
          rpc_model.Branch(channel: 'master', reference: 'master'),
        ]);
      },
    );

    test(
      'returns additional branches by fetching and reading config.releaseCandidateBranchPath',
      () async {
        when(config.releaseBranches).thenReturn(['stable', 'beta']);
        simulateGitubFileContent = {
          'stable': 'flutter-3.29-candidate.0',
          'beta': 'flutter-3.30-candidate.0',
        };

        final releaseBranches = await branchService.getReleaseBranches(
          slug: Config.flutterSlug,
        );
        expect(
          releaseBranches,
          unorderedEquals([
            rpc_model.Branch(channel: 'master', reference: 'master'),
            rpc_model.Branch(
              channel: 'stable',
              reference: 'flutter-3.29-candidate.0',
            ),
            rpc_model.Branch(
              channel: 'beta',
              reference: 'flutter-3.30-candidate.0',
            ),
          ]),
        );
      },
    );

    test(
      'omits branches that fail to fetch or reading config.releaseCandidateBranchPath',
      () async {
        when(
          config.releaseBranches,
        ).thenReturn(['stable', 'beta-will-be-missing']);
        simulateGitubFileContent = {'stable': 'flutter-3.29-candidate.0'};

        final releaseBranches = await branchService.getReleaseBranches(
          slug: Config.flutterSlug,
        );
        expect(
          releaseBranches,
          unorderedEquals([
            rpc_model.Branch(channel: 'master', reference: 'master'),
            rpc_model.Branch(
              channel: 'stable',
              reference: 'flutter-3.29-candidate.0',
            ),
          ]),
        );
        expect(
          log,
          bufferedLoggerOf(
            contains(
              logThat(
                message: contains(
                  'Could not resolve release branch for "beta-will-be-missing"',
                ),
              ),
            ),
          ),
        );
      },
    );
  });

  group('branchFlutterRecipes', () {
    const branch = 'flutter-2.13-candidate.0';
    const sha = 'abc123';
    late gh.RepositoryCommit gitCommit;

    late MockRepositoriesService repositories;

    setUp(() {
      gerritService.branchesValue = [];

      repositories = MockRepositoriesService();
      gitCommit = generateGitCommit(5);
      when(
        // ignore: discarded_futures
        repositories.getCommit(Config.flutterSlug, sha),
      ).thenAnswer((_) async => gitCommit);

      final mockGithub = MockGitHub();
      when(mockGithub.repositories).thenReturn(repositories);
      when(githubService.github).thenReturn(mockGithub);
    });

    test('does not create branch that already exists', () async {
      gitCommit = generateGitCommit(1, commitDate: DateTime(2025, 1, 9));
      gerritService.branchesValue = [branch];
      gerritService.commitsValue = [
        generateGerritCommit('1', DateTime(2025, 1, 10).millisecondsSinceEpoch),
      ];

      expect(
        () async => branchService.branchFlutterRecipes(branch, sha),
        throwsExceptionWith<BadRequestException>('$branch already exists'),
      );
    });

    test('throws BadRequest if github commit has no branch time', () async {
      gerritService.commitsValue = <GerritCommit>[];
      when(repositories.getCommit(Config.flutterSlug, sha)).thenAnswer(
        (_) async => gh.RepositoryCommit(
          commit: gh.GitCommit(
            committer: gh.GitCommitUser('dash', 'dash@flutter.dev', null),
          ),
        ),
      );

      expect(
        () async => branchService.branchFlutterRecipes(branch, sha),
        throwsExceptionWith<BadRequestException>('$sha has no commit time'),
      );
    });

    test(
      'does not create branch if a good branch point cannot be found',
      () async {
        gitCommit = generateGitCommit(1, commitDate: DateTime(2025, 1, 9));
        gerritService.branchesValue = [];
        gerritService.commitsValue = [
          generateGerritCommit(
            '1',
            DateTime(2025, 1, 10).millisecondsSinceEpoch,
          ),
        ];

        when(
          repositories.getCommit(Config.flutterSlug, gitCommit.sha),
        ).thenAnswer((_) async => gitCommit);

        await expectLater(
          () => branchService.branchFlutterRecipes(branch, gitCommit.sha!),
          throwsExceptionWith<InternalServerError>(
            'HTTP 500: Failed to find a revision to flutter/recipes for $branch before 2025-01-09 00:00:00.000',
          ),
        );
      },
    );

    test('creates branch', () async {
      await branchService.branchFlutterRecipes(branch, sha);
    });

    test('creates branch when GitHub requires retries', () async {
      var attempts = 0;
      when(repositories.getCommit(Config.flutterSlug, sha)).thenAnswer((
        _,
      ) async {
        attempts++;
        if (attempts == 3) {
          return generateGitCommit(5);
        }
        throw gh.GitHubError(MockGitHub(), 'Failed to get commit');
      });
      await branchService.branchFlutterRecipes(branch, sha);
    });

    test(
      'ensure createDefaultGithubService is called once for each retry',
      () async {
        var attempts = 0;
        when(repositories.getCommit(Config.flutterSlug, sha)).thenAnswer((
          _,
        ) async {
          attempts++;
          if (attempts == 3) {
            return generateGitCommit(5);
          }
          throw gh.GitHubError(MockGitHub(), 'Failed to get commit');
        });
        await branchService.branchFlutterRecipes(branch, sha);

        verify(config.createDefaultGitHubService()).called(attempts);
      },
    );

    test('creates branch when there is a similar branch', () async {
      gerritService.branchesValue = <String>['$branch-similar'];

      await branchService.branchFlutterRecipes(branch, sha);
    });
  });
}
