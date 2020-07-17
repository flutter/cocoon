// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cocoon_service/protos.dart';

import 'package:app_flutter/build_dashboard_page.dart';
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/build.dart';
import 'package:app_flutter/widgets/error_brook_watcher.dart';
import 'package:app_flutter/widgets/sign_in_button.dart';
import 'package:app_flutter/widgets/state_provider.dart';

import 'utils/fake_build.dart';
import 'utils/mocks.dart';
import 'utils/output.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final BuildState buildState = BuildState(
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
        home: ValueProvider<BuildState>(
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
    final BuildState fakeBuildState = FakeBuildState();

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<BuildState>(
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
    final BuildState fakeBuildState = FakeBuildState()..isTreeBuilding = null;
    final ThemeData lightTheme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: ValueProvider<BuildState>(
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
    final BuildState fakeBuildState = FakeBuildState()..isTreeBuilding = false;
    final ThemeData lightTheme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: ValueProvider<BuildState>(
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
    expect(appbarWidget.backgroundColor, lightTheme.errorColor);
  });

  testWidgets('shows tree open when fetch tree status is true', (WidgetTester tester) async {
    final BuildState fakeBuildState = FakeBuildState()..isTreeBuilding = true;
    final ThemeData lightTheme = ThemeData();

    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        home: ValueProvider<BuildState>(
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
    expect(appbarWidget.backgroundColor, lightTheme.appBarTheme.color);
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    String lastError;
    final FakeBuildState buildState = FakeBuildState()..errors.addListener((String message) => lastError = message);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueProvider<BuildState>(
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
