// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'agent_dashboard_page.dart';
import 'build_dashboard.dart';
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
    final GoogleSignInService signInService = GoogleSignInService(, GoogleSignInService signInService);

    return MaterialApp(
      title: 'Flutter Dashboard',
      theme: theme,
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => IndexPage(signInservice: signInService),
        '/agents': (BuildContext context) => AgentDashboardPage(signInService: signInService),
        '/build': (BuildContext context) => BuildDashboardPage(signInService: signInService,),
      },
    );
  }
}
