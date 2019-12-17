// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationDrawer extends StatelessWidget {
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
            title: const Text('Build'),
            onTap: () => Navigator.pushReplacementNamed(context, '/build'),
          ),
          // ListTile(
          //   title: const Text('Infra Agents'),
          //   onTap: () => Navigator.pushNamed(context, '/agent.html'),
          // ),
          ListTile(
            title: const Text('Performance'),
            onTap: () => launch('/benchmarks.html'),
          ),
          ListTile(
            title: const Text('Repository'),
            onTap: () => launch('/repository.html'),
          ),
        ],
      ),
    );
  }
}
