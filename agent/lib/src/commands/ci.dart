// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../adb.dart';
import '../agent.dart';
import '../firebase.dart';
import '../framework.dart';
import '../utils.dart';

/// Agents periodically poll the server for more tasks. This sleep period is
/// used to prevent us from DDoS-ing the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

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
    AgentHealth health = await _performHealthChecks();
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
        health = await _performHealthChecks();

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
            // Sync flutter outside of the task so it does not contribute to
            // the task timeout.
            await getFlutterAt(task.revision).timeout(const Duration(minutes: 10));

            // No need to pass revision as repo syncing is done here.
            List<String> runnerArgs = <String>[
              'run',
              '--task-name=${task.name}',
              '--task-key=${task.key}',
            ];

            Process proc = await startProcess(
              dartBin,
              [config.runTaskFile.path]..addAll(runnerArgs)
            ).timeout(const Duration(minutes: 1));

            _logStandardStreams(task, proc);
            await proc.exitCode.timeout(taskTimeoutWithGracePeriod);
          }
        } catch(error, stackTrace) {
          print('ERROR: $error\n$stackTrace');
          await agent.updateTaskStatus(task.key, 'Failed');
        }
      } catch(error, stackTrace) {
        print('ERROR: $error\n$stackTrace');
      } finally {
        await forceQuitRunningProcesses();
      }

      await new Future.delayed(_sleepBetweenBuilds);
    }
  }

  Future<AgentHealth> _performHealthChecks() async {
    AgentHealth results = new AgentHealth();
    try {
      results['firebase-connection'] = await checkFirebaseConnection();

      Map<String, HealthCheckResult> deviceChecks = await devices.checkDevices();
      results.addAll(deviceChecks);

      bool hasHealthyDevices = deviceChecks.values
        .where((HealthCheckResult r) => r.succeeded)
        .isNotEmpty;

      results['has-healthy-devices'] = hasHealthyDevices
        ? new HealthCheckResult.success('Found ${deviceChecks.length} healthy devices')
        : new HealthCheckResult.failure('No attached devices were found.');

      try {
        String authStatus = await agent.getAuthenticationStatus();
        results['cocoon-connection'] = new HealthCheckResult.success();

        if (authStatus != 'OK') {
          results['cocoon-authentication'] = new HealthCheckResult.failure('Failed to authenticate to Cocoon. Check config.yaml.');
        } else {
          results['cocoon-authentication'] = new HealthCheckResult.success();
        }
      } catch(e, s) {
        results['cocoon-connection'] = new HealthCheckResult.error(e, s);
      }

      results['able-to-perform-health-check'] = new HealthCheckResult.success();
    } catch(e, s) {
      results['able-to-perform-health-check'] = new HealthCheckResult.error(e, s);
    }

    results['ssh-connectivity'] = await _scrapeRemoteAccessInfo();

    return results;
  }

  /// Listens to standard output and upload logs to Cocoon in semi-realtime.
  Future<Null> _logStandardStreams(CocoonTask task, Process proc) async {
    StringBuffer buffer = new StringBuffer();

    Future<Null> sendLog(String message, {bool flush: false}) async {
      buffer.write(message);
      print('[task runner] $message');
      // Send in chunks 100KB each, or upon request.
      if (flush || buffer.length > 100000) {
        String chunk = buffer.toString();
        buffer = new StringBuffer();
        await agent.uploadLogChunk(task, chunk);
      }
    }

    proc.stdout.transform(UTF8.decoder).listen((String s) {
      sendLog(s);
    });
    proc.stderr.transform(UTF8.decoder).listen((String s) {
      sendLog(s);
    });
    await proc.exitCode;
    sendLog('Task execution finished', flush: true);
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
}

Future<Null> getFlutterAt(String revision) async {
  String currentRevision = await getCurrentFlutterRepoCommit();

  // This agent will likely run multiple tasks in the same checklist and
  // therefore the same revision. It would be too costly to have to reinstall
  // Flutter every time.
  if (currentRevision == revision) {
    print('Reusing previously checked out Flutter revision: $revision');
    return;
  }

  await getFlutter(revision);
}

/// Returns the IP address for remote (SSH) access to this agent.
///
/// Uses `ipconfig getifaddr en0`.
///
/// Always returns [new HealthCheckResult.success] regardless of whether an IP
/// is available or not. Having remote access to an agent is not a prerequisite
/// for being able to perform Cocoon tasks. It's only there to make maintenance
/// convenient. The goal is only to report available IPs as part of the health
/// check.
Future<HealthCheckResult> _scrapeRemoteAccessInfo() async {
  String ip = (await eval('ipconfig', ['getifaddr', 'en0'], canFail: true)).trim();

  return new HealthCheckResult.success(ip.isEmpty
    ? 'No IP found for remote (SSH) access to this client. '
      'Did you forget to plug the Ethernet cable?'
    : 'Possible remote access IP: $ip'
  );
}
