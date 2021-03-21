// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/agent.dart';
import 'package:cocoon_service/src/model/appengine/commit.dart';
import 'package:cocoon_service/src/model/appengine/task.dart';
import 'package:cocoon_service/src/request_handlers/reserve_task.dart';
import 'package:cocoon_service/src/service/reservation_provider.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/datastore/fake_config.dart';
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

  group('ReservationService', () {
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
      tester
        ..context = FakeAuthenticatedContext(agent: agent)
        ..requestData = <String, dynamic>{'AgentID': 'aid'};
    });

    test('retries until reservation can be secured', () async {
      final Task task = Task(name: 'foo_test');
      final Commit commit = Commit(sha: 'abc');
      when(taskService.findNextTask(agent, config)).thenAnswer((Invocation invocation) {
        return Future<FullTask>.value(FullTask(task, commit));
      });
      int reservationAttempt = 0;
      when(reservationService.secureReservation(task, 'aid')).thenAnswer((Invocation invocation) {
        if (reservationAttempt == 0) {
          reservationAttempt += 1;
          throw const ReservationLostException();
        } else {
          return Future<void>.value();
        }
      });
      when(accessTokenService.createAccessToken(
        scopes: anyNamed('scopes'),
      )).thenAnswer((Invocation invocation) {
        return Future<AccessToken>.value(AccessToken('type', 'data', DateTime.utc(2019)));
      });
      final ReserveTaskResponse response = await tester.post(handler);
      expect(response.task.name, 'foo_test');
      expect(response.commit.sha, 'abc');
      expect(response.accessToken.data, 'data');
      verify(taskService.findNextTask(agent, config)).called(2);
      verify(reservationService.secureReservation(task, 'aid')).called(2);
      verify(accessTokenService.createAccessToken(scopes: anyNamed('scopes'))).called(1);
    });
  });
}
