// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation_drawer.dart';
import 'service/google_authentication.dart';
import 'sign_in_button.dart';
import 'state/flutter_build.dart';
import 'status_grid.dart';

/// [BuildDashboard] parent widget that manages the state of the dashboard.
class BuildDashboardPage extends StatefulWidget {
  BuildDashboardPage(
      {FlutterBuildState buildState, GoogleSignInService signInService})
      : buildState =
            buildState ?? FlutterBuildState(authServiceValue: signInService);

  static const String routeName = '/build';

  final FlutterBuildState buildState;

  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);
  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  FlutterBuildState buildState;

  @override
  void initState() {
    super.initState();

    widget.buildState.startFetchingBuildStateUpdates();

    widget.buildState.errors.addListener(_showErrorSnackbar);
  }

  @override
  Widget build(BuildContext context) {
    buildState = widget.buildState;

    return ChangeNotifierProvider<FlutterBuildState>(
      create: (_) => buildState,
      child: BuildDashboard(scaffoldKey: _scaffoldKey),
    );
  }

  void _showErrorSnackbar() {
    final Row snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(buildState.errors.message)
      ],
    );
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: snackbarContent,
        backgroundColor: Theme.of(context).errorColor,
        duration: BuildDashboardPage.errorSnackbarDuration,
      ),
    );
  }

  @override
  void dispose() {
    buildState.errors.removeListener(_showErrorSnackbar);
    super.dispose();
  }
}

/// Shows information about the current build status of flutter/flutter.
///
/// The tree's current build status is reflected in [AppBar].
/// The results from tasks run on individual commits is shown in [StatusGrid].
class BuildDashboard extends StatelessWidget {
  const BuildDashboard({this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    /// Color of [AppBar] based on [buildState.isTreeBuilding].
    final Map<bool, Color> colorTable = <bool, Color>{
      null: Colors.grey,
      false: theme.errorColor,
      true: theme.appBarTheme.color,
    };

    /// Message to show on [AppBar] based on [buildState.isTreeBuilding].
    const Map<bool, Text> statusTable = <bool, Text>{
      null: Text('Loading...'),
      false: Text('Tree is Closed'),
      true: Text('Tree is Open'),
    };

    return Consumer<FlutterBuildState>(
      builder: (_, FlutterBuildState buildState, Widget child) => Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: statusTable[buildState.isTreeBuilding],
          backgroundColor: colorTable[buildState.isTreeBuilding],
          actions: <Widget>[
            SignInButton(authService: buildState.authService),
          ],
        ),
        body: Column(
          children: const <Widget>[
            StatusGridContainer(),
          ],
        ),
        drawer: const NavigationDrawer(
          currentRoute: BuildDashboardPage.routeName,
        ),
      ),
    );
  }
}
