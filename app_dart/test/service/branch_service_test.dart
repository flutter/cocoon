// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server/testing/mocks.dart';
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:github/github.dart' as gh;
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../src/service/fake_gerrit_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/matchers.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  late MockConfig config;
  late BranchService branchService;
  late FakeGerritService gerritService;
  late MockGithubService githubService;
  late List<String> logs;

  setUp(() {
    githubService = MockGithubService();

    config = MockConfig();
    when(
      config.createDefaultGitHubService(),
    ).thenAnswer((_) async => githubService);
    gerritService = FakeGerritService();
    branchService = BranchService(
      config: config,
      gerritService: gerritService,
      retryOptions: const RetryOptions(maxDelay: Duration.zero),
    );

    // TODO(matanlurey): Refactor into test appliance. See https://github.com/flutter/flutter/issues/164652.
    logs = [];
    log = Logger.detached('branch_service_test');
    log.onRecord.listen((r) {
      final buffer = StringBuffer(r.message);
      if (r.error != null) {
        buffer.writeln(r.error);
      }
      if (r.stackTrace != null) {
        buffer.writeln(r.stackTrace);
      }
      logs.add('$buffer');
    });
  });

  tearDown(() {
    printOnFailure(logs.join('\n'));
  });

  group('getReleaseBranches', () {
    late Map<String, String> simulateGitubFileContent;

    setUp(() {
      simulateGitubFileContent = {};

      when(
        config.releaseCandidateBranchPath,
      ).thenReturn('bin/internal/release-candidate-branch.version');
      when(
        githubService.getFileContent(
          // Required because RepositorySlug does not implement operator==.
          argThat(
            isA<gh.RepositorySlug>().having(
              (s) => s.fullName,
              'fullName',
              'flutter/flutter',
            ),
          ),
          'bin/internal/release-candidate-branch.version',
          ref: anyNamed('ref'),
        ),
      ).thenAnswer((i) async {
        final ref = i.namedArguments[#ref] as String;
        final result = simulateGitubFileContent[ref];

        // The error in the actual implementation is not well defined.
        if (result == null) {
          throw StateError('Not found: $ref');
        }
        return result;
      });
    });

    test(
      'always returns master branch, even if config.releaseBranches is empty',
      () async {
        when(config.releaseBranches).thenReturn([]);

        final releaseBranches = await branchService.getReleaseBranches(
          slug: Config.flutterSlug,
        );
        expect(releaseBranches, [
          const ReleaseBranch(channel: 'master', reference: 'HEAD'),
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
            const ReleaseBranch(channel: 'master', reference: 'HEAD'),
            const ReleaseBranch(
              channel: 'stable',
              reference: 'flutter-3.29-candidate.0',
            ),
            const ReleaseBranch(
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
            const ReleaseBranch(channel: 'master', reference: 'HEAD'),
            const ReleaseBranch(
              channel: 'stable',
              reference: 'flutter-3.29-candidate.0',
            ),
          ]),
        );
        expect(
          logs,
          contains(
            contains(
              'Could not resolve release branch for "beta-will-be-missing"',
            ),
          ),
        );
      },
    );
  });

  group('branchFlutterRecipes', () {
    const branch = 'flutter-2.13-candidate.0';
    const sha = 'abc123';
    late MockRepositoriesService repositories;

    setUp(() {
      gerritService.branchesValue = <String>[];

      repositories = MockRepositoriesService();
      when(
        repositories.getCommit(Config.flutterSlug, sha),
      ).thenAnswer((_) async => generateGitCommit(5));

      final mockGithub = MockGitHub();
      when(mockGithub.repositories).thenReturn(repositories);
      when(githubService.github).thenReturn(mockGithub);
    });

    test('does not create branch that already exists', () async {
      gerritService.branchesValue = <String>[branch];
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
        gerritService.commitsValue = <GerritCommit>[];
        when(
          repositories.getCommit(Config.flutterSlug, sha),
        ).thenAnswer((_) async => generateGitCommit(5));

        expect(
          () async => branchService.branchFlutterRecipes(branch, sha),
          throwsExceptionWith<InternalServerError>(
            'HTTP 500: Failed to find a revision to flutter/recipes for $branch before 1969-12-31',
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
