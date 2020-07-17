// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/reserve_task.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/api_request_handler_tester.dart';
import '../src/request_handling/fake_authentication.dart';
import '../src/utilities/mocks.dart';

void main() {
  FakeConfig config;
  MockTaskService taskService;
  MockReservationService reservationService;
  MockAccessTokenService accessTokenService;
  Agent agent;

  setUp(() {
    config = FakeConfig();
    taskService = MockTaskService();
    reservationService = MockReservationService();
    accessTokenService = MockAccessTokenService();
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
        taskServiceProvider: (_) => taskService,
        reservationServiceProvider: (_) => reservationService,
        accessTokenServiceProvider: (_) => accessTokenService,
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
        when(taskService.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(null);
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task, isNull);
        expect(response.commit, isNull);
        expect(response.accessToken, isNull);
        verify(taskService.findNextTask(agent)).called(1);
      });

      test('returns full response if task is available', () async {
        final Task task = Task(name: 'foo_test');
        final Commit commit = Commit(sha: 'abc');
        when(taskService.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(FullTask(task, commit));
        });
        when(accessTokenService.createAccessToken(scopes: anyNamed('scopes'))).thenAnswer((Invocation invocation) {
          return Future<AccessToken>.value(AccessToken('type', 'data', DateTime.utc(2019)));
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task.name, 'foo_test');
        expect(response.commit.sha, 'abc');
        expect(response.accessToken.data, 'data');
        verify(taskService.findNextTask(agent)).called(1);
        verify(reservationService.secureReservation(task, 'aid')).called(1);
        verify(accessTokenService.createAccessToken(scopes: anyNamed('scopes'))).called(1);
      });

      test('Looks up agent if not provided in the context', () async {
        tester.context = FakeAuthenticatedContext();
        config.db.values[agent.key] = agent;
        when(taskService.findNextTask(agent)).thenAnswer((Invocation invocation) {
          return Future<FullTask>.value(null);
        });
        final ReserveTaskResponse response = await tester.post(handler);
        expect(response.task, isNull);
        expect(response.commit, isNull);
        expect(response.accessToken, isNull);
        verify(taskService.findNextTask(agent)).called(1);
      });
    });
  });
}
