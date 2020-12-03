// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8, LineSplitter;
import 'dart:io';

import 'utils.dart';

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];

class ProcessInfo {
  ProcessInfo(this.command, this.process);

  final DateTime startTime = DateTime.now();
  final String command;
  final Process process;

  @override
  String toString() {
    return '''
  command : $command
  started : $startTime
  pid     : ${process.pid}
'''
        .trim();
  }
}
Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, bool silent: false}) async {
  String command = '$executable ${arguments?.join(" ") ?? ""}';
  if (!silent) logger.info('Executing: $command');
  Process proc =
      await processManager.start(<String>[executable]..addAll(arguments), environment: env, workingDirectory: cwd);
  ProcessInfo procInfo = ProcessInfo(command, proc);
  _runningProcesses.add(procInfo);

  // ignore: unawaited_futures
  proc.exitCode.then((_) {
    _runningProcesses.remove(procInfo);
  });

  return proc;
}

/// Executes a command and returns its exit code.
Future<int> exec(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false, bool silent: false}) async {
  Process proc = await startProcess(executable, arguments, env: env, silent: silent);

  final StreamSubscription<String> stdoutSubscription =
      proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(logger.info);
  final StreamSubscription<String> stderrSubscription =
      proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(logger.warning);

  // Wait for stdout and stderr to be fully processed because proc.exitCode
  // may complete first.
  await Future.wait<void>(<Future<void>>[
    stdoutSubscription.asFuture<void>(),
    stderrSubscription.asFuture<void>(),
  ]);
  // The streams as futures have already completed, so waiting for the
  // potentially async stream cancellation to complete likely has no benefit.
  unawaited(stdoutSubscription.cancel());
  unawaited(stderrSubscription.cancel());

  int exitCode = await proc.exitCode;
  if (exitCode != 0 && !canFail) {
    final List<String> command = [executable]..addAll(arguments);
    fail('Command "${command.join(' ')}" failed with exit code $exitCode.');
  }

  return exitCode;
}

/// Executes a command and returns its standard output as a String.
///
/// Standard error is redirected to the current process' standard error stream.
Future<String> eval(String executable, List<String> arguments,
    {Map<String, String> env, bool canFail: false, bool silent: false}) async {
  Process proc = await startProcess(executable, arguments, env: env, silent: silent);
  proc.stderr.listen((List<int> data) {
    stderr.add(data);
  });
  String output = await utf8.decodeStream(proc.stdout);
  int exitCode = await proc.exitCode;

  if (exitCode != 0 && !canFail) fail('Executable $executable failed with exit code $exitCode.');

  return output.trimRight();
}

Future<void> killAllRunningProcessesOnWindows(String processName) async {
  while (true) {
    final pids = runningProcessesOnWindows(processName);
    if (pids.isEmpty) {
      return;
    }
    for (String pid in pids) {
      processManager.runSync(<String>['taskkill', '/pid', pid, '/f']);
    }
    // Killed processes don't release resources instantenously.
    await Future<void>.delayed(Duration(seconds: 1));
  }
}
