// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_progress_button/flutter_progress_button.dart';
import 'package:provider/provider.dart';

import 'agent_list.dart';
import 'app_bar.dart';
import 'error_brook_watcher.dart';
import 'navigation_drawer.dart';
import 'state/agent.dart';

/// Shows current status of Flutter infra agents.
///
/// If [agentFilter] is non-null and non-empty, it will only show agents
/// with [agentId] that contains [agentFilter]. Otherwise, all agents are shown.
class AgentDashboardPage extends StatefulWidget {
  const AgentDashboardPage({
    Key key,
    this.agentFilter,
  }) : super(key: key);

  /// Search term to filter the agents from [agentState] and show only those
  /// that contain this term.
  ///
  /// If this is null, the [Route.arguments] value is used instead.
  final String agentFilter;

  static const String routeName = '/agents';

  @override
  State<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends State<AgentDashboardPage> {
  AgentState _agentState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _agentState = Provider.of<AgentState>(context)..startFetchingStateUpdates();
  }

  void _showCreateAgentDialog(BuildContext context, AgentState agentState) {
    showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) => CreateAgentDialog(agentState: agentState),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _agentState,
      builder: (BuildContext context, Widget child) => Scaffold(
        appBar: const CocoonAppBar(
          title: Text('Infra Agents'),
        ),
        body: ErrorBrookWatcher(
          errors: _agentState.errors,
          child: Column(
            // TODO(ianh): Replace with a more idiomatic solution.
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Without this container the ListView will not be centered.
              Container(),
              Expanded(
                child: SizedBox(
                  width: 500,
                  child: AgentList(
                    // TODO(ianh): stop passing both the state and the value from the state
                    agents: _agentState.agents,
                    agentState: _agentState,
                    agentFilter: widget.agentFilter ?? ModalRoute.of(context).settings.arguments as String,
                  ),
                ),
              ),
            ],
          ),
        ),
        drawer: const NavigationDrawer(),
        floatingActionButton: FloatingActionButton.extended(
          icon: Icon(Icons.add),
          label: const Text('CREATE AGENT'),
          onPressed: () => _showCreateAgentDialog(context, _agentState),
        ),
      ),
    );
  }
}

/// Dialog with a form that has inputs necessary for creating an agent.
///
/// User must input an agent id and a list of capabilities to create an agent.
/// Capabilities are inputted as a comma delimited list.
class CreateAgentDialog extends StatefulWidget {
  const CreateAgentDialog({
    Key key,
    this.agentState,
  }) : super(key: key);

  final AgentState agentState;

  @override
  _CreateAgentDialogState createState() => _CreateAgentDialogState();
}

class _CreateAgentDialogState extends State<CreateAgentDialog> {
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
    return AlertDialog(
      title: const Text('Create Agent'),
      content: Form(
        child: SizedBox(
          height: 200,
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
      ),
    );
  }

  /// Send a request to Cocoon to create an agent with the values inputted
  /// to the form.
  Future<void> _createAgent(BuildContext context) async {
    final String id = _agentIdController.value.text;
    final List<String> capabilities = _agentCapabilitiesController.value.text.split(',');
    final String token = await widget.agentState.createAgent(id, capabilities);

    // TODO(chillers): Copy the token to clipboard when web has support. https://github.com/flutter/flutter/issues/46020
    debugPrint('$id: $token');
    debugPrint('Capabilities: $capabilities');

    Navigator.pop(context);
  }
}
