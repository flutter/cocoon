// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'utils.dart';

final RegExp _whitespace = RegExp(r'\s+');

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

/// Splits [from] into lines and selects those that contain [pattern].
Iterable<String> grep(Pattern pattern, {@required String from}) {
  return from.split('\n').where((String line) {
    return line.contains(pattern);
  });
}

Future<void> killAllRunningProcessesOnWindows(String processName, {ProcessManager processManager}) async {
  processManager ??= LocalProcessManager();
  // Avoid endless loop when a process from a different use exists, and fails
  // to get killed every try.
  int tries = 3;
  while (tries>0) {
    tries--;
    final pids = runningProcessesOnWindows(processName);
    if (pids.isEmpty) {
      return;
    }
    for (String pid in pids) {
      processManager.runSync(<String>['taskkill', '/pid', pid, '/f']);
    }
    // Killed processes don't release resources instantenously.
    const Duration delay = Duration(seconds: 1);
    await Future<void>.delayed(delay);
  }
}

List<String> runningProcessesOnWindows(String processName, {ProcessManager processManager}) {
  processManager ??= LocalProcessManager();
  final ProcessResult result = processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']);
  List<String> pids = <String>[];
  if (result.exitCode == 0) {
    final String stdoutResult = result.stdout as String;
    for (String rawProcess in stdoutResult.split('\n')) {
      final String process = rawProcess.trim();
      if (!process.contains(processName)) {
        continue;
      }
      final List<String> parts = process.split(_whitespace);

      final String processPid = parts[0];
      final String currentRunningProcessPid = pid.toString();
      // Don't kill current process
      if (processPid == currentRunningProcessPid) {
        continue;
      }
      pids.add(processPid);
    }
  }
  return pids;
}
