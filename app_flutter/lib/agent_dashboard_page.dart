// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_progress_button/flutter_progress_button.dart';
import 'package:provider/provider.dart';

import 'agent_list.dart';
import 'navigation_drawer.dart';
import 'service/google_authentication.dart';
import 'sign_in_button.dart';
import 'state/agent.dart';

/// [AgentDashboardPage] parent widget that manages the state of the dashboard.
class AgentDashboardPage extends StatefulWidget {
  AgentDashboardPage({
    AgentState agentState,
    GoogleSignInService signInService,
    @visibleForTesting this.agentFilter,
  }) : agentState = agentState ?? AgentState(authServiceValue: signInService);

  static const String routeName = '/agents';

  final AgentState agentState;

  final String agentFilter;

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

    final String agentFilter =
        ModalRoute.of(context).settings.arguments ?? widget.agentFilter;

    return ChangeNotifierProvider<AgentState>(
      create: (_) => agentState,
      child: AgentDashboard(
        scaffoldKey: _scaffoldKey,
        agentState: agentState,
        agentFilter: agentFilter,
      ),
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
class AgentDashboard extends StatefulWidget {
  const AgentDashboard({
    this.scaffoldKey,
    this.agentState,
    this.agentFilter,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final AgentState agentState;
  final String agentFilter;

  @override
  _AgentDashboardState createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  TextEditingController _agentIdController;
  TextEditingController _agentCapabilitiesController;

  @override
  void initState() {
    super.initState();

    _agentIdController = TextEditingController();
    _agentCapabilitiesController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AgentState>(
      builder: (_, AgentState agentState, Widget child) => Scaffold(
        key: widget.scaffoldKey,
        appBar: AppBar(
          title: const Text('Infra Agents'),
          actions: <Widget>[
            SignInButton(authService: agentState.authService),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Without this container the ListView will not be centered.
            Container(),
            Expanded(
              child: SizedBox(
                width: 500,
                child: AgentList(
                  agents: agentState.agents,
                  agentState: agentState,
                  agentFilter: widget.agentFilter,
                ),
              ),
            ),
          ],
        ),
        drawer: const NavigationDrawer(
          currentRoute: AgentDashboardPage.routeName,
        ),
        floatingActionButton: RaisedButton(
          child: const Text(
            'Create Agent',
            textScaleFactor: 1.5,
          ),
          color: Theme.of(context).primaryColor,
          padding: const EdgeInsets.all(10.0),
          onPressed: () => _showCreateAgentDialog(context, agentState),
        ),
      ),
    );
  }

  void _showCreateAgentDialog(BuildContext context, AgentState agentState) {
    showDialog<AlertDialog>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Create Agent'),
            content: Form(
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _agentIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter agent id',
                    ),
                    validator: (String value) {
                      if (value.isEmpty) {
                        return 'Please enter an agent id (e.g. flutter-devicelab-linux-14)';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _agentCapabilitiesController,
                    decoration: const InputDecoration(
                      hintText: 'Enter agent capabilities',
                    ),
                    validator: (String value) {
                      if (value.split(',').isEmpty) {
                        return 'Please enter agent capabilities as comma delimited list (e.g. linux,linux/android)';
                      }

                      return value;
                    },
                  ),
                  Container(height: 25),
                  ProgressButton(
                    defaultWidget: const Text('Create'),
                    progressWidget: const CircularProgressIndicator(),
                    onPressed: () async => _createAgent(context),
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _createAgent(BuildContext context) async {
    final String id = _agentIdController.value.text;
    final List<String> capabilities =
        _agentCapabilitiesController.value.text.split(',');
    final String token = await widget.agentState.createAgent(id, capabilities);

    // TODO(chillers): Copy the token to clipboard when web has support. https://github.com/flutter/flutter/issues/46020
    print('$id: $token');
    print('Capabilities: $capabilities');

    Navigator.pop(context);
  }
}
