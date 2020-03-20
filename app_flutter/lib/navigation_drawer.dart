// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';
import 'index_page.dart';

/// Sidebar for navigating the different pages of Cocoon.
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String currentRoute = ModalRoute.of(context).settings.name;
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: const FlutterLogoDecoration(
              margin: EdgeInsets.only(bottom: 24.0),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: const Text('Flutter Dashboard'),
            ),
          ),
          ListTile(
            title: const Text('Home'),
            leading: Icon(Icons.home),
            onTap: () => Navigator.pushReplacementNamed(context, IndexPage.routeName),
            selected: currentRoute == '/',
          ),
          ListTile(
            title: const Text('Build'),
            leading: Icon(Icons.build),
            onTap: () => Navigator.pushReplacementNamed(context, BuildDashboardPage.routeName),
            selected: currentRoute == '/build',
          ),
          ListTile(
            title: const Text('Benchmarks'),
            leading: Icon(Icons.show_chart),
            onTap: () => launch('/benchmarks.html'),
          ),
          ListTile(
            title: const Text('Benchmarks on Skia Perf'),
            leading: Icon(Icons.show_chart),
            onTap: () => launch('https://flutter-perf.skia.org/'),
          ),
          ListTile(
            title: const Text('Repository'),
            leading: Icon(Icons.info_outline),
            onTap: () => launch('/repository.html'),
          ),
          const Divider(thickness: 2.0),
          ListTile(
            title: const Text('Infra Agents'),
            leading: Icon(Icons.android),
            onTap: () => Navigator.pushReplacementNamed(context, AgentDashboardPage.routeName),
            selected: currentRoute == '/agents',
          ),
          const Divider(thickness: 2.0),
          ListTile(
            title: const Text('Source Code'),
            leading: Icon(Icons.code),
            onTap: () => launch('https://github.com/flutter/cocoon'),
          ),
          const AboutListTile(
            icon: FlutterLogo(),
          ),
        ],
      ),
    );
  }
}
