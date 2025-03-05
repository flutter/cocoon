// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'logic/links.dart';

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
          const AboutListTile(
            icon: FlutterLogo(),
          ),
        ],
      ),
    );
  }
}
