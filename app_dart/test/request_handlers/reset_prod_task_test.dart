// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/model/luci/buildbucket.dart';
import 'package:cocoon_service/src/request_handlers/reset_prod_task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
import '../src/datastore/fake_datastore.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/utilities/mocks.dart';

void main() {
  group('ResetProdTask', () {
    FakeClientContext clientContext;
    ResetProdTask handler;
    FakeConfig config;
    MockLuciBuildService mockLuciBuildService;
    FakeAuthenticatedContext authContext;
    ApiRequestHandlerTester tester;
    Commit commit;
    Build startedBuild;
    Build scheduledBuild;
    Build succeededBuild;

    setUp(() {
      final FakeDatastoreDB datastoreDB = FakeDatastoreDB();
      config = FakeConfig(dbValue: datastoreDB);
      clientContext = FakeClientContext();
      clientContext.isDevelopmentEnvironment = false;
      authContext = FakeAuthenticatedContext(clientContext: clientContext);
      tester = ApiRequestHandlerTester(context: authContext);
      mockLuciBuildService = MockLuciBuildService();
      handler = ResetProdTask(
        config,
        FakeAuthenticationProvider(clientContext: clientContext),
        mockLuciBuildService,
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
        sha: '7d03371610c07953a5def50d500045941de516b8',
      );
      startedBuild = const Build(
        id: 999,
        builderId: BuilderId(
          project: 'flutter',
          bucket: 'prod',
          builder: 'Mac',
        ),
        status: Status.started,
      );
      scheduledBuild = const Build(
        id: 999,
        builderId: BuilderId(
          project: 'flutter',
          bucket: 'prod',
          builder: 'Mac',
        ),
        status: Status.scheduled,
      );
      succeededBuild = const Build(
        id: 999,
        builderId: BuilderId(
          project: 'flutter',
          bucket: 'prod',
          builder: 'Mac',
        ),
        status: Status.success,
      );
    });
    test('Schedule new task', () async {
      final Task task = Task(
        key: commit.key.append(Task, id: 4590522719010816),
        commitKey: commit.key,
        attempts: 0,
        status: 'Failed',
        name: 'windows_bot',
      );
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.rescheduleProdBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      expect(task.attempts, equals(1));
    });

    test('Re-schedule existing task', () async {
      Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.rescheduleProdBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Re-schedule existing task even though builderName is missing in the task', () async {
      Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          name: 'windows_bot',
          status: 'Failed');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.rescheduleProdBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Does nothing if task already passed', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          status: 'Succeeded',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      await tester.post(handler);
      verifyNever(mockLuciBuildService.rescheduleProdBuild(
        commitSha: captureAnyNamed('commitSha'),
        builderName: captureAnyNamed('builderName'),
      ));
    });

    test('Fails if task already scheduled', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
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

    test('Fails if task already succeded', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
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
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      config.db.values[commit.key] = commit;
      when(mockLuciBuildService.getProdBuilds(any, any, any, any)).thenAnswer((_) async {
        return <Build>[];
      });
      await tester.post(handler);
      expect(
        verify(mockLuciBuildService.rescheduleProdBuild(
          commitSha: captureAnyNamed('commitSha'),
          builderName: captureAnyNamed('builderName'),
        )).captured,
        <dynamic>['7d03371610c07953a5def50d500045941de516b8', 'Windows'],
      );
      task = config.db.values[task.key] as Task;
      expect(task.attempts, equals(1));
    });

    test('Fails if task does not exist', () async {
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('Fails if commit does not exist', () async {
      final Task task = Task(
          key: commit.key.append(Task, id: 4590522719010816),
          commitKey: commit.key,
          attempts: 0,
          status: 'Failed',
          builderName: 'Windows');
      config.db.values[task.key] = task;
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });
  });
}
