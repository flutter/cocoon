// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show CommitStatus;

import 'service/cocoon.dart';
import 'status_grid.dart';

void main() => runApp(MyApp());

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
  final CocoonService service = CocoonService();

  @override
  _BuildDashboardPageState createState() => _BuildDashboardPageState();
}

class _BuildDashboardPageState extends State<BuildDashboardPage> {
  List<CommitStatus> _statuses;

  @override
  void initState() {
    super.initState();

    widget.service
        .fetchCommitStatuses()
        .then((statuses) => setState(() => _statuses = statuses));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Build Dashboard v2'),
      ),
      body: Column(
        children: [
          StatusGrid(
            statuses: _statuses,
          ),
        ],
      ),
    );
  }
}
