// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/branch.dart';
import 'package:cocoon_service/src/model/gerrit/commit.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/branch_service.dart';

import 'package:gcloud/db.dart';
import 'package:github/github.dart' show RepositoryCommit;
import 'package:github/hooks.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/service/fake_gerrit_service.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/matchers.dart';
import '../src/utilities/webhook_generators.dart';

void main() {
  late FakeConfig config;
  late FakeDatastoreDB db;
  late BranchService branchService;
  late FakeGerritService gerritService;
  late FakeGithubService githubService;

  setUp(() {
    db = FakeDatastoreDB();
    githubService = FakeGithubService();
    config = FakeConfig(
      dbValue: db,
      githubService: githubService,
    );
    gerritService = FakeGerritService();
    branchService = BranchService(
      config: config,
      gerritService: gerritService,
    );
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
      expect(branch.branch, 'flutter-2.12-candidate.4');
    });

    test('should not add duplicate entity if branch already exists in db', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;
      expect(db.values.values.whereType<Branch>().length, 1);

      final CreateEvent createEvent = generateCreateBranchEvent('flutter-2.12-candidate.4', 'flutter/flutter');
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 1);
      final Branch branch = db.values.values.whereType<Branch>().single;
      expect(branch.repository, 'flutter/flutter');
      expect(branch.branch, 'flutter-2.12-candidate.4');
    });

    test('should add branch if it is different from previously existing branches', () async {
      expect(db.values.values.whereType<Branch>().length, 0);

      const String id = 'flutter/flutter/flutter-2.12-candidate.4';
      int lastActivity = DateTime.tryParse("2019-05-15T15:20:56Z")!.millisecondsSinceEpoch;
      final Key<String> branchKey = db.emptyKey.append<String>(Branch, id: id);
      final Branch currentBranch = Branch(key: branchKey, lastActivity: lastActivity);
      db.values[currentBranch.key] = currentBranch;

      expect(db.values.values.whereType<Branch>().length, 1);

      final CreateEvent createEvent = generateCreateBranchEvent('flutter-2.12-candidate.5', 'flutter/flutter');
      await branchService.handleCreateRequest(createEvent);

      expect(db.values.values.whereType<Branch>().length, 2);
      expect(db.values.values.whereType<Branch>().map<String>((Branch b) => b.branch),
          containsAll(<String>['flutter-2.12-candidate.4', 'flutter-2.12-candidate.5']));
    });
  });

  group('branchFlutterRecipes', () {
    const String branch = 'flutter-2.13-candidate.0';
    setUp(() {
      gerritService.branchesValue = <String>[];
      githubService.listCommitsBranch = (String branch, int ts) => <RepositoryCommit>[
            generateGitCommit(5),
          ];
    });

    test('does not create branch that already exists', () async {
      gerritService.branchesValue = <String>[branch];
      expect(() async => branchService.branchFlutterRecipes(branch),
          throwsExceptionWith<BadRequestException>('$branch already exists'));
    });

    test('does not create branch if a good branch point cannot be found', () async {
      gerritService.commitsValue = <GerritCommit>[];
      githubService.listCommitsBranch = (String branch, int ts) => <RepositoryCommit>[];
      expect(() async => branchService.branchFlutterRecipes(branch),
          throwsExceptionWith<InternalServerError>('Failed to find a revision to branch Flutter recipes for $branch'));
    });

    test('creates branch', () async {
      await branchService.branchFlutterRecipes(branch);
    });

    test('creates branch when there is a similar branch', () async {
      gerritService.branchesValue = <String>['$branch-similar'];

      await branchService.branchFlutterRecipes(branch);
    });
  });
}
