// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/links.dart';
import 'service/scenarios.dart';
import 'state/build.dart';

/// Sidebar for navigating the different pages of Cocoon.
class DashboardNavigationDrawer extends StatelessWidget {
  const DashboardNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cocoonLinks = createCocoonLinks(context);
    final currentRoute = ModalRoute.of(context)!.settings.name;
    return Drawer(
      child: ListView(
        children: <Widget>[
          const DrawerHeader(
            decoration: FlutterLogoDecoration(
              margin: EdgeInsets.only(bottom: 24.0),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text('Flutter Build Dashboard — Cocoon'),
            ),
          ),
          ...cocoonLinks.map(
            (CocoonLink link) => ListTile(
              leading: link.icon,
              title: Text(link.name!),
              onTap: link.action,
              selected: currentRoute == link.route,
            ),
          ),
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Scenarios'),
              onTap: () {
                Navigator.pop(context);
                _showScenarioDialog(context);
              },
            ),
          ],
          const AboutListTile(icon: FlutterLogo()),
        ],
      ),
    );
  }

  void _showScenarioDialog(BuildContext context) {
    final buildState = Provider.of<BuildState>(context, listen: false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dev Tools: Select Scenario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Scenario.values.map((scenario) {
              return ListTile(
                title: Text(scenario.name),
                onTap: () {
                  buildState.resetScenario(scenario);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
