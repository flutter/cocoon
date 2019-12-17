// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation_drawer.dart';
import 'sign_in_button.dart';
import 'state/index.dart';

class IndexPage extends StatefulWidget {
  IndexPage({IndexState indexState}) : indexState = indexState ?? IndexState();

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

  void _showErrorSnackbar() {
    final Row snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(indexState.errors.message)
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
      builder: (_, IndexState buildState, Widget child) => Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Cocoon'),
          actions: <Widget>[
            SignInButton(authService: buildState.authService),
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
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/build'),
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
                  child: const Text('Old Build'),
                  onPressed: () => launch('/old_build.html'),
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        drawer: NavigationDrawer(),
      ),
    );
  }
}
