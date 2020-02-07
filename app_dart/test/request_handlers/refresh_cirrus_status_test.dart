// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:graphql/client.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_cirrus_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_graphql_client.dart';

void main() {
  group('RefreshCirrusStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    RefreshCirrusStatus handler;
    FakeDatastoreDB datastoreDB;
    FakeGraphQLClient cirrusGraphQLClient;
    List<dynamic> statuses = <dynamic>[];

    setUp(() {
      datastoreDB = FakeDatastoreDB();
      cirrusGraphQLClient = FakeGraphQLClient();
      tester = ApiRequestHandlerTester();
      statuses.clear();
      config = FakeConfig(
          dbValue: datastoreDB, cirrusGraphQLClient: cirrusGraphQLClient);
      handler = RefreshCirrusStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );

      cirrusGraphQLClient.mutateResultForOptions =
          (MutationOptions options) => QueryResult();

      cirrusGraphQLClient.queryResultForOptions = (QueryOptions options) {
        return createQueryResult(statuses);
      };
    });

    test('update cirrus status when all tasks succeeded', () async {
      statuses = <dynamic>[
        <String, String>{'status': 'COMPLETED', 'name': 'test1'},
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
      await tester.get(handler);
      expect(task.status, 'Succeeded');
    });

    test('update cirrus status when some tasks failed', () async {
      statuses = <dynamic>[
        <String, String>{'status': 'FAILED', 'name': 'test1'},
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
      await tester.get(handler);
      expect(task.status, 'Failed');
    });

    test('update cirrus status when some tasks in process', () async {
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
      await tester.get(handler);
      expect(task.status, 'In Progress');
    });
  });
}

QueryResult createQueryResult(List<dynamic> statuses) {
  assert(statuses != null);

  return QueryResult(
    data: <String, dynamic>{
      'searchBuilds': <dynamic>[
        <String, dynamic>{
          'id': '1',
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
        }
      ],
    },
  );
}
