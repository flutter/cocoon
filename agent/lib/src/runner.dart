// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

// TODO(dnfield): Move to replacement once we make it more reasnoable to
// upgrade the agent.
// ignore: deprecated_member_use
import 'package:vm_service_client/vm_service_client.dart';

import 'agent.dart';
import 'utils.dart';

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
      : succeeded = json['success'] as bool,
        data = json['data'] as Map<String, dynamic>,
        detailFilenames = json['detailFiles'],
        benchmarkScoreKeys = json['benchmarkScoreKeys'] ?? const <String>[],
        reason = json['reason'] as String;

  /// Constructs an unsuccessful result.
  TaskResult.failure(this.reason)
      : succeeded = false,
        data = const <String, dynamic>{},
        detailFilenames = null,
        benchmarkScoreKeys = const <String>[];

  /// Whether the task succeeded.
  final bool succeeded;

  /// Task-specific JSON data.
  final Map<String, dynamic> data;

  /// Names of files with Task-specific detail information (e.g. timeline trace).
  /// The files will be copied to an archival GCS bucket for later reference.
  final dynamic detailFilenames;

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
  final dynamic benchmarkScoreKeys;

  /// Whether the task failed.
  bool get failed => !succeeded;

  /// Explains the failure reason if [failed].
  final String reason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': succeeded,
      'data': data,
      'benchmarkScoreKeys': benchmarkScoreKeys,
      'reason': reason,
    };
  }
}

/// Runs a task in a separate Dart VM and collects the result using the VM
/// service protocol.
///
/// [taskName] is the name of the task. The corresponding task executable is
/// expected to be found under `bin/tasks`.
///
/// `fallbackTimeout` specifies the timeout to use if the task does not
/// specify a timeout. It defaults to having no timeout in such a case.
Future<TaskResult> runTask(
  Agent agent,
  CocoonTask task, {
  Duration fallbackTimeout,
}) async {
  String devicelabPath = '${config.flutterDirectory.path}/dev/devicelab';
  String taskExecutable = 'bin/tasks/${task.name}.dart';

  if (!file('$devicelabPath/$taskExecutable').existsSync()) throw 'Executable Dart file not found: $taskExecutable';

  int vmServicePort = await _findAvailablePort();
  Process runner;
  await inDirectory(devicelabPath, () async {
    runner = await startProcess(
        dartBin,
        <String>[
          '--disable-dart-dev',
          '--enable-vm-service=$vmServicePort',
          '--no-pause-isolates-on-exit',
          '--disable-service-auth-codes',
          taskExecutable,
          '--cloud-auth-token=${task.cloudAuthToken}',
        ],
        silent: true);
  });

  bool runnerFinished = false;

  // ignore: unawaited_futures
  runner.exitCode.then((_) {
    runnerFinished = true;
  });

  StringBuffer buffer = StringBuffer();

  Future<Null> sendLog(String message, {bool flush: false}) async {
    buffer.write(toLogString(message));
    logger.info('[task runner] [${task.name}] $message');
    // Send a chunk at a time, or upon request.
    if (flush || buffer.length > _kLogChunkSize) {
      String chunk = buffer.toString();
      buffer = StringBuffer();
      await agent.uploadLogChunk(task.key, chunk);
    }
  }

  await sendLog('Agent ID: ${agent.agentId}', flush: true);

  var stdoutSub = runner.stdout.transform(utf8.decoder).listen((String message) async {
    await sendLog(message);
  });
  var stderrSub = runner.stderr.transform(utf8.decoder).listen((String message) async {
    await sendLog(message);
  });

  String waitingFor = 'connection';
  try {
    VMIsolateRef isolate = await _connectToRunnerIsolate(vmServicePort);
    waitingFor = 'task completion';

    Map<String, String> arguments = <String, String>{};
    Duration taskTimeout = fallbackTimeout;
    if (task.timeoutInMinutes != 0) {
      taskTimeout = Duration(minutes: task.timeoutInMinutes);
      arguments['timeoutInMinutes'] = '${taskTimeout.inMinutes}';
    }

    Future<dynamic> invocation = isolate.invokeExtension('ext.cocoonRunTask', arguments);
    if (taskTimeout != null) {
      invocation = invocation.timeout(taskTimeout + _kGracePeriod);
    }
    Map<String, dynamic> taskResult = await invocation as Map<String, dynamic>;

    waitingFor = 'task process to exit';
    final Future<dynamic> whenProcessExits = Future.wait<void>([
      runner.exitCode,
      stdoutSub.asFuture(),
      stderrSub.asFuture(),
    ]);
    await whenProcessExits.timeout(const Duration(seconds: 1));
    // TODO(flar): for testing purposes only, remove before push
//    for (dynamic filename in taskResult['detailFiles']) {
//      await sendLog('Uploading $filename to testing bucket', flush: true);
//      await cpFileToGcs(filename as String, 'gs://flutter-dashboard-task-detail/testing/');
//    }
    return TaskResult.parse(taskResult);
  } on TimeoutException catch (timeout) {
    runner.kill(ProcessSignal.sigint);
    return TaskResult.failure('Timeout waiting for $waitingFor: ${timeout.message}');
  } finally {
    await stdoutSub.cancel();
    await stderrSub.cancel();
    await sendLog('Task execution finished', flush: true);
    // Force-quit the task runner process.
    if (!runnerFinished) runner.kill(ProcessSignal.sigkill);
    // Force-quit dangling local processes (such as adb commands).
    await forceQuitRunningProcesses();
  }
}

Future<VMIsolateRef> _connectToRunnerIsolate(int vmServicePort) async {
  String url = 'ws://localhost:$vmServicePort/ws';
  DateTime started = DateTime.now();

  // TODO(yjbanov): due to lack of imagination at the moment the handshake with
  //                the task process is very rudimentary and requires this small
  //                delay to let the task process open up the VM service port.
  //                Otherwise we almost always hit the non-ready case first and
  //                wait a whole 1 second, which is annoying.
  await Future<void>.delayed(const Duration(milliseconds: 100));

  while (true) {
    try {
      // Make sure VM server is up by successfully opening and closing a socket.
      await (await WebSocket.connect(url)).close();

      // Look up the isolate.
      VMServiceClient client = VMServiceClient.connect(url);
      VM vm = await client.getVM();
      VMIsolateRef isolate = vm.isolates.single;
      String response = await isolate.invokeExtension('ext.cocoonRunnerReady') as String;
      if (response != 'ready') throw 'not ready yet';
      return isolate;
    } catch (error) {
      const Duration connectionTimeout = const Duration(seconds: 10);
      if (DateTime.now().difference(started) > connectionTimeout) {
        throw TimeoutException(
          'Failed to connect to the task runner process',
          connectionTimeout,
        );
      }
      logger.info('VM service not ready yet: $error');
      const Duration pauseBetweenRetries = const Duration(milliseconds: 200);
      logger.info('Will retry in $pauseBetweenRetries.');
      await Future<void>.delayed(pauseBetweenRetries);
    }
  }
}

Future<int> _findAvailablePort() async {
  int port = 20000;
  while (true) {
    try {
      ServerSocket socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return port;
    } catch (_) {
      port++;
    }
  }
}
