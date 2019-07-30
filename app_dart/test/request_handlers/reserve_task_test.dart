// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/reserve_task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:cocoon_service/src/service/access_token_provider.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';

void main() {
  FakeConfig config;
  MockTaskProvider taskProvider;
  MockReservationProvider reservationProvider;
  MockAccessTokenProvider accessTokenProvider;
  Agent agent;

  setUp(() {
    config = FakeConfig();
    taskProvider = MockTaskProvider();
    reservationProvider = MockReservationProvider();
    accessTokenProvider = MockAccessTokenProvider();
    agent = Agent(key: config.db.emptyKey.append(Agent, id: 'aid'), agentId: 'aid');
  });

  group('ReserveTask', () {
    ApiRequestHandlerTester tester;
    ReserveTask handler;

    setUp(() {
      tester = ApiRequestHandlerTester();
      handler = ReserveTask(
        config,
        FakeAuthenticationProvider(),
        taskProvider: taskProvider,
        reservationProvider: reservationProvider,
        accessTokenProvider: accessTokenProvider,
      );
    });

    test('throws 400 if no agent in context or request', () {
      tester.requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('throws 400 if context and request disagree on agent id', () {
      tester
        ..context = FakeAuthenticatedContext(agent: agent)
        ..requestData = <String, dynamic>{'AgentID': 'bar'};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    test('throws 400 if context has agent but request does not', () {
      tester
        ..context = FakeAuthenticatedContext(agent: agent)
        ..requestData = <String, dynamic>{};
      expect(() => tester.post(handler), throwsA(isA<BadRequestException>()));
    });

    group('when request is well-formed', () {
      setUp(() {
        tester
          ..context = FakeAuthenticatedContext(agent: agent)
          ..requestData = <String, dynamic>{'AgentID': 'aid'};
      });

      test('returns empty response if no task available', () async {
        when(taskProvider.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(null);
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task, isNull);
        expect(response.commit, isNull);
        expect(response.accessToken, isNull);
        verify(taskProvider.findNextTask(agent)).called(1);
      });

      test('returns full response if task is available', () async {
        final Task task = Task(name: 'foo_test');
        final Commit commit = Commit(sha: 'abc');
        when(taskProvider.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(FullTask(task, commit));
        });
        when(accessTokenProvider.createAccessToken(
          any,
          serviceAccount: anyNamed('serviceAccount'),
          scopes: anyNamed('scopes'),
        )).thenAnswer((Invocation invocation) {
          return Future<AccessToken>.value(AccessToken('type', 'data', DateTime.utc(2019)));
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task.name, 'foo_test');
        expect(response.commit.sha, 'abc');
        expect(response.accessToken.data, 'data');
        verify(taskProvider.findNextTask(agent)).called(1);
        verify(reservationProvider.secureReservation(task, 'aid')).called(1);
        verify(accessTokenProvider.createAccessToken(
          any,
          serviceAccount: anyNamed('serviceAccount'),
          scopes: anyNamed('scopes'),
        )).called(1);
      });

      test('retries until reservation can be secured', () async {
        final Task task = Task(name: 'foo_test');
        final Commit commit = Commit(sha: 'abc');
        when(taskProvider.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(FullTask(task, commit));
        });
        int reservationAttempt = 0;
        when(reservationProvider.secureReservation(task, 'aid'))
            .thenAnswer((Invocation invocation) {
          if (reservationAttempt == 0) {
            reservationAttempt += 1;
            throw const ReservationLostException();
          } else {
            return Future<void>.value();
          }
        });
        when(accessTokenProvider.createAccessToken(
          any,
          serviceAccount: anyNamed('serviceAccount'),
          scopes: anyNamed('scopes'),
        )).thenAnswer((Invocation invocation) {
          return Future<AccessToken>.value(AccessToken('type', 'data', DateTime.utc(2019)));
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task.name, 'foo_test');
        expect(response.commit.sha, 'abc');
        expect(response.accessToken.data, 'data');
        verify(taskProvider.findNextTask(agent)).called(2);
        verify(reservationProvider.secureReservation(task, 'aid')).called(2);
        verify(accessTokenProvider.createAccessToken(
          any,
          serviceAccount: anyNamed('serviceAccount'),
          scopes: anyNamed('scopes'),
        )).called(1);
      });

      test('Looks up agent if not provided in the context', () async {
        tester.context = FakeAuthenticatedContext();
        config.db.values[agent.key] = agent;
        when(taskProvider.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(null);
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task, isNull);
        expect(response.commit, isNull);
        expect(response.accessToken, isNull);
        verify(taskProvider.findNextTask(agent)).called(1);
      });
    });
  });

  group('TaskProvider', () {
    int taskIdCounter;
    Agent agent;
    Commit commit;

    TaskProvider taskProvider;

    Task newTask() {
      final String taskId = 'test_${taskIdCounter++}';
      return Task(
        key: commit.key.append(Task, id: taskId),
        name: taskId,
        status: Task.statusNew,
        stageName: 'devicelab',
        attempts: 0,
        isFlaky: false,
        requiredCapabilities: <String>['linux/android'],
      );
    }

    setUp(() {
      taskIdCounter = 1;
      agent = Agent(agentId: 'aid', capabilities: <String>['linux/android']);
      commit = Commit(key: config.db.emptyKey.append(Commit, id: 'abc'), sha: 'abc');
      taskProvider = TaskProvider(config);
    });

    test('if no commits in query returns null', () async {
      expect(await taskProvider.findNextTask(agent), isNull);
    });

    group('if commits in query', () {
      void setTaskResults(List<Task> tasks) {
        for (Task task in tasks) {
          config.db.values[task.key] = task;
        }
      }

      setUp(() {
        config.db.values[commit.key] = commit;
      });

      test('throws if task has no required capabilities', () async {
        setTaskResults(<Task>[
          newTask()..requiredCapabilities.clear(),
        ]);
        expect(taskProvider.findNextTask(agent), throwsA(isA<InvalidTaskException>()));
      });

      test('returns available task', () async {
        setTaskResults(<Task>[
          newTask()..name = 'a',
        ]);
        final FullTask result = await taskProvider.findNextTask(agent);
        expect(result.task.name, 'a');
        expect(result.commit, commit);
      });

      test('skips tasks where agent capabilities are insufficient', () async {
        setTaskResults(<Task>[
          newTask()..requiredCapabilities[0] = 'mac/ios',
        ]);
        expect(await taskProvider.findNextTask(agent), isNull);
      });

      test('skips tasks that are not managed by devicelab', () async {
        setTaskResults(<Task>[
          newTask()..stageName = 'cirrus',
        ]);
        expect(await taskProvider.findNextTask(agent), isNull);
      });

      test('only considers tasks with status "new"', () async {
        setTaskResults(<Task>[
          newTask()..status = Task.statusInProgress,
          newTask()..status = Task.statusSucceeded,
          newTask()..status = Task.statusFailed,
        ]);
        expect(await taskProvider.findNextTask(agent), isNull);
      });

      test('picks the task with fewest attempts first', () async {
        setTaskResults(<Task>[
          newTask()
            ..name = 'c'
            ..attempts = 3,
          newTask()
            ..name = 'a'
            ..attempts = 1,
          newTask()
            ..name = 'b'
            ..attempts = 2,
        ]);
        final FullTask result = await taskProvider.findNextTask(agent);
        expect(result.task.name, 'a');
      });
    });
  });
}

class MockTaskProvider extends Mock implements TaskProvider {}

class MockReservationProvider extends Mock implements ReservationProvider {}

class MockAccessTokenProvider extends Mock implements AccessTokenProvider {}
