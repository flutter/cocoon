// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_icons/flutter_app_icons.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dashboard_navigation_drawer.dart';
import 'logic/task_grid_filter.dart';
import 'model/branch.pb.dart';
import 'model/commit.pb.dart';
import 'service/cocoon.dart';
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
    super.key,
    this.queryParameters,
  });

  static const String routeName = '/build';

  final Map<String, String>? queryParameters;

  @override
  State createState() => BuildDashboardPageState();
}

class BuildDashboardPageState extends State<BuildDashboardPage> {
  TaskGridFilter? _filter;
  TaskGridFilter? _settingsBasis;
  bool _smallScreen = false;
  double screenWidthThreshold = 600;
  final _flutterAppIconsPlugin = FlutterAppIcons();

  /// Current Flutter repository to view.
  String? repo;

  /// Git branch in [repo] to view.
  ///
  /// The frontend will update default branches based on [defaultBranches]. This enables users to easily switch from
  /// master on one repo, to main for a different repo.
  String? branch;

  /// Example branch for [truncate].
  ///
  /// Include the ellipsis to get the correct length that should be truncated at.
  final String _exampleBranch = 'flutter-3.12-candidate.23...';

  @override
  void initState() {
    super.initState();
    if (widget.queryParameters != null) {
      repo = widget.queryParameters!['repo'] ?? 'flutter';
      branch = widget.queryParameters!['branch'] ?? 'master';
    }
    repo ??= 'flutter';
    branch ??= 'master';
    if (branch == 'master' || branch == 'main') {
      branch = defaultBranches[repo!];
    }
    _filter = TaskGridFilter.fromMap(widget.queryParameters);
    _filter!.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _flutterAppIconsPlugin.setIcon(icon: 'favicon.png');
    super.dispose();
  }

  /// Convert the fields from this class into a URL.
  ///
  /// This enables bookmarking state specific values, like [repo].
  void _updateNavigation(BuildContext context) {
    var queryParameters = <String, String>{};
    if (widget.queryParameters != null) {
      queryParameters.addAll(widget.queryParameters!);
    }
    if (_filter != null) {
      queryParameters = _filter!.toMap(initialMap: queryParameters);
    }

    queryParameters['repo'] = repo!;

    queryParameters['branch'] = branch!;

    final uri = Uri(
      path: BuildDashboardPage.routeName,
      queryParameters: queryParameters,
    );
    Navigator.pushNamed(context, uri.toString());
  }

  void _removeSettingsDialog() {
    setState(() {
      _settingsBasis = null;
    });
  }

  void _showSettingsDialog() {
    setState(() {
      _settingsBasis = TaskGridFilter.fromMap(_filter!.toMap());
    });
  }

  Widget _settingsDialog(BuildContext context, BuildState buildState) {
    final theme = Theme.of(context);
    final backgroundColor =
        theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.white;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withAlpha(0xe0),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: FocusTraversalGroup(
            child: SizedBox(
              width: 500,
              height: 360,
              child: ListView(
                children: <Widget>[
                  if (_smallScreen)
                    ..._buildRepositorySelectionWidgets(context, buildState),
                  AnimatedBuilder(
                    animation: buildState,
                    builder: (context, child) {
                      final isAuthenticated =
                          buildState.authService.isAuthenticated;
                      return TextButton(
                        onPressed: isAuthenticated
                            ? buildState.refreshGitHubCommits
                            : null,
                        child: child!,
                      );
                    },
                    child: const Text('Refresh GitHub Commits'),
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: Center(child: FilterPropertySheet(_filter))),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TextButton(
                        onPressed:
                            _filter!.isDefault ? null : () => _filter!.reset(),
                        child: const Text('Defaults'),
                      ),
                      TextButton(
                        onPressed: _filter == _settingsBasis
                            ? null
                            : () => _updateNavigation(context),
                        child: const Text('Apply'),
                      ),
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          if (_filter != _settingsBasis) {
                            _filter!.reset();
                            _filter!.applyMap(_settingsBasis!.toMap());
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
      ),
    );
  }

  /// List of widgets for selecting slug and branch for configuring the build view.
  List<Widget> _buildRepositorySelectionWidgets(
      BuildContext context, BuildState buildState) {
    final theme = Theme.of(context);
    return <Widget>[
      const Padding(
        padding: EdgeInsets.only(top: 22, left: 5, right: 5),
        child: Text(
          'repo: ',
          textAlign: TextAlign.center,
        ),
      ),
      DropdownButton<String>(
        key: const Key('repo dropdown'),
        isExpanded: _smallScreen,
        value: buildState.currentRepo,
        icon: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(
            Icons.arrow_downward,
          ),
        ),
        iconSize: 24,
        elevation: 16,
        underline: Container(
          height: 2,
        ),
        onChanged: (String? selectedRepo) {
          repo = selectedRepo;
          _updateNavigation(context);
        },
        items: buildState.repos.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Center(
                child: Text(
                  value,
                  style: theme.primaryTextTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const Padding(
        padding: EdgeInsets.only(top: 22, left: 5, right: 5),
        child: Text(
          'branch: ',
          textAlign: TextAlign.center,
        ),
      ),
      DropdownButton<String>(
        key: const Key('branch dropdown'),
        isExpanded: _smallScreen,
        value: buildState.currentBranch,
        icon: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Icon(
            Icons.arrow_downward,
          ),
        ),
        iconSize: 24,
        elevation: 16,
        underline: Container(
          height: 2,
        ),
        onChanged: (String? selectedBranch) {
          branch = selectedBranch;
          _updateNavigation(context);
        },
        items: [
          DropdownMenuItem<String>(
            value: buildState.currentBranch,
            child: Padding(
              padding: const EdgeInsets.only(top: 9.0),
              child: Center(
                child: Text(
                  truncate(buildState.currentBranch, _exampleBranch.length),
                  style: theme.primaryTextTheme.bodyLarge,
                ),
              ),
            ),
          ),
          ...buildState.branches
              .where((Branch b) => b.branch != buildState.currentBranch)
              .map<DropdownMenuItem<String>>((Branch b) {
            final branchPrefix = (b.channel != 'HEAD') ? '${b.channel}: ' : '';
            return DropdownMenuItem<String>(
              value: b.branch,
              child: Padding(
                padding: const EdgeInsets.only(top: 9.0),
                child: Center(
                  child: Text(
                    branchPrefix + truncate(b.branch, _exampleBranch.length),
                    style: theme.primaryTextTheme.bodyLarge,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
    ];
  }

  PopupMenuItem<String> _getTaskKeyEntry(
      {required Widget box, required String description}) {
    return PopupMenuItem<String>(
      value: description,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const SizedBox(width: 10.0),
          SizedBox.fromSize(size: Size.square(TaskBox.of(context)), child: box),
          const SizedBox(width: 10.0),
          Text(description),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _getTaskKey(bool isDark) {
    final key = <PopupMenuEntry<String>>[];

    for (final status in TaskBox.statusColor.keys) {
      key.add(
        _getTaskKeyEntry(
          box: Container(color: TaskBox.statusColor[status]),
          description: status,
        ),
      );
      key.add(const PopupMenuDivider());
    }

    key.add(
      _getTaskKeyEntry(
        box: Center(
          child: Container(
            width: TaskBox.of(context) * 0.8,
            height: TaskBox.of(context) * 0.8,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2.0,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
        description: 'Flaky',
      ),
    );

    key.add(const PopupMenuDivider());

    key.add(
      _getTaskKeyEntry(
        box: const Center(
          child: Text(
            '!',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        description: 'Ran more than once',
      ),
    );

    key.add(const PopupMenuDivider());

    return key;
  }

  String _getStatusTitle(BuildState? buildState) {
    if (buildState == null || buildState.isTreeBuilding == null) {
      return 'Loading...';
    }
    if (buildState.isTreeBuilding!) {
      return 'Tree is Open';
    } else {
      if (buildState.failingTasks.isNotEmpty) {
        return 'Tree is Closed (failing: ${buildState.failingTasks.join(', ')})';
      } else {
        return 'Tree is Closed';
      }
    }
  }

  void _updatePage(BuildContext context, String newRepo, String newBranch) {
    repo = newRepo;
    branch = newBranch;
    _updateNavigation(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queryData = MediaQuery.of(context);
    final devicePixelRatio = queryData.devicePixelRatio;
    _smallScreen =
        queryData.size.width * devicePixelRatio < screenWidthThreshold;

    /// Color of [AppBar] based on [buildState.isTreeBuilding].
    final colorTable = <bool?, Color?>{
      null: Colors.grey[850],
      false: isDark ? Colors.red[800] : Colors.red,
      true: isDark ? Colors.green[800] : Colors.green,
    };

    final flutterIssueUrl = Uri.parse(
      'https://github.com/flutter/flutter/issues/new?assignees=&labels=team-infra&projects=&template=6_infrastructure.yml',
    );
    final flutterInfraTicketQueue = Uri.parse(
      'https://github.com/orgs/flutter/projects/81',
    );
    final buildState = Provider.of<BuildState>(context);
    buildState.updateCurrentRepoBranch(repo!, branch!);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _updatePage(context, 'flutter', 'master'),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _updatePage(context, 'cocoon', 'main'),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _updatePage(context, 'packages', 'main'),
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
          animation: buildState,
          builder: (BuildContext context, Widget? child) => Scaffold(
            appBar: CocoonAppBar(
              title: Tooltip(
                message: _getStatusTitle(buildState),
                child: Text(
                  _getStatusTitle(buildState),
                ),
              ),
              backgroundColor: colorTable[buildState.isTreeBuilding],
              actions: <Widget>[
                if (!_smallScreen)
                  ..._buildRepositorySelectionWidgets(context, buildState),
                IconButton(
                  tooltip: 'Infra Ticket Queue',
                  icon: const Icon(Icons.queue),
                  onPressed: () async {
                    if (await canLaunchUrl(flutterInfraTicketQueue)) {
                      await launchUrl(flutterInfraTicketQueue);
                    } else {
                      throw 'Could not launch $flutterInfraTicketQueue';
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Report Issue',
                  icon: const Icon(Icons.bug_report),
                  onPressed: () async {
                    if (await canLaunchUrl(flutterIssueUrl)) {
                      await launchUrl(flutterIssueUrl);
                    } else {
                      throw 'Could not launch $flutterIssueUrl';
                    }
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: 'Task Status Key',
                  child: const Icon(Icons.info_outline),
                  itemBuilder: (BuildContext context) => _getTaskKey(isDark),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings),
                  onPressed:
                      _settingsBasis == null ? _showSettingsDialog : null,
                ),
              ],
            ),
            body: ErrorBrookWatcher(
              errors: buildState.errors,
              child: Stack(
                children: <Widget>[
                  SizedBox.expand(
                    child: TaskGridContainer(
                      filter: _filter,
                      useAnimatedLoading: true,
                      schedulePostsubmitBuildForReleaseBranch: () {
                        if (!buildState.authService.isAuthenticated) {
                          return null;
                        }
                        if (buildState.currentRepo != 'flutter') {
                          return null;
                        }
                        if (buildState.currentBranch == 'master') {
                          return null;
                        }
                        return (commit) {
                          return _schedulePostsubmitBuildForReleaseBranch(
                              context: context, commit: commit);
                        };
                      }(),
                    ),
                  ),
                  if (_settingsBasis != null)
                    _settingsDialog(context, buildState),
                ],
              ),
            ),
            drawer: const DashboardNavigationDrawer(),
          ),
        ),
      ),
    );
  }

  Future<void> _schedulePostsubmitBuildForReleaseBranch({
    required BuildContext context,
    required Commit commit,
  }) async {
    final buildState = Provider.of<BuildState>(context, listen: false);
    final response =
        await buildState.cocoonService.schedulePostsubmitsForCommit(
      commit,
      idToken: await buildState.authService.idToken,
      branch: buildState.currentBranch,
      repo: buildState.currentRepo,
    );
    if (!context.mounted) {
      return;
    }
    final SnackBar snackBar;
    if (response.error case final error?) {
      snackBar = SnackBar(content: Text('Failed to schedule: $error.'));
    } else {
      snackBar = SnackBar(
          content: Text('Scheduled post-submits for commit ${commit.sha}.'));
    }
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
