// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/state/agent.dart';

import '../utils/mocks.dart';
import '../utils/output.dart';

void main() {
  group('AgentState', () {
    AgentState agentState;
    MockCocoonService mockCocoonService;
    MockGoogleSignInService mockSignInService;
    String lastError;

    setUp(() {
      mockSignInService = MockGoogleSignInService();
      mockCocoonService = MockCocoonService();
      agentState = AgentState(cocoonService: mockCocoonService, authService: mockSignInService)
        ..errors.addListener((String message) => lastError = message);

      when(mockCocoonService.fetchAgentStatuses()).thenAnswer(
          (_) => Future<CocoonResponse<List<Agent>>>.value(CocoonResponse<List<Agent>>.data(<Agent>[Agent()])));
    });

    tearDown(() {
      clearInteractions(mockSignInService);
      clearInteractions(mockCocoonService);
    });

    testWidgets('timer should periodically fetch updates', (WidgetTester tester) async {
      agentState.startFetchingStateUpdates();

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchAgentStatuses()).called(1);

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(agentState.refreshRate * 2);
      verify(mockCocoonService.fetchAgentStatuses()).called(greaterThan(1));

      // Tear down fails to cancel the timer before the test is over
      agentState.dispose();
    });

    testWidgets('multiple start updates should not change the timer', (WidgetTester tester) async {
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

    testWidgets('fetching agents error should not delete previous data', (WidgetTester tester) async {
      agentState.startFetchingStateUpdates();

      // Periodic timers don't necessarily run at the same time in each interval.
      // We double the refreshRate to gurantee a call would have been made.
      await tester.pump(agentState.refreshRate * 2);
      final List<Agent> originalData = agentState.agents;

      when(mockCocoonService.fetchAgentStatuses()).thenAnswer(
          (_) => Future<CocoonResponse<List<Agent>>>.value(const CocoonResponse<List<Agent>>.error('error')));

      await checkOutput(
        block: () async {
          await tester.pump(agentState.refreshRate);
          verify(mockCocoonService.fetchAgentStatuses()).called(greaterThan(1));
        },
        output: <String>[
          'An error occured fetching agent statuses from Cocoon: error',
        ],
      );

      expect(agentState.agents, originalData);
      expect(lastError, startsWith(AgentState.errorMessageFetchingStatuses));

      // Tear down fails to cancel the timer before the test is over
      agentState.dispose();
    });

    test('authorize agent calls cocoon service', () async {
      when(mockCocoonService.authorizeAgent(any, any))
          .thenAnswer((_) async => const CocoonResponse<String>.data('abc123'));
      verifyNever(mockCocoonService.authorizeAgent(any, any));

      await agentState.authorizeAgent(Agent());

      verify(mockCocoonService.authorizeAgent(any, any)).called(1);
    });

    test('reserve task calls cocoon service', () async {
      verifyNever(mockCocoonService.reserveTask(any, any));

      await agentState.reserveTask(Agent());

      verify(mockCocoonService.reserveTask(any, any)).called(1);
    });
  });
}
