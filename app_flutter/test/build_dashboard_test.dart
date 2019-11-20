// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/main.dart' as app show theme;
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

import 'utils/fake_flutter_build.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final FlutterBuildState buildState = FlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<FlutterBuildState>(
      builder: (_) => buildState,
      child: const BuildDashboard(),
    )));

    expect(find.byType(SignInButton), findsOneWidget);
  });

  testWidgets('shows tree closed when fetch tree status is false',
      (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        theme: app.theme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          builder: (_) => fakeBuildState,
          child: const BuildDashboard(),
        )));

    expect(find.text('Tree is Closed'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget;
    expect(appbarWidget.backgroundColor, app.theme.errorColor);
  });

  testWidgets('shows tree open when fetch tree status is true',
      (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()
      ..isTreeBuilding = true;

    await tester.pumpWidget(MaterialApp(
        theme: app.theme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          builder: (_) => fakeBuildState,
          child: const BuildDashboard(),
        )));

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget;
    expect(appbarWidget.backgroundColor, app.theme.appBarTheme.color);
  });

  testWidgets('show error snackbar when error occurs',
      (WidgetTester tester) async {
    final FakeFlutterBuildState buildState = FakeFlutterBuildState();
    buildState.errors.message = 'ERRROR';

    await tester.pumpWidget(
        MaterialApp(home: BuildDashboardPage(buildState: buildState)));

    expect(find.text(buildState.errors.message), findsNothing);

    // propagate the error message
    buildState.errors.notifyListeners();

    await tester
        .pump(const Duration(milliseconds: 750)); // open animation for snackbar

    expect(find.text(buildState.errors.message), findsOneWidget);

    // Snackbar message should go away after its duration
    await tester.pumpAndSettle(
        BuildDashboardPage.errorSnackbarDuration); // wait the duration
    await tester.pump(); // schedule animation
    await tester.pump(const Duration(milliseconds: 1500)); // close animation

    // Wait another snackbar duration to prevent a race condition and ensure it clears
    await tester.pumpAndSettle(BuildDashboardPage.errorSnackbarDuration);

    expect(find.text(buildState.errors.message), findsNothing);
  });
}
