// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'package:cocoon_agent/src/utils.dart';

/// Contains information about a Cocoon task.
class CocoonTask {
  CocoonTask({
    @required this.name,
    @required this.revision,
    @required this.timeoutInMinutes,
    this.key,
    this.cloudAuthToken,
  });

  /// Task name as it appears on dashboards and in logs.
  final String name;

  /// Identifies the task in the database, where the tasks status is stored.
  final String key;

  /// The Flutter revision (git SHA) this task is expected to run with.
  final String revision;

  /// Task timeout.
  final int timeoutInMinutes;

  /// Authentication token that gives the task write access to Google Cloud
  /// Storage buckets to upload artifacts, such as screenshots.
  final String cloudAuthToken;
}

/// Client to the Coocon backend.
class Agent {
  Agent({@required this.baseCocoonUrl, @required this.agentId, @required this.httpClient});

  /// Creates an agent from parameters in the global [config] object.
  factory Agent.fromConfig() {
    return new Agent(
      baseCocoonUrl: config.baseCocoonUrl,
      agentId: config.agentId,
      httpClient: new AuthenticatedClient(config.agentId, config.authToken)
    );
  }

  final String baseCocoonUrl;
  final String agentId;
  final Client httpClient;

  /// Makes a REST API request to Cocoon.
  Future<dynamic> _cocoon(String apiPath, [dynamic json]) async {
    String url = '$baseCocoonUrl/api/$apiPath';
    Response resp;
    if (json != null) {
      resp = await httpClient.post(url, body: JSON.encode(json));
    } else {
      resp = await httpClient.get(url);
    }
    return JSON.decode(resp.body);
  }

  Future<Null> uploadLogChunk(String taskKey, String chunk) async {
    if (taskKey == null)
      return;
    String url = '$baseCocoonUrl/api/append-log?ownerKey=${taskKey}';
    Response resp = await httpClient.post(url, body: chunk);
    if (resp.statusCode != 200) {
      throw 'Failed uploading log chunk. Server responded with HTTP status ${resp.statusCode}\n'
            '${resp.body}';
    }
  }

  /// Reserves a task in Cocoon backend to be performed by this agent.
  ///
  /// If not tasks are available returns `null`.
  Future<CocoonTask> reserveTask() async {
    Map<String, dynamic> reservation = await _cocoon('reserve-task', {
      'AgentID': agentId
    });

    if (reservation['TaskEntity'] != null) {
      return new CocoonTask(
        name: reservation['TaskEntity']['Task']['Name'],
        key: reservation['TaskEntity']['Key'],
        revision: reservation['ChecklistEntity']['Checklist']['Commit']['Sha'],
        timeoutInMinutes: reservation['TaskEntity']['Task']['TimeoutInMinutes'],
        cloudAuthToken: reservation['CloudAuthToken'],
      );
    }

    return null;
  }

  Future<Null> reportSuccess(String taskKey, Map<String, dynamic> resultData, List<String> benchmarkScoreKeys) async {
    var status = <String, dynamic>{
      'TaskKey': taskKey,
      'NewStatus': 'Succeeded',
    };

    // Make a copy of resultData because we may alter it during score key
    // validation below.
    resultData = resultData != null
      ? new Map<String, dynamic>.from(resultData)
      : <String, dynamic>{};
    status['ResultData'] = resultData;

    var validScoreKeys = <String>[];
    if (benchmarkScoreKeys != null) {
      for (String scoreKey in benchmarkScoreKeys) {
        var score = resultData[scoreKey];
        if (score is num) {
          // Convert all metrics to double, which provide plenty of precision
          // without having to add support for multiple numeric types on the
          // backend.
          resultData[scoreKey] = score.toDouble();
          validScoreKeys.add(scoreKey);
        } else {
          stderr.writeln('WARNING: non-numeric score value $score submitted for $scoreKey');
        }
      }
    }
    status['BenchmarkScoreKeys'] = validScoreKeys;

    await _cocoon('update-task-status', status);
  }

  Future<Null> reportFailure(String taskKey, String reason) async {
    await uploadLogChunk(taskKey, '\n\nTask failed with the following reason:\n$reason\n');
    await _cocoon('update-task-status', {
      'TaskKey': taskKey,
      'NewStatus': 'Failed',
    });
  }

  Future<String> getAuthenticationStatus() async {
    return (await _cocoon('get-authentication-status'))['Status'];
  }

  Future<Null> updateHealthStatus(AgentHealth health) async {
    await _cocoon('update-agent-health', {
    	'AgentID': agentId,
    	'IsHealthy': health.ok,
    	'HealthDetails': '$health',
    });
  }
}

/// A CLI command.
/// 
/// Commands run in an isolate separate from the main isolate. This way a
/// command may be restarted when it fails.
abstract class Command {
  Command(this.name, this.runContinuously);

  /// Command name as it appears in the CLI.
  final String name;

  /// If `true`, causes the command to run repeatedly, even when it fails.
  final bool runContinuously;

  /// Runs the command logic in the current isolate.
  /// 
  /// [args] contains command-specific arguments (e.g. obtained by calling
  /// [ArgResults.command]).
  /// 
  /// [mainIsolate] is the port for sending messages to the main isolate of
  /// the process (the command itself normally runs in a dedicated isolate).
  Future<Null> run(ArgResults args, SendPort mainIsolate);
}

/// Overall health of the agent.
class AgentHealth {
  /// Check results keyed by parameter.
  final Map<String, HealthCheckResult> checks = <String, HealthCheckResult>{};

  /// Whether all [checks] succeeded.
  bool get ok => checks.isNotEmpty && checks.values.every((HealthCheckResult r) => r.succeeded);

  /// Sets a health check [result] for a given [parameter].
  void operator []=(String parameter, HealthCheckResult result) {
    if (checks.containsKey(parameter)) {
      print('WARNING: duplicate health check ${parameter} submitted');
    }
    checks[parameter] = result;
  }

  void addAll(Map<String, HealthCheckResult> checks) {
    checks.forEach((String p, HealthCheckResult r) {
      this[p] = r;
    });
  }

  /// Human-readable printout of the agent's health status.
  @override
  String toString() {
    StringBuffer buf = new StringBuffer();
    checks.forEach((String parameter, HealthCheckResult result) {
      buf.writeln('$parameter: $result');
    });
    return buf.toString();
  }
}

/// HTTP client authenticated with the Cocoon backend.
class AuthenticatedClient extends BaseClient {
  AuthenticatedClient(this._agentId, this._authToken);

  final String _agentId;
  final String _authToken;
  final Client _delegate = new Client();

  @override
  Future<StreamedResponse> send(Request request) async {
    request.headers['Agent-ID'] = _agentId;
    request.headers['Agent-Auth-Token'] = _authToken;
    final StreamedResponse resp = await _delegate.send(request);

    if (resp.statusCode != 200) {
      throw new AuthenticatedClientError(
        uri: request.url,
        statusCode: resp.statusCode,
        body: (await Response.fromStream(resp)).body,
      );
    }

    return resp;
  }
}

/// An error thrown by [AuthenticatedClient].
class AuthenticatedClientError extends Error {
  AuthenticatedClientError({
    @required this.uri,
    @required this.statusCode,
    @required this.body,
  });

  /// The URI that resulted in this error.
  final Uri uri;

  /// HTTP status code.
  final int statusCode;

  /// HTTP response body.
  final String body;

  @override
  String toString() => '$AuthenticatedClientError:\n'
      '  URI: $uri\n'
      '  HTTP status: $statusCode\n'
      '  Response body:\n'
      '$body';
}
