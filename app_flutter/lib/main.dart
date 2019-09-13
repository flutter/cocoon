// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'result_box.dart';

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

class BuildDashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Build Dashboard v2'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // To demo the different result messages
            ResultBox(message: 'Succeeded'),
            ResultBox(message: 'Failed'),
            ResultBox(message: 'New'),
            ResultBox(message: 'In Progress'),
            ResultBox(message: 'Skipped'),
            ResultBox(message: 'Underperformed'),
            ResultBox(message: 'not found'),
          ],
        ),
      ),
    );
  }
}