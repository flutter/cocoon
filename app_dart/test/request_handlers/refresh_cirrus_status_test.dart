// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:graphql/client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_cirrus_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../foundation/utils_test.dart';
import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';

void main() {
  group('RefreshCirrusStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    RefreshCirrusStatus handler;
    FakeDatastoreDB datastoreDB;
    FakeHttpClient branchHttpClient;
    FakeGraphQLClient cirrusGraphQLClient;
    List<dynamic> statuses = <dynamic>[];
    String cirrusBranch;
    const List<String> githubBranches = <String>[
      'master',
      'flutter-0.0-candidate.0'
    ];

    setUp(() {
      final FakeGithubService githubService = FakeGithubService();
      datastoreDB = FakeDatastoreDB();
      branchHttpClient = FakeHttpClient();
      cirrusGraphQLClient = FakeGraphQLClient();
      tester = ApiRequestHandlerTester();
      config = FakeConfig(
          dbValue: datastoreDB,
          cirrusGraphQLClient: cirrusGraphQLClient,
          githubService: githubService,
          flutterBranchesValue: githubBranches);
      handler = RefreshCirrusStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        branchHttpClientProvider: () => branchHttpClient,
      );

      statuses.clear();
      cirrusBranch = null;

      cirrusGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult();

      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createQueryResult(statuses, cirrusBranch);
      };
    });

    test('update cirrus status when all tasks succeeded', () async {
      cirrusBranch = 'master';
      statuses = <dynamic>[
        <String, String>{'status': 'COMPLETED', 'name': 'test1'},
        <String, String>{'status': 'COMPLETED', 'name': 'test2'}
      ];
      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/$cirrusBranch/7d03371610c07953a5def50d500045941de516b8'),
          branch: 'master');
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          status: 'New');
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      expect(task.status, 'New');
      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);
      expect(task.status, 'Succeeded');
    });

    test('update cirrus status when some tasks failed', () async {
      cirrusBranch = 'master';
      statuses = <dynamic>[
        <String, String>{'status': 'FAILED', 'name': 'test1'},
        <String, String>{'status': 'COMPLETED', 'name': 'test2'}
      ];

      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/$cirrusBranch/7d03371610c07953a5def50d500045941de516b8'),
          branch: 'master');
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          status: 'New');
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      expect(task.status, 'New');
      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);
      expect(task.status, 'Failed');
    });

    test('update cirrus status when some tasks in process', () async {
      cirrusBranch = 'master';
      statuses = <dynamic>[
        <String, String>{'status': 'EXECUTING', 'name': 'test1'},
        <String, String>{'status': 'COMPLETED', 'name': 'test2'}
      ];

      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/7d03371610c07953a5def50d500045941de516b8'));
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          status: 'New');
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      expect(task.status, 'New');
      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);
      expect(task.status, 'In Progress');
    });

    test('update cirrus status with a branch different than master', () async {
      cirrusBranch = 'flutter-0.0-candidate.0';
      statuses = <dynamic>[
        <String, String>{'status': 'EXECUTING', 'name': 'test1'},
        <String, String>{'status': 'COMPLETED', 'name': 'test2'}
      ];

      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit,
              id: 'flutter/flutter/7d03371610c07953a5def50d500045941de516b8'),
          branch: 'flutter-0.0-candidate.0');
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          status: 'New');
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      expect(task.status, 'New');
      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);
      expect(task.status, 'In Progress');
    });

    test('skip updating cirrus status when there is no matching branch',
        () async {
      cirrusBranch = 'flutter-0.0-candidate.0';
      statuses = <dynamic>[
        <String, String>{'status': 'EXECUTING', 'name': 'test1'},
        <String, String>{'status': 'COMPLETED', 'name': 'test2'}
      ];

      final Commit commit = Commit(
          key:
              config.db.emptyKey.append(Commit, id: 'flutter/flutter/master/1'),
          branch: 'master');
      final Task task = Task(
          key: commit.key.append(Task, id: 1),
          commitKey: commit.key,
          status: 'New');
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;

      expect(task.status, 'New');
      branchHttpClient.request.response.body = branchRegExp;
      await tester.get(handler);
      expect(task.status, 'New');
    });
  });
}

QueryResult createQueryResult(List<dynamic> statuses, String branch) {
  assert(statuses != null);

  return QueryResult(
    data: <String, dynamic>{
      'searchBuilds': <dynamic>[
        <String, dynamic>{
          'id': '1',
          'branch': branch,
          'latestGroupTasks': <dynamic>[
            <String, dynamic>{
              'id': '1',
              'name': statuses.first['name'],
              'status': statuses.first['status']
            },
            <String, dynamic>{
              'id': '2',
              'name': statuses.last['name'],
              'status': statuses.last['status']
            }
          ],
        },
      ],
    },
  );
}

class MockGitHub extends Mock implements GitHub {}

class MockRepositoriesService extends Mock implements RepositoriesService {}
