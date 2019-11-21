// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'build_dashboard.dart';

void main() => runApp(MyApp());

final ThemeData theme = ThemeData(
  appBarTheme: AppBarTheme(color: Colors.green),
  primarySwatch: Colors.blue,
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Build Dashboard',
      theme: theme,
      home: BuildDashboardPage(),
    );
  }
}
