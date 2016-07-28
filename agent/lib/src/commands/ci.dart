// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../agent.dart';
import '../utils.dart';

/// Agents periodically poll the server for more tasks. This sleep period is
/// used to prevent us from DDoS-ing the server.
const Duration _sleepBetweenBuilds = const Duration(seconds: 10);

/// Maximum amount of time a single task is allowed to take.
///
/// After that the task is killed and reported as failed.
const Duration _taskTimeout = const Duration(minutes: 10);

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
    _listenToShutdownSignals();
    while(!_exiting) {
      try {
        CocoonTask task = await agent.reserveTask();
        try {
          if (task != null) {
            // Sync flutter outside of the task so it does not contribute to
            // the task timeout.
            await getFlutterAt(task.revision);

            // No need to pass revision as repo syncing is done here.
            List<String> runnerArgs = <String>[
              'run',
              '--task-name=${task.name}',
              '--task-key=${task.key}',
            ];

            Process proc = await startProcess(
              dartBin,
              [config.runTaskFile.path]..addAll(runnerArgs),
              onKill: new Future.delayed(_taskTimeout)
            );

            StringBuffer logBuffer = new StringBuffer();
            proc.stdout.transform(UTF8.decoder).listen((String s) {
              logBuffer.write(s);
            });
            proc.stderr.transform(UTF8.decoder).listen((String s) {
              logBuffer.write(s);
            });

            await proc.exitCode;

            // TODO(yjbanov): do indeed upload the log
            // await agent.uploadLog(task.key, log);
          }
        } catch(error, stackTrace) {
          print('ERROR: $error\n$stackTrace');
          await agent.updateTaskStatus(task.key, 'Failed');
        }
      } catch(error, stackTrace) {
        print('ERROR: $error\n$stackTrace');
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
