// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/build_dashboard_page.dart';
import 'package:app_flutter/main.dart' as app show lightTheme;
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

import 'utils/fake_flutter_build.dart';
import 'utils/output.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final FlutterBuildState buildState = FlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<FlutterBuildState>(
      create: (_) => buildState,
      child: const BuildDashboard(),
    )));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('shows branch dropdown button', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<FlutterBuildState>(
      create: (_) => fakeBuildState,
      child: const BuildDashboard(),
    )));

    final Type dropdownButtonType = DropdownButton<String>(
      onChanged: (_) {},
      items: const <DropdownMenuItem<String>>[],
    ).runtimeType;
    expect(find.byType(dropdownButtonType), findsOneWidget);
  });

  testWidgets('shows loading when fetch tree status is null', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = null;

    await tester.pumpWidget(MaterialApp(
        theme: app.lightTheme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          create: (_) => fakeBuildState,
          child: const BuildDashboard(),
        )));

    expect(find.text('Loading...'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, Colors.grey);
  });

  testWidgets('shows tree closed when fetch tree status is false', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = false;

    await tester.pumpWidget(MaterialApp(
        theme: app.lightTheme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          create: (_) => fakeBuildState,
          child: const BuildDashboard(),
        )));

    expect(find.text('Tree is Closed'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, app.lightTheme.errorColor);
  });

  testWidgets('shows tree open when fetch tree status is true', (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()..isTreeBuilding = true;

    await tester.pumpWidget(MaterialApp(
        theme: app.lightTheme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          create: (_) => fakeBuildState,
          child: const BuildDashboard(),
        )));

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget as AppBar;
    expect(appbarWidget.backgroundColor, app.lightTheme.appBarTheme.color);
  });

  testWidgets('show error snackbar when error occurs', (WidgetTester tester) async {
    String lastError;
    final FakeFlutterBuildState buildState = FakeFlutterBuildState()
      ..errors.addListener((String message) => lastError = message);

    final BuildDashboardPage buildDashboardPage = BuildDashboardPage(buildState: buildState);
    await tester.pumpWidget(MaterialApp(home: buildDashboardPage));

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
    await tester.pump(BuildDashboardPage.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    expect(find.text(lastError), findsNothing);
  });
}
