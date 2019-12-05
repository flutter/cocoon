// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_cirrus_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_github_service.dart';

void main() {
  group('RefreshCirrusStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    RefreshCirrusStatus handler;
    final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
    tester = ApiRequestHandlerTester();

    test('update cirrus status when all tasks succeeded', () async {
      final List<dynamic> statuses = <dynamic>[
        <String, String>{'status': 'completed', 'conclusion': 'success', 'name': 'test1'},
        <String, String>{'status': 'completed', 'conclusion': 'success', 'name': 'test2'}
      ];
      final FakeGithubService githubService = FakeGithubService(statuses);

      config = FakeConfig(dbValue: datastoreDB, githubService: githubService);
      handler = RefreshCirrusStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );

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

    test('update cirrus status when some tasks in process', () async {
      final List<dynamic> statuses = <dynamic>[
        <String, String>{'status': 'in_progress', 'conclusion': null, 'name': 'test1'},
        <String, String>{'status': 'completed', 'conclusion': 'success', 'name': 'test2'}
      ];
      final FakeGithubService githubService = FakeGithubService(statuses);

      config = FakeConfig(dbValue: datastoreDB, githubService: githubService);
      handler = RefreshCirrusStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );

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

    test('update cirrus status when some tasks failed', () async {
      final List<dynamic> statuses = <dynamic>[
        <String, String>{'status': 'completed', 'conclusion': 'failure', 'name': 'test1'},
        <String, String>{'status': 'completed', 'conclusion': 'success', 'name': 'test2'}
      ];
      final FakeGithubService githubService = FakeGithubService(statuses);
      
      config = FakeConfig(dbValue: datastoreDB, githubService: githubService);
      handler = RefreshCirrusStatus(
        config,
        FakeAuthenticationProvider(),
        datastoreProvider: () => DatastoreService(db: config.db),
      );

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
  });
}
