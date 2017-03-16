// Copyright 2017 The Chromium Authors. All rights reserved.
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

  static ArgParser argParser = new ArgParser()
    ..addOption('task', abbr: 't')
    ..addOption('revision', abbr: 'r');

  @override
  Future<Null> run(ArgResults args) async {
    print(args);
    String taskName = args['task'];
    if (taskName == null)
      throw new ArgumentError('--task is required');
    String revision = args['revision'];

    AgentHealth health = await performHealthChecks(agent);
    section('Pre-flight checks:');
    print(health);

    if (!health.ok) {
      print('Some pre-flight checks failed. Quitting.');
      exit(1);
    }

    CocoonTask task = new CocoonTask(name: taskName, revision: revision);
    TaskResult result;
    try {
      if (task.revision != null) {
        // Sync flutter outside of the task so it does not contribute to
        // the task timeout.
        await getFlutterAt(task.revision).timeout(const Duration(minutes: 10));
      } else {
        print('NOTE: No --revision specified. Running on current checkout.');
      }
      result = await runTask(agent, task);
    } catch(error, stackTrace) {
      print('ERROR: $error\n$stackTrace');
    } finally {
      await forceQuitRunningProcesses();
    }
    section('Task result');
    print(const JsonEncoder.withIndent('  ').convert(result));
    section('Finished task "$taskName" ${result.succeeded}');
    exit(result.succeeded ? 0 : 1);
  }
}
