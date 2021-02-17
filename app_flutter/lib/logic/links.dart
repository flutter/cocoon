// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../agent_dashboard_page.dart';
import '../build_dashboard_page.dart';
import '../index_page.dart';

/// List of links that are shown on [IndexPage] and in the [NavigationDrawer].
List<CocoonLink> createCocoonLinks(BuildContext context) {
  return <CocoonLink>[
    CocoonLink(
      name: 'Home',
      route: IndexPage.routeName,
      icon: const Icon(Icons.home),
      action: () => Navigator.pushReplacementNamed(context, IndexPage.routeName),
    ),
    CocoonLink(
      name: 'Build',
      route: BuildDashboardPage.routeName,
      icon: const Icon(Icons.build),
      action: () => Navigator.pushReplacementNamed(context, BuildDashboardPage.routeName),
    ),
    CocoonLink(
      name: 'Framework Benchmarks on Skia Perf',
      icon: const Icon(Icons.show_chart),
      action: () => launch('https://flutter-flutter-perf.skia.org/'),
    ),
    CocoonLink(
      name: 'Engine Benchmarks on Skia Perf',
      icon: const Icon(Icons.show_chart),
      action: () => launch('https://flutter-engine-perf.skia.org/'),
    ),
    CocoonLink(
      name: 'Repository',
      icon: const Icon(Icons.info_outline),
      action: () => launch('/repository.html'),
    ),
    CocoonLink(
      name: 'Infra Agents',
      route: AgentDashboardPage.routeName,
      icon: const Icon(Icons.android),
      action: () => Navigator.pushReplacementNamed(context, AgentDashboardPage.routeName),
    ),
    CocoonLink(
      name: 'Source Code',
      icon: const Icon(Icons.code),
      action: () => launch('https://github.com/flutter/cocoon'),
    ),
  ];
}

/// Data class for storing links on the Cocoon app.
class CocoonLink {
  const CocoonLink({
    this.name,
    this.route,
    this.action,
    this.icon,
  });

  /// Text shown to users describing this link.
  final String name;

  /// If the link is internal to this Flutter app, this can be passed to highlight on the [NavigationDrawer] the page the user is on.
  final String route;

  /// An [Icon] to represent this link.
  final Icon icon;

  /// Callback for when the link is activated.
  ///
  /// Can be used to redirect to internal or external routes. Will have acess to the [BuildContext].
  final Function action;
}
