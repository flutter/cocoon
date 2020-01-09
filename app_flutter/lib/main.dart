// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';
import 'index_page.dart';
import 'service/google_authentication.dart';

void main() => runApp(MyApp());

final ThemeData theme = ThemeData(
  appBarTheme: const AppBarTheme(color: Colors.green),
  primarySwatch: Colors.blue,
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final GoogleSignInService signInService = GoogleSignInService();

    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: theme,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        IndexPage.routeName: (BuildContext context) => IndexPage(),
        AgentDashboardPage.routeName: (BuildContext context) =>
            AgentDashboardPage(),
        BuildDashboardPage.routeName: (BuildContext context) =>
            BuildDashboardPage(),
      },
    );
  }
}
