// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import '../agent.dart';
import '../health.dart';
import '../runner.dart';
import '../utils.dart';

/// Runs a single task at a specified revision.
class RunCommand extends Command {
  RunCommand(Agent agent) : super('run', agent);

  static ArgParser argParser = ArgParser()..addOption('task', abbr: 't')..addOption('revision', abbr: 'r');

  @override
  Future<Null> run(ArgResults args) async {
    logger.info('Running with args: ${args.arguments}');
    String taskName = args['task'] as String;
    if (taskName == null) throw ArgumentError('--task is required');
    String revision = args['revision'] as String;

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

    // TODO(https://github.com/flutter/flutter/issues/29141) - remove
    // once source of leaked processes is identified.
    if (Platform.isWindows) {
      // Kill all dart.exe that are potentially holding flutter bin/cache,
      // preventing it from being deleted.
      await killAllRunningProcessesOnWindows('dart');
    }

    CocoonTask task = CocoonTask(name: taskName, revision: revision, timeoutInMinutes: 0);
    TaskResult result;
    try {
      if (task.revision != null) {
        // Sync flutter outside of the task so it does not contribute to
        // the task timeout.
        await getFlutterAt(task.revision).timeout(const Duration(minutes: 10));
      } else {
        logger.info('NOTE: No --revision specified. Running on current checkout.');
      }
      result = await runTask(agent, task);
    } catch (error, stackTrace) {
      logger.error('ERROR: $error\n$stackTrace');
    } finally {
      await forceQuitRunningProcesses();
    }
    section('Task result');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName" ${result.succeeded}');
    exit(result.succeeded ? 0 : 1);
  }
}
