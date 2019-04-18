// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

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
    health
        .toString()
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .forEach(logger.info);

    if (!health.ok) {
      logger.error('Some pre-flight checks failed. Quitting.');
      exit(1);
    }

    // Do not quit on uncaught exceptions because we're in CI mode.
    Isolate.current.setErrorsFatal(false);

    // Start CI mode
    section('Started continuous integration:');
    _listenToShutdownSignals();
    while (!_exiting) {
      await runZoned(() async {
        agent.resetHttpClient();

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
            logger.warning('Some health checks failed:');
            health
                .toString()
                .split('\n')
                .map((String line) => line.trim())
                .where((String line) => line.isNotEmpty)
                .forEach(logger.warning);
            await Future<void>.delayed(_sleepBetweenBuilds);
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
              logger.info('  name           : ${task.name}');
              logger.info('  key            : ${task.key ?? ""}');
              logger.info('  revision       : ${task.revision}');
              if (task.timeoutInMinutes != 0) {
                logger.info('  custom timeout : ${task.timeoutInMinutes}');
              }

              // Sync flutter outside of the task so it does not contribute to
              // the task timeout.
              await getFlutterAt(task.revision).timeout(_kInstallationTimeout);
              await _cleanBuildDirectories(agent, task);
              await _runTask(task);
            } else {
              logger.info('No tasks available for this agent.');
            }
          } catch (error, stackTrace) {
            String errorMessage = 'ERROR: $error\n$stackTrace';
            logger.error(errorMessage);
            await agent.reportFailure(task.key, errorMessage);
          }
        } catch (error, stackTrace) {
          // Unable to report failure to the backend.
          stderr.writeln('ERROR: $error\n$stackTrace');
        } finally {
          await _screensOff();
          await forceQuitRunningProcesses();
        }

        logger.info('Pausing before asking for more tasks.');
        await Future<void>.delayed(_sleepBetweenBuilds);
      }, onError: (dynamic error, StackTrace stackTrace) {
        // Catches errors from dangling futures that cannot be reported to the
        // server.
        stderr.writeln('ERROR: $error\n$stackTrace');
      });
    }
  }

  /// Recursively finds all Dart packages in the cloned Flutter repository
  /// (i.e. directories with `pubspec.yaml` files), and deletes the `build`
  /// directories, if any.
  ///
  /// This is to prevent cross-contamination of build artifacts across tests.
  Future<Null> _cleanBuildDirectories(Agent agent, CocoonTask task) async {
    Future<Null> recursivelyDeleteBuildDirectories(Directory directory) async {
      final List<FileSystemEntity> contents = directory.listSync();
      final bool isDartPackage = contents.any((FileSystemEntity entity) =>
          entity is File && path.basename(entity.path) == 'pubspec.yaml');
      if (isDartPackage) {
        for (FileSystemEntity entity in contents) {
          if (entity is Directory && path.basename(entity.path) == 'build') {
            await agent.uploadLogChunk(task.key, 'Deleting ${entity.path}\n');
            rrm(entity);
          }
        }
      } else {
        for (FileSystemEntity entity in contents) {
          if (entity is Directory) {
            await recursivelyDeleteBuildDirectories(entity);
          }
        }
      }
    }

    await agent.uploadLogChunk(
        task.key, 'Deleting build/ directories, if any.\n');
    try {
      await recursivelyDeleteBuildDirectories(config.flutterDirectory);
    } catch (error, stack) {
      await agent.uploadLogChunk(
        task.key,
        'Failed to delete build/ directories: $error\n\n$stack',
      );
    }
  }

  Future<Null> _runTask(CocoonTask task) async {
    TaskResult result = await runTask(agent, task);
    if (result.succeeded) {
      await agent.reportSuccess(
          task.key, result.data, result.benchmarkScoreKeys);
    } else {
      await agent.reportFailure(task.key, result.reason);
    }
  }

  Future<Null> _screensOff() async {
    try {
      for (Device device in await devices.discoverDevices()) {
        await device.disableAccessibility();
        await device.sendToSleep();
      }
    } catch (error, stackTrace) {
      // Best effort only.
      logger.warning('Failed to turn off screen: $error\n$stackTrace');
    }
  }

  void _listenToShutdownSignals() {
    _streamSubscriptions.add(ProcessSignal.sigint.watch().listen((_) {
      logger.info('\nReceived SIGINT. Shutting down.');
      _stop(ProcessSignal.sigint);
    }));
    if (!Platform.isWindows) {
      _streamSubscriptions.add(ProcessSignal.sigterm.watch().listen((_) {
        logger.info('\nReceived SIGTERM. Shutting down.');
        _stop(ProcessSignal.sigterm);
      }));
    }
  }

  Future<Null> _stop(ProcessSignal signal) async {
    _exiting = true;
    for (StreamSubscription sub in _streamSubscriptions) {
      await sub.cancel();
    }
    _streamSubscriptions.clear();
    // TODO(yjbanov): stop processes launched by tasks, if any
    await Future<void>.delayed(const Duration(seconds: 1));
    exit(0);
  }
}
