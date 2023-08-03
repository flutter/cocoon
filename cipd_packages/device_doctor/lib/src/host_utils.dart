// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'dart:io';

import 'package:process/process.dart';

final RegExp _whitespace = RegExp(r'\s+');

/// Kill all running processes on windows.
///
/// This is used when we first fail to list devices and need a retry.
Future<bool> killAllRunningProcessesOnWindows(String processName, {ProcessManager? processManager}) async {
  processManager ??= LocalProcessManager();
  // Avoid endless loop when a process from a different use exists, and fails
  // to get killed every try.
  int tries = 3;
  while (tries > 0) {
    tries--;
    final pids = runningProcessesOnWindows(processName, processManager: processManager);
    if (pids.isEmpty) {
      return true;
    }
    for (String pid in pids) {
      processManager.runSync(<String>['taskkill', '/pid', pid, '/f']);
    }
    // Killed processes don't release resources instantenously.
    const Duration delay = Duration(seconds: 1);
    await Future<void>.delayed(delay);
  }
  return false;
}

List<String> runningProcessesOnWindows(String processName, {ProcessManager? processManager}) {
  processManager ??= LocalProcessManager();
  final ProcessResult result = processManager.runSync(<String>['powershell', 'Get-CimInstance', 'Win32_Process']);
  final List<String> pids = <String>[];
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
