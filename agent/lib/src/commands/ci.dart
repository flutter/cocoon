// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';

import '../adb.dart';
import '../agent.dart';
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

    // Do not quit on uncaught exceptions because we're in CI mode.
    Isolate.current.setErrorsFatal(false);

    // Start CI mode
    section('Started continuous integration:');
    _listenToShutdownSignals();
    await runZoned(() async {
      while(!_exiting) {
        // This try/catch captures errors that we cannot send to the server,
        // because we have not yet reserved a task. It will simply log to the
        // console.
        try {
          section('Preflight checks');
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
            return;
          }

          section('Requesting a task');
          CocoonTask task = await agent.reserveTask();

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
            await agent.reportFailure(task.key, errorMessage);
          }
        } catch (error, stackTrace) {
          // Unable to report failure to the backend.
          stderr.writeln('ERROR: $error\n$stackTrace');
        } finally {
          await _screensOff();
          await forceQuitRunningProcesses();
        }

        print('Pausing before asking for more tasks.');
        await new Future.delayed(_sleepBetweenBuilds);
      }
    }, onError: (error, stackTrace) {
      // Catches errors from dangling futures that cannot be reported to the
      // server.
      stderr.writeln('ERROR: $error\n$stackTrace');
    });
  }

  Future<Null> _runTask(CocoonTask task) async {
    TaskResult result = await runTask(agent, task);
    if (result.succeeded) {
      await agent.reportSuccess(task.key, result.data, result.benchmarkScoreKeys);
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
