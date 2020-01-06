// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:cocoon_service/protos.dart' show Agent;

/// A helper class for [Agent.healthDetails] that splits the expected summary
/// with regex to get actionable health metrics.
///
/// Expected response:
/// ```
/// ssh-connectivity: succeeded
///     Last known IP address: 192.168.1.29
///
/// android-device-ZY223D6B7B: succeeded
/// has-healthy-devices: succeeded
///     Found 1 healthy devices
///
/// cocoon-authentication: succeeded
/// cocoon-connection: succeeded
/// able-to-perform-health-check: succeeded
/// ```
class AgentHealthDetails {
  factory AgentHealthDetails(Agent agent) {
    final DateTime currentTime = DateTime.now();
    final DateTime agentTime =
        DateTime.fromMillisecondsSinceEpoch(agent.healthCheckTimestamp.toInt());
    final Duration agentLastUpdateDuration = currentTime.difference(agentTime);

    final String healthDetails = agent.healthDetails;
    return AgentHealthDetails._(
      agent,
      healthDetails.contains(_hasHealthyDevices),
      healthDetails.contains(_cocoonAuthentication),
      healthDetails.contains(_cocoonConnection),
      healthDetails.contains(_ableToPerformhealthCheck),
      healthDetails.contains(_hasSshConnectivity),
      agentLastUpdateDuration.inMinutes < minutesUntilAgentIsUnresponsive,
    );
  }

  AgentHealthDetails._(
    this.agent,
    this.hasHealthyDevices,
    this.cocoonAuthentication,
    this.cocoonConnection,
    this.canPerformHealthCheck,
    this.hasSshConnectivity,
    this.pingedRecently,
  ) {
    isHealthy = agent.isHealthy &&
        hasHealthyDevices &&
        cocoonAuthentication &&
        cocoonAuthentication &&
        canPerformHealthCheck &&
        hasSshConnectivity &&
        pingedRecently;
  }

  @visibleForTesting
  static const int minutesUntilAgentIsUnresponsive = 10;

  static const String _hasSshConnectivity = 'ssh-connectivity: succeeded';
  static const String _hasHealthyDevices = 'has-healthy-devices: succeeded';
  static const String _cocoonAuthentication =
      'cocoon-authentication: succeeded';
  static const String _cocoonConnection = 'cocoon-connection: succeeded';
  static const String _ableToPerformhealthCheck =
      'able-to-perform-health-check: succeeded';

  /// The agent to show health details from.
  final Agent agent;

  /// Whether or not the devices connected to the agent are healthy.
  ///
  /// Some agents have independent phones connected to them to run tasks, and
  /// they must be healthy for the agent to be considered healthy.
  final bool hasHealthyDevices;

  /// Whether or not this agent can be connected to via SSH.
  final bool hasSshConnectivity;

  /// Whether or not the access token for this agent has been set on the agent.
  final bool cocoonAuthentication;

  /// Whether or not this agent can make network requests to Cocoon.
  final bool cocoonConnection;

  /// Whether or not this agent can perform its own health checks.
  final bool canPerformHealthCheck;

  /// Whether or not this agent has pinged Cocoon recently to show it is still
  /// responsive and able to take tasks.
  ///
  /// Agents that become unresponsive tend to be unresponsive because a process
  /// for running a task has become unresponsive.
  final bool pingedRecently;

  /// An accumlative field that takes in all of the above health metrics.
  ///
  /// If one of the above fields is not considered healthy, this agent is not
  /// considered healthy.
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
