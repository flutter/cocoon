// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handlers/reset_prod_task.dart';
import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:gcloud/db.dart';
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
    FakeAuthenticatedContext authContext;
    late ApiRequestHandlerTester tester;
    late Commit commit;
    late Task task;

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      clientContext = FakeClientContext();
      clientContext.isDevelopmentEnvironment = false;
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      config = FakeConfig(dbValue: datastoreDB, keyHelperValue: keyHelper);
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciBuildService = MockLuciBuildService();
      handler = ResetProdTask(
        config,
        FakeAuthenticationProvider(clientContext: clientContext),
        mockLuciBuildService,
        FakeScheduler(
          config: config,
          ciYaml: exampleConfig,
        ),
      );
      commit = generateCommit(1);
      task = generateTask(1, name: 'Linux A', parent: commit, status: Task.statusFailed,);
      tester.requestData = <String, dynamic>{
        'Key': config.keyHelper.encode(task.key),
      };

      when(mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        datastore: anyNamed('datastore'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => true);
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
      tester.requestData = <String, dynamic>{
        'Commit': 'commitSha',
        'Builder': 'Windows',
        'Repo': 'engine',
      };
      expect(await tester.post(handler), Body.empty);
    });

    test('Re-schedule without any parameters raises exception', () async {
      tester.requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Re-schedule existing task even though builderName is missing in the task', () async {
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(await tester.post(handler), Body.empty);
    });

    test('Fails if task is not rerun', () async {
      when(mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        datastore: anyNamed('datastore'),
        task: anyNamed('task'),
        target: anyNamed('target'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => false);
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      expect(() => tester.post(handler), throwsA(isA<ConflictException>()));
    });

    test('Fails if commit does not exist', () async {
      config.db.values[task.key] = task;
      expect(() => tester.post(handler), throwsA(isA<KeyNotFoundException>()));
    });
  });
}
