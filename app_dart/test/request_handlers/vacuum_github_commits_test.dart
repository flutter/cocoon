// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/vacuum_github_commits.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('VacuumGithubCommits', () {
    late FakeConfig config;
    FakeAuthenticationProvider auth;
    late FakeDatastoreDB db;
    FakeScheduler scheduler;
    late ApiRequestHandlerTester tester;
    late VacuumGithubCommits handler;

    late List<String> githubCommits;
    late int yieldedCommitCount;

    List<RepositoryCommit> commitList() {
      final List<RepositoryCommit> commits = <RepositoryCommit>[];
      for (String sha in githubCommits) {
        final User author = User()
          ..login = 'Username'
          ..avatarUrl = 'http://example.org/avatar.jpg';
        final GitCommitUser committer =
            GitCommitUser('Username', 'Username@abc.com', DateTime.fromMillisecondsSinceEpoch(int.parse(sha)));
        final GitCommit gitCommit = GitCommit()
          ..message = 'commit message'
          ..committer = committer;
        commits.add(RepositoryCommit()
          ..sha = sha
          ..author = author
          ..commit = gitCommit);
      }
      return commits;
    }

    Commit shaToCommit(String sha, String branch, RepositorySlug slug) {
      return Commit(
          key: db.emptyKey.append(Commit, id: '${slug.fullName}/$branch/$sha'),
          repository: slug.fullName,
          sha: sha,
          branch: branch,
          timestamp: int.parse(sha));
    }

    setUp(() {
      final MockRepositoriesService repositories = MockRepositoriesService();
      final FakeGithubService githubService = FakeGithubService();
      final MockTabledataResource tabledataResourceApi = MockTabledataResource();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) async {
        return TableDataInsertAllResponse();
      });

      yieldedCommitCount = 0;
      db = FakeDatastoreDB();
      config = FakeConfig(
          tabledataResource: tabledataResourceApi,
          githubService: githubService,
          dbValue: db,
          supportedBranchesValue: <String>['master']);
      auth = FakeAuthenticationProvider();
      scheduler = FakeScheduler(
        config: config,
        ciYaml: exampleConfig,
      );
      tester = ApiRequestHandlerTester();
      handler = VacuumGithubCommits(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        scheduler: scheduler,
      );

      githubService.listCommitsBranch = (String branch, int hours) {
        return commitList();
      };

      when(githubService.github.repositories).thenReturn(repositories);
    });

    test('succeeds when GitHub returns no commits', () async {
      githubCommits = <String>[];
      config.flutterBranchesValue = <String>['master'];
      final Body body = await tester.get<Body>(handler);
      expect(yieldedCommitCount, 0);
      expect(db.values, isEmpty);
      expect(await body.serialize().toList(), isEmpty);
    });

    test('checks branch property for commits', () async {
      githubCommits = <String>['1'];
      config.supportedBranchesValue = <String>['flutter-1.1-candidate.1', 'master'];

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      final Commit commit = db.values.values.whereType<Commit>().first;
      expect(db.values.values.whereType<Commit>().length, 2 * Config.supportedRepos.length);
      expect(commit.branch, 'flutter-1.1-candidate.1');
    });

    test('inserts the latest single commit if a new branch is found', () async {
      githubCommits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      config.supportedBranchesValue = <String>['flutter-0.0-candidate.0'];

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, Config.supportedRepos.length);
      expect(db.values.values.whereType<Commit>().first.sha, '9');
    });

    test('does not fail on empty commit list', () async {
      githubCommits = <String>[];
      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 0);
    });

    test('does not add recent commits', () async {
      githubCommits = <String>['${DateTime.now().millisecondsSinceEpoch}'];

      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 0);
    });

    test('inserts all relevant fields of the commit', () async {
      githubCommits = <String>['1'];
      config.flutterBranchesValue = <String>['master'];
      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, Config.supportedRepos.length);
      final List<Commit> commits = db.values.values.whereType<Commit>().toList();
      final Commit commit = commits.first;
      expect(commit.repository, 'flutter/cocoon');
      expect(commit.branch, 'master');
      expect(commit.sha, '1');
      expect(commit.timestamp, 1);
      expect(commit.author, 'Username');
      expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
      expect(commit.message, 'commit message');
      expect(commits[1].repository, Config.engineSlug.fullName);
      expect(commits[2].repository, Config.flutterSlug.fullName);
    });

    test('skips commits for which transaction commit fails', () async {
      githubCommits = <String>['2', '3', '4'];
      config.flutterBranchesValue = <String>['master'];

      /// This test is simulating an existing branch, which must already
      /// have at least one commit in the datastore.
      final Commit commit = shaToCommit('1', 'master', Config.flutterSlug);
      db.values[commit.key] = commit;

      db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
        if (inserts.whereType<Commit>().where((Commit commit) => commit.sha == '3').isNotEmpty) {
          throw StateError('Commit failed');
        }
      };
      final Body body = await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 4 + Config.supportedRepos.length);
      expect(db.values.values.whereType<Task>().length, 2 + (2 * 3 * Config.supportedRepos.length));
      expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
      expect(db.values.values.whereType<Commit>().map<int>(toTimestamp), containsAll(<int>[1, 2, 4]));
      expect(await body.serialize().toList(), isEmpty);
    });
  });
}

String toSha(Commit commit) => commit.sha!;

int toTimestamp(Commit commit) => commit.timestamp!;
