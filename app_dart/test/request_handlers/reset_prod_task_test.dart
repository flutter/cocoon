// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
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
    test('Schedule new task', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: 4590522719010816),
        commitKey: commit.key,
        attempts: 0,
        status: 'Failed',
        name: 'Windows A',
      );
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'prod',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: anyNamed('repo'),
          properties: anyNamed('properties'),
          tags: anyNamed('tags'),
          bucket: 'prod',
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows A'],
      );
      expect(task.attempts, equals(1));
    });

    test('Re-schedule existing task', () async {
      Task task = Task(
        key: commit.key.append(Task, id: 4590522719010816),
        commitKey: commit.key,
        attempts: 0,
        name: 'Linux A',
        status: 'Failed',
        builderName: 'Windows',
      );
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'prod',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: anyNamed('repo'),
          properties: anyNamed('properties'),
          tags: anyNamed('tags'),
          bucket: 'prod',
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Re-schedule existing flaky task in staging', () async {
      Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          name: 'Linux A',
          status: 'Failed',
          builderName: 'Windows',
          isFlaky: true);
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'staging',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: anyNamed('repo'),
          properties: anyNamed('properties'),
          tags: anyNamed('tags'),
          bucket: 'staging',
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Re-schedule passing all the parameters', () async {
      tester.requestData = <String, dynamic>{
        'Commit': 'commitSha',
        'Builder': 'Windows',
        'Repo': 'engine',
        'Properties': <String, dynamic>{'myproperty': true},
      };
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'prod',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: captureAnyNamed('repo'),
          properties: captureAnyNamed('properties'),
          tags: captureAnyNamed('tags'),
          bucket: 'prod',
        )).captured,
        <dynamic>[
          'commitSha',
          'Windows',
          'engine',
          <String, dynamic>{'myproperty': true},
          <String, List<String>>{
            'triggered_by': <String>['abc@gmail.com'],
            'trigger_type': <String>['manual']
          },
        ],
      );
    });

    test('Using curl with flutter repo raises exception', () async {
      tester.requestData = <String, dynamic>{
        'Commit': 'commitSha',
        'Builder': 'Windows',
        'Repo': 'flutter',
      };
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Re-schedule without all the parameters raises exception', () async {
      tester.requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Re-schedule existing task even though builderName is missing in the task', () async {
      Task task = Task(
        key: commit.key.append(Task, id: 4590522719010816),
        commitKey: commit.key,
        attempts: 0,
        name: 'Windows A',
        status: 'Failed',
      );
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'prod',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: anyNamed('repo'),
          properties: anyNamed('properties'),
          tags: anyNamed('tags'),
          bucket: 'prod',
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows A'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Does nothing if task already passed', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          name: 'Linux A',
          status: 'Succeeded',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      await tester.post(handler);
      verifyNever(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: captureAnyNamed('commitSha'),
        builderName: captureAnyNamed('builderName'),
      ));
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
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
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
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
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
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[succeededBuild];
      });
      expect(() => tester.post(handler), throwsA(isA<ConflictException>()));
    });

    test('Reschedules if build is empty', () async {
      Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          name: 'Linux A',
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      when(mockLuciBuildService.reschedulePostsubmitBuild(
        commitSha: anyNamed('commitSha'),
        builderName: anyNamed('builderName'),
        repo: anyNamed('repo'),
        properties: anyNamed('properties'),
        tags: anyNamed('tags'),
        bucket: 'prod',
      )).thenAnswer((_) async => generateBuild(123));
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.reschedulePostsubmitBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
          repo: anyNamed('repo'),
          properties: anyNamed('properties'),
          tags: anyNamed('tags'),
          bucket: 'prod',
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
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
