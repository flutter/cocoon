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
  // TODO(ianh): there's a number of problems with the design here
  // - the widget itself (as opposed to its State) has state (it creates an FlutterBuildState)
  // - the State doesn't handle the widget's buildState property changing dynamically
  // - the State doesn't handle the case of the signInService changing dynamically
  // - the State caches the buildState from the widget, leading to a two-sources-of-truth situation
  // - the State causes the FlutterBuildState to start donig its updates, rather than just subscribing
  //   and letting the FlutterBuildState logic determine whether it has clients and should be live
  // We could probably solve most of these problems by moving all the app state out of the widget
  // tree and using inherited widgets to get at it.

  BuildDashboardPage({
    Key key,
    FlutterBuildState buildState,
    GoogleSignInService signInService,
  })  : buildState = buildState ?? FlutterBuildState(authServiceValue: signInService),
        super(key: key);

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
    widget.buildState.startFetchingUpdates();
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

  void _showErrorSnackbar(String error) {
    final Row snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(error),
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
  const BuildDashboard({
    Key key,
    this.scaffoldKey,
  }) : super(key: key);

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
            DropdownButton<String>(
                value: buildState.currentBranch,
                icon: Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                ),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.white),
                underline: Container(
                  height: 2,
                  color: Colors.white,
                ),
                onChanged: (String branch) {
                  buildState.updateCurrentBranch(branch);
                },
                items: buildState.branches.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.black)),
                  );
                }).toList()),
            const SizedBox(width: 10), // Padding between branches and sign in
            SignInButton(authService: buildState.authService),
          ],
        ),
        body: Column(
          children: const <Widget>[
            StatusGridContainer(),
          ],
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
