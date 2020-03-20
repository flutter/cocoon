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
  // - the widget doesn't have a key argument
  // - the widget itself (as opposed to its State) has state (it creates an IndexState)
  // - the State doesn't handle the widget's indexState property changing dynamically
  // - the State doesn't handle the case of the signInService changing dynamically
  // - the State caches the indexState from the widget, leading to a two-sources-of-truth situation
  // We could probably solve most of these problems by moving all the app state out of the widget
  // tree and using inherited widgets to get at it.

  IndexPage({IndexState indexState, GoogleSignInService signInService})
      : indexState = indexState ?? IndexState(authServiceValue: signInService);

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
  const Index({this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Consumer<IndexState>(
      builder: (_, IndexState indexState, Widget child) => Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Cocoon'),
          actions: <Widget>[
            SignInButton(authService: indexState.authService),
          ],
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Container(height: 50),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  child: const Text('Build'),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/build'),
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                ),
              ),
              Container(height: 25),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  child: const Text('Performance'),
                  onPressed: () => launch('/benchmarks.html'),
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                ),
              ),
              Container(height: 25),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  child: const Text('Benchmarks on Skia Perf'),
                  onPressed: () => launch('https://flutter-perf.skia.org/'),
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                ),
              ),
              Container(height: 25),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  child: const Text('Repository'),
                  onPressed: () => launch('/repository.html'),
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                ),
              ),
              Container(height: 50),
              SizedBox(
                width: 300,
                child: RaisedButton(
                  child: const Text('Infra Agents'),
                  onPressed: () => Navigator.pushReplacementNamed(context, '/agents'),
                  padding: const EdgeInsets.all(20),
                  color: Colors.blueAccent,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        drawer: const NavigationDrawer(),
      ),
    );
  }
}
