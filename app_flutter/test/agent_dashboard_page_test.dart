// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/models.dart';

import 'package:app_flutter/agent_dashboard_page.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/agent.dart';
import 'package:app_flutter/widgets/agent_tile.dart';
import 'package:app_flutter/widgets/error_brook_watcher.dart';
import 'package:app_flutter/widgets/now.dart';
import 'package:app_flutter/widgets/sign_in_button.dart';
import 'package:app_flutter/widgets/state_provider.dart';

import 'utils/fake_agent_state.dart';
import 'utils/mocks.dart';
import 'utils/output.dart';
import 'utils/wrapper.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeInserter(child: AgentDashboardPage())));
    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('create agent FAB opens dialog', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeInserter(child: AgentDashboardPage())));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('CREATE AGENT'), findsOneWidget); // the floating action button
    expect(find.text('Create Agent'), findsNothing);

    await tester.tap(find.text('CREATE AGENT'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('CREATE AGENT'), findsOneWidget); // the floating action button
    expect(find.text('Create Agent'), findsOneWidget); // the dialog title
  });

  testWidgets('create agent dialog calls create agent', (WidgetTester tester) async {
    final MockCocoonService mockCocoonService = MockCocoonService();
    final AgentState agentState = AgentState(
      cocoonService: mockCocoonService,
      authService: MockGoogleSignInService(),
    );

    when(mockCocoonService.fetchAgentStatuses()).thenAnswer((_) => Completer<CocoonResponse<List<Agent>>>().future);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<AgentState>(
          value: agentState,
          child: ValueProvider<GoogleSignInService>(
            value: agentState.authService,
            child: const AgentDashboardPage(),
          ),
        ),
      ),
    );

    when(mockCocoonService.createAgent(any, any, any))
        .thenAnswer((_) async => const CocoonResponse<String>.data('abc123'));

    verifyNever(mockCocoonService.createAgent(any, any, any));

    await tester.tap(find.text('CREATE AGENT'));
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

    await tester.pumpWidget(Container());
    agentState.dispose();
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    final FakeAgentState agentState = FakeAgentState();

    String lastError;
    agentState.errors.addListener((String message) => lastError = message);

    await tester.pumpWidget(
      Now.fixed(
        dateTime: DateTime.utc(2000),
        child: MaterialApp(
          home: ValueProvider<AgentState>(
            value: agentState,
            child: ValueProvider<GoogleSignInService>(
              value: agentState.authService,
              child: const AgentDashboardPage(),
            ),
          ),
        ),
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
    await tester.pump(ErrorBrookWatcher.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(lastError), findsNothing);
  });

  testWidgets('agent filter is passed to agent list', (WidgetTester tester) async {
    final GoogleSignInService mockAuthService = MockGoogleSignInService();
    final MockCocoonService mockCocoonService = MockCocoonService();
    final AgentState agentState = AgentState(
      authService: mockAuthService,
      cocoonService: mockCocoonService,
    );

    when(mockCocoonService.fetchAgentStatuses()).thenAnswer(
      (_) async => CocoonResponse<List<Agent>>.data(
        List<Agent>.generate(
          10,
          (int i) => Agent()
            ..agentId = 'dash-test-$i'
            ..capabilities.add('dash')
            ..isHealthy = i % 2 == 0
            ..isHidden = false
            ..healthCheckTimestamp = DateTime.utc(2000, 1, 1, i).millisecondsSinceEpoch
            ..healthDetails = 'ssh-connectivity: succeeded\n'
                'Last known IP address: flutter-devicelab-linux-vm-1\n\n'
                'android-device-ZY223D6B7B: succeeded\n'
                'has-healthy-devices: succeeded\n'
                'Found 1 healthy devices\n\n'
                'cocoon-authentication: succeeded\n'
                'cocoon-connection: succeeded\n'
                'able-to-perform-health-check: succeeded\n',
        ),
      ),
    );

    await tester.pumpWidget(
      Now.fixed(
        dateTime: DateTime.utc(2000),
        child: MaterialApp(
          home: ValueProvider<AgentState>(
            value: agentState,
            child: ValueProvider<GoogleSignInService>(
              value: mockAuthService,
              child: const AgentDashboardPage(
                agentFilter: 'dash-test-3',
              ),
            ),
          ),
        ),
      ),
    );
    agentState.notifyListeners();
    await tester.pump();

    expect(find.byType(AgentTile), findsOneWidget);
    // agent id shows in the search bar and the agent tile
    expect(find.text('dash-test-3'), findsNWidgets(2));

    await tester.pumpWidget(Container());
    agentState.dispose();
  });
}
