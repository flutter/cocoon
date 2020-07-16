// Copyright 2019 The Flutter Authors. All rights reserved.
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
    MockCocoonService mockCocoonService;
    MockGoogleSignInService mockSignInService;

    setUp(() {
      mockSignInService = MockGoogleSignInService();
      mockCocoonService = MockCocoonService();

      when(mockCocoonService.fetchAgentStatuses()).thenAnswer((_) =>
          Future<CocoonResponse<List<Agent>>>.value(
              CocoonResponse<List<Agent>>.data(<Agent>[Agent()])));
    });

    tearDown(() {
      clearInteractions(mockSignInService);
      clearInteractions(mockCocoonService);
    });

    testWidgets('timer should periodically fetch updates',
        (WidgetTester tester) async {
      final AgentState agentState = AgentState(
          cocoonService: mockCocoonService, authService: mockSignInService);
      verifyNever(mockCocoonService.fetchAgentStatuses());

      void listener() {}
      agentState.addListener(listener);

      // startFetching immediately starts fetching results
      verify(mockCocoonService.fetchAgentStatuses()).called(1);
      verifyNever(mockCocoonService.fetchAgentStatuses());

      await tester.pump(agentState.refreshRate);
      verify(mockCocoonService.fetchAgentStatuses()).called(1);

      await tester.pump(agentState.refreshRate);
      verify(mockCocoonService.fetchAgentStatuses()).called(1);

      agentState.dispose();
    });

    testWidgets('multiple start updates should not change the timer',
        (WidgetTester tester) async {
      final AgentState agentState = AgentState(
          cocoonService: mockCocoonService, authService: mockSignInService);
      void listener1() {}
      agentState.addListener(listener1);
      final Timer refreshTimer = agentState.refreshTimer;

      // This second listener should not change the refresh timer.
      void listener2() {}
      agentState.addListener(listener2);

      expect(refreshTimer, equals(agentState.refreshTimer));

      agentState.dispose();
    });

    testWidgets('fetching agents error should not delete previous data',
        (WidgetTester tester) async {
      String lastError;
      final AgentState agentState = AgentState(
          cocoonService: mockCocoonService, authService: mockSignInService)
        ..errors.addListener((String message) => lastError = message);
      verifyNever(mockCocoonService.fetchAgentStatuses());

      void listener1() {}
      agentState.addListener(listener1);
      verify(mockCocoonService.fetchAgentStatuses()).called(1);

      await tester.pump(agentState.refreshRate);
      final List<Agent> originalData = agentState.agents;

      when(mockCocoonService.fetchAgentStatuses()).thenAnswer(
        (_) => Future<CocoonResponse<List<Agent>>>.value(
            const CocoonResponse<List<Agent>>.error('error')),
      );

      await checkOutput(
        block: () async {
          await tester.pump(agentState.refreshRate);
          verify(mockCocoonService.fetchAgentStatuses()).called(2);
        },
        output: <String>[
          'An error occured fetching agent statuses from Cocoon: error',
        ],
      );

      expect(agentState.agents, originalData);
      expect(lastError, startsWith(AgentState.errorMessageFetchingStatuses));

      agentState.dispose();
    });

    test('authorize agent calls cocoon service', () async {
      final AgentState agentState = AgentState(
          cocoonService: mockCocoonService, authService: mockSignInService);
      when(mockCocoonService.authorizeAgent(any, any)).thenAnswer(
        (_) async => const CocoonResponse<String>.data('abc123'),
      );
      verifyNever(mockCocoonService.authorizeAgent(any, any));

      await agentState.authorizeAgent(Agent());

      verify(mockCocoonService.authorizeAgent(any, any)).called(1);
      agentState.dispose();
    });

    test('reserve task calls cocoon service', () async {
      final AgentState agentState = AgentState(
          cocoonService: mockCocoonService, authService: mockSignInService);
      verifyNever(mockCocoonService.reserveTask(any, any));

      await agentState.reserveTask(Agent());

      verify(mockCocoonService.reserveTask(any, any)).called(1);

      agentState.dispose();
    });
  });
}
