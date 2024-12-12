// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/testing/mocks.dart';
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:github/github.dart' as gh;
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../request_handlers/check_flaky_builders_test_data.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/matchers.dart';
import '../src/utilities/mocks.mocks.dart';

void main() {
  late MockConfig config;
  late FakeDatastoreDB db;
  late BranchService branchService;
  late FakeGerritService gerritService;
  late FakeGithubService githubService;
  late MockRepositoriesService repositories;
  late MockGitHub github;

  setUp(() {
    db = FakeDatastoreDB();
    github = MockGitHub();
    githubService = FakeGithubService(client: github);
    repositories = MockRepositoriesService();
    when(github.repositories).thenReturn(repositories);
    config = MockConfig();
    gerritService = FakeGerritService();
    branchService = BranchService(
      config: config,
      gerritService: gerritService,
      retryOptions: const RetryOptions(maxDelay: Duration.zero),
    );

    when(config.createDefaultGitHubService()).thenAnswer((_) async => githubService);
    when(config.db).thenReturn(db);
  });

  group('retrieve latest release branches', () {
    late MockRepositoriesService mockRepositoriesService;

    setUp(() {
      mockRepositoriesService = MockRepositoriesService();
      when(githubService.github.repositories).thenReturn(mockRepositoriesService);
    });

    test('return empty when branch version file does not exist', () async {
      final gh.Branch candidateBranch = generateBranch(3, name: 'flutter-3.4-candidate.5', sha: '789dev');
      when(mockRepositoriesService.listBranches(any)).thenAnswer((_) => Stream.value(candidateBranch));
      when(mockRepositoriesService.getContents(any, any)).thenThrow(gh.GitHubError(github, '404 file not found'));
      final List<Map<String, String>> result =
          await branchService.getReleaseBranches(githubService: githubService, slug: Config.cocoonSlug);
      final betaBranch = result.singleWhere((Map<String, String> branch) => branch['name'] == 'beta');
      expect(betaBranch['branch']?.isEmpty, isTrue);
      final stableBranch = result.singleWhere((Map<String, String> branch) => branch['name'] == 'stable');
      expect(stableBranch['branch']?.isEmpty, isTrue);
    });

    test('return beta, stable, and latest candidate branches', () async {
      final gh.Branch stableBranch = generateBranch(1, name: 'flutter-2.13-candidate.0', sha: '123stable');
      final gh.Branch betaBranch = generateBranch(2, name: 'flutter-3.2-candidate.5', sha: '456beta');
      final gh.Branch candidateBranch = generateBranch(3, name: 'flutter-3.4-candidate.5', sha: '789dev');
      final gh.Branch candidateBranchOne = generateBranch(4, name: 'flutter-3.3-candidate.9', sha: 'lagerZValue');
      final gh.Branch candidateBranchTwo =
          generateBranch(5, name: 'flutter-2.15-candidate.99', sha: 'superLargeYZvalue');
      final gh.Branch candidateBranchThree = generateBranch(6, name: 'flutter-0.5-candidate.0', sha: 'someZeroValues');
      final gh.Branch candidateCherrypickBranch =
          generateBranch(6, name: 'cherry-picks-flutter-3.11-candidate.3', sha: 'bad');

      when(
        mockRepositoriesService.getContents(
          Config.flutterSlug,
          'bin/internal/release-candidate-branch.version',
          ref: 'beta',
        ),
      ).thenAnswer(
        (_) async => gh.RepositoryContents(file: gh.GitHubFile(content: gitHubEncode('flutter-3.2-candidate.5\n'))),
      );

      when(
        mockRepositoriesService.getContents(
          Config.flutterSlug,
          'bin/internal/release-candidate-branch.version',
          ref: 'stable',
        ),
      ).thenAnswer(
        (_) async => gh.RepositoryContents(file: gh.GitHubFile(content: gitHubEncode('flutter-2.13-candidate.0\n'))),
      );

      when(mockRepositoriesService.listBranches(any)).thenAnswer((Invocation invocation) {
        return Stream.fromIterable([
          candidateBranch,
          candidateBranchOne,
          stableBranch,
          betaBranch,
          candidateBranchTwo,
          candidateBranchThree,
          candidateCherrypickBranch,
        ]);
      });
      final List<Map<String, String>> result =
          await branchService.getReleaseBranches(githubService: githubService, slug: Config.flutterSlug);
      expect(result.length, 4);
      expect(result[1]['branch'], 'flutter-2.13-candidate.0');
      expect(result[1]['name'], 'stable');
      final devBranch = result.singleWhere((Map<String, String> branch) => branch['name'] == 'dev');
      expect(devBranch['branch'], 'flutter-3.4-candidate.5');
    });
  });

  group('branchFlutterRecipes', () {
    const String branch = 'flutter-2.13-candidate.0';
    const String sha = 'abc123';
    setUp(() {
      gerritService.branchesValue = <String>[];
      when(repositories.getCommit(Config.engineSlug, sha)).thenAnswer((_) async => generateGitCommit(5));
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
      when(repositories.getCommit(Config.engineSlug, sha)).thenAnswer(
        (_) async => gh.RepositoryCommit(
          commit: gh.GitCommit(
            committer: gh.GitCommitUser(
              'dash',
              'dash@flutter.dev',
              null,
            ),
          ),
        ),
      );
      expect(
        () async => branchService.branchFlutterRecipes(branch, sha),
        throwsExceptionWith<BadRequestException>('$sha has no commit time'),
      );
    });

    test('does not create branch if a good branch point cannot be found', () async {
      gerritService.commitsValue = <GerritCommit>[];
      when(repositories.getCommit(Config.engineSlug, sha)).thenAnswer(
        (_) async => generateGitCommit(5),
      );
      expect(
        () async => branchService.branchFlutterRecipes(branch, sha),
        throwsExceptionWith<InternalServerError>(
          'HTTP 500: Failed to find a revision to flutter/recipes for $branch before 1969-12-31',
        ),
      );
    });

    test('creates branch', () async {
      await branchService.branchFlutterRecipes(branch, sha);
    });

    test('creates branch when GitHub requires retries', () async {
      int attempts = 0;
      when(repositories.getCommit(Config.engineSlug, sha)).thenAnswer((_) async {
        attempts++;
        if (attempts == 3) {
          return generateGitCommit(5);
        }
        throw gh.GitHubError(MockGitHub(), 'Failed to get commit');
      });
      await branchService.branchFlutterRecipes(branch, sha);
    });

    test('ensure createDefaultGithubService is called once for each retry', () async {
      int attempts = 0;
      when(repositories.getCommit(Config.engineSlug, sha)).thenAnswer((_) async {
        attempts++;
        if (attempts == 3) {
          return generateGitCommit(5);
        }
        throw gh.GitHubError(MockGitHub(), 'Failed to get commit');
      });
      await branchService.branchFlutterRecipes(branch, sha);

      verify(config.createDefaultGitHubService()).called(attempts);
    });

    test('creates branch when there is a similar branch', () async {
      gerritService.branchesValue = <String>['$branch-similar'];

      await branchService.branchFlutterRecipes(branch, sha);
    });
  });
}
