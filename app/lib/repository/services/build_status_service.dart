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

  final Map<String, dynamic> fetchBuildStatus = await _getStatusBody(client, 'api/public/get-status');
  final List<String> failingAgents = <String>[];
  final List<CommitTestResult> commitTestResults = <CommitTestResult>[];
  if (fetchBuildStatus != null) {
    final List<dynamic> agentStatuses = fetchBuildStatus['AgentStatuses'];
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

      final List<dynamic> statuses = fetchBuildStatus['Statuses'];
      if (statuses != null) {
        for (Map<String, dynamic> status in statuses) {
          final Map<String, dynamic> checklist = status['Checklist']['Checklist'];
          final Map<String, dynamic> commitInfo = checklist['Commit'];
          final Map<String, dynamic> authorInfo = commitInfo['Author'];

          int inProgressTestCount = 0;
          int succeededTestCount = 0;
          int failedFlakyTestCount = 0;
          int failedTestCount = 0;
          final List<String> failingTests = <String>[];
          for (Map<String, dynamic> status in status['Stages']) {
            for (Map<String, dynamic> taskInfo in status['Tasks']) {
              final Map<String, dynamic> task = taskInfo['Task'];
              final String status = task['Status'];
              if (status == 'Succeeded') {
                succeededTestCount++;
              } else if (status == 'In Progress') {
                inProgressTestCount++;
              } else if (status == 'Failed') {
                if (task['Flaky']) {
                  failedFlakyTestCount++;
                } else {
                  failedTestCount++;
                  failingTests.add(task['Name']);
                }
              }
            }
          }
          final DateTime createDateTime = DateTime.fromMillisecondsSinceEpoch(checklist['CreateTimestamp']).toLocal();
          commitTestResults.add(
            CommitTestResult(
              sha: commitInfo['Sha'],
              authorName: authorInfo['Login'],
              avatarImageURL: authorInfo['avatar_url'],
              createDateTime: createDateTime,
              inProgressTestCount: inProgressTestCount,
              succeededTestCount: succeededTestCount,
              failedFlakyTestCount: failedFlakyTestCount,
              failedTestCount: failedTestCount,
              failingTests: failingTests,
            )
          );

          if (commitTestResults.length >= 5) {
            break;
          }
        }
      }
    }
  }
  return BuildStatus(anticipatedBuildStatus: anticipatedBuildStatus, failingAgents: failingAgents, commitTestResults: commitTestResults);
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
