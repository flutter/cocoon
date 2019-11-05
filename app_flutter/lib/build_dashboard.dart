// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'service/google_authentication.dart';
import 'state/flutter_build.dart';
import 'status_grid.dart';

/// [BuildDashboard] parent widget that manages the state of the dashboard.
class BuildDashboardPage extends StatefulWidget {
  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  final FlutterBuildState buildState = FlutterBuildState();

  String gridImplementation = 'GridView.builder';

  @override
  void initState() {
    super.initState();

    buildState.startFetchingBuildStateUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FlutterBuildState>(
        builder: (_) => buildState, child: const BuildDashboard());
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
class BuildDashboard extends StatefulWidget {
  const BuildDashboard({Key key}) : super(key: key);

  @override
  _BuildDashboardState createState() => _BuildDashboardState();
}

class _BuildDashboardState extends State<BuildDashboard> {
  String _gridImplementation = 'GridView.builder';

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
            DropdownButton<String>(
              value: _gridImplementation,
              onChanged: (String newValue) {
                setState(() {
                  _gridImplementation = newValue;
                });
              },
              items: <String>[
                'GridView.builder',
                'GridView.builder addRepaintBoundaries',
                'ListView<ListView>',
                'ListView<ListView> addRepaintBoundaries',
                'ListView<ListView> sync scroller',
                'ListView<ListView> sync scroller addRepaintBoundaries'
              ]
                  .map<DropdownMenuItem<String>>((String value) =>
                      DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                  .toList(),
            ),
            UserAvatar(buildState: buildState),
          ],
        ),
        body: Column(
          children: <Widget>[
            StatusGridContainer(
              gridImplementation: _gridImplementation,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Otherwise, it will show
/// a button for sign in.
class UserAvatar extends StatelessWidget {
  const UserAvatar({@required this.buildState, Key key}) : super(key: key);

  final FlutterBuildState buildState;

  @override
  Widget build(BuildContext context) {
    final GoogleSignInService authService = buildState.authService;

    if (authService.isAuthenticated) {
      return Image.network(authService.avatarUrl);
    }

    return FlatButton(
      child: const Text('Sign in'),
      onPressed: () => buildState.signIn(),
    );
  }
}
