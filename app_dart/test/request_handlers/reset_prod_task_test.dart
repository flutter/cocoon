// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handlers/reset_prod_task.dart';
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

final Build startedBuild = generateBuild(999, name: 'Mac', status: Status.started);
final Build scheduledBuild = generateBuild(999, name: 'Mac', status: Status.scheduled);
final Build succeededBuild = generateBuild(999, name: 'Mac', status: Status.success);

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

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      clientContext = FakeClientContext();
      clientContext.isDevelopmentEnvironment = false;
      keyHelper = FakeKeyHelper(applicationContext: clientContext.applicationContext);
      config = FakeConfig(dbValue: datastoreDB, keyHelperValue: keyHelper);
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciBuildService = MockLuciBuildService();
      when(mockLuciBuildService.checkRerunBuilder(
        commit: anyNamed('commit'),
        datastore: anyNamed('datastore'),
        target: anyNamed('target'),
        task: anyNamed('task'),
        tags: anyNamed('tags'),
      )).thenAnswer((_) async => true);
      handler = ResetProdTask(
        config,
        FakeAuthenticationProvider(clientContext: clientContext),
        mockLuciBuildService,
        FakeScheduler(
          config: config,
          ciYaml: exampleConfig,
        ),
      );
      tester.requestData = <String, dynamic>{
        'Key':
            'ag9zfnR2b2xrZXJ0LXRlc3RyWAsSCUNoZWNrbGlzdCI4Zmx1dHRlci9mbHV0dGVyLzdkMDMzNzE2MTBjMDc5NTNhNWRlZjUwZDUwMDA0NTk0MWRlNTE2YjgMCxIEVGFzaxiAgIDg5eGTCAw'
      };
      commit = Commit(
        key: config.db.emptyKey.append(
          Commit,
          id: 'flutter/flutter/7d03371610c07953a5def50d500045941de516b8',
        ),
        repository: 'flutter/flutter',
        sha: '7d03371610c07953a5def50d500045941de516b8',
      );
    });
    test('Schedule rerun', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: 4590522719010816),
        commitKey: commit.key,
        attempts: 0,
        status: 'Failed',
        name: 'Windows A',
      );
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      await tester.post(handler);
      final List<dynamic> captured = verify(mockLuciBuildService.checkRerunBuilder(
        commit: captureAnyNamed('commit'),
        datastore: anyNamed('datastore'),
        target: anyNamed('target'),
        task: captureAnyNamed('task'),
        tags: captureAnyNamed('tags'),
      )).captured;
      final Commit capturedCommit = captured.first as Commit;
      final Task capturedTask = captured[1] as Task;
      final Map<String, List<String>> capturedTags = captured.last as Map<String, List<String>>;
      expect(capturedCommit.sha, '7d03371610c07953a5def50d500045941de516b8');
      expect(capturedTask.name, 'Windows A');
      expect(
        capturedTags,
        <String, List<String>>{
          'triggered_by': <String>['abc@gmail.com'],
          'trigger_type': <String>['manual']
        },
      );
      expect(capturedTask.attempts, equals(1));
    });

    test('Re-schedule without all the parameters raises exception', () async {
      tester.requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Fails if task already scheduled', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          name: 'Linux A',
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any)).thenAnswer((_) async {
        return <Build>[scheduledBuild];
      });
      expect(() => tester.post(handler), throwsA(isA<ConflictException>()));
    });

    test('Fails if task already running', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          name: 'Linux A',
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any)).thenAnswer((_) async {
        return <Build>[startedBuild];
      });
      expect(() => tester.post(handler), throwsA(isA<ConflictException>()));
    });

    test('Fails if task already succeeded', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          name: 'Linux A',
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any)).thenAnswer((_) async {
        return <Build>[succeededBuild];
      });
      expect(() => tester.post(handler), throwsA(isA<ConflictException>()));
    });

    test('Fails if commit does not exist', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          name: 'Linux A',
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      expect(() => tester.post(handler), throwsA(isA<KeyNotFoundException>()));
    });
  });
}
