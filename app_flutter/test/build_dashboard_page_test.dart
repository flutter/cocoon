// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/protos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/build_dashboard_page.dart';
import 'package:app_flutter/error_brook_watcher.dart';
import 'package:app_flutter/main.dart' as app show lightTheme;
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';
import 'package:app_flutter/state_provider.dart';

import 'utils/fake_flutter_build.dart';
import 'utils/mocks.dart';
import 'utils/output.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final FlutterBuildState buildState = FlutterBuildState(
      cocoonService: MockCocoonService(),
      authService: MockGoogleSignInService(),
    );

    throwOnMissingStub(buildState.cocoonService as Mock);
    when(buildState.cocoonService.fetchFlutterBranches())
        .thenAnswer((_) => Completer<CocoonResponse<List<String>>>().future);
    when(buildState.cocoonService.fetchCommitStatuses(branch: anyNamed('branch')))
        .thenAnswer((_) => Completer<CocoonResponse<List<CommitStatus>>>().future);
    when(buildState.cocoonService.fetchTreeBuildStatus(branch: anyNamed('branch')))
        .thenAnswer((_) => Completer<CocoonResponse<bool>>().future);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<FlutterBuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );
    expect(find.byType(SignInButton), findsOneWidget);

    await tester.pumpWidget(Container());
    buildState.dispose();
  });

  testWidgets('shows branch dropdown button', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState();

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<FlutterBuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    final Type dropdownButtonType = DropdownButton<String>(
      onChanged: (_) {},
      items: const <DropdownMenuItem<String>>[],
    ).runtimeType;
    expect(find.byType(dropdownButtonType), findsOneWidget);
  });

  testWidgets('shows loading when fetch tree status is null', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = null;

    await tester.pumpWidget(
      MaterialApp(
        theme: app.lightTheme,
        home: ValueProvider<FlutterBuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Loading...'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.grey);
  });

  testWidgets('shows tree closed when fetch tree status is false', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: app.lightTheme,
        home: ValueProvider<FlutterBuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Tree is Closed'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, app.lightTheme.errorColor);
  });

  testWidgets('shows tree open when fetch tree status is true', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = true;

    await tester.pumpWidget(
      MaterialApp(
        theme: app.lightTheme,
        home: ValueProvider<FlutterBuildState>(
          value: fakeBuildState,
          child: ValueProvider<GoogleSignInService>(
            value: fakeBuildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, app.lightTheme.appBarTheme.color);
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    String lastError;
    final FakeFlutterBuildState buildState = FakeFlutterBuildState()
      ..errors.addListener((String message) => lastError = message);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<FlutterBuildState>(
          value: buildState,
          child: ValueProvider<GoogleSignInService>(
            value: buildState.authService,
            child: const BuildDashboardPage(),
          ),
        ),
      ),
    );

    expect(find.text(lastError), findsNothing);

    // propagate the error message
    await checkOutput(
      block: () async {
        buildState.errors.send('ERROR');
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
}
