// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

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

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: healthDetails.isHealthy ? Colors.green : Colors.red,
          foregroundColor: Colors.white,
          child: _getIconFromId(agent.agentId),
        ),
        title: Text(agent.agentId),
        subtitle: AgentHealthDetailsBar(healthDetails),
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

/// An icon bar to display information from [AgentHealthDetails].
class AgentHealthDetailsBar extends StatelessWidget {
  const AgentHealthDetailsBar(this.healthDetails);

  final AgentHealthDetails healthDetails;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (!healthDetails.pingedRecently)
          Tooltip(
            message: 'Agent timed out',
            child: Icon(Icons.timer, color: Colors.red),
          ),
        if (healthDetails.cocoonAuthentication)
          Tooltip(
            message: 'Cocoon authentication passed',
            child: Icon(Icons.verified_user),
          )
        else
          Tooltip(
            message: 'Cocoon authentication failed',
            child: Icon(Icons.error, color: Colors.red),
          ),
        if (healthDetails.cocoonConnection)
          Tooltip(
            message: 'Cocoon connected',
            child: Icon(Icons.network_wifi),
          )
        else
          Tooltip(
            message: 'Cocoon connection failed',
            child: Icon(Icons.perm_scan_wifi),
          ),
        if (healthDetails.hasHealthyDevices)
          Tooltip(
            message: 'Devices healthy',
            child: Icon(Icons.devices),
          )
        else
          Tooltip(
            message: 'Devices not healthy',
            child: Icon(Icons.phonelink_erase, color: Colors.red),
          ),
      ],
    );
  }
}

/// A helper class for [Agent.healthDetails] that splits the expected summary
/// with regex to get actionable fields.
class AgentHealthDetails {
  factory AgentHealthDetails(
      String source, Duration durationSinceAgentLastUpdated) {
    final RegExpMatch match = _ipAddress.firstMatch(source);
    return AgentHealthDetails._(
      match?.group(0)?.split(': ')[1],
      source.contains(_hasHealthyDevices),
      source.contains(_cocoonAuthentication),
      source.contains(_cocoonConnection),
      source.contains(_ableToPerformhealthCheck),
      source.contains(_hasSshConnectivity),
      durationSinceAgentLastUpdated.inMinutes < minutesUntilAgentIsUnresponsive,
    );
  }

  AgentHealthDetails._(
    this.ipAddress,
    this.hasHealthyDevices,
    this.cocoonAuthentication,
    this.cocoonConnection,
    this.canPerformHealthCheck,
    this.hasSshConnectivity,
    this.pingedRecently,
  ) {
    isHealthy = hasHealthyDevices &&
        cocoonAuthentication &&
        cocoonAuthentication &&
        canPerformHealthCheck &&
        hasSshConnectivity &&
        pingedRecently;
  }

  static const int minutesUntilAgentIsUnresponsive = 10;

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
  final bool pingedRecently;
  bool isHealthy;
}
