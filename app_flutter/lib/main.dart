// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';
import 'index_page.dart';
import 'service/cocoon.dart';
import 'service/google_authentication.dart';
import 'state/agent.dart';
import 'state/flutter_build.dart';
import 'state/index.dart';
import 'state_provider.dart';

void main() {
  final GoogleSignInService authService = GoogleSignInService();
  final CocoonService cocoonService = CocoonService();
  runApp(
    StateProvider(
      signInService: authService,
      indexState: IndexState(authService: authService),
      agentState: AgentState(authService: authService, cocoonService: cocoonService),
      buildState: FlutterBuildState(authService: authService, cocoonService: cocoonService),
      child: const MyApp(),
    ),
  );
}

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
    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        IndexPage.routeName: (BuildContext context) => const IndexPage(),
        AgentDashboardPage.routeName: (BuildContext context) => const AgentDashboardPage(),
        BuildDashboardPage.routeName: (BuildContext context) => const BuildDashboardPage(),
      },
    );
  }
}
