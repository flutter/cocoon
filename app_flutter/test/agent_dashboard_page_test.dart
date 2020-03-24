// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'package:app_flutter/agent_dashboard_page.dart';
import 'package:app_flutter/agent_tile.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/agent.dart';
import 'package:app_flutter/state/brooks.dart';

import 'utils/output.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AgentState>(
            create: (_) => FakeAgentState(),
            child: const AgentDashboard(),
          ),
        ),
      ),
    );

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('create agent FAB opens dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgentDashboardPage(),
      ),
    );

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Create Agent'), findsOneWidget);

    await tester.tap(find.text('Create Agent'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Create Agent'), findsNWidgets(2));
  });

  testWidgets('create agent dialog calls create agent', (WidgetTester tester) async {
    final MockCocoonService mockCocoonService = MockCocoonService();
    final AgentState agentState = AgentState(
      cocoonServiceValue: mockCocoonService,
      authServiceValue: MockSignInService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AgentState>(
          create: (_) => agentState,
          child: AgentDashboard(
            agentState: agentState,
          ),
        ),
      ),
    );

    when(mockCocoonService.createAgent(any, any, any))
        .thenAnswer((_) async => CocoonResponse<String>()..data = 'abc123');

    verifyNever(mockCocoonService.createAgent(any, any, any));

    await tester.tap(find.text('Create Agent'));
    await tester.pump();

    await checkOutput(
      block: () async {
        await tester.tap(find.text('Create'));
        await tester.pump();
      },
      output: <String>[
        ': abc123',
        'Capabilities: []',
      ],
    );

    verify(mockCocoonService.createAgent(any, any, any)).called(1);
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    final FakeAgentState agentState = FakeAgentState();

    String lastError;
    agentState.errors.addListener((String message) => lastError = message);

    final AgentDashboardPage buildDashboardPage = AgentDashboardPage(agentState: agentState);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: buildDashboardPage),
      ),
    );

    expect(find.text(lastError), findsNothing);

    // propagate the error message
    await checkOutput(
      block: () async {
        agentState.errors.send('ERROR');
      },
      output: <String>[
        'ERROR',
      ],
    );
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 750)); // open animation for snackbar

    expect(find.text(lastError), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester.pump(AgentDashboardPage.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(lastError), findsNothing);
  });

  testWidgets('agent filter is passed to agent list', (WidgetTester tester) async {
    final AgentState agentState = AgentState();
    await tester.pumpWidget(
      MaterialApp(
        home: AgentDashboardPage(
          agentState: agentState,
          agentFilter: 'dash-test-3',
        ),
      ),
    );
    agentState.notifyListeners();
    await tester.pump();

    expect(find.byType(AgentTile), findsOneWidget);
    // agent id shows in the search bar and the agent tile
    expect(find.text('dash-test-3'), findsNWidgets(2));
  });
}

class FakeAgentState extends ChangeNotifier implements AgentState {
  @override
  GoogleSignInService authService = MockSignInService();

  @override
  final ErrorSink errors = ErrorSink();

  @override
  Duration get refreshRate => null;

  @override
  Future<void> signIn() => null;

  @override
  Future<void> signOut() => null;

  @override
  List<Agent> agents = <Agent>[];

  @override
  Future<String> authorizeAgent(Agent agent) async => 'abc123';

  @override
  Future<String> createAgent(String agentId, List<String> capabilities) async => 'def456';

  @override
  Future<void> reserveTask(Agent agent) => null;

  @override
  Future<void> startFetchingStateUpdates() => null;

  @override
  Timer refreshTimer;
}

class MockCocoonService extends Mock implements CocoonService {}

class MockSignInService extends Mock implements GoogleSignInService {}
