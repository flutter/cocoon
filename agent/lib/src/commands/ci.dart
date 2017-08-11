// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/args.dart';

import '../adb.dart';
import '../agent.dart';
import '../health.dart';
import '../runner.dart';
import '../utils.dart';

/// Maximum amount of time we're allowing Flutter to install.
const Duration _kInstallationTimeout = const Duration(minutes: 20);

/// Runs the agent in continuous integration mode.
///
/// In this mode the agent runs in an infinite loop, continuously asking for
/// more tasks from Cocoon, performing them and reporting back results.
class ContinuousIntegrationCommand extends Command {
  ContinuousIntegrationCommand() : super('ci', true);

  Agent _agent;

  @override
  Future<Null> run(ArgResults args, SendPort mainIsolate) async {
    _agent = new Agent.fromConfig();
    // This try/catch captures errors that we cannot send to the server,
    // because we have not yet reserved a task. It will simply log to the
    // console.
    try {
      section('Preflight checks');
      await devices.performPreflightTasks();

      // Check health before requesting a new task.
      AgentHealth health = await performHealthChecks(_agent);

      // Always upload health status whether succeeded or failed.
      await _agent.updateHealthStatus(health);

      if (!health.ok) {
        print('Some health checks failed:');
        print(health);
        // Don't bother requesting new tasks if health is bad.
        return;
      }

      section('Requesting a task');
      CocoonTask task = await _agent.reserveTask();

      // Errors that happen inside this try/catch will be uploaded to the
      // server because we have succeeded at reserving a task.
      try {
        if (task != null) {
          section('Task info:');
          print('  name           : ${task.name}');
          print('  key            : ${task.key ?? ""}');
          print('  revision       : ${task.revision}');
          if (task.timeoutInMinutes != 0) {
            print('  custom timeout : ${task.timeoutInMinutes}');
          }

          mainIsolate.send(taskTimeout(task));

          // Sync flutter outside of the task so it does not contribute to
          // the task timeout.
          await getFlutterAt(task.revision).timeout(_kInstallationTimeout);
          await _runTask(task);
        } else {
          print('No tasks available for this agent.');
        }
      } catch (error, stackTrace) {
        String errorMessage = 'ERROR: $error\n$stackTrace';
        print(errorMessage);
        await _agent.reportFailure(task.key, errorMessage);
      }
    } finally {
      await _screensOff();
      await forceQuitRunningProcesses();
    }
  }

  Future<Null> _runTask(CocoonTask task) async {
    TaskResult result = await runTask(_agent, task);
    if (result.succeeded) {
      await _agent.reportSuccess(task.key, result.data, result.benchmarkScoreKeys);
    } else {
      await _agent.reportFailure(task.key, result.reason);
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
}
