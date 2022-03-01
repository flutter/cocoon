// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/request_handlers/refresh_chromebot_status.dart';
import 'package:cocoon_service/src/service/config.dart';
import 'package:cocoon_service/src/service/datastore.dart';
import 'package:cocoon_service/src/service/luci.dart';
import 'package:gcloud/db.dart';
import 'package:googleapis/bigquery/v2.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/bigquery/fake_tabledata_resource.dart';
import '../src/datastore/fake_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('RefreshChromebotStatus', () {
    late FakeConfig config;
    late ApiRequestHandlerTester tester;
    late MockLuciService mockLuciService;
    late RefreshChromebotStatus handler;
    late MockClient branchHttpClient;
    late FakeScheduler scheduler;
    late FakeTabledataResource tabledataResource;
    late MockLuciBuildService mockLuciBuildService;

    late Commit commit;
    late List<LuciBuilder> builders;

    setUp(() async {
      tabledataResource = FakeTabledataResource();
      config = FakeConfig(tabledataResource: tabledataResource);
      config.flutterBranchesValue = <String>[Config.defaultBranch(Config.flutterSlug)];
      tester = ApiRequestHandlerTester();
      mockLuciService = MockLuciService();
      mockLuciBuildService = MockLuciBuildService();
      branchHttpClient = MockClient((_) async => http.Response('', 200));
      scheduler = FakeScheduler(
        config: config,
        ciYaml: exampleConfig,
      );
      handler = RefreshChromebotStatus(
        config,
        FakeAuthenticationProvider(),
        mockLuciBuildService,
        luciServiceProvider: (_) => mockLuciService,
        datastoreProvider: (DatastoreDB db) => DatastoreService(config.db, 5),
        branchHttpClientProvider: () => branchHttpClient,
        gitHubBackoffCalculator: (int attempt) => Duration.zero,
        scheduler: scheduler,
      );
      commit = Commit(
        key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/master/abc'),
        sha: 'abc',
        branch: Config.defaultBranch(Config.flutterSlug),
        repository: Config.flutterSlug.fullName,
      );
      builders = await scheduler.getPostSubmitBuilders(exampleConfig);
    });

    group('without builder rerun', () {
      setUp(() {
        when(mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          luciTask: anyNamed('luciTask'),
          retries: anyNamed('retries'),
          datastore: anyNamed('datastore'),
          isFlaky: false,
        )).thenAnswer((_) => Future<bool>.value(false));
      });

      test('do not update task status when SHA does not match', () async {
        final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          name: 'Linux A',
          status: Task.statusNew,
        );
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'def': <LuciTask>[
                const LuciTask(
                    commitSha: 'def',
                    ref: 'refs/heads/master',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('do not update task status when commitSha/ref is unknown', () async {
        final Task task = Task(
          key: commit.key.append(Task, id: 123),
          commitKey: commit.key,
          name: 'Linux A',
          status: Task.statusNew,
        );
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;

        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'def': <LuciTask>[
                const LuciTask(
                    commitSha: 'unknown',
                    ref: 'unknown',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('do not update task status when branch does not match', () async {
        final Commit branchCommit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/test/abc'),
          sha: 'abc',
          branch: 'test',
          repository: Config.flutterSlug.fullName,
        );
        final Task task = Task(
          key: branchCommit.key.append(Task, id: 123),
          commitKey: branchCommit.key,
          name: 'Linux A',
          status: Task.statusNew,
        );
        config.db.values[branchCommit.key] = branchCommit;
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                    commitSha: 'abc',
                    ref: 'refs/heads/master',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusNew);
      });

      test('update task status and buildNumber when buildNumberList does not match', () async {
        final Task task =
            Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, name: 'Linux A', status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                    commitSha: 'abc',
                    ref: 'refs/heads/master',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
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
        final Task task =
            Task(key: commit.key.append(Task, id: 123), commitKey: commit.key, name: 'Linux A', status: Task.statusNew);
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                    commitSha: 'abc',
                    ref: 'refs/heads/master',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        await tester.get(handler);
        final TableDataList tableDataList = await tabledataResource.list('test', 'test', 'test');
        expect(tableDataList.totalRows, '1');
      });

      test('update task status and buildNumber when status does not match', () async {
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            name: 'Linux A',
            status: Task.statusNew,
            buildNumberList: '1');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                    commitSha: 'abc',
                    ref: 'refs/heads/master',
                    status: Task.statusSucceeded,
                    buildNumber: 1,
                    builderName: 'abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
      });

      test('update task status with latest status when multilple reruns exist', () async {
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            name: 'Linux A',
            status: Task.statusNew,
            buildNumberList: '1');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
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
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumberList, '1,2');
      });

      test('update task status with latest status when ci yaml targets exist', () async {
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            name: 'Linux A',
            builderName: 'Linux A',
            status: Task.statusNew,
            buildNumberList: '1');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        scheduler.ciYaml = exampleConfig;
        final List<LuciBuilder> builders =
            scheduler.ciYaml!.postsubmitTargets.map((Target target) => LuciBuilder.fromTarget(target)).toList();
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                  commitSha: 'abc',
                  ref: 'refs/heads/master',
                  status: Task.statusSucceeded,
                  buildNumber: 2,
                  builderName: 'Linux A',
                ),
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
        expect(task.buildNumberList, '2');
      });

      test('update task status for non master branch', () async {
        final Commit branchCommit = Commit(
          key: config.db.emptyKey.append(Commit, id: 'flutter/flutter/test/def'),
          sha: 'def',
          branch: 'test',
          repository: Config.flutterSlug.fullName,
        );
        final Task task = Task(
            key: branchCommit.key.append(Task, id: 456),
            commitKey: branchCommit.key,
            name: 'Linux A',
            status: Task.statusNew);
        config.flutterBranchesValue = <String>[Config.defaultBranch(Config.flutterSlug), 'test'];
        config.db.values[commit.key] = commit;
        config.db.values[branchCommit.key] = branchCommit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'def': <LuciTask>[
                const LuciTask(
                    commitSha: 'def',
                    ref: 'refs/heads/master',
                    status: Task.statusFailed,
                    buildNumber: 1,
                    builderName: 'abc'),
              ],
            }
        };
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> testLuciTasks = {
          for (LuciBuilder builder in builders)
            BranchLuciBuilder(luciBuilder: builder, branch: 'test'): <String, List<LuciTask>>{
              'def': <LuciTask>[
                const LuciTask(
                    commitSha: 'def',
                    ref: 'refs/heads/test',
                    status: Task.statusSucceeded,
                    buildNumber: 2,
                    builderName: 'abc')
              ],
            }
        };
        luciTasks.addAll(testLuciTasks);
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
            .thenAnswer((Invocation invocation) {
          return Future<Map<BranchLuciBuilder, Map<String, List<LuciTask>>>>.value(luciTasks);
        });

        expect(task.status, Task.statusNew);
        await tester.get(handler);
        expect(task.status, Task.statusSucceeded);
        expect(task.luciBucket, 'luci.flutter.prod');
      });
    });

    group('with builder rerun', () {
      setUp(() {
        when(mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          luciTask: anyNamed('luciTask'),
          retries: anyNamed('retries'),
          datastore: anyNamed('datastore'),
          isFlaky: false,
        )).thenAnswer((_) => Future<bool>.value(true));
      });

      test('rerun Mac builder when hiting recipe infra failure', () async {
        config.maxTaskRetriesValue = 2;
        final Task task = Task(
            key: commit.key.append(Task, id: 123),
            commitKey: commit.key,
            name: 'Linux A',
            status: Task.statusInProgress,
            buildNumberList: '1',
            attempts: 0,
            builderName: 'Mac abc');
        config.db.values[commit.key] = commit;
        config.db.values[task.key] = task;
        final Map<BranchLuciBuilder, Map<String, List<LuciTask>>> luciTasks = {
          for (LuciBuilder builder in <LuciBuilder>[
            LuciBuilder(name: 'Mac abc', repo: Config.flutterSlug.name, taskName: 'def', flaky: false)
          ])
            BranchLuciBuilder(luciBuilder: builder, branch: 'master'): <String, List<LuciTask>>{
              'abc': <LuciTask>[
                const LuciTask(
                    commitSha: 'abc',
                    ref: 'refs/heads/master',
                    status: Task.statusInfraFailure,
                    buildNumber: 1,
                    builderName: 'Mac abc')
              ],
            }
        };
        when(mockLuciService.getBranchRecentTasks(builders: anyNamed('builders'), requireTaskName: true))
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
