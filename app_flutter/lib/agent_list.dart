// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

import 'agent_tile.dart';

class AgentList extends StatelessWidget {
  const AgentList(this.agents);

  final List<Agent> agents;

  @override
  Widget build(BuildContext context) {
    agents.sort((Agent a, Agent b) =>
        a.isHealthy ? a.agentId.compareTo(b.agentId) : -1);
    return ListView(
      children: List<AgentTile>.generate(
        agents.length,
        (int i) => AgentTile(agents[i]),
      ),
    );
  }
}
