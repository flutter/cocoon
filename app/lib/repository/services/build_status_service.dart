// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:html';

import '../models/build_status.dart';

Future<BuildStatus> fetchBuildStatus() async {
  final Map<String, dynamic> fetchedStatus = await _getStatusBody('api/public/build-status');
  final String anticipatedBuildStatus = fetchedStatus != null ? fetchedStatus['AnticipatedBuildStatus'] : null;

  final Map<String, dynamic> fetchAgentStatus = await _getStatusBody('api/public/get-status');
  List<String> failingAgents = <String>[];
  if (fetchAgentStatus != null) {
    final List<dynamic> agentStatuses = fetchAgentStatus['AgentStatuses'];
    for (Map<String, dynamic> agentStatus in agentStatuses) {
      final String agentID = agentStatus['AgentID'];
      if (agentID == null) {
        continue;
      }
      final bool isHealthy = agentStatus['IsHealthy'];
      final int healthCheckTimeStamp = agentStatus['HealthCheckTimestamp'];

      if (!isHealthy || DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(healthCheckTimeStamp)).inMinutes > 10) {
        failingAgents.add(agentID);
      }
    }
  }
  return BuildStatus(anticipatedBuildStatus: anticipatedBuildStatus, failingAgents: failingAgents);
}

Future<dynamic> _getStatusBody(String url) async {
  try {
    final HttpRequest response = await HttpRequest.request(url);
    final String body = response?.response;
    return (body != null && body.isNotEmpty) ? jsonDecode(body) : null;
  } catch (error) {
    print('Error fetching "$url": $error');
    return null;
  }
}
