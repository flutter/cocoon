// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'utils.dart';

List<ProcessInfo> _runningProcesses = <ProcessInfo>[];

/// Defines detailed information of a process.
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

/// Starts a process for an executable command, and returns the processes.
Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, bool silent: false}) async {
  ProcessManager processManager = LocalProcessManager();
  String command = '$executable ${arguments?.join(" ") ?? ""}';
  if (!silent) logger.info('Executing: $command');
  Process proc = await processManager.start(<String>[executable]..addAll(arguments),
      environment: env, workingDirectory: path.current);
  ProcessInfo procInfo = ProcessInfo(command, proc);
  _runningProcesses.add(procInfo);

  // ignore: unawaited_futures
  proc.exitCode.then((_) {
    _runningProcesses.remove(procInfo);
  });

  return proc;
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
