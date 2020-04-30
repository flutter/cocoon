// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import '../logic/agent_health_details.dart';
import '../state/agent.dart';
import 'agent_health_details_bar.dart';
import 'now.dart';

/// Values to be used in [PopupMenu] to know what action to execute.
enum _AgentTileAction { details, authorize, reserve }

/// A card for showing the information from an [Agent].
///
/// Summarizes [Agent.healthDetails] into a row of icons.
///
/// Offers the ability to view the agent raw health details, re-authorize the
/// agent, and attempt to reserve a task for the agent.
class AgentTile extends StatelessWidget {
  const AgentTile({
    Key key,
    this.agentHealthDetails,
    this.agentState,
  }) : super(key: key);

  final AgentState agentState;

  final AgentHealthDetails agentHealthDetails;

  @visibleForTesting
  static const Duration authorizeAgentSnackbarDuration = Duration(seconds: 5);

  @visibleForTesting
  static const Duration reserveTaskSnackbarDuration = Duration(seconds: 5);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DateTime now = Now.of(context);

    final Agent agent = agentHealthDetails.agent;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: agentHealthDetails.isHealthy(now)
              ? Colors.green
              : theme.errorColor,
          foregroundColor: Colors.white,
          child: _getIconFromId(agent.agentId),
        ),
        title: Text(agent.agentId),
        subtitle: AgentHealthDetailsBar(agentHealthDetails),
        trailing: PopupMenuButton<_AgentTileAction>(
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<_AgentTileAction>>[
            const PopupMenuItem<_AgentTileAction>(
              child: Text('Raw health details'),
              value: _AgentTileAction.details,
            ),
            const PopupMenuItem<_AgentTileAction>(
              child: Text('Authorize agent'),
              value: _AgentTileAction.authorize,
            ),
            const PopupMenuItem<_AgentTileAction>(
              child: Text('Reserve task'),
              value: _AgentTileAction.reserve,
            ),
          ],
          icon: const Icon(Icons.more_vert),
          onSelected: (_AgentTileAction value) {
            switch (value) {
              case _AgentTileAction.details:
                _showHealthDetailsDialog(context, agent.healthDetails);
                break;
              case _AgentTileAction.authorize:
                _authorizeAgent(context, agent);
                break;
              case _AgentTileAction.reserve:
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

  /// A lookup function for showing the leading icon based on [agentId].
  Icon _getIconFromId(String agentId) {
    if (agentId.contains('vm')) {
      return const Icon(Icons.dns);
    } else if (agentId.contains('linux')) {
      return const Icon(Icons.android);
    } else if (agentId.contains('mac')) {
      return const Icon(Icons.phone_iphone);
    } else if (agentId.contains('windows')) {
      return const Icon(Icons.desktop_windows);
    }

    return const Icon(Icons.device_unknown);
  }

  void _showHealthDetailsDialog(BuildContext context, String rawHealthDetails) {
    // TODO(chillers): Add copy button when web has support. https://github.com/flutter/flutter/issues/46020
    debugPrint('health details: $rawHealthDetails');

    showDialog<SimpleDialog>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: <Widget>[
          Text(rawHealthDetails),
        ],
      ),
    );
  }

  /// Call [authorizeAgent] to Cocoon for [agent] and show the new access token.
  ///
  /// On success, displays a [SnackBar] telling the user the access token can
  /// be found in their console.
  ///
  /// If the request fails, [AgentDashboardPage] will handle the error and show
  /// a [SnackBar].
  Future<void> _authorizeAgent(BuildContext context, Agent agent) async {
    final String token = await agentState.authorizeAgent(agent);
    if (token != null) {
      // TODO(chillers): Copy the token to clipboard when web has support. https://github.com/flutter/flutter/issues/46020
      debugPrint('token: $token');

      Scaffold.of(context).showSnackBar(const SnackBar(
        content: Text('Check console for token'),
        duration: authorizeAgentSnackbarDuration,
      ));
    }
  }

  /// Call [reserveTask] to Cocoon for [agent] and show the information for
  /// the [Task] that was reserved.
  ///
  /// On success, displays a [SnackBar] telling the user the information can
  /// be found in their console. The data is just the ids and names for the
  /// task its commit.
  ///
  /// If the request fails, [AgentDashboardPage] will handle the error and show
  /// a [SnackBar].
  Future<void> _reserveTask(BuildContext context, Agent agent) async {
    await agentState.reserveTask(agent);
    Scaffold.of(context).showSnackBar(const SnackBar(
      content: Text('Check console for reserve task info'),
      duration: authorizeAgentSnackbarDuration,
    ));
  }
}
