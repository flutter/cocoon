// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/service/fake_scheduler.dart';
import '../src/utilities/entity_generators.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('ResetProdTask', () {
    FakeClientContext clientContext;
    late ResetProdTask handler;
    late FakeConfig config;
    FakeKeyHelper keyHelper;
    late MockLuciBuildService mockLuciBuildService;
    late ApiRequestHandlerTester tester;
    late Commit commit;
    late Task task;

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      clientContext = FakeClientContext();
      clientContext.isDevelopmentEnvironment = false;
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      config = FakeConfig(
        dbValue: datastoreDB,
        keyHelperValue: keyHelper,
        supportedBranchesValue: <String>[
          Config.defaultBranch(Config.flutterSlug),
        ],
      );
      final FakeAuthenticatedContext authContext = FakeAuthenticatedContext(clientContext: clientContext);
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciBuildService = MockLuciBuildService();
      handler = ResetProdTask(
        config: config,
        authenticationProvider: FakeAuthenticationProvider(clientContext: clientContext),
        luciBuildService: mockLuciBuildService,
        scheduler: FakeScheduler(
          config: config,
          ciYaml: exampleConfig,
        ),
      );
      commit = generateCommit(1);
      task = generateTask(
        1,
        name: 'Linux A',
        parent: commit,
        status: Task.statusFailed,
      );
      tester.requestData = <String, dynamic>{
        'Key': config.keyHelper.encode(task.key),
      };

      when(
        mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          datastore: anyNamed('datastore'),
          task: anyNamed('task'),
          target: anyNamed('target'),
          tags: anyNamed('tags'),
          ignoreChecks: anyNamed('ignoreChecks'),
        ),
      ).thenAnswer((_) async => true);
    });
    test('Schedule new task', () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(await tester.post(handler), Body.empty);
    });

    test('Re-schedule existing task', () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(await tester.post(handler), Body.empty);
    });

    test('Re-schedule passing all the parameters', () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      tester.requestData = <String, dynamic>{
        'Commit': commit.sha,
        'Task': task.name,
        'Repo': commit.slug.name,
      };
      expect(await tester.post(handler), Body.empty);
      verify(
        mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          datastore: anyNamed('datastore'),
          task: anyNamed('task'),
          target: anyNamed('target'),
          tags: anyNamed('tags'),
          ignoreChecks: true,
        ),
      ).called(1);
    });

    test('Rerun all failed tasks when task name is all', () async {
      final Task taskA = generateTask(2, name: 'Linux A', parent: commit, status: Task.statusFailed);
      final Task taskB = generateTask(3, name: 'Mac A', parent: commit, status: Task.statusFailed);
      config.db.values[taskA.key] = taskA;
      config.db.values[taskB.key] = taskB;
      config.db.values[commit.key] = commit;
      tester.requestData = <String, dynamic>{
        'Commit': commit.sha,
        'Task': 'all',
        'Repo': commit.slug.name,
      };
      expect(await tester.post(handler), Body.empty);
      verify(
        mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          datastore: anyNamed('datastore'),
          task: anyNamed('task'),
          target: anyNamed('target'),
          tags: anyNamed('tags'),
          ignoreChecks: false,
        ),
      ).called(2);
    });

    test('Rerun all runs nothing when everything is passed', () async {
      final Task task = generateTask(2, name: 'Windows A', parent: commit, status: Task.statusSucceeded);
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      tester.requestData = <String, dynamic>{
        'Commit': commit.sha,
        'Task': 'all',
        'Repo': commit.slug.name,
      };
      expect(await tester.post(handler), Body.empty);
      verifyNever(
        mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          datastore: anyNamed('datastore'),
          task: anyNamed('task'),
          target: anyNamed('target'),
          tags: anyNamed('tags'),
          ignoreChecks: false,
        ),
      );
    });

    test('Re-schedule without any parameters raises exception', () async {
      tester.requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Re-schedule existing task even though taskName is missing in the task', () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(await tester.post(handler), Body.empty);
    });

    test('Fails if task is not rerun', () async {
      when(
        mockLuciBuildService.checkRerunBuilder(
          commit: anyNamed('commit'),
          datastore: anyNamed('datastore'),
          task: anyNamed('task'),
          target: anyNamed('target'),
          tags: anyNamed('tags'),
          ignoreChecks: true,
        ),
      ).thenAnswer((_) async => false);
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(() => tester.post(handler), throwsA(isA<InternalServerError>()));
    });

    test('Fails if commit does not exist', () async {
      config.db.values[task.key] = task;
      expect(() => tester.post(handler), throwsA(isA<StateError>()));
    });
  });
}
