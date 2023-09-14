// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';
import 'package:cocoon_service/src/service/config.dart';

import 'package:github/github.dart' as gh;
import 'package:mockito/mockito.dart';
import 'package:retry/retry.dart';
import 'package:test/test.dart';
import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:gcloud/db.dart';
import 'package:github/hooks.dart';

import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/matchers.dart';
import '../src/utilities/mocks.mocks.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late MockConfig config;
  late FakeDatastoreDB db;
  late BranchService branchService;
  late FakeGerritService gerritService;
  late FakeGithubService githubService;
  late MockRepositoriesService repositories;

  setUp(() {
    db = FakeDatastoreDB();
    final MockGitHub github = MockGitHub();
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

  group('handleCreateRequest', () {
    test('should not add branch if it is created in a fork', () async {
      expect(db.values.values.whereType<Branch>().length, 0);
      final CreateEvent createEvent = generateCreateBranchEvent('filter_forks', 'godofredo/cocoon', forked: true);
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 0);
    });

    test('should add branch to db if db is empty', () async {
      expect(db.values.values.whereType<Branch>().length, 0);
      final CreateEvent createEvent = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 1);
      final Branch branch = db.values.values.whereType<Branch>().single;
      expect(branch.repository, 'flutter/flutter');
      expect(branch.name, 'flutter-2.12-candidate.4');
    });

    test('should not add duplicate entity if branch already exists in db', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      final int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;
      expect(db.values.values.whereType<Branch>().length, 1);

      final CreateEvent createEvent = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 1);
      final Branch branch = db.values.values.whereType<Branch>().single;
      expect(branch.repository, 'flutter/flutter');
      expect(branch.name, 'flutter-2.12-candidate.4');
    });

    test('should add branch if it is different from previously existing branches', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      final int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;

      expect(db.values.values.whereType<Branch>().length, 1);

      final CreateEvent createEvent = generateCreateBranchEvent('flutter-2.12-candidate.5', 'flutter/flutter');
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 2);
      expect(
        db.values.values.whereType<Branch>().map<String>((Branch b) => b.name),
        containsAll(<String>['flutter-2.12-candidate.4', 'flutter-2.12-candidate.5']),
      );
    });
  });

  group('retrieve latest release branches', () {
    late MockRepositoriesService mockRepositoriesService;

    setUp(() {
      mockRepositoriesService = MockRepositoriesService();
      when(githubService.github.repositories).thenReturn(mockRepositoriesService);
    });

    test('return beta, stable, and latest candidate branches', () async {
      final gh.Branch stableBranch = generateBranch(1, name: 'flutter-2.13-candidate.0', sha: '123stable');
      final gh.Branch betaBranch = generateBranch(2, name: 'flutter-3.2-candidate.5', sha: '456beta');
      final gh.Branch candidateBranch = generateBranch(3, name: 'flutter-3.4-candidate.5', sha: '789dev');
      final gh.Branch candidateBranchOne = generateBranch(4, name: 'flutter-3.3-candidate.9', sha: 'lagerZValue');
      final gh.Branch candidateBranchTwo =
          generateBranch(5, name: 'flutter-2.15-candidate.99', sha: 'superLargeYZvalue');
      final gh.Branch candidateBranchThree = generateBranch(6, name: 'flutter-0.5-candidate.0', sha: 'someZeroValues');

      when(mockRepositoriesService.listBranches(any)).thenAnswer((Invocation invocation) {
        return Stream.fromIterable([
          candidateBranch,
          candidateBranchOne,
          stableBranch,
          betaBranch,
          candidateBranchTwo,
          candidateBranchThree,
        ]);
      });
      final List<Map<String, String>> result =
          await branchService.getReleaseBranches(githubService: githubService, slug: Config.flutterSlug);
      expect(result.length, 4);
      expect(result[1]['branch'], 'flutter-2.13-candidate.0');
      expect(result[1]['name'], 'stable');
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
