// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_bar.dart';
import 'error_brook_watcher.dart';
import 'navigation_drawer.dart';
import 'state/index.dart';

/// Index page
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
    return AnimatedBuilder(
      animation: indexState,
      builder: (BuildContext context, Widget child) => Scaffold(
        appBar: const CocoonAppBar(
          title: Text('Cocoon'),
        ),
        body: ErrorBrookWatcher(
          errors: indexState.errors,
          child: Center(
            child: IntrinsicWidth(
              stepWidth: 80.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  separator,
                  // TODO(ianh): Factor out into a HeaderText widget.
                  Text('Select a dashboard', style: Theme.of(context).textTheme.headline4, textAlign: TextAlign.center),
                  separator,
                  RaisedButton.icon(
                    icon: Icon(Icons.build),
                    label: const Text('BUILD'),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/build'),
                  ),
                  separator,
                  RaisedButton.icon(
                    icon: Icon(Icons.show_chart),
                    label: const Text('BENCHMARKS'),
                    onPressed: () => launch('/benchmarks.html'),
                  ),
                  separator,
                  RaisedButton.icon(
                    icon: Icon(Icons.show_chart),
                    label: const Text('BENCHMARKS ON SKIA PERF'),
                    onPressed: () => launch('https://flutter-perf.skia.org/'),
                  ),
                  separator,
                  RaisedButton.icon(
                    icon: Icon(Icons.info_outline),
                    label: const Text('REPOSITORY'),
                    onPressed: () => launch('/repository.html'),
                  ),
                  separator,
                  const Divider(thickness: 2.0),
                  separator,
                  RaisedButton.icon(
                    icon: Icon(Icons.android),
                    label: const Text('INFRA AGENTS'),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/agents'),
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
