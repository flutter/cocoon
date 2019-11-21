// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cocoon_service/protos.dart' show Commit, CommitStatus, Task;

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/main.dart' as app show theme;
import 'package:app_flutter/service/cocoon.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  testWidgets('shows sign in button', (WidgetTester tester) async {
    final FlutterBuildState buildState = FlutterBuildState();

    await tester.pumpWidget(MaterialApp(
        home: ChangeNotifierProvider<FlutterBuildState>(
      builder: (_) => buildState,
      child: BuildDashboard(),
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
          child: BuildDashboard(),
        )));

    expect(find.text('Tree is Closed'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget;
    expect(appbarWidget.backgroundColor, app.theme.errorColor);
  });

  testWidgets('shows tree open when fetch tree status is true',
      (WidgetTester tester) async {
    final FlutterBuildState fakeBuildState = FakeFlutterBuildState()
      ..isTreeBuilding = (CocoonResponse<bool>()..data = true);

    await tester.pumpWidget(MaterialApp(
        theme: app.theme,
        home: ChangeNotifierProvider<FlutterBuildState>(
          builder: (_) => fakeBuildState,
          child: BuildDashboard(),
        )));

    expect(find.text('Tree is Open'), findsOneWidget);

    final AppBar appbarWidget = find.byType(AppBar).evaluate().first.widget;
    expect(appbarWidget.backgroundColor, app.theme.appBarTheme.color);
  });
}

class FakeFlutterBuildState extends ChangeNotifier
    implements FlutterBuildState {
  @override
  GoogleSignInService authService = GoogleSignInService();

  @override
  Timer refreshTimer;

  @override
  bool hasError = false;

  @override
  CocoonResponse<bool> isTreeBuilding = CocoonResponse<bool>()..data = false;

  @override
  Duration get refreshRate => null;

  @override
  Future<bool> rerunTask(Task task) => null;

  @override
  Future<void> signIn() => null;

  @override
  Future<void> signOut() => null;

  @override
  Future<void> startFetchingBuildStateUpdates() => null;

  @override
  CocoonResponse<List<CommitStatus>> statuses =
      CocoonResponse<List<CommitStatus>>()..data = <CommitStatus>[];

  @override
  Future<bool> downloadLog(Task task, Commit commit) => null;
}
