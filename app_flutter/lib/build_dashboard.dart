// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/authentication.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/flutter_build.dart';
import 'status_grid.dart';

/// [BuildDashboard] parent widget that manages the state of the dashboard.
class BuildDashboardPage extends StatefulWidget {
  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  final FlutterBuildState buildState = FlutterBuildState();
  final AuthenticationService authService = AuthenticationService();

  @override
  void initState() {
    super.initState();

    buildState.startFetchingBuildStateUpdates();
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          title: const Text('Flutter Build Dashboard v2'),
          backgroundColor: buildState.isTreeBuilding.data
              ? theme.primaryColor
              : theme.errorColor,
          actions: <Widget>[
            RaisedButton(
              child: const Text('Sign In'),
              onPressed: () {},
            )
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
