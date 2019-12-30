// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'agent_health_details.dart';

/// A card for showing the information from an [Agent].
///
/// Summarizes [Agent.healthDetails] into a row of icons.
///
/// Offers the ability to view the raw health details of the agent and
/// regenerate an access token for the agent.
class AgentTile extends StatelessWidget {
  const AgentTile(this.agent);

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final DateTime currentTime = DateTime.now();
    final DateTime agentTime =
        DateTime.fromMillisecondsSinceEpoch(agent.healthCheckTimestamp.toInt());
    final Duration agentLastUpdateDuration = currentTime.difference(agentTime);

    final AgentHealthDetails healthDetails =
        AgentHealthDetails(agent.healthDetails, agentLastUpdateDuration);

    const String authorizeAgentValue = 'authorize';
    const String healthDetailsValue = 'details';
    const String reserveTaskValue = 'reserve';

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
              value: healthDetailsValue,
            ),
            const PopupMenuItem<String>(
              child: Text('Authorize agent'),
              value: authorizeAgentValue,
            ),
            const PopupMenuItem<String>(
              child: Text('Reserve task'),
              value: reserveTaskValue,
            ),
          ],
          icon: Icon(Icons.more_vert),
          onSelected: (String value) {
            switch (value) {
              case healthDetailsValue:
                _showHealthDetailsDialog(context);
                break;
              case authorizeAgentValue:
                _showAuthorizeAgentDialog(context);
                break;
              case reserveTaskValue:
                _showReserveTaskDialog(context);
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

  void _showHealthDetailsDialog(BuildContext context) {
    showDialog<SimpleDialog>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        children: <Widget>[
          Text(agent.healthDetails),
        ],
      ),
    );
  }

  void _showAuthorizeAgentDialog(BuildContext context) {}

  void _showReserveTaskDialog(BuildContext context) {}
}
