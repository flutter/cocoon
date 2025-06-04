// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard_navigation_drawer.dart';
import '../state/build.dart';
import 'app_bar.dart';
import 'repository_selector.dart';

/// Composable widget built on top of [Scaffold] that provides Cocoon defaults.
///
/// This was originally extracted from `BuildDashboardPage`.
///
/// Requires [BuildState] to be provided at a higher-level widget to be used.
final class CocoonScaffold extends StatelessWidget {
  const CocoonScaffold({
    required this.body,
    required this.onUpdateNavigation,
    required this.title,
    this.actions,
  });

  /// The widget that is isnerted into the resulting [CocoonAppBar.title].
  final Widget title;

  /// The widget that is inserted into the resulting [Scaffold.body].
  final Widget body;

  /// When navigation should be updated.
  final void Function({
    required String repo, //
    required String branch,
  })
  onUpdateNavigation;

  /// Addtional actions that are inserted into [CocoonAppBar.actions].
  final List<Widget>? actions;

  static final _flutterIssueUrl = Uri.https(
    'github.com',
    '/flutter/flutter/issues/new',
    {'labels': 'team-infra'},
  );

  @override
  Widget build(BuildContext context) {
    final buildState = Provider.of<BuildState>(context);
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final smallScreen = mediaQuery.size.width * devicePixelRatio < 600;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          buildState.updateCurrentRepoBranch('flutter', 'master');
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          buildState.updateCurrentRepoBranch('cocoon', 'main');
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          buildState.updateCurrentRepoBranch('packages', 'main');
        },
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
          animation: buildState,
          builder: (context, _) {
            return Scaffold(
              appBar: CocoonAppBar(
                title: title,
                actions: [
                  if (!smallScreen)
                    RepositorySelector(
                      repositories: buildState.repos,
                      branches: buildState.branches,
                      selectedRepository: buildState.currentRepo,
                      selectedBranch: buildState.currentBranch,
                      onRepositoryChange: (newRepo) {
                        onUpdateNavigation(
                          repo: newRepo,
                          branch: buildState.currentBranch,
                        );
                      },
                      onBranchChange: (newBranch) {
                        onUpdateNavigation(
                          repo: buildState.currentRepo,
                          branch: newBranch,
                        );
                      },
                      smallScreen: smallScreen,
                    ),
                  IconButton(
                    tooltip: 'Report Issue',
                    icon: const Icon(Icons.bug_report),
                    onPressed: () async {
                      await launchUrl(_flutterIssueUrl);
                    },
                  ),
                  ...?actions,
                ],
              ),
              body: body,
              drawer: const DashboardNavigationDrawer(),
            );
          },
        ),
      ),
    );
  }
}
