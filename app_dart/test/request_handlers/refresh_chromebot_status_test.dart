// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_chromebot_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/request_handling/fake_http.dart';

void main() {
  group('RefreshChromebotStatus', () {
    FakeConfig config;
    ApiRequestHandlerTester tester;
    MockLuciService mockLuciService;
    RefreshChromebotStatus handler;
    FakeHttpClient branchHttpClient;

    setUp(() {
      branchHttpClient = FakeHttpClient();
      config = FakeConfig(
        luciBuildersValue: const <Map<String, String>>[
          <String, String>{
            'name': 'Builder1',
            'repo': 'flutter',
            'taskName': 'foo',
          },
        ],
      );
      tester = ApiRequestHandlerTester();
      mockLuciService = MockLuciService();
      handler = RefreshChromebotStatus(
        config,
        FakeAuthenticationProvider(),
        luciServiceProvider: (_) => mockLuciService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );
    });

    test('updates datastore entry for task', () async {
      final Commit commit =
          Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      final Task task =
          Task(key: commit.key.append(Task, id: 123), status: Task.statusNew);
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      config.flutterBranchesValue = <String>['master'];

      final Map<LuciBuilder, List<LuciTask>> luciTasks =
          Map<LuciBuilder, List<LuciTask>>.fromIterable(
        await LuciBuilder.getBuilders(config),
        key: (dynamic builder) => builder as LuciBuilder,
        value: (dynamic builder) => <LuciTask>[
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusSucceeded),
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusFailed)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusSucceeded);
    });

    test('updates datastore entry for task - multiple branches', () async {
      final Commit commitMaster = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc'),
          sha: 'abc',
          branch: 'master');
      final Commit commitOther = Commit(
          key: config.db.emptyKey.append(Commit, id: 'def'),
          sha: 'def',
          branch: 'flutter-0.0-candidate.0');
      final Task taskMaster = Task(
          key: commitMaster.key.append(Task, id: 123), status: Task.statusNew);
      final Task taskOther = Task(
          key: commitOther.key.append(Task, id: 456), status: Task.statusNew);
      config.db.values[commitMaster.key] = commitMaster;
      config.db.values[commitOther.key] = commitOther;
      config.db.values[taskMaster.key] = taskMaster;
      config.db.values[taskOther.key] = taskOther;
      config.flutterBranchesValue = <String>[
        'master',
        'flutter-0.0-candidate.0'
      ];

      final Map<LuciBuilder, List<LuciTask>> luciTasks =
          Map<LuciBuilder, List<LuciTask>>.fromIterable(
        await LuciBuilder.getBuilders(config),
        key: (dynamic builder) => builder as LuciBuilder,
        value: (dynamic builder) => <LuciTask>[
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusSucceeded),
          const LuciTask(
              commitSha: 'def',
              ref: 'refs/heads/flutter-0.0-candiate.0',
              status: Task.statusSucceeded)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(taskMaster.status, Task.statusNew);
      expect(taskOther.status, Task.statusNew);
      await tester.get(handler);
      expect(taskMaster.status, Task.statusSucceeded);
      expect(taskOther.status, Task.statusSucceeded);
    });
  });
}

// ignore: must_be_immutable
class MockLuciService extends Mock implements LuciService {}
