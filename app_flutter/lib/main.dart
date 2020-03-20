// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';
import 'index_page.dart';
import 'service/google_authentication.dart';

void main() => runApp(const MyApp());

final ThemeData lightTheme = ThemeData.from(
  colorScheme: ColorScheme.light(
    primary: Colors.green,
    secondary: Colors.blueAccent,
  ),
);

final ThemeData darkTheme = ThemeData.from(
  colorScheme: ColorScheme.dark(
    primary: Colors.green,
    secondary: Colors.blueAccent,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoogleSignInService signInService = GoogleSignInService();

    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        IndexPage.routeName: (BuildContext context) => IndexPage(signInService: signInService),
        AgentDashboardPage.routeName: (BuildContext context) => AgentDashboardPage(signInService: signInService),
        BuildDashboardPage.routeName: (BuildContext context) => BuildDashboardPage(signInService: signInService),
      },
    );
  }
}
