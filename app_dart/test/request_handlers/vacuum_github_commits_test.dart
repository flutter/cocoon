// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
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
    late MockFirestoreService mockFirestoreService;
    late VacuumGithubCommits handler;

    late List<String> githubCommits;
    late int yieldedCommitCount;

    List<RepositoryCommit> commitList() {
      final commits = <RepositoryCommit>[];
      for (var sha in githubCommits) {
        final author =
            User()
              ..login = 'Username'
              ..avatarUrl = 'http://example.org/avatar.jpg';
        final committer = GitCommitUser(
          'Username',
          'Username@abc.com',
          DateTime.fromMillisecondsSinceEpoch(int.parse(sha)),
        );
        final gitCommit =
            GitCommit()
              ..message = 'commit message'
              ..committer = committer;
        commits.add(
          RepositoryCommit()
            ..sha = sha
            ..author = author
            ..commit = gitCommit,
        );
      }
      return commits;
    }

    Commit shaToCommit(String sha, String branch, RepositorySlug slug) {
      return Commit(
        key: db.emptyKey.append(Commit, id: '${slug.fullName}/$branch/$sha'),
        repository: slug.fullName,
        sha: sha,
        branch: branch,
        timestamp: int.parse(sha),
      );
    }

    setUp(() {
      final repositories = MockRepositoriesService();
      final githubService = FakeGithubService();
      final tabledataResourceApi = MockTabledataResource();
      mockFirestoreService = MockFirestoreService();
      when(
        mockFirestoreService.queryRecentTasksByName(
          name: anyNamed('name'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => []);

      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((
        _,
      ) async {
        return TableDataInsertAllResponse();
      });

      yieldedCommitCount = 0;
      db = FakeDatastoreDB();
      config = FakeConfig(
        tabledataResource: tabledataResourceApi,
        githubService: githubService,
        firestoreService: mockFirestoreService,
        dbValue: db,
        supportedBranchesValue: <String>['master', 'main'],
        supportedReposValue: <RepositorySlug>{
          Config.cocoonSlug,
          Config.flutterSlug,
          Config.packagesSlug,
        },
      );

      auth = FakeAuthenticationProvider();
      scheduler = FakeScheduler(config: config);
      tester = ApiRequestHandlerTester();
      handler = VacuumGithubCommits(
        config: config,
        authenticationProvider: auth,
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
      config.supportedBranchesValue = <String>['master'];
      final body = await tester.get<Body>(handler);
      expect(yieldedCommitCount, 0);
      expect(db.values, isEmpty);
      expect(await body.serialize().toList(), isEmpty);
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
      expect(db.values.values.whereType<Commit>().length, 0);
      await tester.get<Body>(handler);
      expect(
        db.values.values.whereType<Commit>().length,
        config.supportedRepos.length,
      );
      final commits = db.values.values.whereType<Commit>().toList();
      final commit = commits.first;
      expect(commit.repository, 'flutter/cocoon');
      expect(commit.branch, 'main');
      expect(commit.sha, '1');
      expect(commit.timestamp, 1);
      expect(commit.author, 'Username');
      expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
      expect(commit.message, 'commit message');
      expect(commits[1].repository, Config.flutterSlug.fullName);
    });

    test('skips commits for which transaction commit fails', () async {
      githubCommits = <String>['2', '3', '4'];

      /// This test is simulating an existing branch, which must already
      /// have at least one commit in the datastore.
      final commit = shaToCommit('1', 'master', Config.flutterSlug);
      db.values[commit.key] = commit;

      db.onCommit = (
        List<gcloud_db.Model<dynamic>> inserts,
        List<gcloud_db.Key<dynamic>> deletes,
      ) {
        if (inserts
            .whereType<Commit>()
            .where((Commit commit) => commit.sha == '3')
            .isNotEmpty) {
          throw StateError('Commit failed');
        }
      };
      final body = await tester.get<Body>(handler);

      /// The +1 is coming from the engine repository and manually added commit on the top of this test.
      expect(
        db.values.values.whereType<Commit>().length,
        6 + 1,
      ); // 2 commits for 3 repos
      expect(
        db.values.values.whereType<Commit>().map<String>(toSha),
        containsAll(<String>['1', '2', '4']),
      );
      expect(
        db.values.values.whereType<Commit>().map<int>(toTimestamp),
        containsAll(<int>[1, 2, 4]),
      );
      expect(await body.serialize().toList(), isEmpty);
    });
  });
}

String toSha(Commit commit) => commit.sha!;

int toTimestamp(Commit commit) => commit.timestamp!;
