// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/agent.dart';

void main() {
  group('AgentState', () {
    AgentState agentState;
    MockCocoonService mockService;

    setUp(() {
      mockService = MockCocoonService();
      agentState = AgentState(cocoonServiceValue: mockService);

      when(mockService.fetchAgentStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<Agent>>>.value(
              CocoonResponse<List<Agent>>()..data = <Agent>[Agent()]));
    });

    testWidgets('timer should periodically fetch updates',
        (WidgetTester tester) async {
      agentState.startFetchingStateUpdates();

      // startFetching immediately starts fetching results
      verify(mockService.fetchAgentStatuses()).called(1);

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(agentState.refreshRate * 2);
      verify(mockService.fetchAgentStatuses()).called(greaterThan(1));

      // Tear down fails to cancel the timer before the test is over
      agentState.dispose();
    });

    testWidgets('multiple start updates should not change the timer',
        (WidgetTester tester) async {
      agentState.startFetchingStateUpdates();
      final Timer refreshTimer = agentState.refreshTimer;

      // This second run should not change the refresh timer
      agentState.startFetchingStateUpdates();

      expect(refreshTimer, equals(agentState.refreshTimer));

      // Since startFetching sends out requests on start, we need to wait
      // for them to finish before disposing of the state.
      await tester.pumpAndSettle();

      // Tear down fails to cancel the timer before the test is over
      agentState.dispose();
    });

    testWidgets('fetching agents error should not delete previous data',
        (WidgetTester tester) async {
      agentState.startFetchingStateUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(agentState.refreshRate * 2);
      final List<Agent> originalData = agentState.agents;

      when(mockService.fetchAgentStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<Agent>>>.value(
              CocoonResponse<List<Agent>>()..error = 'error'));

      await tester.pump(agentState.refreshRate * 2);
      verify(mockService.fetchAgentStatuses()).called(greaterThan(1));

      expect(agentState.agents, originalData);
      expect(
          agentState.errors.message, AgentState.errorMessageFetchingStatuses);

      // Tear down fails to cancel the timer before the test is over
      agentState.dispose();
    });

    test('authorize agent calls cocoon service', () async {
      when(mockService.authorizeAgent(any, any))
          .thenAnswer((_) async => CocoonResponse<String>()..data = 'abc123');
      verifyNever(mockService.authorizeAgent(any, any));

      await agentState.authorizeAgent(Agent());

      verify(mockService.authorizeAgent(any, any)).called(1);
    });

    test('reserve task calls cocoon service', () async {
      verifyNever(mockService.reserveTask(any, any));

      await agentState.reserveTask(Agent());

      verify(mockService.reserveTask(any, any)).called(1);
    });

    test('auth functions call auth service', () async {
      final MockGoogleSignInService mockSignInService =
          MockGoogleSignInService();
      agentState = AgentState(authServiceValue: mockSignInService);

      verifyNever(mockSignInService.signIn());
      verifyNever(mockSignInService.signOut());

      await agentState.signIn();
      verify(mockSignInService.signIn()).called(1);
      verifyNever(mockSignInService.signOut());

      await agentState.signOut();
      verify(mockSignInService.signOut()).called(1);
    });
  });
}

/// CocoonService for checking interactions.
class MockCocoonService extends Mock implements FakeCocoonService {}

/// GoogleAuthenticationService for checking interactions.
class MockGoogleSignInService extends Mock implements GoogleSignInService {}
