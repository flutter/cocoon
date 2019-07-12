// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/build_status.dart';

Future<BuildStatus> fetchBuildStatus({http.Client client}) async {
  client ??= http.Client();
  final Map<String, dynamic> fetchedStatus = await _getStatusBody(client, 'api/public/build-status');
  final String anticipatedBuildStatus = fetchedStatus != null ? fetchedStatus['AnticipatedBuildStatus'] : null;

  final Map<String, dynamic> fetchAgentStatus = await _getStatusBody(client, 'api/public/get-status');
  final List<String> failingAgents = <String>[];
  if (fetchAgentStatus != null) {
    final List<dynamic> agentStatuses = fetchAgentStatus['AgentStatuses'];
    if (agentStatuses != null) {
      for (Map<String, dynamic> agentStatus in agentStatuses) {
        final String agentID = agentStatus['AgentID'];
        if (agentID == null) {
          continue;
        }
        final bool isHealthy = agentStatus['IsHealthy'];
        final int healthCheckTimeStamp = agentStatus['HealthCheckTimestamp'];
        final int minutesSinceHealthCheck = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(healthCheckTimeStamp)).inMinutes;
        if (!isHealthy || minutesSinceHealthCheck > 10) {
          failingAgents.add(agentID);
        }
      }
    }
  }
  return BuildStatus(anticipatedBuildStatus: anticipatedBuildStatus, failingAgents: failingAgents);
}

Future<dynamic> _getStatusBody(http.Client client, String url) async {
  try {
    final http.Response response = await client.get(url);
    final String body = response?.body;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching "$url": $error');
    return null;
  }
}
