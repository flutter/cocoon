// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

/// Returns a list of Process IDs (PIDs).
Future<List<int>> listFlutterProcessIds(Directory flutterDirectory) {
  if (Platform.isMacOS || Platform.isLinux) {
    return _listFlutterProcessesPosix(flutterDirectory);
  }
  if (Platform.isWindows) {
    return _listFlutterProcessesWindows(flutterDirectory);
  }
  throw 'Unsupported platform: ${Platform.operatingSystem}';
}

// POSIX implementation

Future<List<int>> _listFlutterProcessesPosix(Directory flutterDirectory) async {
  List<ProcessListResult> processes = await _listProcessesPosix();
  return processes
      .where((ProcessListResult result) => result.currentWorkingDirectory.contains(flutterDirectory.absolute.path))
      .map((ProcessListResult result) => result.processId)
      .toList();
}

class ProcessListResult {
  ProcessListResult({@required this.processId, @required this.currentWorkingDirectory});

  /// The "PID" field reported by `ps`.
  final int processId;

  /// The "cwd" field reported by `lsof`.
  final String currentWorkingDirectory;
}

final _emptySpace = RegExp(r'\s+');

Future<List<ProcessListResult>> _listProcessesPosix() async {
  var results = <ProcessListResult>[];
  String ps = await eval('ps', ['-ef', '-u', Platform.environment['USER']]);
  for (String psLine in ps.split('\n').skip(1)) {
    int processId = int.parse(psLine.trim().split(_emptySpace)[1].trim());
    String lsof = await eval('lsof', ['-p', '$processId'], canFail: true, silent: true);
    Iterable<String> cwdGrep = grep('cwd', from: lsof);
    if (cwdGrep.isEmpty) {
      // Not all processes report cwd; skip those, unlikely to be interesting.
      continue;
    }
    String cwd = cwdGrep.first.split(' ').last;
    results.add(ProcessListResult(
      processId: processId,
      currentWorkingDirectory: cwd,
    ));
  }
  return results;
}

// Windows implementation

const String _handleUtil = 'handle64';
final RegExp _pid = RegExp(r'.*pid: (\d+).*');

Future<List<int>> _listFlutterProcessesWindows(Directory flutterDirectory) async {
  if (!canRun(_handleUtil))
    throw 'Please add Microsoft\'s Handle utility to your PATH: '
        'https://technet.microsoft.com/en-us/sysinternals/handle.aspx';
  // `handle` return non-zero exit code when no process is found.
  String result = await eval(_handleUtil, [path.canonicalize(flutterDirectory.absolute.path)], canFail: true);

  return _pid
      .allMatches(result)
      .map((Match m) => int.parse(m.group(1)))
      .where((int matchedPid) => matchedPid != pid) // Exclude our own PID.
      .toList();
}
