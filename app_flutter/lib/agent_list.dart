// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'agent_health_details.dart';
import 'agent_tile.dart';
import 'state/agent.dart';

class AgentList extends StatelessWidget {
  const AgentList(
      {this.agents,
      this.agentState,
      @visibleForTesting this.insertKeys = false});

  final List<Agent> agents;

  final AgentState agentState;

  /// When true, will set a key for the [AgentTile] that is composed of its
  /// position in the list and the agent id.
  @visibleForTesting
  final bool insertKeys;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return const CircularProgressIndicator();
    }

    final List<FullAgent> fullAgents = agents
        .map((Agent agent) => FullAgent(agent, AgentHealthDetails(agent)))
        .toList()
          ..sort();
    return ListView(
      children: List<AgentTile>.generate(
        fullAgents.length,
        (int i) => AgentTile(
          key: insertKeys ? Key('$i-${fullAgents[i].agent.agentId}') : null,
          fullAgent: fullAgents[i],
          agentState: agentState,
        ),
      ),
    );
  }
}

class FullAgent implements Comparable<FullAgent> {
  const FullAgent(this.agent, this.healthDetails);

  final Agent agent;
  final AgentHealthDetails healthDetails;

  @override
  int compareTo(FullAgent other) {
    if (healthDetails.isHealthy && other.healthDetails.isHealthy) {
      return agent.agentId.compareTo(other.agent.agentId);
    } else if (healthDetails.isHealthy) {
      return 1;
    }

    return -1;
  }
}
