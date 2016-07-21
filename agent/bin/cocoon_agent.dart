// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:meta/meta.dart';

import 'package:dashboard_box/src/analysis.dart';
import 'package:dashboard_box/src/framework.dart';
import 'package:dashboard_box/src/gallery.dart';
import 'package:dashboard_box/src/golem.dart';
import 'package:dashboard_box/src/perf_tests.dart';
import 'package:dashboard_box/src/refresh.dart';
import 'package:dashboard_box/src/size_tests.dart';
import 'package:dashboard_box/src/utils.dart';

/// Agents are polling the server for more tasks. This sleep is so that we don't
/// DDOS the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

final List<StreamSubscription> _streamSubscriptions = <StreamSubscription>[];

bool _exiting = false;

main() async {
  _streamSubscriptions.addAll(<StreamSubscription>[
    ProcessSignal.SIGINT.watch().listen((_) {
      print('\nReceived SIGINT. Shutting down.');
      _stop(ProcessSignal.SIGINT);
    }),
    ProcessSignal.SIGTERM.watch().listen((_) {
      print('\nReceived SIGTERM. Shutting down.');
      _stop(ProcessSignal.SIGTERM);
    }),
  ]);

  Directory rootDirectory = dir('./').absolute;
  File agentConfigFile = file('${rootDirectory.path}/dashboard_box/agent_config.json');

  if (!agentConfigFile.existsSync()) {
    throw (
      'Agent config file not found: ${agentConfigFile.path}.\n'
      'Note that Cocoon agent must be launched from the direct parent of dashboard_box.'
    );
  }

  config = new Config(rootDirectory.path);

  Map<String, dynamic> agentConfig = JSON.decode(agentConfigFile.readAsStringSync());
  String agentId = agentConfig['agent_id'];
  String baseCocoonUrl = agentConfig['base_cocoon_url'] ?? 'https://flutter-dashboard.appspot.com';

  Agent agent = new Agent(
    baseCocoonUrl: baseCocoonUrl,
    agentId: agentId,
    httpClient: new AuthenticatedClient(agentId, agentConfig['auth_token'])
  );

  while(!_exiting) {
    try {
      await agent.performNextTaskIfAny();
    } catch(error, stackTrace) {
      print('Caught: $error\n$stackTrace');
    }
    // TODO(yjbanov): report health status after running the task
    await new Future.delayed(_sleepBetweenBuilds);
  }
}

Future<Null> _stop(ProcessSignal signal) async {
  _exiting = true;
  for (StreamSubscription sub in _streamSubscriptions) {
    await sub.cancel();
  }
  _streamSubscriptions.clear();
}

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

  Future<Null> performNextTaskIfAny() async {
    Map<String, dynamic> reservation = await reserveTask();
    if (reservation['TaskEntity'] != null) {
      String taskName = reservation['TaskEntity']['Task']['Name'];
      String taskKey = reservation['TaskEntity']['Key'];
      String revision = reservation['ChecklistEntity']['Checklist']['Commit']['Sha'];
      section('Task info');
      print('name           : $taskName');
      print('key            : $taskKey');
      print('revision       : $revision');

      try {
        await getFlutterAt(revision);
        int golemRevision = await computeGolemRevision();
        DateTime revisionTimestamp = await getFlutterRepoCommitTimestamp(revision);
        String dartSdkVersion = await getDartVersion();
        Task task = getTask(taskName, revision, revisionTimestamp, dartSdkVersion);
        TaskRunner runner = new TaskRunner(revision, golemRevision, <Task>[task]);
        BuildResult result = await runner.run();
        // TODO(yjbanov): upload logs
        if (result.succeeded) {
          await updateTaskStatus(taskKey, 'Succeeded');
        } else {
          await updateTaskStatus(taskKey, 'Failed');
        }
      } catch(error, stackTrace) {
        // TODO(yjbanov): upload logs
        print('Caught: $error\n$stackTrace');
        await updateTaskStatus(taskKey, 'Failed');
      }
    }
  }

  Task getTask(String taskName, String revision, DateTime revisionTimestamp, String dartSdkVersion) {
    List<Task> allTasks = <Task>[
      createComplexLayoutScrollPerfTest(),
      createFlutterGalleryStartupTest(),
      createComplexLayoutStartupTest(),
      createFlutterGalleryBuildTest(),
      createComplexLayoutBuildTest(),
      createGalleryTransitionTest(),
      createBasicMaterialAppSizeTest(),
      createAnalyzerCliTest(sdk: dartSdkVersion, commit: revision, timestamp: revisionTimestamp),
      createAnalyzerServerTest(sdk: dartSdkVersion, commit: revision, timestamp: revisionTimestamp),
      createRefreshTest(commit: revision, timestamp: revisionTimestamp),
    ];

    return allTasks.firstWhere(
      (Task t) => t.name == taskName,
      orElse: () {
        throw 'Task $taskName not found';
      }
    );
  }

  Future<Map<String, dynamic>> reserveTask() => _cocoon('reserve-task', {
    'AgentID': agentId
  });

  Future<Null> getFlutterAt(String revision) async {
    String currentRevision = await getCurrentFlutterRepoCommit();

    // This agent will likely run multiple tasks in the same checklist and
    // therefore the same revision. It would be too costly to have to reinstall
    // Flutter every time.
    if (currentRevision == revision) {
      return;
    }

    await getFlutter(revision);
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
