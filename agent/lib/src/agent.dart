// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'package:cocoon_agent/src/adb.dart';
import 'package:cocoon_agent/src/analysis.dart';
import 'package:cocoon_agent/src/framework.dart';
import 'package:cocoon_agent/src/gallery.dart';
import 'package:cocoon_agent/src/golem.dart';
import 'package:cocoon_agent/src/perf_tests.dart';
import 'package:cocoon_agent/src/refresh.dart';
import 'package:cocoon_agent/src/size_tests.dart';
import 'package:cocoon_agent/src/utils.dart';

/// Contains information about a Cocoon task.
class CocoonTask {
  CocoonTask({this.name, this.key, this.revision});

  final String name;
  final String key;
  final String revision;
}

/// Client to the Coocon backend.
class Agent {
  Agent({@required this.baseCocoonUrl, @required this.agentId, @required this.httpClient});

  final String baseCocoonUrl;
  final String agentId;
  final Client httpClient;

  /// Makes a REST API request to Cocoon.
  Future<dynamic> _cocoon(String apiPath, dynamic json) async {
    String url = '$baseCocoonUrl/api/$apiPath';
    Response resp = await httpClient.post(url, body: JSON.encode(json));
    return JSON.decode(resp.body);
  }

  Future<BuildResult> performTask(CocoonTask reservation) async {
    int golemRevision = await computeGolemRevision();
    Task task = await getTask(reservation);
    TaskRunner runner = new TaskRunner(reservation.revision, golemRevision, <Task>[task]);
    try {
      return await runner.run();
    } finally {
      await _screenOff();
    }
  }

  Future<Null> _screenOff() async {
    try {
      await (await adb()).sendToSleep();
    } catch(error, stackTrace) {
      print('Failed to turn off screen: $error\n$stackTrace');
    }
  }

  Future<Null> uploadLogChunk(CocoonTask task, String chunk) async {
    String url = '$baseCocoonUrl/api/append-log?ownerKey=${task.key}';
    Response resp = await httpClient.post(url, body: chunk);
    if (resp.statusCode != 200) {
      throw 'Failed uploading log chunk. Server responded with HTTP status ${resp.statusCode}\n'
            '${resp.body}';
    }
  }

  Future<Task> getTask(CocoonTask task) async {
    DateTime revisionTimestamp = await getFlutterRepoCommitTimestamp(task.revision);
    String dartSdkVersion = await getDartVersion();

    List<Task> allTasks = <Task>[
      createComplexLayoutScrollPerfTest(),
      createFlutterGalleryStartupTest(),
      createComplexLayoutStartupTest(),
      createFlutterGalleryBuildTest(),
      createComplexLayoutBuildTest(),
      createGalleryTransitionTest(),
      createBasicMaterialAppSizeTest(),
      createAnalyzerCliTest(sdk: dartSdkVersion, commit: task.revision, timestamp: revisionTimestamp),
      createAnalyzerServerTest(sdk: dartSdkVersion, commit: task.revision, timestamp: revisionTimestamp),
      createRefreshTest(commit: task.revision, timestamp: revisionTimestamp),
    ];

    return allTasks.firstWhere(
      (Task t) => t.name == task.name,
      orElse: () {
        throw 'Task $task.name not found';
      }
    );
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
        revision: reservation['ChecklistEntity']['Checklist']['Commit']['Sha']
      );
    }

    return null;
  }

  Future<Null> updateTaskStatus(String taskKey, String newStatus) async {
    await _cocoon('update-task-status', {
      'TaskKey': taskKey,
      'NewStatus': newStatus,
    });
  }
}

class AuthenticatedClient extends BaseClient {
  AuthenticatedClient(this._agentId, this._authToken);

  final String _agentId;
  final String _authToken;
  final Client _delegate = new Client();

  Future<StreamedResponse> send(Request request) async {
    request.headers['Agent-ID'] = _agentId;
    request.headers['Agent-Auth-Token'] = _authToken;
    StreamedResponse resp = await _delegate.send(request);

    if (resp.statusCode != 200)
      throw 'HTTP error ${resp.statusCode}:\n${(await Response.fromStream(resp)).body}';

    return resp;
  }
}

abstract class Command {
  Command(this.name, this.agent);

  /// Command name as it appears in the CLI.
  final String name;

  /// Coocon agent client.
  final Agent agent;

  Future<Null> run(ArgResults args);
}
