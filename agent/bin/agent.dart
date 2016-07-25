// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:stack_trace/stack_trace.dart';

import 'package:cocoon_agent/src/adb.dart';
import 'package:cocoon_agent/src/analysis.dart';
import 'package:cocoon_agent/src/firebase.dart';
import 'package:cocoon_agent/src/framework.dart';
import 'package:cocoon_agent/src/gallery.dart';
import 'package:cocoon_agent/src/golem.dart';
import 'package:cocoon_agent/src/perf_tests.dart';
import 'package:cocoon_agent/src/refresh.dart';
import 'package:cocoon_agent/src/size_tests.dart';
import 'package:cocoon_agent/src/utils.dart';

/// Agents periodically poll the server for more tasks. This sleep period is
/// used to prevent us from DDoS-ing the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

final List<StreamSubscription> _streamSubscriptions = <StreamSubscription>[];

bool _exiting = false;

Future<Null> main(List<String> args) async {
  Config.initialize(args);

  print('Agent configuration:');
  print(config);

  Agent agent = new Agent(
    baseCocoonUrl: config.baseCocoonUrl,
    agentId: config.agentId,
    httpClient: new AuthenticatedClient(config.agentId, config.authToken)
  );

  _listenToShutdownSignals();
  while(!_exiting) {
    try {
      await _captureAsyncStacks(agent.performNextTaskIfAny);
    } catch(error, chain) {
      print('Caught: $error\n${(chain as Chain).terse}');
    }

    // TODO(yjbanov): report health status after running the task
    await new Future.delayed(_sleepBetweenBuilds);
  }
}

void _listenToShutdownSignals() {
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
}

Future<Null> _stop(ProcessSignal signal) async {
  _exiting = true;
  for (StreamSubscription sub in _streamSubscriptions) {
    await sub.cancel();
  }
  _streamSubscriptions.clear();
  // TODO(yjbanov): stop processes launched by tasks, if any
  await new Future.delayed(const Duration(seconds: 1));
  exit(0);
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
        await _captureAsyncStacks(() async {
          await getFlutterAt(revision);
          int golemRevision = await computeGolemRevision();
          DateTime revisionTimestamp = await getFlutterRepoCommitTimestamp(revision);
          String dartSdkVersion = await getDartVersion();
          Task task = getTask(taskName, revision, revisionTimestamp, dartSdkVersion);
          TaskRunner runner = new TaskRunner(revision, golemRevision, <Task>[task]);
          BuildResult result = await _runTask(runner);
          // TODO(yjbanov): upload logs
          if (result.succeeded) {
            await updateTaskStatus(taskKey, 'Succeeded');
            await _uploadDataToFirebase(result);
          } else {
            await updateTaskStatus(taskKey, 'Failed');
          }
        });
      } catch(error, chain) {
        // TODO(yjbanov): upload logs
        print('Caught: $error\n${(chain as Chain).terse}');
        await updateTaskStatus(taskKey, 'Failed');
      }
    }
  }

  Future<Null> _screenOff() async {
    try {
      await (await adb()).sendToSleep();
    } catch(error, stackTrace) {
      print('Failed to turn off screen: $error\n$stackTrace');
    }
  }

  Future<BuildResult> _runTask(TaskRunner runner) async {
    // Load-balance tests across attached devices
    await pickNextDevice();
    try {
      return await runner.run();
    } finally {
      await _screenOff();
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

Future<Null> _uploadDataToFirebase(BuildResult result) async {
  List<Map<String, dynamic>> golemData = <Map<String, dynamic>>[];

  for (TaskResult taskResult in result.results) {
    // TODO(devoncarew): We should also upload the fact that these tasks failed.
    if (taskResult.data == null)
      continue;

    Map<String, dynamic> data = new Map<String, dynamic>.from(taskResult.data.json);

    if (taskResult.data.benchmarkScoreKeys != null) {
      for (String scoreKey in taskResult.data.benchmarkScoreKeys) {
        String benchmarkName = '${taskResult.task.name}.$scoreKey';
        if (registeredBenchmarkNames.contains(benchmarkName)) {
          golemData.add(<String, dynamic>{
            'benchmark_name': benchmarkName,
            'golem_revision': result.golemRevision,
            'score': taskResult.data.json[scoreKey],
          });
        }
      }
    }

    data['__metadata__'] = <String, dynamic>{
      'success': taskResult.succeeded,
      'revision': taskResult.revision,
      'message': taskResult.message,
    };

    data['__golem__'] = golemData;

    uploadToFirebase(taskResult.task.name, data);
  }
}

Future<Null> _captureAsyncStacks(Future<Null> callback()) {
  Completer<Null> completer = new Completer<Null>();
  Chain.capture(() async {
    await callback();
    completer.complete();
  }, onError: (error, Chain chain) async {
    completer.completeError(error, chain);
  });
  return completer.future;
}
