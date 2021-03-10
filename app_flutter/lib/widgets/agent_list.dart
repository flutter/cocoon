// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/models.dart' show Agent;

import '../logic/agent_health_details.dart';
import '../state/agent.dart';
import 'agent_tile.dart';
import 'now.dart';

/// Shows [List<Agent>] that have [Agent.agentId] that contains [agentFilter] in
/// a ListView of [AgentTile].
///
/// Sorts this list to show unhealthy agents first.
class AgentList extends StatefulWidget {
  const AgentList({
    Key key,
    this.agents,
    this.agentState,
    this.agentFilter,
    @visibleForTesting this.insertKeys = false,
  }) : super(key: key);

  /// All known agents that can be shown.
  final List<Agent> agents;

  final AgentState agentState;

  /// Search term to filter the agents from [agentState] and show only those
  /// that contain this term.
  ///
  /// This is set either:
  ///   1. Route argument set when being redirected from the build dashboard
  ///      to view a specific agent that ran a task.
  ///   2. In the search bar of this widget.
  final String agentFilter;

  /// When true, will set a key for the [AgentTile] that is composed of its
  /// position in the list and the agent id.
  @visibleForTesting
  final bool insertKeys;

  @override
  _AgentListState createState() => _AgentListState();
}

class _AgentListState extends State<AgentList> {
  /// Controller for filtering the agents, acting as a search bar.
  TextEditingController filterAgentsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// When redirected from the build dashboard, display a specific agent.
    /// Updates the search bar to show [agentFilter].
    if (widget.agentFilter != null && widget.agentFilter.isNotEmpty) {
      filterAgentsController.text = widget.agentFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.agents.isEmpty) {
      return const Center(
        child: SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(),
        ),
      );
    }

    final DateTime now = Now.of(context);

    // TODO(chillers): Remove sort once backend handles sorting. https://github.com/flutter/flutter/issues/48249
    final List<_SortableAgent> sortableAgents =
        widget.agents.map((Agent agent) => _SortableAgent(agent, AgentHealthDetails(agent), now)).toList()..sort();
    final List<_SortableAgent> filteredAgents = filterAgents(sortableAgents, filterAgentsController.text);

    return Column(
      children: <Widget>[
        // Padding for the search bar
        Container(height: 25),
        TextField(
          onChanged: (String value) {
            setState(() {
              // the filterAgentsController.text changed (used above in generating the filteredAgents)
            });
          },
          controller: filterAgentsController,
          decoration: const InputDecoration(
            labelText: 'Filter',
            hintText: 'Filter',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(25.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: List<AgentTile>.generate(filteredAgents.length, (int i) {
              return AgentTile(
                key: widget.insertKeys ? Key('$i-${filteredAgents[i].agent.agentId}') : null,
                agentHealthDetails: filteredAgents[i].agentHealthDetails,
                agentState: widget.agentState,
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Creates a new [List<FullAgent>] of only the agents that have an [agentId]
  /// that contains [filter].
  ///
  /// If filter is empty, the original list of agents.
  List<_SortableAgent> filterAgents(List<_SortableAgent> agents, String filter) {
    if (filter.isEmpty) {
      return agents;
    }

    return agents.where((_SortableAgent fullAgent) => fullAgent.agent.agentId.contains(filter)).toList();
  }
}

/// A wrapper class for sorting [AgentHealthDetails].
///
/// Sorts to show unhealthy agents before healthy agents, with those groups
/// being sorted alphabetically.
class _SortableAgent implements Comparable<_SortableAgent> {
  _SortableAgent(
    this.agent,
    this.agentHealthDetails,
    DateTime now,
  ) : _isHealthy = agentHealthDetails.isHealthy(now);

  final Agent agent;

  final AgentHealthDetails agentHealthDetails;

  final bool _isHealthy;

  @override
  int compareTo(_SortableAgent other) {
    if (_isHealthy && other._isHealthy) {
      return agent.agentId.compareTo(other.agent.agentId);
    }
    return _isHealthy ? 1 : -1;
  }
}
