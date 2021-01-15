// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard_page.dart';
import 'index_page.dart';
import 'service/cocoon.dart';
import 'service/google_authentication.dart';
import 'state/agent.dart';
import 'state/build.dart';
import 'state/index.dart';
import 'widgets/now.dart';
import 'widgets/state_provider.dart';

void main(List<String> args) {
  final GoogleSignInService authService = GoogleSignInService();
  bool useProductionService = kReleaseMode;
  if (args.contains('--use-production-service')) {
    useProductionService = true;
  }
  if (args.contains('--no-use-production-service')) {
    useProductionService = false;
  }
  final CocoonService cocoonService = CocoonService(useProductionService: useProductionService);
  runApp(
    StateProvider(
      signInService: authService,
      indexState: IndexState(authService: authService),
      agentState: AgentState(authService: authService, cocoonService: cocoonService),
      buildState: BuildState(authService: authService, cocoonService: cocoonService),
      child: Now(child: const MyApp()),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        IndexPage.routeName: (BuildContext context) => const IndexPage(),
        AgentDashboardPage.routeName: (BuildContext context) => const AgentDashboardPage(),
        BuildDashboardPage.routeName: (BuildContext context) => const BuildDashboardPage(),
      },
      onGenerateRoute: (RouteSettings settings) {
        final Uri uriData = Uri.parse(settings.name);
        if (uriData.path == BuildDashboardPage.routeName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (BuildContext context) => BuildDashboardPage(queryParameters: uriData.queryParameters),
          );
        }
        return null;
      },
    );
  }
}
