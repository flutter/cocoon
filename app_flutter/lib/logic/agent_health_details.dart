// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

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
@immutable
class AgentHealthDetails {
  factory AgentHealthDetails(Agent agent) {
    final String healthDetails = agent.healthDetails;
    return AgentHealthDetails._(
      agent,
      DateTime.fromMillisecondsSinceEpoch(agent.healthCheckTimestamp.toInt()),
      healthDetails.contains(_hasHealthyDevices),
      healthDetails.contains(_cocoonAuthentication),
      healthDetails.contains(_cocoonConnection),
      healthDetails.contains(_ableToPerformhealthCheck),
      healthDetails.contains(_hasSshConnectivity),
    );
  }

  AgentHealthDetails._(
    this.agent,
    this.lastPing,
    this.hasHealthyDevices,
    this.cocoonAuthentication,
    this.cocoonConnection,
    this.canPerformHealthCheck,
    this.hasSshConnectivity,
  ) : _isHealthy = agent.isHealthy &&
            hasHealthyDevices &&
            cocoonAuthentication &&
            cocoonAuthentication &&
            canPerformHealthCheck &&
            hasSshConnectivity;

  @visibleForTesting
  static const int minutesUntilAgentIsUnresponsive = 30;

  static const String _hasSshConnectivity = 'ssh-connectivity: succeeded';
  static const String _hasHealthyDevices = 'has-healthy-devices: succeeded';
  static const String _cocoonAuthentication = 'cocoon-authentication: succeeded';
  static const String _cocoonConnection = 'cocoon-connection: succeeded';
  static const String _ableToPerformhealthCheck = 'able-to-perform-health-check: succeeded';

  /// The agent to show health details from.
  final Agent agent;

  /// The date and time of the last time this agent pinged Cocoon to show it is
  /// still responsive and able to take tasks.
  ///
  /// The typical cause of an agent becoming unresponsive is that the
  /// task itself, or more specifically one of the processes in the
  /// task, has hung or otherwise stopped making progress. (As opposed
  /// to the agent itself having a problem, which is much less
  /// common.)
  ///
  /// The [isHealthy] method compares this time to the given time and
  /// classifies the agent as unhealthy if it is more than
  /// [minutesUntilAgentIsUnresponsive] minutes before the given time.
  final DateTime lastPing;

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

  final bool _isHealthy;

  /// Whether the [lastPing] was sufficiently recent to consider the agent responsive.
  ///
  /// The parameter is the current time. See [lastPing].
  bool pingedRecently(DateTime now) {
    final Duration agentLastUpdateDuration = now.difference(lastPing);
    return agentLastUpdateDuration.inMinutes < minutesUntilAgentIsUnresponsive;
  }

  /// An accumlative field that takes in all of the above health metrics.
  ///
  /// If one of the above fields is not considered healthy, this agent is not
  /// considered healthy.
  ///
  /// The parameter is the current time. See [lastPing].
  bool isHealthy(DateTime now) {
    return _isHealthy && pingedRecently(now);
  }
}
