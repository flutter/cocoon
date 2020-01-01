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
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/agent.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final AgentState agentState = AgentState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<AgentState>(
      create: (_) => agentState,
      child: const AgentDashboard(),
    )));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('create agent FAB opens dialog', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: AgentDashboardPage()));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Create Agent'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Create Agent'), findsOneWidget);
  });

  testWidgets('create agent dialog calls create agent',
      (WidgetTester tester) async {
    final CocoonService mockCocoonService = MockCocoonService();
    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<AgentState>(
      create: (_) => AgentState(cocoonServiceValue: mockCocoonService),
      child: AgentDashboard(
        agentState: AgentState(cocoonServiceValue: mockCocoonService),
      ),
    )));

    when(mockCocoonService.createAgent(any, any, any))
        .thenAnswer((_) async => CocoonResponse<String>()..data = 'abc123');

    verifyNever(mockCocoonService.createAgent(any, any, any));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create agent'));
    await tester.pump();

    verify(mockCocoonService.createAgent(any, any, any)).called(1);
  });

  testWidgets('show error snackbar when error occurs',
      (WidgetTester tester) async {
    final FakeAgentState agentState = FakeAgentState();

    final AgentDashboardPage buildDashboardPage =
        AgentDashboardPage(agentState: agentState);
    await tester.pumpWidget(MaterialApp(home: buildDashboardPage));

    expect(find.text(agentState.errors.message), findsNothing);

    // propagate the error message
    agentState.errors.message = 'ERROR';
    agentState.errors.notifyListeners();
    await tester.pump();

    await tester
        .pump(const Duration(milliseconds: 750)); // open animation for snackbar

    expect(find.text(agentState.errors.message), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester
        .pump(AgentDashboardPage.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(agentState.errors.message), findsNothing);
  });
}

class FakeAgentState extends ChangeNotifier implements AgentState {
  @override
  GoogleSignInService authService = GoogleSignInService();

  @override
  AgentStateErrors errors = AgentStateErrors();

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
  Future<String> createAgent(String agentId, List<String> capabilities) async =>
      'def456';

  @override
  Future<void> reserveTask(Agent agent) => null;

  @override
  Future<void> startFetchingStateUpdates() => null;

  @override
  Timer refreshTimer;
}

class MockCocoonService extends Mock implements CocoonService {}
