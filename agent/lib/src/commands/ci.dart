// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import '../adb.dart';
import '../agent.dart';
import '../firebase.dart';
import '../golem.dart';
import '../health.dart';
import '../runner.dart';
import '../utils.dart';

/// Agents periodically poll the server for more tasks. This sleep period is
/// used to prevent us from DDoS-ing the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

/// Maximum amount of time we're allowing Flutter to install.
const Duration _kInstallationTimeout = const Duration(minutes: 20);

/// Runs the agent in continuous integration mode.
///
/// In this mode the agent runs in an infinite loop, continuously asking for
/// more tasks from Cocoon, performing them and reporting back results.
class ContinuousIntegrationCommand extends Command {
  ContinuousIntegrationCommand(Agent agent) : super('ci', agent);

  final List<StreamSubscription> _streamSubscriptions = <StreamSubscription>[];

  bool _exiting = false;

  @override
  Future<Null> run(ArgResults args) async {
    // Perform one pre-flight round of checks and quit immediately if something
    // is wrong.
    AgentHealth health = await performHealthChecks(agent);
    section('Pre-flight checks:');
    print(health);

    if (!health.ok) {
      print('Some pre-flight checks failed. Quitting.');
      exit(1);
    }

    // Start CI mode
    section('Started continuous integration:');
    _listenToShutdownSignals();
    while(!_exiting) {
      try {
        await devices.performPreflightTasks();

        // Check health before requesting a new task.
        health = await performHealthChecks(agent);

        // Always upload health status whether succeeded or failed.
        await agent.updateHealthStatus(health);

        if (!health.ok) {
          print('Some health checks failed:');
          print(health);
          await new Future.delayed(_sleepBetweenBuilds);
          // Don't bother requesting new tasks if health is bad.
          continue;
        }

        CocoonTask task = await agent.reserveTask();
        try {
          if (task != null) {
            section('Task info:');
            print('  name           : ${task.name}');
            print('  key            : ${task.key ?? ""}');
            print('  revision       : ${task.revision}');
            if (task.timeoutInMinutes != 0) {
              print('  custom timeout : ${task.timeoutInMinutes}');
            }

            // Sync flutter outside of the task so it does not contribute to
            // the task timeout.
            await getFlutterAt(task.revision).timeout(_kInstallationTimeout);
            await _runTask(task);
          }
        } catch(error, stackTrace) {
          String errorMessage = 'ERROR: $error\n$stackTrace';
          print(errorMessage);
          await agent.reportFailure(task.key, errorMessage);
        }
      } catch(error, stackTrace) {
        print('ERROR: $error\n$stackTrace');
      } finally {
        await _screensOff();
        await forceQuitRunningProcesses();
      }

      await new Future.delayed(_sleepBetweenBuilds);
    }
  }

  Future<Null> _runTask(CocoonTask task) async {
    TaskResult result = await runTask(agent, task);
    if (result.succeeded) {
      await agent.reportSuccess(task.key, result.data, result.benchmarkScoreKeys);
      await _uploadDataToFirebase(task, result);
    } else {
      await agent.reportFailure(task.key, result.reason);
    }
  }

  Future<Null> _screensOff() async {
    try {
      for (Device device in await devices.discoverDevices()) {
        await device.sendToSleep();
      }
    } catch(error, stackTrace) {
      // Best effort only.
      print('Failed to turn off screen: $error\n$stackTrace');
    }
  }

  void _listenToShutdownSignals() {
    _streamSubscriptions.add(
      ProcessSignal.SIGINT.watch().listen((_) {
        print('\nReceived SIGINT. Shutting down.');
        _stop(ProcessSignal.SIGINT);
      })
    );
    if (!Platform.isWindows) {
      _streamSubscriptions.add(
        ProcessSignal.SIGTERM.watch().listen((_) {
          print('\nReceived SIGTERM. Shutting down.');
          _stop(ProcessSignal.SIGTERM);
       })
      );
    }
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
}



Future<Null> _uploadDataToFirebase(CocoonTask task, TaskResult result) async {
  List<Map<String, dynamic>> golemData = <Map<String, dynamic>>[];
  int golemRevision = await computeGolemRevision();

  Map<String, dynamic> data = <String, dynamic>{};

  if (result.data != null) {
    data.addAll(result.data);
  }

  if (result.benchmarkScoreKeys != null) {
    for (String scoreKey in result.benchmarkScoreKeys) {
      String benchmarkName = '${task.name}.$scoreKey';
      if (registeredBenchmarkNames.contains(benchmarkName)) {
        golemData.add(<String, dynamic>{
          'benchmark_name': benchmarkName,
          'golem_revision': golemRevision,
          'score': result.data[scoreKey],
        });
      }
    }
  }

  data['__metadata__'] = <String, dynamic>{
    'success': result.succeeded,
    'revision': task.revision,
    'message': result.reason ?? 'N/A',
  };

  data['__golem__'] = golemData;

  await uploadToFirebase(task.name, data);
}
