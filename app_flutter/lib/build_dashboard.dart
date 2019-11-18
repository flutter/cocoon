// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sign_in_button.dart';
import 'state/flutter_build.dart';
import 'status_grid.dart';

/// [BuildDashboard] parent widget that manages the state of the dashboard.
class BuildDashboardPage extends StatefulWidget {
  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);
  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  final FlutterBuildState buildState = FlutterBuildState();

  @override
  void initState() {
    super.initState();

    buildState.startFetchingBuildStateUpdates();
  }

  @override
  Widget build(BuildContext context) {
    buildState.errors.addListener(() {
      print(buildState.errors.message);
      final Row snackbarContent = Row(
        children: <Widget>[
          const Icon(Icons.error),
          const SizedBox(width: 10),
          Text(buildState.errors.message)
        ],
      );
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: snackbarContent,
          backgroundColor: Theme.of(context).errorColor,
          duration: BuildDashboardPage.errorSnackbarDuration,
        ),
      );
    });
    return ChangeNotifierProvider<FlutterBuildState>(
        builder: (_) => buildState, child: BuildDashboard());
  }

  @override
  void dispose() {
    buildState.dispose();
    super.dispose();
  }
}

/// Shows information about the current build status of flutter/flutter.
///
/// The tree's current build status is reflected in the color of [AppBar].
/// The results from tasks run on individual commits is shown in [StatusGrid].
class BuildDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<FlutterBuildState>(
      builder: (_, FlutterBuildState buildState, Widget child) => Scaffold(
        key: const Key('build-dashboard-scaffold'),
        appBar: AppBar(
          title: buildState.isTreeBuilding
              ? const Text('Tree is Open')
              : const Text('Tree is Closed'),
          backgroundColor: buildState.isTreeBuilding
              ? theme.appBarTheme.color
              : theme.errorColor,
          actions: <Widget>[
            SignInButton(authService: buildState.authService),
          ],
        ),
        body: Column(
          children: const <Widget>[
            StatusGridContainer(),
          ],
        ),
      ),
    );
  }
}
