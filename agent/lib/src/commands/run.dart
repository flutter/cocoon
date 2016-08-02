// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:stack_trace/stack_trace.dart';

import '../adb.dart';
import '../agent.dart';
import '../golem.dart';
import '../firebase.dart';
import '../framework.dart';
import '../utils.dart';

/// Runs the agent once to perform a specific task and, optionally, report the
/// result back to Cocoon backend.
///
/// The task is run at the currently synced revision of Flutter. This command
/// assumes that Flutter is already synced to the desired revision.
class RunCommand extends Command {
  RunCommand(Agent agent) : super('run', agent);

  static final ArgParser argParser = new ArgParser()
    ..addOption(
      'task-name',
      help: '(required) The name of the task to run.'
    )
    ..addOption(
      'task-key',
      help: '(optional) The key of the task to update the status of in Cocoon. '
            'It is only required if you want the runner to upload logs and '
            'change task status in Cocoon.'
    );

  @override
  Future<Null> run(ArgResults args) async {
    CocoonTask task = new CocoonTask(
      name: args['task-name'],
      key: args['task-key'],
      revision: await getCurrentFlutterRepoCommit()
    );

    section('Task info:');
    print('  name     : ${task.name}');
    print('  key      : ${task.key ?? ""}');
    print('  revision : ${task.revision}');

    if (task.name == null || task.name == '') {
      print('\n Incorrect command-line options. Usage:');
      print(argParser.usage);
      exit(1);
    }

    try {
      await runAndCaptureAsyncStacks(() async {
        // Load-balance tests across attached devices
        pickNextDevice();

        BuildResult result = await agent.performTask(task);
        if (task.key != null) {
          if (result.succeeded) {
            await agent.updateTaskStatus(task.key, 'Succeeded');
            await _uploadDataToFirebase(result);
          } else {
            await agent.updateTaskStatus(task.key, 'Failed');
          }
        }
      }).timeout(taskTimeout);
    } catch(error, chain) {
      // TODO(yjbanov): upload logs
      print('Caught: $error\n${(chain as Chain).terse}');
      if (task.key != null)
        await agent.updateTaskStatus(task.key, 'Failed');
      exitCode = 1;
    } finally {
      await forceQuitRunningProcesses();
    }
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
