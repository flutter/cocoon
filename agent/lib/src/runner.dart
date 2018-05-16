// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:vm_service_client/vm_service_client.dart';

import 'agent.dart';
import 'utils.dart';

/// The default task timeout, if a custom value is not provided.
///
/// This should be the same as `_kDefaultTaskTimeout` defined in https://github.com/flutter/flutter/blob/master/dev/devicelab/lib/framework/framework.dart
const Duration _kDefaultTaskTimeout = const Duration(minutes: 15);

/// Extra amount of time we give the devicelab task to finish or timeout on its
/// own before forcefully quitting it.
const Duration _kGracePeriod = const Duration(minutes: 1);

/// Send logs in 10KB chunks.
const int _kLogChunkSize = 10000;

/// A result of running a single task.
///
/// In normal circumstances, even when a task fails, the result is parsed from
/// JSON returned by the task runner process via the VM service. However, if
/// things are completely out of control and the task runner process is
/// corrupted a failed result can be instantiated directly using
/// [TaskResult.failure] constructor.
class TaskResult {
  /// Parses a task result from JSON.
  TaskResult.parse(Map<String, dynamic> json)
    : succeeded = json['success'],
      data = json['data'],
      benchmarkScoreKeys = json['benchmarkScoreKeys'] ?? const <String>[],
      reason = json['reason'];

  /// Constructs an unsuccessful result.
  TaskResult.failure(this.reason)
      : this.succeeded = false,
        this.data = const <String, dynamic>{},
        this.benchmarkScoreKeys = const <String>[];

  /// Whether the task succeeded.
  final bool succeeded;

  /// Task-specific JSON data.
  final Map<String, dynamic> data;

  /// Keys in [data] that store scores that will be submitted to Golem.
  ///
  /// Each key is also part of a benchmark's name tracked by Golem.
  /// A benchmark name is computed by combining [Task.name] with a key
  /// separated by a dot. For example, if a task's name is
  /// `"complex_layout__start_up"` and score key is
  /// `"engineEnterTimestampMicros"`, the score will be submitted to Golem under
  /// `"complex_layout__start_up.engineEnterTimestampMicros"`.
  ///
  /// This convention reduces the amount of configuration that needs to be done
  /// to submit benchmark scores to Golem.
  final List<String> benchmarkScoreKeys;

  /// Whether the task failed.
  bool get failed => !succeeded;

  /// Explains the failure reason if [failed].
  final String reason;

  Map<String, dynamic> toJson() {
    return {
      'success': succeeded,
      'data': data,
      'benchmarkScoreKeys': benchmarkScoreKeys,
      'reason' : reason,
    };
  }
}

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
Future<TaskResult> runTask(Agent agent, CocoonTask task) async {
  String devicelabPath = '${config.flutterDirectory.path}/dev/devicelab';
  String taskExecutable = 'bin/tasks/${task.name}.dart';

  if (!file('$devicelabPath/$taskExecutable').existsSync())
    throw 'Executable Dart file not found: $taskExecutable';

  int vmServicePort = await _findAvailablePort();
  Process runner;
  await inDirectory(devicelabPath, () async {
    runner = await startProcess(dartBin, <String>[
      '--enable-vm-service=$vmServicePort',
      '--no-pause-isolates-on-exit',
      taskExecutable,
      '--cloud-auth-token=${task.cloudAuthToken}',
    ], silent: true);
  });

  bool runnerFinished = false;

  // ignore: unawaited_futures
  runner.exitCode.then((_) {
    runnerFinished = true;
  });

  StringBuffer buffer = new StringBuffer();

  Future<Null> sendLog(String message, {bool flush: false}) async {
    buffer.write(message);
    print('[task runner] [${task.name}] $message');
    // Send a chunk at a time, or upon request.
    if (flush || buffer.length > _kLogChunkSize) {
      String chunk = buffer.toString();
      buffer = new StringBuffer();
      await agent.uploadLogChunk(task.key, chunk);
    }
  }

  var stdoutSub = runner.stdout.transform(utf8.decoder).listen((String message) async {
    await sendLog(message);
  });
  var stderrSub = runner.stderr.transform(utf8.decoder).listen((String message) async {
    await sendLog(message);
  });

  String waitingFor = 'connection';
  try {
    VMIsolate isolate = await _connectToRunnerIsolate(vmServicePort);
    waitingFor = 'task completion';

    Duration taskTimeout = task.timeoutInMinutes != 0
      ? new Duration(minutes: task.timeoutInMinutes)
      : _kDefaultTaskTimeout;

    Map<String, dynamic> taskResult =
        await isolate.invokeExtension('ext.cocoonRunTask', <String, String>{'timeoutInMinutes': '${taskTimeout.inMinutes}'})
            .timeout(taskTimeout + _kGracePeriod);

    waitingFor = 'task process to exit';
    final Future<dynamic> whenProcessExits = Future.wait([
      runner.exitCode,
      stdoutSub.asFuture(),
      stderrSub.asFuture(),
    ]);
    await whenProcessExits.timeout(const Duration(seconds: 1));
    return new TaskResult.parse(taskResult);
  } on TimeoutException catch (timeout) {
    runner.kill(ProcessSignal.sigint);
    return new TaskResult.failure(
      'Timeout waiting for $waitingFor: ${timeout.message}'
    );
  } finally {
    await stdoutSub.cancel();
    await stderrSub.cancel();
    await sendLog('Task execution finished', flush: true);
    // Force-quit the task runner process.
    if (!runnerFinished)
      runner.kill(ProcessSignal.sigkill);
    // Force-quit dangling local processes (such as adb commands).
    await forceQuitRunningProcesses();
  }
}

Future<VMIsolate> _connectToRunnerIsolate(int vmServicePort) async {
  String url = 'ws://localhost:$vmServicePort/ws';
  DateTime started = new DateTime.now();

  // TODO(yjbanov): due to lack of imagination at the moment the handshake with
  //                the task process is very rudimentary and requires this small
  //                delay to let the task process open up the VM service port.
  //                Otherwise we almost always hit the non-ready case first and
  //                wait a whole 1 second, which is annoying.
  await new Future<Null>.delayed(const Duration(milliseconds: 100));

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      VMServiceClient client = new VMServiceClient.connect(url);
      VM vm = await client.getVM();
      VMIsolate isolate = vm.isolates.single;
      String response = await isolate.invokeExtension('ext.cocoonRunnerReady');
      if (response != 'ready')
        throw 'not ready yet';
      return isolate;
    } catch (error) {
      const Duration connectionTimeout = const Duration(seconds: 2);
      if (new DateTime.now().difference(started) > connectionTimeout) {
        throw new TimeoutException(
          'Failed to connect to the task runner process',
          connectionTimeout,
        );
      }
      print('VM service not ready yet: $error');
      const Duration pauseBetweenRetries = const Duration(milliseconds: 200);
      print('Will retry in $pauseBetweenRetries.');
      await new Future<Null>.delayed(pauseBetweenRetries);
    }
  }
}

Future<int> _findAvailablePort() async {
  int port = 20000;
  while (true) {
    try {
      ServerSocket socket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return port;
    } catch (_) {
      port++;
    }
  }
}
