// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/refresh_chromebot_status.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
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
    FakeTabledataResourceApi tabledataResourceApi;
    MockLuciBuildService mockLuciBuildService;

    setUp(() {
      branchHttpClient = FakeHttpClient();
      tabledataResourceApi = FakeTabledataResourceApi();
      config = FakeConfig(tabledataResourceApi: tabledataResourceApi);
      tester = ApiRequestHandlerTester();
      mockLuciService = MockLuciService();
      mockLuciBuildService = MockLuciBuildService();
      handler = RefreshChromebotStatus(
        config,
        FakeAuthenticationProvider(),
        mockLuciBuildService,
        luciServiceProvider: (_) => mockLuciService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
      );
    });

    group('without builder rerun', () {
      setUp(() {
        when(mockLuciBuildService.checkRerunBuilder(
                commitSha: anyNamed('commitSha'), luciTask: anyNamed('luciTask'), retries: anyNamed('retries')))
            .thenAnswer((_) => Future<bool>.value(false));
      });

      test('do not update task status when SHA does not match', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'def': <LuciTask>[
                        const LuciTask(
                            commitSha: 'def',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('do not update task status when commitSha/ref is unknown', () async {
        final Commit commit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'abc'),
          sha: 'abc',
        );
        final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          status: Task.statusNew,
        );
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'def': <LuciTask>[
                        const LuciTask(
                            commitSha: 'unknown',
                            ref: 'unknown',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('do not update task status when branch does not match', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc', branch: 'test');
        final Task task = Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('update task status and buildNumber when buildNumberList does not match', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        expect(task.buildNumberList, isNull);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumberList, '1');
      });

      test('save data to BigQuery when task finishes', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        await tester.get(handler);
        final TableDataList tableDataList = await tabledataResourceApi.list('test', 'test', 'test');
        expect(tableDataList.totalRows, '1');
      });

      test('update task status and buildNumber when status does not match', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(
            key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew, buildNumberList: '1');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
      });

      test('update task status with latest status when multilple reruns exist', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(
            key: commit.key.append(Task, id: 123), commitKey: commit.key, status: Task.statusNew, buildNumberList: '1');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusSucceeded,
                            buildNumber: 2,
                            builderName: 'abc'),
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusFailed,
                            buildNumber: 1,
                            builderName: 'abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumberList, '1,2');
      });

      test('update task status for non master branch', () async {
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'def'), sha: 'def', branch: 'test');
        final Task task = Task(key: commit.key.append(Task, id: 456), commitKey: commit.key, status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'def': <LuciTask>[
                        const LuciTask(
                            commitSha: 'def',
                            ref: 'refs/heads/master',
                            status: Task.statusFailed,
                            buildNumber: 1,
                            builderName: 'abc'),
                      ],
                    });
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> testLuciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(
                await LuciBuilder.getProdBuilders(config.flutterSlug, config),
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'test'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'def': <LuciTask>[
                        const LuciTask(
                            commitSha: 'def',
                            ref: 'refs/heads/test',
                            status: Task.statusSucceeded,
                            buildNumber: 2,
                            builderName: 'abc')
                      ],
                    });
        luciTasks.addAll(testLuciTasks);
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
      });
    });

    group('without builder rerun', () {
      setUp(() {
        when(mockLuciBuildService.checkRerunBuilder(
                commitSha: anyNamed('commitSha'), luciTask: anyNamed('luciTask'), retries: anyNamed('retries')))
            .thenAnswer((_) => Future<bool>.value(true));
      });

      test('rerun Mac builder when hiting recipe infra failure', () async {
        config.maxTaskRetriesValue = 2;
        final Commit commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            status: Task.statusInProgress,
            buildNumberList: '1',
            attempts: 0,
            builderName: 'Mac abc');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks =
            Map<BranchLuciBuilder, Map<String, List<LuciTask>>>.fromIterable(<LuciBuilder>[
          LuciBuilder(name: 'Mac abc', repo: config.flutterSlug.name, taskName: 'def', flaky: false)
        ],
                key: (dynamic builder) => BranchLuciBuilder(luciBuilder: builder as LuciBuilder, branch: 'master'),
                value: (dynamic builder) => <String, List<LuciTask>>{
                      'abc': <LuciTask>[
                        const LuciTask(
                            commitSha: 'abc',
                            ref: 'refs/heads/master',
                            status: Task.statusInfraFailure,
                            buildNumber: 1,
                            builderName: 'Mac abc')
                      ],
                    });
        when(mockLuciService.getBranchRecentTasks(slug: config.flutterSlug, requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusInProgress);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
        expect(task.attempts, 1);
      });
    });
  });
}
