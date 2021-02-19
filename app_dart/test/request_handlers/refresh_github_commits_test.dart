// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_github_commits.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_github_service.dart';
import '../src/utilities/mocks.dart';

const String singleTaskManifestYaml = '''
tasks:
  linux_test:
    stage: devicelab
    required_agent_capabilities: ["linux/android"]
''';

void main() {
  group('RefreshGithubCommits', () {
    FakeConfig config;
    FakeAuthenticationProvider auth;
    FakeDatastoreDB db;
    FakeHttpClient httpClient;
    ApiRequestHandlerTester tester;
    RefreshGithubCommits handler;

    List<String> githubCommits;
    int yieldedCommitCount;

    List<RepositoryCommit> commitList(int lastCommitTimestampMills) {
      List<RepositoryCommit> commits = <RepositoryCommit>[];
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
      if (lastCommitTimestampMills == 0) {
        commits = commits.take(1).toList();
      }
      return commits;
    }

    Commit shaToCommit(String sha, String branch) {
      return Commit(
          key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
          sha: sha,
          branch: branch,
          timestamp: int.parse(sha));
    }

    setUp(() {
      final MockRepositoriesService repositories = MockRepositoriesService();
      final FakeGithubService githubService = FakeGithubService();
      final MockTabledataResourceApi tabledataResourceApi = MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      yieldedCommitCount = 0;
      db = FakeDatastoreDB();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi, githubService: githubService, dbValue: db);
      auth = FakeAuthenticationProvider();
      httpClient = FakeHttpClient();
      tester = ApiRequestHandlerTester();
      handler = RefreshGithubCommits(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        httpClientProvider: () => httpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );

      githubService.listCommitsBranch = (String branch, int hours) {
        return commitList(hours);
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
      config.flutterBranchesValue = <String>['flutter-1.1-candidate.1', 'master'];

      expect(db.values.values.whereType<Commit>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      await tester.get<Body>(handler);
      final Commit commit = db.values.values.whereType<Commit>().first;
      expect(db.values.values.whereType<Commit>().length, 2);
      expect(commit.branch, 'flutter-1.1-candidate.1');
    });

    test('stops requesting GitHub commits when it finds an existing commit', () async {
      githubCommits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      config.flutterBranchesValue = <String>['master'];
      const List<String> dbCommits = <String>['3', '4', '5', '6'];
      for (String sha in dbCommits) {
        final Commit commit = shaToCommit(sha, 'master');
        db.values[commit.key] = commit;
      }

      expect(db.values.values.whereType<Commit>().length, 4);
      expect(db.values.values.whereType<Task>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      // Commits 7, 8, 9 will get added and scheduled to the tree
      final Body body = await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 7);
      expect(db.values.values.whereType<Task>().length, 15);
      expect(await body.serialize().toList(), isEmpty);
    });

    test('inserts the latest single commit if a new branch is found', () async {
      githubCommits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      config.flutterBranchesValue = <String>['flutter-0.0-candidate.0'];

      expect(db.values.values.whereType<Commit>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test('inserts all relevant fields of the commit', () async {
      githubCommits = <String>['1'];
      config.flutterBranchesValue = <String>['master'];
      expect(db.values.values.whereType<Commit>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 1);
      final Commit commit = db.values.values.whereType<Commit>().single;
      expect(commit.repository, 'flutter/flutter');
      expect(commit.branch, 'master');
      expect(commit.sha, '1');
      expect(commit.timestamp, 1);
      expect(commit.author, 'Username');
      expect(commit.authorAvatarUrl, 'http://example.org/avatar.jpg');
      expect(commit.message, 'commit message');
    });

    test('skips commits for which transaction commit fails', () async {
      githubCommits = <String>['2', '3', '4'];
      config.flutterBranchesValue = <String>['master'];

      /// This test is simulating an existing branch, which must already
      /// have at least one commit in the datastore.
      final Commit commit = shaToCommit('1', 'master');
      db.values[commit.key] = commit;

      db.onCommit = (List<gcloud_db.Model<dynamic>> inserts, List<gcloud_db.Key<dynamic>> deletes) {
        if (inserts.whereType<Commit>().where((Commit commit) => commit.sha == '3').isNotEmpty) {
          throw StateError('Commit failed');
        }
      };
      httpClient.request.response.body = singleTaskManifestYaml;
      final Body body = await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 3);
      expect(db.values.values.whereType<Task>().length, 10);
      expect(db.values.values.whereType<Commit>().map<String>(toSha), containsAll(<String>['1', '2', '4']));
      expect(db.values.values.whereType<Commit>().map<int>(toTimestamp), containsAll(<int>[1, 2, 4]));
      expect(await body.serialize().toList(), isEmpty);
    });
  });
}

String toSha(Commit commit) => commit.sha;

int toTimestamp(Commit commit) => commit.timestamp;
