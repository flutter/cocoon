// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

class AgentTile extends StatelessWidget {
  const AgentTile(this.agent);

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final DateTime currentTime = DateTime.now();
    final DateTime agentTime =
        DateTime.fromMillisecondsSinceEpoch(agent.healthCheckTimestamp.toInt());
    final Duration agentLastUpdateDuration = currentTime.difference(agentTime);
    final bool isHealthy =
        agentLastUpdateDuration.inMinutes < 10 && agent.isHealthy;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHealthy ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          child: _getIconFromId(agent.agentId),
        ),
        title: Text(agent.agentId),
        trailing: IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () => print('authorize'),
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
}
