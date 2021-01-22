// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import 'dart:convert' show utf8;

const String kDevicePropertiesFilename = '.properties';
const String kDeviceFailedHealthcheckFilename = '.healthcheck';
const String kAttachedDeviceHealthcheckKey = 'attached_device';
const String kAttachedDeviceHealthcheckValue = 'No device is available';
final Logger logger = Logger('DeviceDoctor');

void fail(String message) {
  throw BuildFailedError(message);
}

class BuildFailedError extends Error {
  BuildFailedError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a directory from the given path, or multiple path parts by joining
/// them using OS-specific file path separator.
Directory dir(String thePath,
    [String part2, String part3, String part4, String part5, String part6, String part7, String part8]) {
  return Directory(path.join(thePath, part2, part3, part4, part5, part6, part7, part8));
}

Future<dynamic> inDirectory(dynamic directory, Future<dynamic> action()) async {
  String previousCwd = path.current;
  try {
    cd(directory);
    return await action();
  } finally {
    cd(previousCwd);
  }
}

void cd(dynamic directory) {
  Directory d;
  if (directory is String) {
    d = dir(directory);
  } else if (directory is Directory) {
    d = directory;
  } else {
    throw 'Unsupported type ${directory.runtimeType} of $directory';
  }

  if (!d.existsSync()) throw 'Cannot cd into directory that does not exist: $directory';
}

/// Starts a process for an executable command, and returns the processes.
Future<Process> startProcess(String executable, List<String> arguments,
    {Map<String, String> env, bool silent: false, ProcessManager processManager = const LocalProcessManager()}) async {
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
    {Map<String, String> env,
    bool canFail: false,
    bool silent: false,
    ProcessManager processManager = const LocalProcessManager()}) async {
  Process proc = await startProcess(executable, arguments, env: env, silent: silent, processManager: processManager);
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

/// Get file based on `Platform` home directory.
File getFile(String fileName) {
  if (Platform.isLinux || Platform.isMacOS) {
    return File(path.join(Platform.environment['HOME'], '$fileName'));
  }
  if (!Platform.isWindows) {
    throw StateError('Unexpected platform ${Platform.operatingSystem}');
  }
  return File(path.join(Platform.environment['USERPROFILE'], '.$fileName'));
}

/// Write [results] to [fileName] based on `Platform` home directory.
void writeToFile(String results, String fileName) {
  final File file = getFile(fileName);
  if (file.existsSync()) {
    try {
      file.deleteSync();
    } on FileSystemException catch (error) {
      print('Failed to delete ${file.path}: $error');
    }
  }
  file
    ..createSync()
    ..writeAsStringSync(results);
  return;
}
