// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_drawer.dart';
import 'service/google_authentication.dart';
import 'sign_in_button.dart';
import 'state/index.dart';

class IndexPage extends StatefulWidget {
  // TODO(ianh): there's a number of problems with the design here
  // - the widget itself (as opposed to its State) has state (it creates an IndexState)
  // - the State doesn't handle the widget's indexState property changing dynamically
  // - the State doesn't handle the case of the signInService changing dynamically
  // - the State caches the indexState from the widget, leading to a two-sources-of-truth situation
  // We could probably solve most of these problems by moving all the app state out of the widget
  // tree and using inherited widgets to get at it.

  IndexPage({
    Key key,
    IndexState indexState,
    GoogleSignInService signInService,
  })  : indexState = indexState ?? IndexState(authServiceValue: signInService),
        super(key: key);

  static const String routeName = '/';

  final IndexState indexState;

  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);
  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  IndexState indexState;

  @override
  void initState() {
    super.initState();
    widget.indexState.errors.addListener(_showErrorSnackbar);
  }

  @override
  Widget build(BuildContext context) {
    indexState = widget.indexState;
    return ChangeNotifierProvider<IndexState>(
      create: (_) => indexState,
      child: Index(scaffoldKey: _scaffoldKey),
    );
  }

  void _showErrorSnackbar(String error) {
    final Row snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(error),
      ],
    );
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: snackbarContent,
        backgroundColor: Theme.of(context).errorColor,
        duration: IndexPage.errorSnackbarDuration,
      ),
    );
  }

  @override
  void dispose() {
    indexState.errors.removeListener(_showErrorSnackbar);
    super.dispose();
  }
}

class Index extends StatelessWidget {
  const Index({
    Key key,
    this.scaffoldKey,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;

  static const Widget separator = SizedBox(height: 24.0);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Consumer<IndexState>(
      builder: (BuildContext context, IndexState indexState, Widget child) => Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Cocoon'),
          actions: <Widget>[
            SignInButton(
              authService: indexState.authService,
              colorBrightness: theme.appBarTheme.brightness ?? theme.primaryColorBrightness,
            ),
          ],
        ),
        body: Center(
          child: IntrinsicWidth(
            stepWidth: 80.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                separator,
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
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
