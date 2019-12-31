// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

/// A helper class for [Agent.healthDetails] that splits the expected summary
/// with regex to get actionable fields.
class AgentHealthDetails {
  factory AgentHealthDetails(Agent agent) {
    final DateTime currentTime = DateTime.now();
    final DateTime agentTime =
        DateTime.fromMillisecondsSinceEpoch(agent.healthCheckTimestamp.toInt());
    final Duration agentLastUpdateDuration = currentTime.difference(agentTime);

    final String source = agent.healthDetails;
    final RegExpMatch match = _ipAddress.firstMatch(source);
    return AgentHealthDetails._(
      match?.group(0)?.split(': ')[1],
      source.contains(_hasHealthyDevices),
      source.contains(_cocoonAuthentication),
      source.contains(_cocoonConnection),
      source.contains(_ableToPerformhealthCheck),
      source.contains(_hasSshConnectivity),
      agentLastUpdateDuration.inMinutes < minutesUntilAgentIsUnresponsive,
    );
  }

  AgentHealthDetails._(
    this.networkAddress,
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

  static final RegExp _ipAddress = RegExp(r'Last known IP address: *');
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

  final String networkAddress;
  final bool hasHealthyDevices;
  final bool hasSshConnectivity;
  final bool cocoonAuthentication;
  final bool cocoonConnection;
  final bool canPerformHealthCheck;
  final bool pingedRecently;
  bool isHealthy;
}

/// An icon bar to display information from [AgentHealthDetails].
class AgentHealthDetailsBar extends StatelessWidget {
  const AgentHealthDetailsBar(this.healthDetails);

  final AgentHealthDetails healthDetails;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        if (!healthDetails.pingedRecently)
          Tooltip(
            message: 'Agent timed out',
            child: Icon(Icons.timer, color: theme.errorColor),
          ),
        if (healthDetails.cocoonAuthentication)
          Tooltip(
            message: 'Cocoon authentication passed',
            child: Icon(Icons.verified_user),
          )
        else
          Tooltip(
            message: 'Cocoon authentication failed',
            child: Icon(Icons.error, color: theme.errorColor),
          ),
        if (healthDetails.cocoonConnection)
          Tooltip(
            message: 'Cocoon connected',
            child: Icon(Icons.network_wifi),
          )
        else
          Tooltip(
            message: 'Cocoon connection failed',
            child: Icon(Icons.perm_scan_wifi, color: theme.errorColor),
          ),
        if (healthDetails.hasHealthyDevices)
          Tooltip(
            message: 'Devices healthy',
            child: Icon(Icons.devices),
          )
        else
          Tooltip(
            message: 'Devices not healthy',
            child: Icon(Icons.phonelink_erase, color: theme.errorColor),
          ),
      ],
    );
  }
}
