// Copyright 2019 The Flutter Authors. All rights reserved.
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
import '../src/utilities/mocks.dart';

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

    test('do not update task status when SHA does not match', () async {
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
              commitSha: 'def',
              ref: 'refs/heads/master',
              status: Task.statusSucceeded,
              buildId: 1)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusNew);
    });

    test('do not update task status when branch does not match', () async {
      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc'),
          sha: 'abc',
          branch: 'test');
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
              status: Task.statusSucceeded,
              buildId: 1)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusNew);
    });

    test('update task status and buildId when buildId is null', () async {
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
              status: Task.statusSucceeded,
              buildId: 1)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      expect(task.buildId, isNull);
      await tester.get(handler);
      expect(task.status, Task.statusSucceeded);
      expect(task.buildId, 1);
    });

    test('update task status when buildId matches one luci build', () async {
      final Commit commit =
          Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          status: Task.statusNew,
          buildId: 1);
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
              status: Task.statusSucceeded,
              buildId: 1)
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

    test(
        'does not update task status when buildId does not match any luci build',
        () async {
      final Commit commit =
          Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          status: Task.statusNew,
          buildId: 1);
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
              status: Task.statusSucceeded,
              buildId: 2)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusNew);
    });

    // Note here the first matched luci build is in the reverse order: from old to new.
    test(
        'update task status with first matched luci build when multiple luci builds match',
        () async {
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
              status: Task.statusSucceeded,
              buildId: 1),
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusFailed,
              buildId: 2)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusFailed);
    });

    test('create a new Task entry for rerun luci build', () async {
      final Commit commit =
          Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      final Task task = Task(
          key: commit.key.append(Task, id: 123),
          status: Task.statusNew,
          buildId: 2);
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
              status: Task.statusInProgress,
              buildId: 1),
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusFailed,
              buildId: 2)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      expect(config.db.values.values.whereType<Task>().length, 1);
      await tester.get(handler);
      expect(task.status, Task.statusFailed);
      final List<Task> tasks =
          config.db.values.values.whereType<Task>().toList();
      expect(tasks.length, 2);
      expect(tasks[1].buildId, 1);
      expect(tasks[1].status, Task.statusInProgress);
    });

    test('update task status for non master branch', () async {
      final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'def'),
          sha: 'def',
          branch: 'test');
      final Task task =
          Task(key: commit.key.append(Task, id: 456), status: Task.statusNew);
      config.db.values[commit.key] = commit;
      config.db.values[task.key] = task;
      config.flutterBranchesValue = <String>['master', 'test'];

      final Map<LuciBuilder, List<LuciTask>> luciTasks =
          Map<LuciBuilder, List<LuciTask>>.fromIterable(
        await LuciBuilder.getBuilders(config),
        key: (dynamic builder) => builder as LuciBuilder,
        value: (dynamic builder) => <LuciTask>[
          const LuciTask(
              commitSha: 'def',
              ref: 'refs/heads/test',
              status: Task.statusFailed,
              buildId: 1),
          const LuciTask(
              commitSha: 'abc',
              ref: 'refs/heads/master',
              status: Task.statusSucceeded,
              buildId: 2)
        ],
      );
      when(mockLuciService.getRecentTasks(
              repo: 'flutter', requireTaskName: true))
          .thenAnswer((Invocation invocation) {
        return Future<Map<LuciBuilder, List<LuciTask>>>.value(luciTasks);
      });

      expect(task.status, Task.statusNew);
      await tester.get(handler);
      expect(task.status, Task.statusFailed);
    });
  });
}
