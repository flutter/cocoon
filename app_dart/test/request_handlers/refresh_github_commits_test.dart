// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_github_commits.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart' as gcloud_db;
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:github/server.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/request_handling/fake_logging.dart';
import '../src/service/fake_github_service.dart';

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
    FakeHttpClient branchHttpClient;
    ApiRequestHandlerTester tester;
    RefreshGithubCommits handler;

    List<String> githubCommits;
    int yieldedCommitCount;
    int newBranchHours;

    List<RepositoryCommit> commitList(int hours) {
      List<RepositoryCommit> commits = <RepositoryCommit>[];
      for (String sha in githubCommits) {
        final User author = User()
          ..login = 'Username'
          ..avatarUrl = 'http://example.org/avatar.jpg';
        final GitCommitUser committer = GitCommitUser(
            'Username',
            'Username@abc.com',
            DateTime.fromMillisecondsSinceEpoch(int.parse(sha)));
        final GitCommit gitCommit = GitCommit()..committer = committer;
        commits.add(RepositoryCommit()
          ..sha = sha
          ..author = author
          ..commit = gitCommit);
      }
      if (hours == newBranchHours) {
        commits = commits.take(1).toList();
      }
      return commits;
    }

    Commit shaToCommit(String sha, String branch) {
      return Commit(
          key: db.emptyKey.append(Commit, id: 'flutter/flutter/$branch/$sha'),
          sha: sha);
    }

    setUp(() {
      final MockRepositoriesService repositories = MockRepositoriesService();
      final FakeGithubService githubService = FakeGithubService();
      final MockTabledataResourceApi tabledataResourceApi =
          MockTabledataResourceApi();
      when(tabledataResourceApi.insertAll(any, any, any, any)).thenAnswer((_) {
        return Future<TableDataInsertAllResponse>.value(null);
      });

      yieldedCommitCount = 0;
      newBranchHours = 168;
      db = FakeDatastoreDB();
      config = FakeConfig(
          tabledataResourceApi: tabledataResourceApi,
          githubService: githubService,
          dbValue: db);
      auth = FakeAuthenticationProvider();
      httpClient = FakeHttpClient();
      branchHttpClient = FakeHttpClient();
      tester = ApiRequestHandlerTester();
      handler = RefreshGithubCommits(
        config,
        auth,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        httpClientProvider: () => httpClient,
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );

      githubService.listCommitsBranch = (String branch, int hours) {
        return commitList(hours);
      };

      when(githubService.github.repositories).thenReturn(repositories);
    });

    test('succeeds when GitHub returns no commits', () async {
      githubCommits = <String>[];
      config.flutterBranchesValue = 'master';
      final Body body = await tester.get<Body>(handler);
      expect(yieldedCommitCount, 0);
      expect(db.values, isEmpty);
      expect(await body.serialize().toList(), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
    });

    test('checks branch property for commits', () async {
      githubCommits = <String>['1'];
      config.flutterBranchesValue = 'flutter-1.1-candidate.1,master';

      expect(db.values.values.whereType<Commit>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      await tester.get<Body>(handler);
      final Commit commit = db.values.values.whereType<Commit>().first;
      expect(db.values.values.whereType<Commit>().length, 2);
      expect(commit.branch, 'flutter-1.1-candidate.1');
    });

    test('stops requesting GitHub commits when it finds an existing commit',
        () async {
      githubCommits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      config.flutterBranchesValue = 'master';
      const List<String> dbCommits = <String>['3', '4', '5', '6'];
      for (String sha in dbCommits) {
        final Commit commit = shaToCommit(sha, 'master');
        db.values[commit.key] = commit;
      }

      expect(db.values.values.whereType<Commit>().length, 4);
      expect(db.values.values.whereType<Task>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      final Body body = await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 6);
      expect(db.values.values.whereType<Task>().length, 10);
      expect(await body.serialize().toList(), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.WARNING)), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
    });

    test('inserts the latest single commit if a new branch is found', () async {
      githubCommits = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9'];
      config.flutterBranchesValue = 'flutter-0.0-candidate.0';
      config.newBranchHoursValue = 168;

      expect(db.values.values.whereType<Commit>().length, 0);
      httpClient.request.response.body = singleTaskManifestYaml;
      await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 1);
    });

    test('skips commits for which transaction commit fails', () async {
      githubCommits = <String>['1', '2', '3'];
      config.flutterBranchesValue = 'master';
      db.onCommit =
          (List<gcloud_db.Model> inserts, List<gcloud_db.Key> deletes) {
        if (inserts
            .whereType<Commit>()
            .where((Commit commit) => commit.sha == '2')
            .isNotEmpty) {
          throw StateError('Commit failed');
        }
      };
      httpClient.request.response.body = singleTaskManifestYaml;
      final Body body = await tester.get<Body>(handler);
      expect(db.values.values.whereType<Commit>().length, 2);
      expect(db.values.values.whereType<Task>().length, 10);
      expect(db.values.values.whereType<Commit>().map<String>(toSha),
          <String>['1', '3']);
      expect(db.values.values.whereType<Commit>().map<int>(toTimestamp),
          <int>[1, 3]);
      expect(await body.serialize().toList(), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
    });

    test('retries manifest download upon HTTP failure', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) {
        request.response.statusCode =
            retry == 0 ? HttpStatus.serviceUnavailable : HttpStatus.ok;
        retry++;
      };

      githubCommits = <String>['1'];
      config.flutterBranchesValue = 'master';
      httpClient.request.response.body = singleTaskManifestYaml;
      final Body body = await tester.get<Body>(handler);
      expect(retry, 2);
      expect(db.values.values.whereType<Commit>().length, 1);
      expect(db.values.values.whereType<Task>().length, 5);
      expect(await body.serialize().toList(), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.ERROR)), isEmpty);
    });

    test('gives up manifest download after 3 tries', () async {
      int retry = 0;
      httpClient.onIssueRequest = (FakeHttpClientRequest request) => retry++;

      githubCommits = <String>['1'];
      config.flutterBranchesValue = 'master';
      httpClient.request.response.body = singleTaskManifestYaml;
      httpClient.request.response.statusCode = HttpStatus.serviceUnavailable;
      await expectLater(
          tester.get<Body>(handler), throwsA(isA<HttpStatusException>()));
      expect(retry, 3);
      expect(db.values.values.whereType<Commit>(), isEmpty);
      expect(db.values.values.whereType<Task>(), isEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.WARNING)), isNotEmpty);
      expect(tester.log.records.where(hasLevel(LogLevel.ERROR)), isNotEmpty);
    });
  });
}

String toSha(Commit commit) => commit.sha;

int toTimestamp(Commit commit) => commit.timestamp;

class MockGitHub extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}

class MockTabledataResourceApi extends Mock implements TabledataResourceApi {}
