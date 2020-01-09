// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'agent_health_details.dart';
import 'agent_tile.dart';
import 'state/agent.dart';

class AgentList extends StatefulWidget {
  const AgentList(
      {this.agents,
      this.agentState,
      this.agentFilter,
      @visibleForTesting this.insertKeys = false});

  final List<Agent> agents;

  final AgentState agentState;

  /// Term to filter [agents] by.
  final String agentFilter;

  /// When true, will set a key for the [AgentTile] that is composed of its
  /// position in the list and the agent id.
  @visibleForTesting
  final bool insertKeys;

  @override
  _AgentListState createState() => _AgentListState();
}

class _AgentListState extends State<AgentList> {
  TextEditingController filterAgentsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// When redirected from the build dashboard, display a specific agent.
    if (widget.agentFilter != null && widget.agentFilter.isNotEmpty) {
      filterAgentsController.text = widget.agentFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.agents.isEmpty) {
      return const CircularProgressIndicator();
    }

    final List<FullAgent> fullAgents = widget.agents
        .map((Agent agent) => FullAgent(agent, AgentHealthDetails(agent)))
        .toList()
          // TODO(chillers): Remove sort once backend handles sorting. https://github.com/flutter/flutter/issues/48249
          ..sort();
    List<FullAgent> filteredAgents =
        filterAgents(fullAgents, filterAgentsController.value.text);

    return Column(
      children: <Widget>[
        // Padding for the search bar
        Container(height: 25),
        TextField(
          onChanged: (String value) {
            setState(() {
              filteredAgents = filterAgents(fullAgents, value);
            });
          },
          controller: filterAgentsController,
          decoration: InputDecoration(
              labelText: 'Filter',
              hintText: 'Filter',
              prefixIcon: Icon(Icons.search),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)))),
        ),
        Expanded(
          child: ListView(
            children: List<AgentTile>.generate(filteredAgents.length, (int i) {
              return AgentTile(
                key: widget.insertKeys
                    ? Key('$i-${filteredAgents[i].agent.agentId}')
                    : null,
                fullAgent: filteredAgents[i],
                agentState: widget.agentState,
              );
            }),
          ),
        ),
      ],
    );
  }

  List<FullAgent> filterAgents(List<FullAgent> agents, String filter) {
    if (filter.isEmpty) {
      return agents;
    }

    return agents
        .where(
            (FullAgent fullAgent) => fullAgent.agent.agentId.contains(filter))
        .toList();
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
