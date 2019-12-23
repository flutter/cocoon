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

    final AgentHealthDetails healthDetails =
        AgentHealthDetails(agent.healthDetails);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isHealthy ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          child: _getIconFromId(agent.agentId),
        ),
        title: Text(agent.agentId),
        subtitle: Row(
          children: <Widget>[
            if (healthDetails.cocoonAuthentication)
              Icon(Icons.verified_user)
            else
              Icon(Icons.error),
            if (healthDetails.cocoonConnection)
              Icon(Icons.network_wifi)
            else
              Icon(Icons.perm_scan_wifi),
            if (healthDetails.hasHealthyDevices)
              // Icon(Icons.mobile_friendly)
              Icon(Icons.devices)
            else
              Icon(Icons.phonelink_erase),
          ],
        ),
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

class AgentHealthDetails {
  factory AgentHealthDetails(String source) {
    final RegExpMatch match = _ipAddress.firstMatch(source);
    return AgentHealthDetails._(
      match?.group(0)?.split(': ')[1],
      source.contains(_hasHealthyDevices),
      source.contains(_cocoonAuthentication),
      source.contains(_cocoonConnection),
      source.contains(_ableToPerformhealthCheck),
      source.contains(_hasSshConnectivity),
    );
  }

  AgentHealthDetails._(
    this.ipAddress,
    this.hasHealthyDevices,
    this.cocoonAuthentication,
    this.cocoonConnection,
    this.canPerformHealthCheck,
    this.hasSshConnectivity,
  );

  static final RegExp _ipAddress =
      RegExp(r'Last known IP address: +\d+\.\d+\.\d+\.\d+');
  static final RegExp _hasSshConnectivity =
      RegExp('ssh-connectivity: succeeded');
  static final RegExp _hasHealthyDevices =
      RegExp('has-healthy-devices: succeeded');
  static final RegExp _cocoonAuthentication =
      RegExp('cocoon-authentication: succeeded');
  static final RegExp _cocoonConnection =
      RegExp('cocoon-connection: succeeded');
  static final RegExp _ableToPerformhealthCheck =
      RegExp('able-to-perform-health-check: succeeded');

  final String ipAddress;
  final bool hasHealthyDevices;
  final bool hasSshConnectivity;
  final bool cocoonAuthentication;
  final bool cocoonConnection;
  final bool canPerformHealthCheck;
}
