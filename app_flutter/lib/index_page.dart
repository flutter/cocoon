// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'logic/links.dart';
import 'navigation_drawer.dart';
import 'state/index.dart';
import 'widgets/app_bar.dart';
import 'widgets/error_brook_watcher.dart';
import 'widgets/header_text.dart';

/// Index page.
///
/// Expects an [IndexState] to be available via [Provider].
class IndexPage extends StatelessWidget {
  const IndexPage({
    Key key,
  }) : super(key: key);

  static const String routeName = '/';

  static const Widget separator = SizedBox(height: 24.0);

  @override
  Widget build(BuildContext context) {
    final IndexState indexState = Provider.of<IndexState>(context);
    final List<CocoonLink> cocoonLinks = createCocoonLinks(context);
    return AnimatedBuilder(
      animation: indexState,
      builder: (BuildContext context, Widget child) => Scaffold(
        appBar: const CocoonAppBar(
          title: Text('Cocoon'),
        ),
        body: ErrorBrookWatcher(
          errors: indexState.errors,
          child: Center(
            child: ListView(
              children: <Widget>[
                const HeaderText('Select a dashboard'),
                for (CocoonLink link in cocoonLinks)
                  Column(children: <Widget>[
                    IntrinsicWidth(
                      child: ElevatedButton.icon(
                          icon: link.icon, label: Text(link.name.toUpperCase()), onPressed: link.action),
                      stepWidth: 80.0,
                    ),
                    separator,
                  ])
              ],
            ),
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
