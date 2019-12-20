// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'agent.dart';
import 'navigation_drawer.dart';
import 'service/google_authentication.dart';
import 'sign_in_button.dart';
import 'state/agent.dart';

/// [AgentDashboardPage] parent widget that manages the state of the dashboard.
class AgentDashboardPage extends StatefulWidget {
  AgentDashboardPage({AgentState agentState, GoogleSignInService signInService})
      : agentState = agentState ?? AgentState(authServiceValue: signInService);

  final AgentState agentState;

  @visibleForTesting
  static const Duration errorSnackbarDuration = Duration(seconds: 8);
  @override
  _AgentDashboardPageState createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends State<AgentDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  AgentState agentState;

  @override
  void initState() {
    super.initState();

    widget.agentState.startFetchingStateUpdates();

    widget.agentState.errors.addListener(_showErrorSnackbar);
  }

  @override
  Widget build(BuildContext context) {
    agentState = widget.agentState;

    return ChangeNotifierProvider<AgentState>(
      create: (_) => agentState,
      child: AgentDashboard(scaffoldKey: _scaffoldKey),
    );
  }

  void _showErrorSnackbar() {
    final Row snackbarContent = Row(
      children: <Widget>[
        const Icon(Icons.error),
        const SizedBox(width: 10),
        Text(agentState.errors.message)
      ],
    );
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: snackbarContent,
        backgroundColor: Theme.of(context).errorColor,
        duration: AgentDashboardPage.errorSnackbarDuration,
      ),
    );
  }

  @override
  void dispose() {
    agentState.errors.removeListener(_showErrorSnackbar);
    super.dispose();
  }
}

/// Shows current status of Flutter infra agents.
class AgentDashboard extends StatelessWidget {
  const AgentDashboard({this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentState>(
      builder: (_, AgentState agentState, Widget child) => Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: const Text('Infra Agents'),
          actions: <Widget>[
            SignInButton(authService: agentState.authService),
          ],
        ),
        body: Column(
          children: <Widget>[
            Container(height: 25),
            Expanded(
              child: ListView(
                children: List<Widget>.generate(
                  agentState.agents.length,
                  (int i) => AgentTile(agentState.agents[i]),
                ),
              ),
            ),
          ],
        ),
        drawer: const NavigationDrawer(
          currentRoute: '/agents',
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add_to_queue),
          onPressed: () => print('trying to work'),
        ),
      ),
    );
  }
}
