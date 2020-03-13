// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';

/// Sidebar for navigating the different pages of Cocoon.
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({this.currentRoute});

  /// When given, will make the corresponding [ListTile] selected.
  ///
  /// Since Navigator cannot provide the current route, must be passed
  /// where this widget is used.
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Row(
              children: const <Widget>[
                FlutterLogo(),
                Text('Flutter Dashboards'),
              ],
            ),
          ),
          ListTile(
            key: const Key('nav-link-build'),
            title: const Text('Build'),
            leading: Icon(Icons.build),
            onTap: () => Navigator.pushReplacementNamed(
                context, BuildDashboardPage.routeName),
            selected: currentRoute == '/build',
          ),
          ListTile(
            key: const Key('nav-link-skia-perf'),
            title: const Text('Benchmarks on Skia Perf'),
            leading: Icon(Icons.show_chart),
            onTap: () => launch('https://flutter-perf.skia.org/'),
          ),
          ListTile(
            key: const Key('nav-link-benchmarks'),
            title: const Text('Benchmarks'),
            leading: Icon(Icons.show_chart),
            onTap: () => launch('/benchmarks.html'),
          ),
          ListTile(
            key: const Key('nav-link-repository'),
            title: const Text('Repository'),
            leading: Icon(Icons.info_outline),
            onTap: () => launch('/repository.html'),
          ),
          ListTile(
            key: const Key('nav-link-agents'),
            title: const Text('Infra Agents'),
            leading: Icon(Icons.android),
            onTap: () => Navigator.pushReplacementNamed(
                context, AgentDashboardPage.routeName),
            selected: currentRoute == '/agents',
          ),
          ListTile(
            key: const Key('nav-link-source'),
            title: const Text('Source Code'),
            leading: Icon(Icons.code),
            onTap: () => launch('https://github.com/flutter/cocoon'),
          ),
        ],
      ),
    );
  }
}
