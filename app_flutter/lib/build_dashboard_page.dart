// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation_drawer.dart';
import 'state/build.dart';
import 'widgets/app_bar.dart';
import 'widgets/error_brook_watcher.dart';
import 'widgets/task_grid.dart';

/// Shows information about the current build status of flutter/flutter.
///
/// The tree's current build status is reflected in [AppBar].
/// The results from tasks run on individual commits is shown in [TaskGrid].
class BuildDashboardPage extends StatelessWidget {
  const BuildDashboardPage({
    Key key,
  }) : super(key: key);

  static const String routeName = '/build';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    /// Color of [AppBar] based on [buildState.isTreeBuilding].
    final Map<bool, Color> colorTable = <bool, Color>{
      null: Colors.grey[850],
      false: isDark ? Colors.red[800] : Colors.red,
      true: isDark ? Colors.green[800] : Colors.green,
    };

    /// Message to show on [AppBar] based on [buildState.isTreeBuilding].
    const Map<bool, Text> statusTable = <bool, Text>{
      null: Text('Loading...'),
      false: Text('Tree is Closed'),
      true: Text('Tree is Open'),
    };

    final BuildState _buildState = Provider.of<BuildState>(context);
    return AnimatedBuilder(
      animation: _buildState,
      builder: (BuildContext context, Widget child) => Scaffold(
        appBar: CocoonAppBar(
          title: statusTable[_buildState.isTreeBuilding],
          backgroundColor: colorTable[_buildState.isTreeBuilding],
          actions: <Widget>[
            DropdownButton<String>(
              value: _buildState.currentBranch,
              icon: const Icon(
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
              items: _buildState.branches.map<DropdownMenuItem<String>>(
                (String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                },
              ).toList(),
            ),
          ],
        ),
        body: ErrorBrookWatcher(
          errors: _buildState.errors,
          child: const SizedBox.expand(
            child: TaskGridContainer(),
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
