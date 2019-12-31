// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'agent_health_details.dart';
import 'agent_list.dart';
import 'state/agent.dart';

/// A card for showing the information from an [Agent].
///
/// Summarizes [Agent.healthDetails] into a row of icons.
///
/// Offers the ability to view the raw health details of the agent and
/// regenerate an access token for the agent.
class AgentTile extends StatelessWidget {
  const AgentTile({this.fullAgent, this.agentState});

  final AgentState agentState;

  final FullAgent fullAgent;

  @visibleForTesting
  static const Duration authorizeAgentSnackbarDuration = Duration(seconds: 5);

  @visibleForTesting
  static const Duration reserveTaskSnackbarDuration = Duration(seconds: 5);

  static const String _authorizeAgentValue = 'authorize';
  static const String _healthDetailsValue = 'details';
  static const String _reserveTaskValue = 'reserve';

  @override
  Widget build(BuildContext context) {
    final Agent agent = fullAgent.agent;
    final AgentHealthDetails healthDetails = fullAgent.healthDetails;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: healthDetails.isHealthy ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          child: _getIconFromId(agent.agentId),
        ),
        title: Text(agent.agentId),
        subtitle: AgentHealthDetailsBar(healthDetails),
        trailing: PopupMenuButton<String>(
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              child: Text('Raw health details'),
              value: _healthDetailsValue,
            ),
            const PopupMenuItem<String>(
              child: Text('Authorize agent'),
              value: _authorizeAgentValue,
            ),
            const PopupMenuItem<String>(
              child: Text('Reserve task'),
              value: _reserveTaskValue,
            ),
          ],
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            switch (value) {
              case _healthDetailsValue:
                _showHealthDetailsDialog(context, agent.healthDetails);
                break;
              case _authorizeAgentValue:
                _authorizeAgent(context, agent);
                break;
              case _reserveTaskValue:
                _reserveTask(context, agent);
                break;
              default:
                throw Exception(
                    '$value is not a valid operation on AgentTile popup menu');
            }
          },
        ),
      ),
    );
  }

  Icon _getIconFromId(String agentId) {
    if (agentId.contains('vm')) {
      return Icon(Icons.dns);
    } else if (agentId.contains('linux')) {
      return Icon(Icons.android);
    } else if (agentId.contains('mac')) {
      return Icon(Icons.phone_iphone);
    } else if (agentId.contains('windows')) {
      return Icon(Icons.desktop_windows);
    }

    return Icon(Icons.device_unknown);
  }

  void _showHealthDetailsDialog(BuildContext context, String rawHealthDetails) {
    // TODO(chillers): Add copy button when web has support. https://github.com/flutter/flutter/issues/46020
    print(rawHealthDetails);

    showDialog<SimpleDialog>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: <Widget>[
          Text(rawHealthDetails),
        ],
      ),
    );
  }

  Future<void> _authorizeAgent(BuildContext context, Agent agent) async {
    final String token = await agentState.authorizeAgent(agent);
    if (token != null) {
      print(token);

      Scaffold.of(context).showSnackBar(const SnackBar(
        content: Text('Check console for token'),
        duration: authorizeAgentSnackbarDuration,
      ));
    }
    // if the token is null, the error handler will print the snackbar
  }

  Future<void> _reserveTask(BuildContext context, Agent agent) async {
    await agentState.reserveTask(agent);
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Check console for reserve task info'),
      duration: authorizeAgentSnackbarDuration,
    ));
  }
}
