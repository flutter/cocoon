// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'error_brook_watcher.dart';
import 'navigation_drawer.dart';
import 'sign_in_button.dart';
import 'state/flutter_build.dart';
import 'status_grid.dart';

/// Shows information about the current build status of flutter/flutter.
///
/// The tree's current build status is reflected in [AppBar].
/// The results from tasks run on individual commits is shown in [StatusGrid].
class BuildDashboardPage extends StatefulWidget {
  const BuildDashboardPage({
    Key key,
  }) : super(key: key);

  static const String routeName = '/build';

  @override
  State<BuildDashboardPage> createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  FlutterBuildState _buildState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildState = Provider.of<FlutterBuildState>(context)..startFetchingUpdates();
  }

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

    return AnimatedBuilder(
      animation: _buildState,
      builder: (BuildContext context, Widget child) => Scaffold(
        appBar: AppBar(
          title: statusTable[_buildState.isTreeBuilding],
          backgroundColor: colorTable[_buildState.isTreeBuilding],
          actions: <Widget>[
            DropdownButton<String>(
                value: _buildState.currentBranch,
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
                  _buildState.updateCurrentBranch(branch);
                },
                items: _buildState.branches.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.black)),
                  );
                }).toList()),
            const SizedBox(width: 10), // Padding between branches and sign in
            const SignInButton(),
          ],
        ),
        body: ErrorBrookWatcher(
          errors: _buildState.errors,
          child: Column(
            // TODO(ianh): Replace with a more idiomatic solution.
            children: const <Widget>[
              StatusGridContainer(),
            ],
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
