// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/task_grid_filter.dart';
import 'navigation_drawer.dart';
import 'state/build.dart';
import 'widgets/app_bar.dart';
import 'widgets/error_brook_watcher.dart';
import 'widgets/filter_property_sheet.dart';
import 'widgets/task_grid.dart';

/// Shows information about the current build status of flutter/flutter.
///
/// The tree's current build status is reflected in [AppBar].
/// The results from tasks run on individual commits is shown in [TaskGrid].
class BuildDashboardPage extends StatefulWidget {
  const BuildDashboardPage({
    Key key,
    this.queryParameters,
  }) : super(key: key);

  static const String routeName = '/build';

  final Map<String, String> queryParameters;

  @override
  State createState() => BuildDashboardPageState();
}

class BuildDashboardPageState extends State<BuildDashboardPage> {
  TaskGridFilter _filter;
  Widget _settingsDialog;

  @override
  void initState() {
    super.initState();
    _filter = TaskGridFilter.fromMap(widget.queryParameters);
  }

  void _navigateWithSettings(BuildContext context, TaskGridFilter filter) {
    if (filter.isDefault) {
      Navigator.pushNamed(context, BuildDashboardPage.routeName);
    } else {
      Navigator.pushNamed(context, '${BuildDashboardPage.routeName}?${filter.queryParameters}');
    }
  }

  void _removeSettingsOverlay() {
    setState(() {
      _settingsDialog = null;
    });
  }

  void _showSettingsDialog(BuildContext context, BuildState _buildState) {
    TaskGridFilter originalFilter = TaskGridFilter.fromMap(_filter.toMap(includeDefaults: false));
    setState(() {
      _settingsDialog = Center(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).dialogBackgroundColor.withAlpha(0xe0),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Material(
            color: Colors.transparent,
            child: FocusTraversalGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButton<String>(
                    value: _buildState.currentBranch,
                    icon: const Icon(
                      Icons.arrow_downward,
                    ),
                    iconSize: 24,
                    elevation: 16,
                    underline: Container(
                      height: 2,
                    ),
                    onChanged: (String branch) {
                      _buildState.updateCurrentBranch(branch);
                    },
                    items: _buildState.branches.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  FilterPropertySheet(_filter),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _filter,
                        builder: (BuildContext context, Widget child) {
                          return FlatButton(
                            child: const Text('Defaults'),
                            onPressed: _filter.isDefault ? null : () => _filter.reset(),
                          );
                        },
                      ),
                      AnimatedBuilder(
                        animation: _filter,
                        builder: (BuildContext context, Widget child) {
                          return FlatButton(
                            child: const Text('Apply'),
                            onPressed: _filter == originalFilter ? null : () => _navigateWithSettings(context, _filter),
                          );
                        },
                      ),
                      FlatButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          if (_filter != originalFilter) {
                            _filter.reset();
                            _filter.applyMap(originalFilter.toMap(includeDefaults: false));
                          }
                          _removeSettingsOverlay();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

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
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _settingsDialog == null ? () => _showSettingsDialog(context, _buildState) : null,
            ),
          ],
        ),
        body: ErrorBrookWatcher(
          errors: _buildState.errors,
          child: Stack(
            children: <Widget>[
              SizedBox.expand(
                child: TaskGridContainer(filter: _filter),
              ),
              if (_settingsDialog != null) _settingsDialog,
            ],
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
