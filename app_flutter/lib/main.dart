// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/flutter_build.dart';
import 'status_grid.dart';

void main() => runApp(MyApp());

/// How often to query the Cocoon backend for the current build state.
final Duration dashboardRefreshRate = Duration(seconds: 10);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Build Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BuildDashboardPage(),
    );
  }
}

class BuildDashboardPage extends StatefulWidget {
  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  final FlutterBuildState buildState = FlutterBuildState();

  @override
  void initState() {
    super.initState();

    _updateBuildState();
  }

  /// Recursive function that calls itself to maintain a constant cycle of updates.
  void _updateBuildState() {
    buildState.fetchBuildStatusUpdate();

    Future.delayed(dashboardRefreshRate, () => _updateBuildState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Build Dashboard v2'),
      ),
      body: Column(
        children: [
          ChangeNotifierProvider(
            builder: (context) => buildState,
            child: StatusGrid(),
          ),
        ],
      ),
    );
  }
}
