// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'service/authentication.dart';
import 'state/flutter_build.dart';
import 'status_grid.dart';

/// [BuildDashboard] parent widget that manages the state of the dashboard.
class BuildDashboardPage extends StatefulWidget {
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
            UserAvatar(buildState: buildState),
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

/// Widget for displaying sign in information for the current user.
///
/// If logged in, it will display the user's avatar. Otherwise, it will show
/// a button for sign in.
class UserAvatar extends StatelessWidget {
  const UserAvatar({@required this.buildState, Key key}) : super(key: key);

  final FlutterBuildState buildState;

  @override
  Widget build(BuildContext context) {
    final AuthenticationService authenticationService =
        buildState.authenticationService;

    if (authenticationService.isAuthenticated) {
      return Image.network(authenticationService.avatarUrl);
    }

    return FlatButton(
      child: const Text('Sign in'),
      onPressed: () => buildState.signIn(),
    );
  }
}
