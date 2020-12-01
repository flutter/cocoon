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
import 'widgets/task_box.dart';
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
  TaskGridFilter _settingsBasis;

  @override
  void initState() {
    super.initState();
    _filter = TaskGridFilter.fromMap(widget.queryParameters);
    _filter.addListener(() {
      setState(() {});
    });
  }

  void _navigateWithSettings(BuildContext context, TaskGridFilter filter) {
    if (filter.isDefault) {
      Navigator.pushNamed(context, BuildDashboardPage.routeName);
    } else {
      Navigator.pushNamed(context, '${BuildDashboardPage.routeName}?${filter.queryParameters}');
    }
  }

  void _removeSettingsDialog() {
    setState(() {
      _settingsBasis = null;
    });
  }

  void _showSettingsDialog() {
    setState(() {
      _settingsBasis = TaskGridFilter.fromMap(_filter.toMap(includeDefaults: false));
    });
  }

  Widget _settingsDialog(BuildContext context, BuildState _buildState) {
    return Center(
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
                    FlatButton(
                      child: const Text('Defaults'),
                      onPressed: _filter.isDefault ? null : () => _filter.reset(),
                    ),
                    FlatButton(
                      child: const Text('Apply'),
                      onPressed: _filter == _settingsBasis ? null : () => _navigateWithSettings(context, _filter),
                    ),
                    FlatButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        if (_filter != _settingsBasis) {
                          _filter.reset();
                          _filter.applyMap(_settingsBasis.toMap(includeDefaults: false));
                        }
                        _removeSettingsDialog();
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
  }

  PopupMenuItem<String> _getTaskKeyEntry({ @required Widget box, @required String description }) {
    return PopupMenuItem<String>(
      value: description,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const SizedBox(width: 10.0),
          SizedBox.fromSize(
            size: const Size.square(TaskBox.cellSize), child: box),
          const SizedBox(width: 10.0),
          Text(description),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _getTaskKey(bool isDark) {
    final List<PopupMenuEntry<String>> key = <PopupMenuEntry<String>>[];

    for (final String status in TaskBox.statusColor.keys) {
      key.add(_getTaskKeyEntry(
        box: Container(color: TaskBox.statusColor[status]),
        description: status,
      ));
      key.add(const PopupMenuDivider());
    }

    key.add(_getTaskKeyEntry(
      box: Center(
        child: Container(
          width: TaskBox.cellSize * 0.8,
          height: TaskBox.cellSize * 0.8,
          decoration: BoxDecoration(
            border: Border.all(
              width: 2.0,
              color: isDark ? Colors.white : Colors.black,
            )
          ),
        ),
      ),
      description: 'Flaky',
    ));

    key.add(const PopupMenuDivider());

    key.add(_getTaskKeyEntry(
      box: const Center(
        child: Text(
          '!',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      description: 'Passed on rerun',
    ));

    key.add(const PopupMenuDivider());

    return key;
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
            PopupMenuButton<String>(
              tooltip: 'Task Status Key',
              child: const Icon(Icons.info_outline),
              itemBuilder: (BuildContext context) => _getTaskKey(isDark),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings),
              onPressed: _settingsBasis == null ? () => _showSettingsDialog() : null,
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
              if (_settingsBasis != null) _settingsDialog(context, _buildState),
            ],
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
